import base64
import random
import time
import tkinter as tk
from tkinter import ttk, messagebox
from dataclasses import dataclass
from typing import Tuple

# ======================================================
# =============== БАЗОВЫЕ ФУНКЦИИ ======================
# ======================================================

def b64e(data: bytes) -> str:
    return base64.b64encode(data).decode("ascii")

def b64d(s: str) -> bytes:
    return base64.b64decode(s.encode("ascii"))

def text_to_chunks_bytes(text: str) -> bytes:
    return base64.b64encode(text.encode("utf-8"))

def chunks_bytes_to_text(ch: bytes) -> str:
    return base64.b64decode(ch).decode("utf-8")

def bytes_to_int(b: bytes) -> int:
    return int.from_bytes(b, "big", signed=False)


# ======================================================
# =============== ПРИМАЛЬНЫЕ ЧИСЛА =====================
# ======================================================

def _is_probable_prime(n: int, k: int = 16) -> bool:
    if n < 2:
        return False
    small = [2,3,5,7,11,13,17,19,23,29]
    if n in small:
        return True
    if any(n % p == 0 for p in small):
        return False

    d = n - 1
    s = 0
    while not d % 2:
        s += 1
        d //= 2

    for _ in range(k):
        a = random.randrange(2, n - 2)
        x = pow(a, d, n)
        if x == 1 or x == n - 1:
            continue

        ok = False
        for _ in range(s - 1):
            x = pow(x, 2, n)
            if x == n - 1:
                ok = True
                break
        if not ok:
            return False
    return True

def gen_prime(bits: int) -> int:
    while True:
        n = random.getrandbits(bits) | (1 << bits - 1) | 1
        if _is_probable_prime(n):
            return n


# ======================================================
# ===================== RSA ============================
# ======================================================

