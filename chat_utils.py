from Crypto.PublicKey import RSA
from Crypto.Cipher import PKCS1_OAEP, AES
from Crypto.Random import get_random_bytes
import base64

# ================== RSA ==================

def generate_rsa_keys():
    key = RSA.generate(2048)
    private_key = key.export_key()
    public_key = key.publickey().export_key()
    return private_key, public_key

def rsa_encrypt(public_key_bytes, message):
    public_key = RSA.import_key(public_key_bytes)
    cipher_rsa = PKCS1_OAEP.new(public_key)
    encrypted_message = cipher_rsa.encrypt(message)
    return encrypted_message

def rsa_decrypt(private_key_bytes, encrypted_message):
    private_key = RSA.import_key(private_key_bytes)
    cipher_rsa = PKCS1_OAEP.new(private_key)
    message = cipher_rsa.decrypt(encrypted_message)
    return message

# ================== AES ==================

def aes_encrypt(aes_key, plaintext):
    cipher_aes = AES.new(aes_key, AES.MODE_CBC)
    # padding plaintext lên bội số 16
    pad_len = 16 - (len(plaintext) % 16)
    plaintext += bytes([pad_len]) * pad_len
    ciphertext = cipher_aes.encrypt(plaintext)
    return cipher_aes.iv + ciphertext  # lưu kèm IV

def aes_decrypt(aes_key, ciphertext):
    iv = ciphertext[:16]
    cipher_aes = AES.new(aes_key, AES.MODE_CBC, iv)
    plaintext_padded = cipher_aes.decrypt(ciphertext[16:])
    pad_len = plaintext_padded[-1]
    return plaintext_padded[:-pad_len]
