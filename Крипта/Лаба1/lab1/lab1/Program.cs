using System;
using System.Collections.Generic;

class Lab1
{
    // НОД двух чисел (алгоритм Евклида)
    static int GCD(int a, int b)
    {
        while (b != 0)
        {
            int temp = b;
            b = a % b;
            a = temp;
        }
        return Math.Abs(a);
    }

    // НОД трёх чисел
    static int GCD(int a, int b, int c)
    {
        return GCD(GCD(a, b), c);
    }

    // Решето Эратосфена — поиск простых чисел до n
    static List<int> SieveOfEratosthenes(int n)
    {
        bool[] prime = new bool[n + 1];
        for (int i = 2; i <= n; i++)
            prime[i] = true;

        for (int p = 2; p * p <= n; p++)
        {
            if (prime[p])
            {
                for (int i = p * p; i <= n; i += p)
                    prime[i] = false;
            }
        }

        List<int> primes = new List<int>();
        for (int i = 2; i <= n; i++)
            if (prime[i]) primes.Add(i);

        return primes;
    }

    // Поиск простых чисел в диапазоне [m, n]
    static List<int> PrimesInRange(int m, int n)
    {
        List<int> allPrimes = SieveOfEratosthenes(n);
        return allPrimes.FindAll(p => p >= m);
    }

    static void Main()
    {
        Console.WriteLine("Лабораторная работа №1");
        Console.WriteLine("1. Вычисление НОД");
        Console.WriteLine("2. Поиск простых чисел");
        Console.Write("Выберите операцию (1 или 2): ");
        int choice = int.Parse(Console.ReadLine());

        if (choice == 1)
        {
            Console.Write("Введите количество чисел (2 или 3): ");
            int k = int.Parse(Console.ReadLine());

            if (k == 2)
            {
                Console.Write("Введите два числа: ");
                int a = int.Parse(Console.ReadLine());
                int b = int.Parse(Console.ReadLine());
                Console.WriteLine($"НОД({a}, {b}) = {GCD(a, b)}");
            }
            else if (k == 3)
            {
                Console.Write("Введите три числа: ");
                int a = int.Parse(Console.ReadLine());
                int b = int.Parse(Console.ReadLine());
                int c = int.Parse(Console.ReadLine());
                Console.WriteLine($"НОД({a}, {b}, {c}) = {GCD(a, b, c)}");
            }
        }
        else if (choice == 2)
        {
            Console.WriteLine("1. Поиск простых чисел от 2 до n");
            Console.WriteLine("2. Поиск простых чисел в диапазоне [m, n]");
            int subChoice = int.Parse(Console.ReadLine());

            if (subChoice == 1)
            {
                Console.Write("Введите n: ");
                int n = int.Parse(Console.ReadLine());
                var primes = SieveOfEratosthenes(n);
                Console.WriteLine($"Простые числа до {n}: {string.Join(", ", primes)}");
                Console.WriteLine($"Количество: {primes.Count}");
            }
            else if (subChoice == 2)
            {
                Console.Write("Введите m: ");
                int m = int.Parse(Console.ReadLine());
                Console.Write("Введите n: ");
                int n = int.Parse(Console.ReadLine());
                var primes = PrimesInRange(m, n);
                Console.WriteLine($"Простые числа в диапазоне [{m}, {n}]: {string.Join(", ", primes)}");
                Console.WriteLine($"Количество: {primes.Count}");
            }
        }
    }
}
