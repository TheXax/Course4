import os
import random
import time
import fitz  # PyMuPDF
from bs4 import BeautifulSoup
import matplotlib.pyplot as plt

# === Строка, вставляемая во все файлы ===
TEST_STRING = "строка для проверки стеганографии"

# === Создание исходных файлов ===
def create_test_files():
    os.makedirs("texts", exist_ok=True)

    texts = {
        "ru": f"Это пример русского текста. {TEST_STRING}",
        "en": f"This is an English text example. {TEST_STRING}"
    }

    # --- TXT файлы ---
    with open("texts/sample_ru.txt", "w", encoding="utf-8") as f:
        f.write(texts["ru"])
    with open("texts/sample_en.txt", "w", encoding="utf-8") as f:
        f.write(texts["en"])

    # --- HTML файл ---
    html_content = f"""
    <html>
    <body>
    <h2>HTML Example</h2>
    <p>{texts["en"]}</p>
    <p>{texts["ru"]}</p>
    <p>{TEST_STRING}</p>
    </body>
    </html>
    """
    with open("texts/sample.html", "w", encoding="utf-8") as f:
        f.write(html_content)

    # --- PDF файл ---
    pdf_doc = fitz.open()
    page = pdf_doc.new_page()
    page.insert_text((72, 72),
                     f"{texts['en']}\n\n{texts['ru']}\n\n{TEST_STRING}",
                     fontsize=12)
    pdf_doc.save("texts/sample.pdf")
    pdf_doc.close()


# === Методы стеганографии ===
def embed_with_spaces(text, binary):
    """Метод пробелов: 0 = обычный, 1 = неразрывный"""
    words = text.split(' ')
    result = []
    for i, w in enumerate(words):
        result.append(w)
        if i < len(binary):
            result.append(' ' if binary[i] == '0' else '\u00A0')
        elif i < len(words) - 1:
            result.append(' ')
    return ''.join(result)


def extract_from_spaces(stego):
    chars = list(stego)
    binary = []
    for i in range(len(chars) - 1):
        if chars[i] != ' ' and (chars[i + 1] == ' ' or chars[i + 1] == '\u00A0'):
            binary.append('0' if chars[i + 1] == ' ' else '1')
    return ''.join(binary)


def embed_with_zero_width(text, binary):
    """Метод невидимых символов"""
    zwsp = '\u200B'
    zwnj = '\u200C'
    return text + ''.join(zwsp if bit == '0' else zwnj for bit in binary)


def extract_from_zero_width(stego):
    bits = []
    for c in stego:
        if c == '\u200B':
            bits.append('0')
        elif c == '\u200C':
            bits.append('1')
    return ''.join(bits)


# === Вспомогательные функции ===
def generate_random_binary(length):
    return ''.join(random.choice('01') for _ in range(length))


def read_text_from_file(filepath):
    """Чтение текста из TXT, HTML, PDF"""
    if filepath.endswith(".txt"):
        with open(filepath, "r", encoding="utf-8") as f:
            return f.read()
    elif filepath.endswith(".html"):
        with open(filepath, "r", encoding="utf-8") as f:
            soup = BeautifulSoup(f, "html.parser")
            return soup.get_text()
    elif filepath.endswith(".pdf"):
        doc = fitz.open(filepath)
        text = ""
        for page in doc:
            text += page.get_text()
        doc.close()
        return text
    else:
        return ""


# === Эксперимент ===
def run_experiment(method, text, msg_length, file_basename):
    """Встраивание, извлечение и сохранение результата в отдельный файл"""
    binary = generate_random_binary(msg_length)

    start = time.time()
    stego = embed_with_spaces(text, binary) if method == "space" else embed_with_zero_width(text, binary)
    embed_time = (time.time() - start) * 1000

    start = time.time()
    extracted = extract_from_spaces(stego) if method == "space" else extract_from_zero_width(stego)
    extract_time = (time.time() - start) * 1000

    success = binary == extracted

    # --- Сохраняем разные файлы для разных методов ---
    suffix = "_space" if method == "space" else "_zero"
    output_name = f"{file_basename}{suffix}.txt"
    os.makedirs("results", exist_ok=True)
    with open(os.path.join("results", output_name), "w", encoding="utf-8") as f:
        f.write(stego)

    return embed_time, extract_time, success, output_name


# === Основной поток ===
def main():
    create_test_files()
    print(f"Созданы файлы TXT, HTML, PDF с общей строкой: '{TEST_STRING}'\n")

    files = ["texts/sample_en.txt", "texts/sample_ru.txt", "texts/sample.html", "texts/sample.pdf"]
    methods = ["space", "zero"]
    msg_lengths = [100, 500, 1000]
    results = []

    for file in files:
        text = read_text_from_file(file)
        base = os.path.splitext(os.path.basename(file))[0]
        for method in methods:
            for length in msg_lengths:
                embed_time, extract_time, success, outfile = run_experiment(method, text, length, base)
                results.append({
                    "file": os.path.basename(file),
                    "method": method,
                    "msg_len": length,
                    "embed": embed_time,
                    "extract": extract_time,
                    "ok": success
                })
                print(f"{file:<25} | {method:<5} | {length:>5} бит | {embed_time:.2f}/{extract_time:.2f} мс | {'✅' if success else '❌'} | results/{outfile}")

    # === Строим гистограммы ===
    avg_embed = {"space": 0, "zero": 0}
    avg_extract = {"space": 0, "zero": 0}
    count = {"space": 0, "zero": 0}

    for r in results:
        avg_embed[r["method"]] += r["embed"]
        avg_extract[r["method"]] += r["extract"]
        count[r["method"]] += 1

    for m in methods:
        avg_embed[m] /= count[m]
        avg_extract[m] /= count[m]

    # --- Графики ---
    plt.figure(figsize=(8, 5))
    plt.bar(["Space", "Zero-Width"], [avg_embed["space"], avg_embed["zero"]], color=["#ff6666", "#66b3ff"])
    plt.title("Среднее время встраивания (мс)")
    plt.ylabel("мс")
    plt.savefig("embed_chart.png")

    plt.figure(figsize=(8, 5))
    plt.bar(["Space", "Zero-Width"], [avg_extract["space"], avg_extract["zero"]], color=["#99ff99", "#ffcc99"])
    plt.title("Среднее время извлечения (мс)")
    plt.ylabel("мс")
    plt.savefig("extract_chart.png")

    print("\nВсе эксперименты завершены.")
    print("Результаты файлов сохранены в папке 'results/'.")
    print("Гистограммы сохранены: embed_chart.png, extract_chart.png")


if __name__ == "__main__":
    main()
