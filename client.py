from tkinter import *
import socket
import threading
import json
import struct
import base64
from chat_utils import *

HOST = '127.0.0.1'
PORT = 9999

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

# --------- Config client ---------
client_private, client_public = generate_rsa_keys()
other_clients_pub = []  # list of bytes

s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
s.connect((HOST, PORT))

# Gửi public key cho server
send_msg(s, client_public)

# Nhận public key của các client khác
data = recv_msg(s)
if data:
    payload = json.loads(data.decode())
    if payload["type"] == "pub_keys":
        other_clients_pub = [k.encode() for k in payload["keys"]]

# --------- GUI ---------
window = Tk()
window.title("User Chat")

Label(window, text="Lịch sử chat", font=("Arial Bold", 14)).grid(column=0, row=0, columnspan=2, pady=5)
msg_list = Listbox(window, width=60, height=20)
msg_list.grid(column=0, row=1, columnspan=2, padx=10)
Label(window, text="Nhập tin nhắn:", font=("Arial", 12)).grid(column=0, row=2, pady=5)
entry_field = Entry(window, width=45)
entry_field.grid(column=0, row=3, padx=10, pady=5)

def send_message():
    msg = entry_field.get()
    if not msg or not other_clients_pub:
        return
    aes_key = get_random_bytes(16)
    enc_msg = aes_encrypt(aes_key, msg.encode())
    for pub_bytes in other_clients_pub:
        enc_aes_key = rsa_encrypt(pub_bytes, aes_key)
        payload = {
            "type": "message",
            "enc_aes_key": base64.b64encode(enc_aes_key).decode(),
            "enc_message": base64.b64encode(enc_msg).decode()
        }
        send_msg(s, json.dumps(payload).encode())
    entry_field.delete(0, END)
    msg_list.insert(END, f"You: {msg}")

send_button = Button(window, text="Gửi", width=10, command=send_message)
send_button.grid(column=1, row=3, padx=10, pady=5)

# --------- Receive messages ---------
def receive_messages():
    global other_clients_pub
    while True:
        data = recv_msg(s)
        if not data:
            break
        payload = json.loads(data.decode())
        if payload["type"] == "message":
            enc_aes_key = base64.b64decode(payload["enc_aes_key"])
            enc_msg = base64.b64decode(payload["enc_message"])
            try:
                aes_key = rsa_decrypt(client_private, enc_aes_key)
                msg = aes_decrypt(aes_key, enc_msg).decode()
                window.after(0, lambda m=msg: msg_list.insert(END, f"                                                                      Partner: {m}"))
            except Exception as e:
                print("Decrypt failed:", e)
        elif payload["type"] == "new_client":
            other_clients_pub.append(payload["key"].encode())

threading.Thread(target=receive_messages, daemon=True).start()

window.geometry('600x500')
window.mainloop()