def egcd(a, b):
    if b == 0:
        return a, 1, 0
    g, x1, y1 = egcd(b, a % b)
    return g, y1, x1 - (a // b) * y1

def modinv(a, m):
    g, x, _ = egcd(a, m)
    if g != 1:
        raise ValueError("Inverse does not exist")
    return x % m

@dataclass
class RSAKeyPair:
    n: int
    e: int
    d: int

def rsa_keygen(bits=1024, e=65537):
    p = gen_prime(bits // 2)
    q = gen_prime(bits // 2)
    n = p * q
    phi = (p - 1)*(q - 1)
    d = modinv(e, phi)
    return RSAKeyPair(n, e, d)

def rsa_encrypt_blocks(data: bytes, n: int, e: int):
    t0 = time.perf_counter()
    block = max(1, (n.bit_length() // 8) - 1)

    out = []
    for i in range(0, len(data), block):
        m = bytes_to_int(data[i:i+block])
        c = pow(m, e, n)
        out.append(b64e(c.to_bytes((n.bit_length()+7)//8, "big")))

    return ".".join(out), time.perf_counter() - t0

def rsa_decrypt_blocks(cipher: str, n: int, d: int):
    t0 = time.perf_counter()
    size = (n.bit_length()+7)//8
    out = bytearray()

    for part in cipher.split("."):
        c = bytes_to_int(b64d(part))
        m = pow(c, d, n)
        out.extend(m.to_bytes(size, "big").lstrip(b"\x00"))

    return bytes(out), time.perf_counter() - t0


# ======================================================
# ================== EL GAMAL ==========================
# ======================================================

@dataclass
class EGKeyPair:
    p: int
    g: int
    x: int
    y: int

def eg_keygen(bits=1024):
    p = gen_prime(bits)
    g = 2
    x = random.randrange(2, p - 2)
    y = pow(g, x, p)
    return EGKeyPair(p, g, x, y)

def eg_encrypt_blocks(data: bytes, p: int, g: int, y: int):
    t0 = time.perf_counter()
    size = (p.bit_length()+7)//8
    block = size - 2

    out = []
    for i in range(0, len(data), block):
        m = bytes_to_int(data[i:i+block])
        k = random.randrange(2, p - 2)
        a = pow(g, k, p)
        b = (pow(y, k, p) * m) % p
        out.append(b64e(a.to_bytes(size,"big")+b.to_bytes(size,"big")))
    return ".".join(out), time.perf_counter() - t0

def eg_decrypt_blocks(cipher: str, p: int, x: int):
    t0 = time.perf_counter()
    size = (p.bit_length()+7)//8
    out = bytearray()

    for c in cipher.split("."):
        raw = b64d(c)
        a = bytes_to_int(raw[:size])
        b = bytes_to_int(raw[size:])
        s = pow(a, x, p)
        s_inv = pow(s, p - 2, p)
        m = (b * s_inv) % p
        out.extend(m.to_bytes(size,"big").lstrip(b"\x00"))
    return bytes(out), time.perf_counter() - t0


# ======================================================
# ==================== UI =============================
# ======================================================

class App(tk.Tk):
    def __init__(self):
        super().__init__()
        self.title("💻 Crypto Lab — RSA & ElGamal")
        self.geometry("950x650")

        self.rsa_keys = None
        self.eg_keys  = None

        self.build_ui()

    def build_ui(self):
        nb = ttk.Notebook(self)
        nb.pack(fill="both", expand=True, padx=10, pady=10)

        tab1 = ttk.Frame(nb)
        tab2 = ttk.Frame(nb)

        nb.add(tab1, text="🔐 RSA")
        nb.add(tab2, text="🛡 ElGamal")

        self.build_rsa(tab1)
        self.build_eg(tab2)

    # ========================= RSA TAB =========================

    def build_rsa(self, parent):

        box = ttk.Frame(parent, padding=10)
        box.pack(fill="both", expand=True)

        # ---------------- KEY GEN ----------------
        f = ttk.LabelFrame(box, text="🔑 Генерация ключей RSA")
        f.pack(fill="x", pady=5)

        ttk.Label(f, text="Размер ключа:").grid(row=0, column=0)
        self.rsa_bits = tk.StringVar(value="1024")
        ttk.Entry(f, width=10, textvariable=self.rsa_bits).grid(row=0, column=1)

        ttk.Button(f, text="Сгенерировать", command=self.rsa_gen).grid(row=0, column=2, padx=10)

        self.rsa_info = tk.Text(f, height=4)
        self.rsa_info.grid(row=1, column=0, columnspan=3, sticky="we")

        # ---------------- MESSAGE ----------------
        area = ttk.LabelFrame(box, text="📄 Работа с текстом")
        area.pack(fill="both", expand=True)

        ttk.Label(area, text="Исходный текст:").pack(anchor="w")
        self.rsa_plain = tk.Text(area, height=4)
        self.rsa_plain.pack(fill="x")
        self.rsa_plain.insert("1.0", "Стрелковская Вероника Андреевна")

        ttk.Label(area, text="Результат шифрования:").pack(anchor="w")
        self.rsa_cipher = tk.Text(area, height=7)
        self.rsa_cipher.pack(fill="both", expand=True)

        # ---------------- BUTTONS ----------------
        btns = ttk.Frame(box)
        btns.pack(pady=5)

        ttk.Button(btns, text="🔐 Шифровать", command=self.rsa_encrypt).pack(side="left", padx=6)
        ttk.Button(btns, text="🔓 Расшифровать", command=self.rsa_decrypt).pack(side="left", padx=6)

        self.rsa_status = ttk.Label(box, text="...")
        self.rsa_status.pack(fill="x", pady=5)

    # ======================= RSA API =======================

    def rsa_gen(self):
        try:
            bits = int(self.rsa_bits.get())
            t0 = time.perf_counter()
            self.rsa_keys = rsa_keygen(bits)
            dt = time.perf_counter() - t0

            self.rsa_info.delete("1.0", "end")
            self.rsa_info.insert("end", f"n bits  = {self.rsa_keys.n.bit_length()}\n")
            self.rsa_info.insert("end", f"e       = 65537\n")
            self.rsa_info.insert("end", f"d hex   = {len(hex(self.rsa_keys.d))} символов\n")
            self.rsa_info.insert("end", f"Время:  {dt:.3f} сек\n")
        except Exception as e:
            messagebox.showerror("Ошибка", str(e))

    def rsa_encrypt(self):
        if not self.rsa_keys:
            return messagebox.showwarning("Нет ключа", "Сгенерируйте ключи.")
        text = self.rsa_plain.get("1.0", "end").strip()
        b = text_to_chunks_bytes(text)
        cipher, t = rsa_encrypt_blocks(b, self.rsa_keys.n, self.rsa_keys.e)
        self.rsa_cipher.delete("1.0", "end")
        self.rsa_cipher.insert("end", cipher)
        self.rsa_status.config(text=f"⏱ Шифрование: {t*1000:.1f} ms")

    def rsa_decrypt(self):
        if not self.rsa_keys:
            return messagebox.showwarning("Нет ключа", "Сгенерируйте ключи.")
        cipher = self.rsa_cipher.get("1.0", "end").strip()
        data, t = rsa_decrypt_blocks(cipher, self.rsa_keys.n, self.rsa_keys.d)
        self.rsa_plain.delete("1.0", "end")
        self.rsa_plain.insert("end", chunks_bytes_to_text(data))
        self.rsa_status.config(text=f"⏱ Расшифрование: {t*1000:.1f} ms")

    # ==============================================================
    # =========================== EG ===============================
    # ==============================================================

    def build_eg(self, parent):

        box = ttk.Frame(parent, padding=10)
        box.pack(fill="both", expand=True)

        f = ttk.LabelFrame(box, text="🔑 Генерация ключей ElGamal")
        f.pack(fill="x", pady=5)

        ttk.Label(f, text="Размер p:").grid(row=0, column=0)
        self.eg_bits = tk.StringVar(value="1024")
        ttk.Entry(f, width=10, textvariable=self.eg_bits).grid(row=0, column=1)

        ttk.Button(f, text="Сгенерировать", command=self.eg_gen).grid(row=0, column=2, padx=10)

        self.eg_info = tk.Text(f, height=4)
        self.eg_info.grid(row=1, column=0, columnspan=3, sticky="we")

        area = ttk.LabelFrame(box, text="📄 Работа с текстом")
        area.pack(fill="both", expand=True)

        ttk.Label(area, text="Исходный текст:").pack(anchor="w")
        self.eg_plain = tk.Text(area, height=4)
        self.eg_plain.pack(fill="x")
        self.eg_plain.insert("1.0", "Стрелковская Вероника Андреевна")

        ttk.Label(area, text="Результат шифрования:").pack(anchor="w")
        self.eg_cipher = tk.Text(area, height=7)
        self.eg_cipher.pack(fill="both", expand=True)

        btns = ttk.Frame(box)
        btns.pack()

        ttk.Button(btns, text="🔐 Шифровать", command=self.eg_encrypt).pack(side="left", padx=6)
        ttk.Button(btns, text="🔓 Расшифровать", command=self.eg_decrypt).pack(side="left", padx=6)

        self.eg_status = ttk.Label(box, text="...")
        self.eg_status.pack(fill="x", pady=5)

    # --------------------- EG API ----------------------

    def eg_gen(self):
        bits = int(self.eg_bits.get())
        t0 = time.perf_counter()
        self.eg_keys = eg_keygen(bits)
        dt = time.perf_counter() - t0

        self.eg_info.delete("1.0", "end")
        self.eg_info.insert("end", f"p bits = {self.eg_keys.p.bit_length()}\n")
        self.eg_info.insert("end", f"g     = {self.eg_keys.g}\n")
        self.eg_info.insert("end", f"Время генерации = {dt:.3f} sec\n")

    def eg_encrypt(self):
        if not self.eg_keys:
            return messagebox.showwarning("Нет ключа", "Сгенерируйте ключ.")
        txt = self.eg_plain.get("1.0","end").strip()
        b = text_to_chunks_bytes(txt)
        cipher, t = eg_encrypt_blocks(b, self.eg_keys.p, self.eg_keys.g, self.eg_keys.y)
        self.eg_cipher.delete("1.0","end")
        self.eg_cipher.insert("end", cipher)
        self.eg_status.config(text=f"⏱ Шифрование: {t*1000:.1f} ms")

    def eg_decrypt(self):
        if not self.eg_keys:
            return messagebox.showwarning("Нет ключа", "Сгенерируйте ключ.")
        cipher = self.eg_cipher.get("1.0","end").strip()
        data, t = eg_decrypt_blocks(cipher, self.eg_keys.p, self.eg_keys.x)
        self.eg_plain.delete("1.0","end")
        self.eg_plain.insert("end", chunks_bytes_to_text(data))
        self.eg_status.config(text=f"⏱ Расшифрование: {t*1000:.1f} ms")


# ======================================================
# ====================== MAIN ==========================
# ======================================================

if __name__ == "__main__":
    app = App()
    app.mainloop()
