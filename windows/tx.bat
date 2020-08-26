@echo %PATH% | find /i "gstreamer" >nul || set "PATH=C:\gstreamer\1.0\msvc_x86_64\bin;%PATH%"
@set GST_DEBUG=3

rem dx9screencapsrc
rem dxgiscreencapsrc
rem gdiscreencapsrc

rem openh264enc scene-change-detection=0 complexity=high rate-control=bitrate bitrate=500000 max-bitrate=500000
rem   2x latency if more than half of the screen is modified and bitrate > 500000

rem x264enc byte-stream=1 rc-lookahead=0 tune=zerolatency key-int-max=30 speed-preset=faster bitrate=4000

gst-launch-1.0 -v rtpbin name=r ^
! gdiscreencapsrc x=0 y=0 width=1280 height=576 cursor=1 ^
! clockoverlay valignment=bottom font-desc="Mono, 8" shaded-background=1 shading-value=192 ypad=0 time-format="%%F %%T" ^
! videoconvert ^
! video/x-raw,framerate=30/1,format=I420 ^
! queue ^
! x264enc byte-stream=1 rc-lookahead=0 tune=zerolatency key-int-max=30 speed-preset=faster bitrate=4000 ^
! rtph264pay ^
! r.send_rtp_sink_0 ^
 r.send_rtp_src_0 ! udpsink host=127.0.0.1 port=4321 ^
r.send_rtcp_src_0 ! udpsink host=127.0.0.1 port=4322 sync=0 async=0

exit /b

rem first ver
gst-launch-1.0 -v gdiscreencapsrc x=0 y=0 width=1280 height=576 cursor=1 ^
! clockoverlay valignment=bottom font-desc="Mono, 8" shaded-background=1 shading-value=192 ypad=0 time-format="%%F %%T" ^
! videoconvert ^
! video/x-raw,framerate=30/1,format=I420 ^
! queue ^
! x264enc byte-stream=1 rc-lookahead=0 tune=zerolatency key-int-max=30 speed-preset=faster bitrate=4000 ^
! rtph264pay ^
! udpsink host=127.0.0.1 port=4321 sync=0

exit /b

rem linux, unmaintained
gst-launch-1.0 -v ximagesrc startx=0 starty=0 endx=1279 endy=575 use-damage=0 ! videoconvert ! video/x-raw,framerate=30/1,format=I420 ! queue ! x264enc byte-stream=1 rc-lookahead=0 tune=zerolatency key-int-max=30 speed-preset=faster bitrate=4000 ! rtph264pay ! udpsink host=127.0.0.1 port=4321
