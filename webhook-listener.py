#!/usr/bin/env python3
"""
Simple webhook listener for testing Gerrit webhooks
"""

from http.server import HTTPServer, BaseHTTPRequestHandler
import json
import datetime

class WebhookHandler(BaseHTTPRequestHandler):
    def do_POST(self):
        content_length = int(self.headers.get('Content-Length', 0))
        post_data = self.rfile.read(content_length).decode('utf-8')
        
        # Log the webhook
        timestamp = datetime.datetime.now().isoformat()
        print(f"\n{'='*60}")
        print(f"[{timestamp}] Received webhook")
        print(f"Path: {self.path}")
        print(f"Headers:")
        for header, value in self.headers.items():
            print(f"  {header}: {value}")
        
        print(f"\nBody:")
        try:
            # Try to parse and pretty-print JSON
            data = json.loads(post_data)
            print(json.dumps(data, indent=2))
            
            # Extract key information
            if 'type' in data:
                print(f"\nEvent Type: {data['type']}")
            if 'change' in data:
                print(f"Change: {data['change'].get('subject', 'N/A')}")
                print(f"Project: {data['change'].get('project', 'N/A')}")
                print(f"Branch: {data['change'].get('branch', 'N/A')}")
        except json.JSONDecodeError:
            print(post_data)
        
        print(f"{'='*60}\n")
        
        # Send response
        self.send_response(200)
        self.send_header('Content-type', 'application/json')
        self.end_headers()
        response = {'status': 'received', 'timestamp': timestamp}
        self.wfile.write(json.dumps(response).encode())
    
    def log_message(self, format, *args):
        # Suppress default logging
        pass

def run_server(port=8001):
    server_address = ('', port)
    httpd = HTTPServer(server_address, WebhookHandler)
    print(f"Webhook listener started on port {port}")
    print(f"URL: http://localhost:{port}")
    print("Press Ctrl+C to stop\n")
    
    try:
        httpd.serve_forever()
    except KeyboardInterrupt:
        print("\nShutting down...")
        httpd.shutdown()

if __name__ == '__main__':
    run_server()