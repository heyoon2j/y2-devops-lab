import socket

host = '0.0.0.0'
port = 80

server_sock = socket.socket(socket.AF_INET)
server_sock.bind((host, port))
server_sock.listen(1)

print("Waiting")
while True:
    client_sock, addr = server_sock.accept()
    print("Connecting", addr)