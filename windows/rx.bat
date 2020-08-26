@rem ffmpeg -hide_banner -protocol_whitelist file,crypto,data,udp,rtp -i sdp -c copy -c:v rawvideo -f sdl - & exit /b
@rem ffmpeg -hide_banner -protocol_whitelist file,crypto,data,udp,rtp -i sdp -c copy -f nut - | ffplay -hide_banner -v fatal - & exit /b

@echo %PATH% | find /i "gstreamer" >nul || set "PATH=C:\gstreamer\1.0\msvc_x86_64\bin;%PATH%"

rem autovideosink  -- uses d3d11 on win10.1809
rem directdrawsink -- dx7+
rem dshowvideosink -- vista+
rem d3dvideosink   -- newest ! videobalance brightness=-0.057 contrast=1.15 hue=0.025 saturation=1.2
rem d3d11videosink -- best   ! videobalance brightness=0.006 contrast=1.157 saturation=1.15

rem avdec_h264 output-corrupt=1
rem d3d11h264dec
rem nvh264dec

gst-launch-1.0 -v rtpbin name=r ^
udpsrc port=4322 ! r.recv_rtcp_sink_0 ^
udpsrc port=4321 caps="application/x-rtp, media=video, encoding-name=H264, payload=96, clock-rate=90000" ^
! r.recv_rtp_sink_0 r. ^
! queue ^
! rtph264depay ^
! h264parse disable-passthrough=1 ^
! tee name=t ^
t. ^
! avdec_h264 output-corrupt=1 ^
! videobalance brightness=0.006 contrast=1.157 saturation=1.22 ^
! videoconvert ^
! d3d11videosink max-lateness=2000000 sync=0 ^
t. ^
! queue ^
! matroskamux ^
! filesink location=cap.mkv async=0
@rem t. ^
@rem ! queue ^
@rem ! fakesink dump=1 async=0

exit /b

rem first ver
gst-launch-1.0 -v udpsrc port=4321 caps="application/x-rtp, media=video, encoding-name=H264, payload=96" ^
! rtpjitterbuffer latency=1 ^
! rtph264depay ^
! h264parse disable-passthrough=1 ^
! avdec_h264 output-corrupt=1 ^
! videobalance brightness=0.006 contrast=1.157 saturation=1.22 ^
! videoconvert ^
! d3d11videosink max-lateness=2000000 sync=0

exit /b

rem linux, unmaintained
gst-launch-1.0 -v udpsrc port=4321 caps = "application/x-rtp, media=video, encoding-name=H264, payload=96" ! rtpjitterbuffer latency=1 ! rtph264depay ! h264parse disable-passthrough=1 ! queue ! avdec_h264 output-corrupt=1 ! queue ! videoconvert ! autovideosink
