import socket
import threading
import json
import struct

from chat_utils import *

HOST = '127.0.0.1'
PORT = 9999

clients = []
pub_keys = {}  # {conn: public_key_bytes}
clients_lock = threading.Lock()

# --------- Send/Recv with length header ---------
def send_msg(sock, payload_bytes):
    length = struct.pack('>I', len(payload_bytes))
    sock.sendall(length + payload_bytes)

def recv_msg(sock):
    raw_len = recvall(sock, 4)
    if not raw_len:
        return None
    msg_len = struct.unpack('>I', raw_len)[0]
    return recvall(sock, msg_len)

def recvall(sock, n):
    data = b''
    while len(data) < n:
        packet = sock.recv(n - len(data))
        if not packet:
            return None
        data += packet
    return data

# --------- Broadcast payload to all other clients ---------
def broadcast(payload_bytes, sender_conn):
    with clients_lock:
        for c in clients:
            if c != sender_conn:
                try:
                    send_msg(c, payload_bytes)
                except:
                    pass

# --------- Handle each client ---------
def handle_client(conn, addr):
    print(f"Connected: {addr}")
    # 1. Nhận public key từ client
    client_pub = recv_msg(conn)
    if not client_pub:
        conn.close()
        return
    with clients_lock:
        clients.append(conn)
        pub_keys[conn] = client_pub

    # 2. Gửi tất cả public key khác cho client mới
    other_keys = [v.decode() for k, v in pub_keys.items() if k != conn]
    payload = json.dumps({"type": "pub_keys", "keys": other_keys}).encode()
    send_msg(conn, payload)

    # 3. Thông báo client mới cho tất cả client khác
    broadcast(json.dumps({"type": "new_client", "key": client_pub.decode()}).encode(), conn)

    # 4. Nhận tin nhắn từ client
    while True:
        data = recv_msg(conn)
        if not data:
            break
        broadcast(data, conn)

    print(f"Disconnected: {addr}")
    with clients_lock:
        clients.remove(conn)
        del pub_keys[conn]
    conn.close()

# --------- Start server ---------
def start_server():
    s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    s.bind((HOST, PORT))
    s.listen()
    print(f"Server listening on {HOST}:{PORT}")

    while True:
        conn, addr = s.accept()
        threading.Thread(target=handle_client, args=(conn, addr), daemon=True).start()

if __name__ == "__main__":
    start_server()
