#!/bin/bash
set -e

sed=$(command -v gsed || echo sed)

handle_client() {
	mime="$2"
	shift 2
	
	# get headers
	req=()
	while IFS= read -r ln; do
	  [ ${#ln} -ge 2 ] || break
	  req+=("$ln")
	done

	# handle OPTION
	printf '%s\n' "$req" |
	grep -E '^OPTION' >&2 &&
	  exec $sed -r 's/$/\r/' <<EOF
HTTP/1.1 204 No Content
Allow: GET
Connection: close
Access-Control-Allow-Origin: *
Access-Control-Allow-Headers: *

EOF

	# handle GET
	($sed -r 's/$/\r/' | tee /dev/stderr) <<EOF
HTTP/1.1 200 OK
Connection: close
Content-Type: $mime
Access-Control-Allow-Origin: *
Access-Control-Allow-Headers: *

EOF

	exec "$@"
}


run_server() {
	enc="$1"
	src="$2"
	codec="$3"
	ctr="$4"
	
	[ "$enc" = ff  ] && enc=./enc-ffmpeg.sh
	[ "$enc" = gst ] && enc=./enc-gstreamer.sh

	[ -e "$enc" ] || {
		echo "usage: $0 <ff|gst> source codec container"
		echo "example: $0 ff x11 h264b h264"
		echo "example: $0 ff mac mpeg1b ts"
		exit 1
	}

	mime=application/octet-stream
	[ "$ctr" = "ts"   ] && mime=video/MP2T
	[ "$ctr" = "h264" ] && mime=video/H264

	args="$mime $enc $src $codec $ctr stdout"
	echo "using encoder settings: $args"
	
	exec socat tcp-l:3737,reuseaddr,fork \
		exec:"./videoserver.sh cli $args"
}


[ "$1" = "cli" ] && handle_client "$@"

run_server "$@"
