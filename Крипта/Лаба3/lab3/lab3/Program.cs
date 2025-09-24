using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.IO;
using System.Linq;
using System.Text;

class Program
{
    //Русский алфавит (без ё, 33 буквы)
    static string Alphabet = "АБВГДЕЖЗИЙКЛМНОПРСТУФХЦЧШЩЪЫЬЭЮЯ";

    static void Main()
    {
        Console.OutputEncoding = Encoding.UTF8;
        string path = "input.txt"; // файл с исходным текстом (≥500 знаков)

        string text = File.ReadAllText(path, Encoding.UTF8)
                          .ToUpper() //в верхний регистр
                          .Where(c => Alphabet.Contains(c) || c == ' ') //только буквы и пробелы
                          .Aggregate("", (s, c) => s + c); //сборка обратно в строку

        Console.WriteLine($"Загружено символов: {text.Length}");

        //1. Маршрутная перестановка (спираль)
        Stopwatch sw = Stopwatch.StartNew();
        string spiralEnc = SpiralEncrypt(text, 20, 25); //запись текста в матрицу построчно, чтение её по спирали
        sw.Stop();
        Console.WriteLine($"Спираль: шифрование {sw.ElapsedMilliseconds} мс");
        sw.Restart();
        string spiralDec = SpiralDecrypt(spiralEnc, 20, 25); //заполняем матрицу по спирали, читаем по строкам
        sw.Stop();
        Console.WriteLine($"Спираль: расшифрование {sw.ElapsedMilliseconds} мс");

        //2. Множественная перестановка
        string key1 = "ВЕРОНИКА";
        string key2 = "СТРЕЛКОВСКАЯ";
        sw.Restart();
        string multiEnc = DoubleTranspositionEncrypt(text, key1, key2); //запись в таблицу
        sw.Stop();
        Console.WriteLine($"Множественная перестановка: шифрование {sw.ElapsedMilliseconds} мс");
        sw.Restart();
        string multiDec = DoubleTranspositionDecrypt(multiEnc, key1, key2);
        sw.Stop();
        Console.WriteLine($"Множественная перестановка: расшифрование {sw.ElapsedMilliseconds} мс");

        // ===== Частоты для построения гистограмм вручную =====
        Console.WriteLine("\nЧастоты (в %) исходный текст:");
        PrintFrequency(Frequency(text)); //процент появления букв

        Console.WriteLine("\nЧастоты (в %) после спирали:");
        PrintFrequency(Frequency(spiralEnc)); //вывод результата

        Console.WriteLine("\nЧастоты (в %) после множественной перестановки:");
        PrintFrequency(Frequency(multiEnc));
    }

    // ---------- Маршрутная перестановка (по спирали) ----------
    static string SpiralEncrypt(string text, int rows, int cols)
    {
        char[,] matrix = new char[rows, cols];
        int idx = 0;
        // заполняем матрицу построчно
        for (int r = 0; r < rows; r++)
            for (int c = 0; c < cols; c++)
                matrix[r, c] = idx < text.Length ? text[idx++] : ' ';

        // читаем по спирали
        var sb = new StringBuilder(); //для зашифрованного текста
        int top = 0, bottom = rows - 1, left = 0, right = cols - 1; //четыре непрочитанные границы
        while (top <= bottom && left <= right)
        {
            for (int c = left; c <= right; c++) sb.Append(matrix[top, c]); //чтение верхней строки
            top++; //после чего сдвигаем границу вниз
            for (int r = top; r <= bottom; r++) sb.Append(matrix[r, right]); //по правому столбцу
            right--; //сдвигаем влево границу
            if (top <= bottom)
            {
                for (int c = right; c >= left; c--) sb.Append(matrix[bottom, c]);
                bottom--;
            }
            if (left <= right)
            {
                for (int r = bottom; r >= top; r--) sb.Append(matrix[r, left]);
                left++;
            }
        }
        return sb.ToString();
    }

