using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.IO;
using System.Linq;
using System.Security.Cryptography;
using System.Text;

class Program
{
    // Размер блока DES в байтах
    const int BlockSizeBytes = 8;

    static void Main()
    {
        Console.OutputEncoding = Encoding.UTF8;

        Console.WriteLine("=== DES-лабораторка: вариант 1 (ключ = первые 8 символов фамилии) ===");
        Console.Write("Путь к входному файлу (txt, UTF-8): ");
        string path = Console.ReadLine().Trim('"');

        if (!File.Exists(path))
        {
            Console.WriteLine("Файл не найден.");
            return;
        }

        Console.Write("Введите вашу фамилию (используется для формирования ключа): ");
        string surname = Console.ReadLine() ?? "";

        // Формируем ключ DES — первые 8 байт фамилии в ASCII (или UTF8), дополняем нулями
        byte[] key = BuildDesKeyFromSurname(surname);

        Console.WriteLine($"Ключ (hex): {BitConverter.ToString(key)}");

        // Читаем файл в байты (UTF-8)
        string plainText = File.ReadAllText(path, Encoding.UTF8);
        byte[] plainBytes = Encoding.UTF8.GetBytes(plainText);

        // Разбивка на блоки и PKCS#7 дополение
        byte[] padded = ApplyPkcs7Padding(plainBytes, BlockSizeBytes);
        var blocks = SplitBlocks(padded, BlockSizeBytes);

        Console.WriteLine($"Исходный текст (символов): {plainText.Length}");
        Console.WriteLine($"Исходных байт: {plainBytes.Length}, после PKCS#7: {padded.Length}, блоков: {blocks.Count}");

        // Шифрование (DES ECB)
        Console.WriteLine("\n--- Шифрование DES (ECB) ---");
        var swEnc = Stopwatch.StartNew();
        byte[] cipher = DesEncryptEcb(padded, key);
        swEnc.Stop();
        Console.WriteLine($"Время шифрования: {swEnc.ElapsedMilliseconds} ms ({swEnc.ElapsedTicks} ticks)");
        Console.WriteLine($"Шифртекст (hex, первые 128 байт): {HexPreview(cipher, 128)}");

        // Расшифрование
        Console.WriteLine("\n--- Расшифрование DES (ECB) ---");
        var swDec = Stopwatch.StartNew();
        byte[] recovered = DesDecryptEcb(cipher, key);
        swDec.Stop();
        Console.WriteLine($"Время расшифрования: {swDec.ElapsedMilliseconds} ms ({swDec.ElapsedTicks} ticks)");

        // Удаляем padding и получаем строку
        byte[] recoveredTrim = RemovePkcs7Padding(recovered);
        string recoveredText = Encoding.UTF8.GetString(recoveredTrim);
        Console.WriteLine($"Восстановлено символов: {recoveredText.Length}");
        Console.WriteLine($"Восстановленный текст совпадает с исходным? {recoveredText.Equals(plainText)}");

        // Сохраним шифртекст в файл
        string outCipherFile = Path.Combine(Path.GetDirectoryName(path), Path.GetFileNameWithoutExtension(path) + "_des_cipher.bin");
        File.WriteAllBytes(outCipherFile, cipher);
        Console.WriteLine($"Шифртекст сохранён в: {outCipherFile}");

            // Оценка лавинного эффекта (анализ по первому блоку)
            Console.WriteLine("\n--- Анализ лавинного эффекта (по первому блоку) ---");
            if (padded.Length < BlockSizeBytes)
            {
                Console.WriteLine("Недостаточно данных для анализа (меньше одного блока).");
                return;
            }

            byte[] firstBlock = new byte[BlockSizeBytes];
            Array.Copy(padded, 0, firstBlock, 0, BlockSizeBytes);

            byte[] cipherOriginal = new byte[BlockSizeBytes];
            Array.Copy(cipher, 0, cipherOriginal, 0, BlockSizeBytes);

            // Для каждого бита в первом блоке: инвертировать, зашифровать весь массив (или только блок в ECB),
            // и сравнить получившийся шифртекст с оригинальным шифртекстом в битах.
            // Так как используем ECB, изменение в первом блоке влияет только на соответствующий блок выходного шифртекста.
            var avalancheResults = new List<(int bitIndex, int changedBits, double changedPercent)>();

            for (int bit = 0; bit < BlockSizeBytes * 8; bit++)
            {
                byte[] modifiedPadded = new byte[padded.Length];
                Array.Copy(padded, modifiedPadded, padded.Length);
                // инвертировать бит в первом блоке
                int byteIndex = 0;
                int bitInByte = bit % 8;
                modifiedPadded[byteIndex] ^= (byte)(1 << bitInByte);

                // зашифровать (только ECB)
                byte[] cipherMod = DesEncryptEcb(modifiedPadded, key);

                // сравнение: посмотрим сколько бит отличаются в первом блоке (или в целом)
                int changedBits = CountDifferentBits(cipher, cipherMod); // считаем по всему шифртексту — но в ECB влияние только первого блока
                double percent = changedBits * 100.0 / (cipher.Length * 8);

                avalancheResults.Add((bit, changedBits, percent));
                Console.WriteLine($"Бит {bit,2}: изменилось битов в шифртексте = {changedBits}, доля = {percent:F2}%");
            }

            // Подведение итогов
            double avgChangedBits = avalancheResults.Average(x => x.changedBits);
            Console.WriteLine($"\nСреднее число изменившихся битов (по всем 64 позициям) = {avgChangedBits:F2}");
            Console.WriteLine("Готово.");
    }

