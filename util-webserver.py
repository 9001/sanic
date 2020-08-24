#!/usr/bin/env python3
# coding: utf-8

import http.server
import socketserver
from http.server import HTTPServer, BaseHTTPRequestHandler


class ACAOHandler(http.server.SimpleHTTPRequestHandler):
	def __init__(self, *args, **kwargs):
		self.extensions_map = {
			'.html': 'text/html',
			'.js':	'application/x-javascript',
			'.wasm': 'application/wasm',
			'': 'application/octet-stream', # Default
		}
		super(ACAOHandler, self).__init__(*args, **kwargs)
	
	def end_headers(self):
		self.send_my_headers()
		http.server.SimpleHTTPRequestHandler.end_headers(self)
	
	def send_my_headers(self):
		self.send_header('Access-Control-Allow-Origin', '*')
		self.send_header('Access-Control-Allow-Headers', '*')


def main():
	try:
		port = int(sys.argv[1])
	except:
		port = 8080

	httpd = socketserver.TCPServer(("0.0.0.0", port), ACAOHandler)
	print("serving on http://127.0.0.1:{}/".format(port))
	httpd.serve_forever()


if __name__ == '__main__':
	main()
