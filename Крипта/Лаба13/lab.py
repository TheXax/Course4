# ==========================================
# ТЕКСТОВАЯ СТЕГАНОГРАФИЯ (ОДИН ФАЙЛ)
# ==========================================

def text_to_bits(text):
    return ''.join(format(ord(c), '08b') for c in text)

def bits_to_text(bits):
    return ''.join(chr(int(bits[i:i+8], 2)) for i in range(0, len(bits), 8))


# ---------- МЕТОД 1: ИЗМЕНЕНИЕ ДЛИНЫ СТРОКИ ----------

def embed_line_length(container_text, secret):
    lines = container_text.splitlines()
    bits = text_to_bits(secret)

    if len(bits) > len(lines):
        raise ValueError("Недостаточно строк в контейнере")

    result = []
    for i, line in enumerate(lines):
        if i < len(bits) and bits[i] == '1':
            result.append(line.rstrip() + ' ')
        else:
            result.append(line.rstrip())

    return '\n'.join(result)

def extract_line_length(container_text, secret_length):
    lines = container_text.splitlines()
    bits = ''

    for i in range(secret_length * 8):
        bits += '1' if lines[i].endswith(' ') else '0'

    return bits_to_text(bits)


# ---------- МЕТОД 2: МОДИФИКАЦИЯ ЦВЕТА (HTML) ----------

def embed_color(container_text, secret):
    bits = text_to_bits(secret)
    result = ''
    bit_index = 0

    for char in container_text:
        if bit_index < len(bits):
            color = 'rgb(0,0,1)' if bits[bit_index] == '1' else 'rgb(0,0,0)'
            result += f'<span style="color:{color}">{char}</span>'
            bit_index += 1
        else:
            result += char

    return result

def extract_color(container_html, secret_length):
    bits = ''
    i = 0

    while i < len(container_html) and len(bits) < secret_length * 8:
        if container_html.startswith('<span', i):
            if 'rgb(0,0,1)' in container_html[i:i+50]:
                bits += '1'
            else:
                bits += '0'
            i = container_html.find('</span>', i) + 7
        else:
            i += 1

    return bits_to_text(bits)


# ---------- ИНТЕРФЕЙС ----------

def main():
    print("СТЕГАНОГРАФИЯ ТЕКСТА")
    print("1 — Изменение длины строки")
    print("2 — Модификация цвета (HTML)")
    method = input("Выберите метод: ")

    print("\n1 — Встроить сообщение")
    print("2 — Извлечь сообщение")
    action = input("Выберите действие: ")

    filename = input("\nВведите имя файла контейнера: ")

    with open(filename, 'r', encoding='utf-8') as f:
        container = f.read()

    # ---------- МЕТОД 1 ----------
    if method == '1' and action == '1':
        secret = input("Введите секретное сообщение: ")
        result = embed_line_length(container, secret)

        with open("stego_container.txt", "w", encoding='utf-8') as f:
            f.write(result)

        print("\nСообщение встроено в stego_container.txt")

    elif method == '1' and action == '2':
        length = int(input("Длина секретного сообщения: "))
        secret = extract_line_length(container, length)
        print("\nИзвлечённое сообщение:", secret)

    # ---------- МЕТОД 2 ----------
    elif method == '2' and action == '1':
        secret = input("Введите секретное сообщение: ")
        result = embed_color(container, secret)

        with open("stego_container.html", "w", encoding='utf-8') as f:
            f.write(result)

        print("\nСообщение встроено в stego_container.html")

    elif method == '2' and action == '2':
        length = int(input("Длина секретного сообщения: "))
        secret = extract_color(container, length)
        print("\nИзвлечённое сообщение:", secret)

    else:
        print("Неверный выбор")


if __name__ == "__main__":
    main()
