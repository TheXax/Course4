using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.Linq;
using System.Numerics;
using System.Text;
using System.Windows.Forms;

namespace lab7
{
    public partial class Form1 : Form
    {
        List<BigInteger> A;   // приватный сверхвозрастающий ключ
        List<BigInteger> B;   // открытый ключ
        BigInteger m, w, wInv;
        int z = 6; // Base64 по умолчанию

        int realBitCount = 0;   // <<< ВАЖНО: количество бит до разбиения на блоки

        public Form1()
        {
            InitializeComponent();
        }

        private void Form1_Load(object sender, EventArgs e)
        {
            txtLog.Text = "Готово к работе.\r\n";
        }


        //СОЗДАНИЕ ПРИВАТНОГО КЛЮЧА A

        private void btnPriv_Click(object sender, EventArgs e)
        {
            int n = (int)numN.Value;
            A = new List<BigInteger>();
            Random rnd = new Random();

            A.Add(new BigInteger(rnd.Next(2, 10))); // первый элемент
            BigInteger sum = A[0];

            // генерируем сверхвозрастающую последовательность
            for (int i = 1; i < n; i++)
            {
                BigInteger next = sum + rnd.Next(5, 25);
                A.Add(next);
                sum += next;
            }

            // увеличиваем, пока последний элемент не станет >= 100 бит
            while (A.Last().GetBitLength() < 100)
            {
                for (int i = 0; i < A.Count; i++)
                    A[i] <<= 1;
            }

            txtLog.Text += "Создана сверхвозрастающая последовательность A\r\n";
        }


        //СОЗДАНИЕ ПУБЛИЧНОГО КЛЮЧА B

        private void btnPub_Click(object sender, EventArgs e)
        {
            if (A == null)
            {
                MessageBox.Show("Сначала создайте A");
                return;
            }

            BigInteger sum = A.Aggregate(BigInteger.Zero, (s, x) => s + x);
            m = sum + 123;

            Random rnd = new Random();

            do
            {
                w = rnd.Next(2, 500);
            }
            while (BigInteger.GreatestCommonDivisor(w, m) != 1);

            wInv = ModInverse(w, m);

            B = A.Select(ai => (ai * w) % m).ToList();

            txtLog.Text += "Создан открытый ключ B\r\n";
        }


        //Шифрование

        private void btnEncrypt_Click(object sender, EventArgs e)
        {
            if (B == null)
            {
                MessageBox.Show("Сначала создайте B");
                return;
            }

            z = rbBase64.Checked ? 6 : 8;

            string msg = txtInput.Text;

            List<bool> bits = MsgToBits(msg, z);

            realBitCount = bits.Count; 

            bool[][] blocks = BitsToBlocks(bits, A.Count);

            Stopwatch sw = Stopwatch.StartNew();

            List<BigInteger> cipher = new List<BigInteger>();

            foreach (var block in blocks)
            {
                BigInteger c = 0;
                for (int i = 0; i < block.Length; i++)
                    if (block[i]) c += B[i];
                cipher.Add(c);
            }

            sw.Stop();

            txtCipher.Text = string.Join(" ", cipher);
            txtLog.Text += $"Шифрование: {sw.ElapsedMilliseconds} ms\r\n";
        }


        //Дешифрование

        private void btnDecrypt_Click(object sender, EventArgs e)
        {
            if (A == null)
            {
                MessageBox.Show("Сначала создайте A");
                return;
            }

            string[] parts = txtCipher.Text.Split(new[] { ' ', '\n', '\r' },
                StringSplitOptions.RemoveEmptyEntries);

            List<BigInteger> cipher = parts.Select(BigInteger.Parse).ToList();

            z = rbBase64.Checked ? 6 : 8;

            Stopwatch sw = Stopwatch.StartNew();

            List<bool> bits = new List<bool>();

            foreach (BigInteger c in cipher)
            {
                BigInteger s = (c * wInv) % m;
                if (s < 0) s += m;

                bool[] block = new bool[A.Count];
                BigInteger rem = s;

                for (int i = A.Count - 1; i >= 0; i--)
                {
                    if (A[i] <= rem)
                    {
                        block[i] = true;
                        rem -= A[i];
                    }
                }

                bits.AddRange(block);
            }

            if (bits.Count > realBitCount)
                bits = bits.Take(realBitCount).ToList();

            sw.Stop();

            txtOutput.Text = BitsToMsg(bits.ToArray(), z);
            txtLog.Text += $"Дешифрование: {sw.ElapsedMilliseconds} ms\r\n";
        }