    // Формирование ключа DES из фамилии: первые 8 байт в ASCII (или UTF8),
    // если меньше — дополняем нулями; если больше — усечём.
    static byte[] BuildDesKeyFromSurname(string surname)
    {
        if (surname == null) surname = "";
        // используем ASCII (буквы английские) или UTF8 — тут берем UTF8 для универсальности
        byte[] bytes = Encoding.UTF8.GetBytes(surname);
        byte[] key = new byte[8];
        for (int i = 0; i < 8; i++)
        {
            key[i] = (i < bytes.Length) ? bytes[i] : (byte)0x00;
        }

        // У DES ключ должен удовлетворять проверке на нечетность бита паритета (исторически).
        // .NET автоматически корректирует ключ parity при установке. Мы можем оставить как есть.
        return key;
    }

    // PKCS#7 padding
    static byte[] ApplyPkcs7Padding(byte[] data, int blockSize)
    {
        int padLen = blockSize - (data.Length % blockSize);
        if (padLen == 0) padLen = blockSize;
        byte[] outb = new byte[data.Length + padLen];
        Array.Copy(data, outb, data.Length);
        for (int i = data.Length; i < outb.Length; i++) outb[i] = (byte)padLen;
        return outb;
    }

    // Remove PKCS#7 padding (без жесткой проверки корректности)
    static byte[] RemovePkcs7Padding(byte[] data)
    {
        if (data.Length == 0) return data;
        int padLen = data[data.Length - 1];
        if (padLen <= 0 || padLen > BlockSizeBytes) return data; // подозрительно — возвращаем исход
        byte[] outb = new byte[data.Length - padLen];
        Array.Copy(data, 0, outb, 0, outb.Length);
        return outb;
    }

    // Разбить на блоки (список массивов) — вспомогательно (не обязательно)
    static List<byte[]> SplitBlocks(byte[] data, int blockSize)
    {
        var list = new List<byte[]>();
        for (int i = 0; i < data.Length; i += blockSize)
        {
            byte[] b = new byte[blockSize];
            Array.Copy(data, i, b, 0, blockSize);
            list.Add(b);
        }
        return list;
    }

    // DES ECB encrypt (uses System.Security.Cryptography)
    static byte[] DesEncryptEcb(byte[] data, byte[] key)
    {
        using (var des = DES.Create())
        {
            des.Mode = CipherMode.ECB;
            des.Padding = PaddingMode.None; // padding мы делаем сами
            des.Key = key;
            // IV не используется в ECB
            using (var encryptor = des.CreateEncryptor())
            {
                return encryptor.TransformFinalBlock(data, 0, data.Length);
            }
        }
    }

    static byte[] DesDecryptEcb(byte[] data, byte[] key)
    {
        using (var des = DES.Create())
        {
            des.Mode = CipherMode.ECB;
            des.Padding = PaddingMode.None;
            des.Key = key;
            using (var decryptor = des.CreateDecryptor())
            {
                return decryptor.TransformFinalBlock(data, 0, data.Length);
            }
        }
    }

    // Количество отличающихся битов между двумя массивами одинаковой длины
    static int CountDifferentBits(byte[] a, byte[] b)
    {
        int n = Math.Min(a.Length, b.Length);
        int diff = 0;
        for (int i = 0; i < n; i++)
        {
            byte x = (byte)(a[i] ^ b[i]);
            diff += CountBitsInByte(x);
        }
        // если длины отличаются, учитываем остаток
        if (a.Length != b.Length)
        {
            var longer = (a.Length > b.Length) ? a : b;
            for (int i = n; i < longer.Length; i++) diff += CountBitsInByte(longer[i]);
        }
        return diff;
    }

    static int CountBitsInByte(byte x)
    {
        // быстрое подсчётное хак-табло
        int cnt = 0;
        while (x != 0) { cnt += x & 1; x >>= 1; }
        return cnt;
    }

    // Вывод первой части шифртекста в hex для просмотра
    static string HexPreview(byte[] data, int maxBytes)
    {
        int n = Math.Min(data.Length, maxBytes);
        return BitConverter.ToString(data, 0, n).Replace("-", " ");
    }
}
