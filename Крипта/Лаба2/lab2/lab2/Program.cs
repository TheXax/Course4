using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.IO;
using System.Linq;
using System.Text;

class Program
{
    // --- Русский алфавит (без ё, 33 буквы) ---
    static string Alphabet = "АБВГДЕЖЗИЙКЛМНОПРСТУФХЦЧШЩЪЫЬЭЮЯ";

    static void Main()
    {
        Console.OutputEncoding = Encoding.UTF8;
        string path = "input.txt"; // ваш файл с текстом (≥5000 символов)

        string text = File.ReadAllText(path, Encoding.UTF8)
                          .ToUpper()
                          .Where(c => Alphabet.Contains(c) || c == ' ')
                          .Aggregate("", (current, c) => current + c);

        Console.WriteLine($"Загружено символов: {text.Length}");

        // ===== 1. Цезарь с ключевым словом =====
        string keyword = "БЕЗОПАСНОСТЬ";
        Stopwatch sw = Stopwatch.StartNew();
        string caesarEnc = KeywordCipherEncrypt(text, keyword);
        sw.Stop();
        Console.WriteLine($"Цезарь с ключевым словом: шифрование {sw.ElapsedMilliseconds} мс");
        sw.Restart();
        string caesarDec = KeywordCipherDecrypt(caesarEnc, keyword);
        sw.Stop();
        Console.WriteLine($"Цезарь с ключевым словом: расшифрование {sw.ElapsedMilliseconds} мс");

        // ===== 2. Таблица Трисемуса =====
        sw.Restart();
        string trisemusEnc = TrisemusEncrypt(text, keyword);
        sw.Stop();
        Console.WriteLine($"Трисемус: шифрование {sw.ElapsedMilliseconds} мс");
        sw.Restart();
        string trisemusDec = TrisemusDecrypt(trisemusEnc, keyword);
        sw.Stop();
        Console.WriteLine($"Трисемус: расшифрование {sw.ElapsedMilliseconds} мс");

        // ===== Вывод частот для построения гистограмм вручную =====
        Console.WriteLine("\nЧастоты (в %) в исходном тексте:");
        PrintFrequency(Frequency(text));

        Console.WriteLine("\nЧастоты (в %) после Цезаря:");
        PrintFrequency(Frequency(caesarEnc));

        Console.WriteLine("\nЧастоты (в %) после Трисемуса:");
        PrintFrequency(Frequency(trisemusEnc));
    }

    // ---------- Цезарь с ключевым словом ----------
    static string KeywordCipherEncrypt(string text, string keyword)
    {
        string keyAlphabet = BuildKeywordAlphabet(keyword);
        return new string(text.Select(c =>
        {
            int idx = Alphabet.IndexOf(c);
            return idx < 0 ? c : keyAlphabet[idx];
        }).ToArray());
    }

    static string KeywordCipherDecrypt(string text, string keyword)
    {
        string keyAlphabet = BuildKeywordAlphabet(keyword);
        return new string(text.Select(c =>
        {
            int idx = keyAlphabet.IndexOf(c);
            return idx < 0 ? c : Alphabet[idx];
        }).ToArray());
    }

    static string BuildKeywordAlphabet(string keyword)
    {
        keyword = new string(keyword.ToUpper().Where(c => Alphabet.Contains(c)).ToArray());
        string result = new string((keyword + Alphabet)
            .Where((c, i) => (keyword + Alphabet).IndexOf(c) == i).ToArray());
        return result;
    }

    // ---------- Таблица Трисемуса ----------
    // 6x6 таблица (33 буквы → 6х6, лишние клетки заполняем пробелом)
    static char[,] BuildTrisemusTable(string keyword)
    {
        string keyAlphabet = BuildKeywordAlphabet(keyword);
        char[,] table = new char[6, 6];
        int k = 0;
        foreach (var c in keyAlphabet)
            table[k / 6, k++ % 6] = c;
        while (k < 36)
        {
            table[k / 6, k % 6] = ' ';
            k++;
        }
        return table;
    }

    static string TrisemusEncrypt(string text, string keyword)
    {
        char[,] table = BuildTrisemusTable(keyword);
        return new string(text.Select(c =>
        {
            if (!Alphabet.Contains(c)) return c;
            for (int i = 0; i < 6; i++)
                for (int j = 0; j < 6; j++)
                    if (table[i, j] == c)
                        return table[(i + 1) % 6, j]; // сдвиг вниз
            return c;
        }).ToArray());
    }

    static string TrisemusDecrypt(string text, string keyword)
    {
        char[,] table = BuildTrisemusTable(keyword);
        return new string(text.Select(c =>
        {
            if (!Alphabet.Contains(c)) return c;
            for (int i = 0; i < 6; i++)
                for (int j = 0; j < 6; j++)
                    if (table[i, j] == c)
                        return table[(i + 5) % 6, j]; // сдвиг вверх
            return c;
        }).ToArray());
    }

    // ---------- Частоты ----------
    static Dictionary<char, double> Frequency(string text)
    {
        var counts = new Dictionary<char, int>();
        int total = 0;
        foreach (char c in text)
        {
            if (Alphabet.Contains(c))
            {
                total++;
                if (!counts.ContainsKey(c)) counts[c] = 0;
                counts[c]++;
            }
        }
        return counts.ToDictionary(kv => kv.Key, kv => kv.Value * 100.0 / total);
    }

    static void PrintFrequency(Dictionary<char, double> freq)
    {
        foreach (var kv in freq.OrderBy(kv => kv.Key))
            Console.WriteLine($"{kv.Key}: {kv.Value:F2}%");
    }
}