        //Утилиты

        BigInteger ModInverse(BigInteger a, BigInteger mod)
        {
            BigInteger x, y;
            ExtendedGCD(a, mod, out x, out y);
            x %= mod;
            if (x < 0) x += mod;
            return x;
        }

        BigInteger ExtendedGCD(BigInteger a, BigInteger b, out BigInteger x, out BigInteger y)
        {
            if (b == 0)
            {
                x = 1; y = 0; return a;
            }

            BigInteger x1, y1;
            BigInteger g = ExtendedGCD(b, a % b, out x1, out y1);
            x = y1;
            y = x1 - (a / b) * y1;
            return g;
        }


        //преобразование сообщения → биты

        List<bool> MsgToBits(string msg, int z)
        {
            List<bool> bits = new List<bool>();

            if (z == 6)   // Base64
            {
                string base64 = Convert.ToBase64String(Encoding.UTF8.GetBytes(msg));
                const string T = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

                foreach (char c in base64)
                {
                    int v = T.IndexOf(c);
                    for (int i = 5; i >= 0; i--)
                        bits.Add(((v >> i) & 1) == 1);
                }
            }
            else           // z = 8
            {
                foreach (byte b in Encoding.UTF8.GetBytes(msg))
                    for (int i = 7; i >= 0; i--)
                        bits.Add(((b >> i) & 1) == 1);
            }

            return bits;
        }


        //разбиение битов на блоки

        bool[][] BitsToBlocks(List<bool> bits, int n)
        {
            List<bool[]> blocks = new List<bool[]>();

            for (int i = 0; i < bits.Count; i += n)
            {
                bool[] block = new bool[n];
                for (int j = 0; j < n; j++)
                    if (i + j < bits.Count)
                        block[j] = bits[i + j];
                blocks.Add(block);
            }

            return blocks.ToArray();
        }


        //преобразование битов → сообщение

        string BitsToMsg(bool[] bits, int z)
        {
            if (z == 8)
            {
                List<byte> bytes = new List<byte>();

                for (int i = 0; i < bits.Length; i += 8)
                {
                    byte b = 0;
                    for (int j = 0; j < 8; j++)
                    {
                        b <<= 1;
                        if (i + j < bits.Length && bits[i + j]) b |= 1;
                    }
                    bytes.Add(b);
                }

                return Encoding.UTF8.GetString(bytes.ToArray());
            }
            else
            {
                const string T = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";
                List<char> chars = new List<char>();

                for (int i = 0; i < bits.Length; i += 6)
                {
                    int v = 0;
                    for (int j = 0; j < 6; j++)
                    {
                        v <<= 1;
                        if (i + j < bits.Length && bits[i + j]) v |= 1;
                    }
                    chars.Add(T[v]);
                }

                string b64 = new string(chars.ToArray());
                int pad = (4 - b64.Length % 4) % 4;
                b64 += new string('=', pad);

                return Encoding.UTF8.GetString(Convert.FromBase64String(b64));
            }
        }
    }


    // расширение для BigInteger: длина в битах
    public static class BigIntegerExt
    {
        public static int GetBitLength(this BigInteger x)
        {
            byte[] bytes = x.ToByteArray();
            int msb = bytes[bytes.Length - 1];
            int bits = (bytes.Length - 1) * 8;

            while (msb > 0)
            {
                msb >>= 1;
                bits++;
            }

            return bits;
        }
    }
}
