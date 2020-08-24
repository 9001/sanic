obs settings » audio:
  sample rate = 48khz

obs settings » output:
  output mode = advanced

obs settings » recording:
  type = custom output (ffmpeg)
  ffmpeg output type = output to url
  file path or url = icecast://source:hackme@127.0.0.1:8000/the.h264
  container format = h264 (video)
  muxer settings (if any) =
  video bitrate = 2500 kbps
  keyframe interval (frames) = 30
  rescale output [ ]
  [x] show all codecs (even if potentially incompatible)
  video encoder = libx264
  video encoder settings (if any) = -tune zerolatency -preset veryfast -g 30 -crf 26 -profile:v baseline -coder 0 -bf 0 -flags -loop -wpredp 0
  audio encoder = disable encoder

obs settings » video:
  downscale filter = lanczos
  common fps values = 30
