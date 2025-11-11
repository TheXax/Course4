import random
import time
import json
import matplotlib.pyplot as plt


# === Методы стеганографии ===

def embed_with_spaces(text, binary):
    """Встраивание битов в пробелы (0 = обычный, 1 = неразрывный)"""
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
    """Извлечение битов из пробелов"""
    chars = list(stego)
    binary = []
    for i in range(len(chars) - 1):
        if chars[i] != ' ' and (chars[i + 1] == ' ' or chars[i + 1] == '\u00A0'):
            binary.append('0' if chars[i + 1] == ' ' else '1')
    return ''.join(binary)


def embed_with_zero_width(text, binary):
    """Встраивание с помощью нулевой ширины символов"""
    zwsp = '\u200B'
    zwnj = '\u200C'
    result = list(text)
    for bit in binary:
        result.append(zwsp if bit == '0' else zwnj)
    return ''.join(result)


def extract_from_zero_width(stego):
    """Извлечение из нулевых символов"""
    bits = []
    for c in stego:
        if c == '\u200B':
            bits.append('0')
        elif c == '\u200C':
            bits.append('1')
    return ''.join(bits)


# === Генерация данных ===

def generate_random_binary(length):
    return ''.join(random.choice('01') for _ in range(length))


def generate_container(fmt, word_count):
    sb = []
    if fmt == "TXT":
        return ' '.join([f"слово{i}" for i in range(word_count)])
    elif fmt == "HTML":
        return ' '.join([f"<span>слово{i}</span>" for i in range(word_count)])
    elif fmt == "JSON":
        return json.dumps({"data": [f"слово{i}" for i in range(word_count)]}, ensure_ascii=False)
    elif fmt == "Mark":
        return '\n'.join([f"* слово{i}" for i in range(word_count)])
    elif fmt == "Code":
        return '\n'.join([f'string word{i} = "слово{i}";' for i in range(word_count)])
    return ''


def evaluate_universality(fmt, stego):
    """Проверка устойчивости к формату"""
    try:
        if fmt == "JSON":
            json.loads(stego)
        elif fmt == "HTML":
            if "<" in stego and ">" in stego:
                return 2
        return 3
    except Exception:
        return 0


# === Эксперимент ===

def run_experiment(method, fmt, word_count, msg_length):
    text = generate_container(fmt, word_count)
    binary = generate_random_binary(msg_length)

    # --- Встраивание ---
    start = time.time()
    stego = embed_with_spaces(text, binary) if method == "space" else embed_with_zero_width(text, binary)
    embed_time = (time.time() - start) * 1000

    # --- Извлечение ---
    start = time.time()
    extracted = extract_from_spaces(stego) if method == "space" else extract_from_zero_width(stego)
    extract_time = (time.time() - start) * 1000

    success = (binary == extracted)
    universality = evaluate_universality(fmt, stego)

    return {
        "method": method,
        "format": fmt,
        "words": word_count,
        "msg_bits": msg_length,
        "embed_ms": embed_time,
        "extract_ms": extract_time,
        "success": success,
        "universality": universality
    }


# === Основной поток ===

def main():
    formats = ["TXT", "HTML", "JSON", "Mark", "Code"]
    word_counts = [20000, 100000]
    msg_lengths = [500, 1000]
    results = []

    print("=== Анализ методов текстовой стеганографии ===\n")

    for fmt in formats:
        print(f"\nФормат контейнера: {fmt}")
        print("--------------------------------------------")
        for wc in word_counts:
            for ml in msg_lengths:
                for method in ["space", "zero"]:
                    res = run_experiment(method, fmt, wc, ml)
                    results.append(res)
                    color = "\033[92m" if res["success"] else "\033[91m"
                    print(
                        f"{fmt:<6} {wc:>8} слов | {ml:>6} бит | {method.upper():<6} "
                        f"{res['embed_ms']:.2f} / {res['extract_ms']:.2f} мс → "
                        f"{color}{'OK' if res['success'] else 'FAIL'}\033[0m"
                    )

    print("\nВсе эксперименты завершены.")

    # === Подсчёт средних значений ===
    avg_embed = {"space": 0, "zero": 0}
    avg_extract = {"space": 0, "zero": 0}
    avg_univ = {"space": 0, "zero": 0}
    count = {"space": 0, "zero": 0}

    for r in results:
        m = r["method"]
        avg_embed[m] += r["embed_ms"]
        avg_extract[m] += r["extract_ms"]
        avg_univ[m] += r["universality"]
        count[m] += 1

    for m in ["space", "zero"]:
        avg_embed[m] /= count[m]
        avg_extract[m] /= count[m]
        avg_univ[m] /= count[m]

    # === Гистограммы ===
    labels = ["Space", "Zero-Width"]

    # Время встраивания
    plt.figure(figsize=(8, 5))
    plt.bar(labels, [avg_embed["space"], avg_embed["zero"]], color=["#ff6666", "#66b3ff"])
    plt.title("Среднее время встраивания (мс)")
    plt.ylabel("мс")
    plt.savefig("embed_time_chart.png")
    plt.close()

    # Время извлечения
    plt.figure(figsize=(8, 5))
    plt.bar(labels, [avg_extract["space"], avg_extract["zero"]], color=["#99ff99", "#ffcc99"])
    plt.title("Среднее время извлечения (мс)")
    plt.ylabel("мс")
    plt.savefig("extract_time_chart.png")
    plt.close()

    # Универсальность
    plt.figure(figsize=(8, 5))
    plt.bar(labels, [avg_univ["space"], avg_univ["zero"]], color=["#ffb366", "#99ccff"])
    plt.title("Средняя универсальность методов (0–3)")
    plt.ylabel("Баллы")
    plt.ylim(0, 3.5)
    plt.savefig("universality_chart.png")
    plt.close()

    print("Гистограммы сохранены: embed_time_chart.png, extract_time_chart.png, universality_chart.png")


if __name__ == "__main__":
    main()
