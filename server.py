import socket
import threading
import json
import base64

clients = []  # list socket
pub_keys = {}  # {conn: client_public_bytes}

HOST = '127.0.0.1'
PORT = 9999

def handle_client(conn, addr):
    print(f"[+] Connected: {addr}")
    # Nhận public key từ client
    client_pub = conn.recv(4096)
    pub_keys[conn] = client_pub
    clients.append(conn)

    # Gửi public key client mới cho tất cả client cũ
    for other_conn in clients:
        if other_conn != conn:
            msg = json.dumps({
                "type": "new_client",
                "pub_key": base64.b64encode(client_pub).decode()
            }).encode()
            other_conn.send(msg)

    # Gửi public key tất cả client cũ cho client mới
    old_keys = []
    for other_conn, other_pub in pub_keys.items():
        if other_conn != conn:
            old_keys.append(base64.b64encode(other_pub).decode())
    if old_keys:
        msg = json.dumps({"type": "all_clients", "pub_keys": old_keys}).encode()
        conn.send(msg)

    # Nhận tin nhắn từ client
    while True:
        try:
            data = conn.recv(8192)
            if not data:
                break
            payload = json.loads(data.decode())
            # Gửi payload này cho client khác
            for c in clients:
                if c != conn:
                    c.send(json.dumps(payload).encode())
        except Exception as e:
            print(f"[!] Error: {e}")
            break

    print(f"[-] Disconnected: {addr}")
    clients.remove(conn)
    pub_keys.pop(conn)
    conn.close()

def start_server():
    s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    s.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
    s.bind((HOST, PORT))
    s.listen()
    print(f"[+] Server listening on {HOST}:{PORT}")
    while True:
        conn, addr = s.accept()
        threading.Thread(target=handle_client, args=(conn, addr), daemon=True).start()

if __name__ == "__main__":
    start_server()