    static string SpiralDecrypt(string cipher, int rows, int cols)
    {
        char[,] matrix = new char[rows, cols];
        int idx = 0;
        int top = 0, bottom = rows - 1, left = 0, right = cols - 1;
        // заполняем по спирали
        while (top <= bottom && left <= right)
        {
            for (int c = left; c <= right; c++) matrix[top, c] = cipher[idx++];
            top++;
            for (int r = top; r <= bottom; r++) matrix[r, right] = cipher[idx++];
            right--;
            if (top <= bottom)
            {
                for (int c = right; c >= left; c--) matrix[bottom, c] = cipher[idx++];
                bottom--;
            }
            if (left <= right)
            {
                for (int r = bottom; r >= top; r--) matrix[r, left] = cipher[idx++];
                left++;
            }
        }
        // читаем построчно
        var sb = new StringBuilder();
        for (int r = 0; r < rows; r++)
            for (int c = 0; c < cols; c++)
                sb.Append(matrix[r, c]);
        return sb.ToString();
    }

    // ---------- Множественная перестановка ----------
    static string DoubleTranspositionEncrypt(string text, string key1, string key2)
    {
        // формируем матрицу key1 x key2
        int cols = key1.Length;
        int rows = key2.Length;
        char[,] matrix = new char[rows, cols];
        int idx = 0;
        for (int r = 0; r < rows; r++)
            for (int c = 0; c < cols; c++)
                matrix[r, c] = idx < text.Length ? text[idx++] : ' ';

        // сортируем столбцы по алфавиту ключа key1
        int[] colOrder = GetOrder(key1);
        char[,] colPerm = new char[rows, cols];
        for (int c = 0; c < cols; c++)
            for (int r = 0; r < rows; r++)
                colPerm[r, c] = matrix[r, colOrder[c]];

        // сортируем строки по алфавиту ключа key2
        int[] rowOrder = GetOrder(key2);
        char[,] final = new char[rows, cols];
        for (int r = 0; r < rows; r++)
            for (int c = 0; c < cols; c++)
                final[r, c] = colPerm[rowOrder[r] % rows, c];

        // читаем построчно
        var sb = new StringBuilder();
        for (int r = 0; r < rows; r++)
            for (int c = 0; c < cols; c++)
                sb.Append(final[r, c]);
        return sb.ToString();
    }

    static string DoubleTranspositionDecrypt(string cipher, string key1, string key2)
    {
        int cols = key1.Length;
        int rows = key2.Length;
        char[,] matrix = new char[rows, cols];
        int idx = 0;
        for (int r = 0; r < rows; r++)
            for (int c = 0; c < cols; c++)
                matrix[r, c] = cipher[idx++];

        int[] rowOrder = GetOrder(key2);
        char[,] rowPerm = new char[rows, cols];
        for (int r = 0; r < rows; r++)
            for (int c = 0; c < cols; c++)
                rowPerm[rowOrder[r] % rows, c] = matrix[r, c];

        int[] colOrder = GetOrder(key1);
        char[,] final = new char[rows, cols];
        for (int c = 0; c < cols; c++)
            for (int r = 0; r < rows; r++)
                final[r, colOrder[c]] = rowPerm[r, c];

        var sb = new StringBuilder();
        for (int r = 0; r < rows; r++)
            for (int c = 0; c < cols; c++)
                sb.Append(final[r, c]);
        return sb.ToString();
    }

    static int[] GetOrder(string key)
    {
        // возвращает массив позиций символов ключа в порядке возрастания
        var pairs = key.ToUpper().Select((c, i) => new { c, i })
                               .OrderBy(x => x.c)
                               .ThenBy(x => x.i)
                               .ToArray();
        int[] order = new int[key.Length];
        for (int i = 0; i < pairs.Length; i++)
            order[i] = pairs[i].i;
        return order;
    }

    // ---------- Частотный анализ ----------
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
