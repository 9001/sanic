# sanic
from webcam to web-browsers in 0.07 seconds

# status: junk
* found this in ~/dev, might be useful as a collection of notes
* it'll fall apart if much more is done without a rewrite
* (wanted to redo in python or rust but ENOTIME)

# this was going to be a speed comparison table
| codec | latency | encoder | browser
| -- | -- | -- | --
| h264, cpu-enc  | 0.077 sec | % | %
| h264, nvidia   | ?         | % | %
| h264, intel    | ?         | % | %
| mpeg1, cpu-enc | 0.071 sec | % | %
| mpeg4, cpu-enc | 0.064 sec | % | %

# dependencies
depending on features used, one or more of: ffmpeg, socat, 

# caveats
* each new client / http-connection will start a new encoder

# usage
```
# start the httpd for remote access (and h264 streams in general)
./util-webserver.py

# stream h264 to web-browsers (latency 0.077 sec)
# **broken**, probably the NAL parser in view-h264-broadway.html (use the alternate playback client below instead)
./videoserver.sh ff x11 h264b h264
http://127.0.0.1:8080/view-h264-broadway.html

# stream mpeg1 to web-browsers (latency 0.071 sec)
./videoserver.sh ff x11 mpeg1b ts
http://127.0.0.1:8080/view-mpeg1-jsmpeg.html

# stream mpeg4 over tcp (latency 0.063 sec)
while true; do ./enc-ffmpeg.sh x11 mpeg4 ts tcp; sleep 0.2; done
ffplay -fflags nobuffer -flags low_delay -probesize 32 -sync ext http://127.0.0.1:3737/the.ts

# alternative playback clients for tcp/http/udp
mpv --profile=low-latency --fps=30 http://127.0.0.1:3737/the.ts
ffplay -fflags nobuffer -flags low_delay -probesize 32 -sync ext http://127.0.0.1:3737/the.ts

# loopback tests (passthrough)
ffplay -fflags nobuffer -flags low_delay -probesize 32 -sync ext -f x11grab -framerate 60 -s 1024x720 -i :0.0+128,32
gst-launch-1.0 ximagesrc startx=128 starty=32 endx=$((128+1024-1)) endy=$((32+720-1)) use-damage=0 ! video/x-raw,framerate=30/1 ! ximagesink
ffmpeg -hide_banner -nostdin -fflags nobuffer -flags low_delay -probesize 32 -f x11grab -framerate 60 -s 1024x720 -i :0.0+128,32 -c:v rawvideo -f nut - | ffplay -hide_banner -v warning -fflags nobuffer -flags low_delay -probesize 32 -sync ext -
ffmpeg -hide_banner -nostdin -fflags nobuffer -flags low_delay -probesize 32 -f x11grab -framerate 60 -s 1024x720 -i :0.0+128,32 -c:v rawvideo -f nut - | mpv --profile=low-latency -

# loopback tests (with encoding)
./enc-ffmpeg.sh x11 h264 ts stdout | mpv --profile=low-latency --really-quiet -
./enc-ffmpeg.sh x11 h264 ts stdout | ffplay -fflags nobuffer -flags low_delay -probesize 32 -sync ext -
```
