import tkinter as tk
from tkinter import filedialog, messagebox
from PIL import Image
import numpy as np
import random
import matplotlib.pyplot as plt

# ===================== ВСПОМОГАТЕЛЬНЫЕ =====================

def text_to_bits(text: str) -> str:
    return ''.join(f'{b:08b}' for b in text.encode('utf-8'))

def bits_to_text(bits: str) -> str:
    bytes_list = [bits[i:i+8] for i in range(0, len(bits), 8)]
    return bytes(int(b, 2) for b in bytes_list).decode('utf-8', errors='ignore')

# ===================== LSB =====================

def embed_lsb(img, message, random_mode=False, seed=42):
    data = np.array(img)
    bits = text_to_bits(message) + '00000000'  # маркер конца
    h, w, c = data.shape

    coords = [(i, j, k) for i in range(h) for j in range(w) for k in range(3)]
    if random_mode:
        random.seed(seed)
        random.shuffle(coords)

    idx = 0
    for i, j, k in coords:
        if idx >= len(bits):
            break
        data[i, j, k] = (data[i, j, k] & 0xFE) | int(bits[idx])
        idx += 1

    return Image.fromarray(data)

def extract_lsb(img, random_mode=False, seed=42):
    data = np.array(img)
    h, w, c = data.shape

    coords = [(i, j, k) for i in range(h) for j in range(w) for k in range(3)]
    if random_mode:
        random.seed(seed)
        random.shuffle(coords)

    bits = ""
    for i, j, k in coords:
        bits += str(data[i, j, k] & 1)
        if bits.endswith('00000000'):
            break

    return bits_to_text(bits[:-8])

# ===================== ВИЗУАЛИЗАЦИЯ =====================

def show_lsb_planes(img):
    data = np.array(img)
    fig, axes = plt.subplots(1, 3, figsize=(12, 4))
    titles = ['R LSB', 'G LSB', 'B LSB']

    for i in range(3):
        plane = data[:, :, i] & 1
        axes[i].imshow(plane, cmap='gray')
        axes[i].set_title(titles[i])
        axes[i].axis('off')

    plt.show()

# ===================== GUI =====================

class App(tk.Tk):
    def __init__(self):
        super().__init__()
        self.title("LSB Стеганография (НЗБ)")
        self.geometry("500x350")
        self.img = None
        self.build()

    def build(self):
        tk.Button(self, text="Открыть контейнер (PNG)", command=self.load_img).pack(pady=5)
        self.text = tk.Text(self, height=5)
        self.text.pack(fill="x", padx=10)

        tk.Button(self, text="Скрыть (последовательно)", command=self.embed_seq).pack(pady=3)
        tk.Button(self, text="Скрыть (псевдослучайно)", command=self.embed_rand).pack(pady=3)

        tk.Button(self, text="Извлечь (последовательно)", command=self.extract_seq).pack(pady=3)
        tk.Button(self, text="Извлечь (псевдослучайно)", command=self.extract_rand).pack(pady=3)

        tk.Button(self, text="Показать LSB-матрицы", command=self.show_planes).pack(pady=5)

    def load_img(self):
        path = filedialog.askopenfilename(filetypes=[("PNG", "*.png")])
        if path:
            self.img = Image.open(path).convert("RGB")
            messagebox.showinfo("OK", "Контейнер загружен")

    def embed_seq(self):
        msg = self.text.get("1.0", "end").strip()
        out = embed_lsb(self.img, msg, False)
        out.save("stego_seq.png")
        messagebox.showinfo("OK", "Сохранено: stego_seq.png")

    def embed_rand(self):
        msg = self.text.get("1.0", "end").strip()
        out = embed_lsb(self.img, msg, True)
        out.save("stego_rand.png")
        messagebox.showinfo("OK", "Сохранено: stego_rand.png")

    def extract_seq(self):
        msg = extract_lsb(self.img, False)
        self.text.delete("1.0", "end")
        self.text.insert("end", msg)

    def extract_rand(self):
        msg = extract_lsb(self.img, True)
        self.text.delete("1.0", "end")
        self.text.insert("end", msg)

    def show_planes(self):
        show_lsb_planes(self.img)

if __name__ == "__main__":
    App().mainloop()
