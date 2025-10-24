from tkinter import *
import socket, threading, json, base64
from chat_utils import *

HOST = '127.0.0.1'
PORT = 9999

client_private, client_public = generate_rsa_keys()

s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
s.connect((HOST, PORT))

# Gửi public key cho server
s.send(client_public)

# Lưu public key của các client khác
other_clients_pub = []

# ================= GUI =================
window = Tk()
window.title("Chat")

msg_list = Listbox(window, width=60, height=20)
msg_list.grid(column=0, row=0, columnspan=2, padx=10, pady=5)

entry_field = Entry(window, width=45)
entry_field.grid(column=0, row=1, padx=10, pady=5)

def send_message():
    msg = entry_field.get()
    if msg and other_clients_pub:
        aes_key = get_random_bytes(16)
        enc_msg = aes_encrypt(aes_key, msg.encode())
        print('danh sách thành viên khác: ', other_clients_pub)
        for pub_bytes in other_clients_pub:
            enc_aes_key = rsa_encrypt(pub_bytes, aes_key)
            payload = {
                "type": "message",
                "enc_aes_key": base64.b64encode(enc_aes_key).decode(),
                "enc_message": base64.b64encode(enc_msg).decode()
            }
            s.send(json.dumps(payload).encode())
        entry_field.delete(0, END)
        msg_list.insert(END, f"You: {msg}")

send_button = Button(window, text="Send", width=10, command=send_message)
send_button.grid(column=1, row=1, padx=10, pady=5)

def receive_messages():
    while True:
        try:
            data = s.recv(8192)
            if not data:
                break
            payload = json.loads(data.decode())
            if payload["type"] == "all_clients":
                # Lưu public key của client cũ
                other_clients_pub.extend([base64.b64decode(k) for k in payload["pub_keys"]])
            elif payload["type"] == "new_client":
                other_clients_pub.append(base64.b64decode(payload["pub_key"]))
            elif payload["type"] == "message":
                enc_aes_key = base64.b64decode(payload["enc_aes_key"])
                enc_msg = base64.b64decode(payload["enc_message"])
                aes_key = rsa_decrypt(client_private, enc_aes_key)
                msg = aes_decrypt(aes_key, enc_msg).decode()
                window.after(0, lambda m=msg: msg_list.insert(END, f"                                                        Partner: {m}"))

        except Exception as e:
            print(e)
            break

threading.Thread(target=receive_messages, daemon=True).start()
window.geometry("600x500")
window.mainloop()
