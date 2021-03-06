#!/bin/bash
set -e

fps=30
resw=1024
resh=768
ofsx=128
ofsy=32

src="$1"
codec="$2"
ctr="$3"
proto="$4"

[ -z "$proto" ] && { cat >&2 <<EOF

low latency stream generator; need 4 arguments:

1 source
   x11 mac kms kms-nv kms-va

2 codec
   mpeg1 mpeg1b mpeg2 mpeg4 vp8
   h264nv420 h264nv444 h264 h264b h264va
   h265nv420 h265nv444

3 container
   ts webm h264

4 protocol
   tcp udp file ice stdout

EOF
exit 1
}

# for codec options see ffmpeg -h encoder=mpeg2video

args=(
	-nostdin -hide_banner -color_range mpeg
	-color_primaries bt709 -color_trc bt709 -colorspace bt709
	-flush_packets 1 -fflags +nobuffer -flags +low_delay )

[ "$src" = x11 ] && args+=(
	-f x11grab -framerate $fps -s ${resw}x${resh} -i :0.0+${ofsx},${ofsy} -show_region 1 )

# ffmpeg -f avfoundation -list_devices true -i ""
#macfix="format=yuv444p16,lutyuv=y=val*1.02:v=val*1.03"
#macfix="lutrgb=r=val*1.07:g=val*1.05:b=val*1"
macfix="eq=gamma_r=1.08:gamma_g=1.06:gamma_b=1.07:saturation=1.1"
[ "$src" = mac ] && args+=(
	-f avfoundation -pixel_format bgr0 -framerate $fps -vsync 2
	-capture_cursor 1 -i "Capture screen 0"
	-copyts -start_at_zero
	-vf "crop=$resw:$resh:$ofsx:$ofsy,$macfix" )
	# ,eq=saturation=1.2:brightness=0.03

[ "$src" = kms ] && args+=(
	-f kmsgrab -framerate $fps -i - -vf 'hwdownload,format=bgr0' )

# kms-nvidia, untested
[ "$src" = kms-nv ] && args+=(
	-device /dev/dri/card0 -f kmsgrab -i - 
	-vf "hwupload_cuda,scale_npp=w=$resw:h=$resh:interp_algo=lanczos" 
	-c:v h264_nvenc -qp:v 19 -profile:v high -rc:v cbr_ld_hq \
	-level:v 4.2 -r:v $fps -g:v 120 -bf:v 3 -refs:v 16 )

# kms-intel, broken on i5-6200U, untested on recent gear
[ "$src" = kms-va ] && args+=(
	-threads:v 2 -filter_threads 2 -v debug
	-f kmsgrab -framerate $fps -i -
	-vf 'hwmap=derive_device=vaapi'
	-c:v h264_vaapi -profile:v constrained_baseline -qp 30 -g 30
	-level 3.1 -coder 0 -bf 0 -flags -loop )

# mpeg1;  1/9 sec latency
[ "$codec" = mpeg1 ] && args+=(
	-pix_fmt yuv420p
	-codec:v mpeg1video -b:v 2000k -q 10 -g 30 )

# baseline (jsmpeg)
[ "$codec" = mpeg1b ] && args+=(
	-pix_fmt yuv420p
	-codec:v mpeg1video -b:v 2000k -bf 0 -q 10 -g 30 )
	#-dst_range 1

# mpeg2;  1/9 sec latency using either tcp / http / icecast
[ "$codec" = mpeg2 ] && args+=(
	-pix_fmt yuv420p
	-codec:v mpeg2video -b:v 2000k -q 10 -g 30 )

# mpeg4;  1/12 sec latency (ice 1/11 sec)
[ "$codec" = mpeg4 ] && args+=(
	-pix_fmt yuv420p
	-codec:v mpeg4 -vtag xvid -q:v 12 -g 30 )
	# -bf 0

# x264;  1/9 sec latency (ice 1/8 sec)
[ "$codec" = h264 ] && args+=(
	-pix_fmt yuv420p
	-vcodec libx264 -tune zerolatency,animation -preset veryfast -g 30 -crf 26 )

# baseline (broadway)
[ "$codec" = h264b ] && args+=(
	-pix_fmt yuv420p
	-vcodec libx264 -tune zerolatency,animation -preset veryfast -g 30 -crf 26
	-profile:v baseline -coder 0 -bf 0 -flags -loop -wpredp 0 )

# h264_vaapi (intel);  1/7 sec latency
[ "$codec" = h264va ] && args+=(
	-vaapi_device /dev/dri/renderD128 -vf format=nv12,hwupload
	-c:v h264_vaapi -profile:v constrained_baseline -qp 30 -g 30
	-level 3.1 -coder 0 -bf 0 -flags -loop )

# h264_nvenc (nvidia);  1/9 sec latency (ice 1/7 sec)
[ "$codec" = h264nv420 ] ||
[ "$codec" = h264nv444 ] && args+=(
	-c:v h264_nvenc -preset llhq
	-profile baseline -level 3.1 -coder default
	-zerolatency 1 -rc constqp -qp 30 -g 30 )

[ "$codec" = h264nv420 ] && args+=( -pix_fmt yuv420p -profile:v high )
[ "$codec" = h264nv444 ] && args+=( -pix_fmt yuv444p16 -profile:v high444p )

# hevc_nvenc;  untested
[ "$codec" = h265nv420 ] ||
[ "$codec" = h265nv444 ] && args+=(
	-c:v hevc_nvenc -preset llhq  -profile:v main -tier high
	-zerolatency 1 -rc constqp -qp 30 -g 30 )

[ "$codec" = h265nv420 ] && args+=( -pix_fmt yuv420p )
[ "$codec" = h265nv444 ] && args+=( -pix_fmt yuv444p16 )

# vp8;  untested
[ "$codec" = vp8 ] && args+=(
	-pix_fmt yuv420p
	-c:v libvpx -profile:v 1 -deadline realtime -cpu-used 16
	-lag-in-frames 1 -bf 0 -b:v 4M -crf 40 -g 30 )


args+=( -color_range mpeg 
	-color_primaries bt709 -color_trc bt709 -colorspace bt709 )


[ "$ctr" = ts ] && args+=(
   -f mpegts )

[ "$ctr" = webm ] && args+=(
   -f webm )

[ "$ctr" = h264 ] && args+=(
   -f h264 )

[ "$proto" = tcp ] && [ "$ctr" = ts ] && args+=(
	'tcp://127.0.0.1:3737/?listen=1&tcp_nodelay=1&tcp_mss=188&send_buffer_size=188' )

[ "$proto" = udp ] && [ "$ctr" = ts ] && args+=(
	'udp://127.0.0.1:3737/?reuse=1&pkt_size=188&buffer_size=188' )

[ "$proto" = tcp ] && [ "$ctr" = webm ] && args+=(
	'tcp://127.0.0.1:3737/?listen=1&tcp_nodelay=1' )

[ "$proto" = udp ] && [ "$ctr" = webm ] && args+=(
	'udp://127.0.0.1:3737/?reuse=1' )

[ "$proto" = file ] && args+=(
	-y /dev/shm/tmp.nut )

[ "$proto" = ice ] && args+=(
	-content_type video/MP2T icecast://source:hackme@127.0.0.1:8000/the.$ctr )

[ "$proto" = stdout ] && args+=(
	-
)


{
	printf '\n'
	printf '%s ' "${args[@]}"
	printf '\n\n'
} >&2

exec ffmpeg "${args[@]}"
