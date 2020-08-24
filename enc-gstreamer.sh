#!/bin/bash
set -e

fps=30
resw=1024
resh=720
ofsx=128
ofsy=32

src="$1"
codec="$2"
ctr="$3"
proto="$4"

[ -z "$proto" ] && { cat >&2 <<EOF

low latency stream generator; need 4 arguments:

1 source
   x11

2 codec
   mpeg1b mpeg4 h264b h264va

3 container
   ts h264

4 protocol
   tcp udp file stdout

EOF
exit 1
}

# for codec options see gst-inspect-1.0 avenc_mpeg1video


[ "$src" = x11 ] && args+=(
	ximagesrc startx=$ofsx starty=$ofsy endx=$((ofsx+resw-1)) endy=$((ofsy+resh-1)) use-damage=0 !
	videoconvert !
	video/x-raw,framerate=${fps}000/1001,format=I420,profile=constrained-baseline ! )


# baseline mpeg1 (jsmpeg)
#  (the gst-native mpeg1 encoder is garbage)
[ "$codec" = mpeg1b ] && args+=(
	avenc_mpeg1video gop-size=${fps}
		pass=quant global-quality=10 quantizer=10 !
	video/mpeg,mpegversion=1 ! )


# baseline h264 (broadway)
[ "$codec" = h264b ] && args+=(
	x264enc cabac=0 b-adapt=0 bframes=0 ref=4 byte-stream=1
	rc-lookahead=0 vbv-buf-capacity=0
	psy-tune=animation tune=zerolatency
	quantizer=34 key-int-max=30 pass=qual speed-preset=faster ! )


# baseline h264 (broadway), intel-hwaccel
[ "$codec" = h264va ] && args+=(
	vaapih264enc ! )


[ "$ctr" = h264 ] && args+=(
	video/x-h264,profile=constrained-baseline,stream-format=byte-stream ! )


[ "$ctr" = ts ] && args+=(
	mpegtsmux ! )


[ "$proto" = stdout ] && args+=(
	fdsink fd=0
)


[ "$proto" = tcp ] && args+=(
	tcpserversink host=0.0.0.0 port=3737 )


{
	printf '\n'
	printf '%s ' "${args[@]}"
	printf '\n\n'
} >&2


exec gst-launch-1.0 -v "${args[@]}" >&2 2>&1
