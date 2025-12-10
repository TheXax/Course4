using System;
using System.Diagnostics;
using System.Linq;
using System.Numerics;
using System.Security.Cryptography;
using System.Text;
using System.Windows.Forms;

namespace lab10
{
    static class Program
    {
        [STAThread]
        static void Main()
        {
            ApplicationConfiguration.Initialize();
            Application.Run(new MainForm());
        }
    }

    public class MainForm : Form
    {
        TabControl tabs;

        // RSA controls
        Button btnRsaGen, btnRsaSign, btnRsaVerify;
        TextBox txtRsaMsg, txtRsaSig, txtRsaLog;
        NumericUpDown nudRsaBits;
        RSA rsaKey;

        // ElGamal controls
        Button btnEgGen, btnEgSign, btnEgVerify;
        TextBox txtEgMsg, txtEgSig, txtEgLog;
        NumericUpDown nudEgBits;
        ElGamalKeyPair egKey;

        // Schnorr controls
        Button btnScGen, btnScSign, btnScVerify;
        TextBox txtScMsg, txtScSig, txtScLog;
        NumericUpDown nudScBits;
        SchnorrKeyPair scKey;

        public MainForm()
        {
            Text = "ЭЦП: RSA / ElGamal / Schnorr — учебный пример";
            Width = 900;
            Height = 720;
            StartPosition = FormStartPosition.CenterScreen;

            InitializeUI();
        }

        void InitializeUI()
        {
            tabs = new TabControl { Dock = DockStyle.Fill };
            var tabRsa = new TabPage("RSA");
            var tabEg = new TabPage("ElGamal");
            var tabSc = new TabPage("Schnorr");

            tabs.TabPages.AddRange(new[] { tabRsa, tabEg, tabSc });
            Controls.Add(tabs);

            BuildRsaTab(tabRsa);
            BuildElGamalTab(tabEg);
            BuildSchnorrTab(tabSc);
        }

        // --------------- RSA TAB ----------------
        void BuildRsaTab(TabPage p)
        {
            var lblBits = new Label { Left = 10, Top = 10, Text = "bits", Width = 40 };
            nudRsaBits = new NumericUpDown { Left = 60, Top = 7, Width = 100, Minimum = 512, Maximum = 8192, Value = 2048, Increment = 256 };

            btnRsaGen = new Button { Left = 180, Top = 5, Width = 160, Text = "Сгенерировать ключи RSA" };
            btnRsaGen.Click += BtnRsaGen_Click;

            p.Controls.AddRange(new Control[] { lblBits, nudRsaBits, btnRsaGen });

            var lblMsg = new Label { Left = 10, Top = 45, Text = "Сообщение:" };
            txtRsaMsg = new TextBox { Left = 10, Top = 65, Width = 820, Height = 80, Multiline = true, Text = "Стрелковская Вероника Андреевна" };

            btnRsaSign = new Button { Left = 10, Top = 155, Width = 120, Text = "Подписать" };
            btnRsaSign.Click += BtnRsaSign_Click;
            btnRsaVerify = new Button { Left = 140, Top = 155, Width = 120, Text = "Проверить" };
            btnRsaVerify.Click += BtnRsaVerify_Click;

            txtRsaSig = new TextBox { Left = 10, Top = 190, Width = 820, Height = 80, Multiline = true, ScrollBars = ScrollBars.Vertical };

            txtRsaLog = new TextBox { Left = 10, Top = 280, Width = 820, Height = 360, Multiline = true, ScrollBars = ScrollBars.Vertical, ReadOnly = true };

            p.Controls.AddRange(new Control[] { lblMsg, txtRsaMsg, btnRsaSign, btnRsaVerify, txtRsaSig, txtRsaLog });
        }

        private void BtnRsaGen_Click(object? sender, EventArgs e)
        {
            int bits = (int)nudRsaBits.Value;
            txtRsaLog.AppendText($"Генерация RSA ключей {bits} бит...\r\n");
            var sw = Stopwatch.StartNew();
            rsaKey?.Dispose();
            rsaKey = RSA.Create(bits);
            sw.Stop();
            txtRsaLog.AppendText($"Готово. Время: {sw.Elapsed.TotalMilliseconds:F1} ms. Modulus size: {rsaKey.KeySize} bits.\r\n\r\n");
        }

        private void BtnRsaSign_Click(object? sender, EventArgs e)
        {
            if (rsaKey == null) { MessageBox.Show("Сначала сгенерируйте ключи RSA."); return; }
            var msg = Encoding.UTF8.GetBytes(txtRsaMsg.Text ?? "");
            var sw = Stopwatch.StartNew();
            // используем SHA256 with PKCS#1 v1.5
            var sig = rsaKey.SignData(msg, HashAlgorithmName.SHA256, RSASignaturePadding.Pkcs1);
            sw.Stop();
            txtRsaSig.Text = Convert.ToBase64String(sig);
            txtRsaLog.AppendText($"RSA: подпись создана; время {sw.Elapsed.TotalMilliseconds:F3} ms; длина подписи {sig.Length} bytes.\r\n\r\n");
        }

        private void BtnRsaVerify_Click(object? sender, EventArgs e)
        {
            if (rsaKey == null) { MessageBox.Show("Сначала сгенерируйте ключи RSA."); return; }
            try
            {
                var msg = Encoding.UTF8.GetBytes(txtRsaMsg.Text ?? "");
                var sig = Convert.FromBase64String(txtRsaSig.Text.Trim());
                var sw = Stopwatch.StartNew();
                bool ok = rsaKey.VerifyData(msg, sig, HashAlgorithmName.SHA256, RSASignaturePadding.Pkcs1);
                sw.Stop();
                txtRsaLog.AppendText($"RSA: проверка => {(ok ? "ОК" : "НЕ ОК")}; время {sw.Elapsed.TotalMilliseconds:F3} ms.\r\n\r\n");
            }
            catch (FormatException)
            {
                MessageBox.Show("Подпись должна быть в Base64.");
            }
        }

        // --------------- ElGamal TAB ----------------
        void BuildElGamalTab(TabPage p)
        {
            var lblBits = new Label { Left = 10, Top = 10, Text = "p bits" };
            nudEgBits = new NumericUpDown { Left = 70, Top = 7, Width = 100, Minimum = 256, Maximum = 4096, Value = 512, Increment = 128 };

            btnEgGen = new Button { Left = 190, Top = 5, Width = 160, Text = "Сгенерировать ключи ElGamal" };
            btnEgGen.Click += BtnEgGen_Click;

            p.Controls.AddRange(new Control[] { lblBits, nudEgBits, btnEgGen });

            var lblMsg = new Label { Left = 10, Top = 45, Text = "Сообщение:" };
            txtEgMsg = new TextBox { Left = 10, Top = 65, Width = 820, Height = 80, Multiline = true, Text = "Стрелковская Вероника Андреевна" };

            btnEgSign = new Button { Left = 10, Top = 155, Width = 120, Text = "Подписать (ElGamal)" };
            btnEgSign.Click += BtnEgSign_Click;
            btnEgVerify = new Button { Left = 140, Top = 155, Width = 120, Text = "Проверить (ElGamal)" };
            btnEgVerify.Click += BtnEgVerify_Click;

            txtEgSig = new TextBox { Left = 10, Top = 190, Width = 820, Height = 80, Multiline = true, ScrollBars = ScrollBars.Vertical };

            txtEgLog = new TextBox { Left = 10, Top = 280, Width = 820, Height = 360, Multiline = true, ScrollBars = ScrollBars.Vertical, ReadOnly = true };

            p.Controls.AddRange(new Control[] { lblMsg, txtEgMsg, btnEgSign, btnEgVerify, txtEgSig, txtEgLog });
        }

        private void BtnEgGen_Click(object? sender, EventArgs e)
        {
            int bits = (int)nudEgBits.Value;
            txtEgLog.AppendText($"Генерация простого p ~ {bits} бит и ключей ElGamal...\r\n");
            var sw = Stopwatch.StartNew();
            egKey = ElGamalKeyPair.Generate(bits);
            sw.Stop();
            txtEgLog.AppendText($"Готово. Время: {sw.Elapsed.TotalMilliseconds:F1} ms. p битность={egKey.P.BitLength()}.\r\n");
            var phex = egKey.P.ToString("X");
            txtEgLog.AppendText($"p (hex prefix)={phex.Substring(0, Math.Min(40, phex.Length))}...\r\n\r\n");
        }

        private void BtnEgSign_Click(object? sender, EventArgs e)
        {
            if (egKey == null) { MessageBox.Show("Сначала сгенерируйте ключи ElGamal."); return; }
            var msg = Encoding.UTF8.GetBytes(txtEgMsg.Text ?? "");
            var h = HashToBigInteger(msg);
            var sw = Stopwatch.StartNew();
            var sig = egKey.Sign(h);
            sw.Stop();
            // Encode signature as "r:s"
            txtEgSig.Text = $"{sig.R}:{sig.S}";
            txtEgLog.AppendText($"ElGamal: подпись выполнена; время {sw.Elapsed.TotalMilliseconds:F3} ms.\r\n\r\n");
        }

        private void BtnEgVerify_Click(object? sender, EventArgs e)
        {
            if (egKey == null) { MessageBox.Show("Сначала сгенерируйте ключи ElGamal."); return; }
            try
            {
                var parts = txtEgSig.Text.Split(':');
                if (parts.Length < 2) { MessageBox.Show("Неверный формат подписи. Ожидается R:S"); return; }
                BigInteger r = BigInteger.Parse(parts[0]);
                BigInteger s = BigInteger.Parse(parts[1]);
                var msg = Encoding.UTF8.GetBytes(txtEgMsg.Text ?? "");
                var h = HashToBigInteger(msg);
                var sw = Stopwatch.StartNew();
                bool ok = egKey.Verify(h, r, s);
                sw.Stop();
                txtEgLog.AppendText($"ElGamal: проверка => {(ok ? "ОК" : "НЕ ОК")}; время {sw.Elapsed.TotalMilliseconds:F3} ms.\r\n\r\n");
            }
            catch (Exception ex)
            {
                MessageBox.Show("Ошибка разбора подписи: " + ex.Message);
            }
        }

        // --------------- Schnorr TAB ----------------
        void BuildSchnorrTab(TabPage p)
        {
            var lblBits = new Label { Left = 10, Top = 10, Text = "q bits (for q|p-1)" };
            nudScBits = new NumericUpDown { Left = 130, Top = 7, Width = 100, Minimum = 160, Maximum = 1024, Value = 256, Increment = 32 };

            btnScGen = new Button { Left = 250, Top = 5, Width = 160, Text = "Сгенерировать Schnorr params" };
            btnScGen.Click += BtnScGen_Click;

            p.Controls.AddRange(new Control[] { lblBits, nudScBits, btnScGen });

            var lblMsg = new Label { Left = 10, Top = 45, Text = "Сообщение:" };
            txtScMsg = new TextBox { Left = 10, Top = 65, Width = 820, Height = 80, Multiline = true, Text = "Стрелковская Вероника Андреевна" };

            btnScSign = new Button { Left = 10, Top = 155, Width = 120, Text = "Подписать (Schnorr)" };
            btnScSign.Click += BtnScSign_Click;
            btnScVerify = new Button { Left = 140, Top = 155, Width = 120, Text = "Проверить (Schnorr)" };
            btnScVerify.Click += BtnScVerify_Click;

            txtScSig = new TextBox { Left = 10, Top = 190, Width = 820, Height = 80, Multiline = true, ScrollBars = ScrollBars.Vertical };

            txtScLog = new TextBox { Left = 10, Top = 280, Width = 820, Height = 360, Multiline = true, ScrollBars = ScrollBars.Vertical, ReadOnly = true };

            p.Controls.AddRange(new Control[] { lblMsg, txtScMsg, btnScSign, btnScVerify, txtScSig, txtScLog });
        }

        private void BtnScGen_Click(object? sender, EventArgs e)
        {
            int qBits = (int)nudScBits.Value;
            txtScLog.AppendText($"Генерация параметров Schnorr (q ~ {qBits} бит)...\r\n");
            var sw = Stopwatch.StartNew();
            scKey = SchnorrKeyPair.Generate(qBits);
            sw.Stop();
            txtScLog.AppendText($"Готово. Время: {sw.Elapsed.TotalMilliseconds:F1} ms. q.bitlen={scKey.Q.BitLength()}\r\n");
            var phex = scKey.P.ToString("X");
            txtScLog.AppendText($"p hex prefix: {phex.Substring(0, Math.Min(40, phex.Length))}...\r\n\r\n");
        }

        private void BtnScSign_Click(object? sender, EventArgs e)
        {
            if (scKey == null) { MessageBox.Show("Сначала сгенерируйте параметры Schnorr."); return; }
            var msg = Encoding.UTF8.GetBytes(txtScMsg.Text ?? "");
            var sw = Stopwatch.StartNew();
            var sig = scKey.Sign(msg);
            sw.Stop();
            txtScSig.Text = $"{sig.E}:{sig.S}";
            txtScLog.AppendText($"Schnorr: подпись выполнена; время {sw.Elapsed.TotalMilliseconds:F3} ms.\r\n\r\n");
        }

        private void BtnScVerify_Click(object? sender, EventArgs e)
        {
            if (scKey == null) { MessageBox.Show("Сначала сгенерируйте параметры Schnorr."); return; }
            try
            {
                var parts = txtScSig.Text.Split(':');
                if (parts.Length < 2) { MessageBox.Show("Неверный формат подписи. Ожидается E:S"); return; }
                BigInteger eVal = BigInteger.Parse(parts[0]);
                BigInteger s = BigInteger.Parse(parts[1]);
                var msg = Encoding.UTF8.GetBytes(txtScMsg.Text ?? "");
                var sw = Stopwatch.StartNew();
                bool ok = scKey.Verify(msg, eVal, s);
                sw.Stop();
                txtScLog.AppendText($"Schnorr: проверка => {(ok ? "ОК" : "НЕ ОК")}; время {sw.Elapsed.TotalMilliseconds:F3} ms.\r\n\r\n");
            }
            catch (Exception ex)
            {
                MessageBox.Show("Ошибка разбора подписи: " + ex.Message);
            }
        }

        // ---------------- Helpers ----------------

        static BigInteger HashToBigInteger(byte[] data)
        {
            using var sha = SHA256.Create();
            var h = sha.ComputeHash(data);
            // создаём маленький padding-байт впереди, затем переворачиваем для little-endian BigInteger ctor
            var arr = new byte[h.Length + 1];
            Array.Copy(h, 0, arr, 1, h.Length);
            var little = arr.Reverse().ToArray();
            return new BigInteger(little);
        }
    }

    // ---------------- ElGamal keypair and sign/verify ----------------
    class ElGamalKeyPair
    {
        public BigInteger P { get; private set; }
        public BigInteger G { get; private set; }
        public BigInteger X { get; private set; } // private
        public BigInteger Y { get; private set; } // public = g^x mod p

        static readonly RandomNumberGenerator rng = RandomNumberGenerator.Create();

        ElGamalKeyPair() { }

        public static ElGamalKeyPair Generate(int bits)
        {
            BigInteger p = GenerateProbablePrime(bits);
            BigInteger g = 2;
            if (g >= p) g = 3;
            BigInteger x = RandomBigIntegerBelow(p - 2) + 1;
            BigInteger y = BigInteger.ModPow(g, x, p);
            return new ElGamalKeyPair { P = p, G = g, X = x, Y = y };
        }

        // ElGamal signature in Z_p: given H (as BigInteger), pick k coprime to p-1
        public (BigInteger R, BigInteger S) Sign(BigInteger H)
        {
            BigInteger p1 = P - 1;
            BigInteger k;
            do
            {
                k = RandomBigIntegerBelow(p1 - 1) + 1;
            } while (BigInteger.GreatestCommonDivisor(k, p1) != 1);

            BigInteger r = BigInteger.ModPow(G, k, P);
            BigInteger kinv = k.ModInverse(p1);
            BigInteger s = (kinv * (H - X * r)) % p1;
            if (s < 0) s += p1;
            return (r, s);
        }

        public bool Verify(BigInteger H, BigInteger r, BigInteger s)
        {
            if (r <= 0 || r >= P) return false;
            BigInteger left = BigInteger.ModPow(G, H, P);
            BigInteger yr = BigInteger.ModPow(Y, r, P);
            BigInteger rs = BigInteger.ModPow(r, s, P);
            BigInteger right = (yr * rs) % P;
            return left == right;
        }

        // ---------------- helpers ----------------
        static BigInteger RandomBigIntegerBelow(BigInteger bound)
        {
            if (bound <= 0) return BigInteger.Zero;
            int bits = bound.BitLength();
            while (true)
            {
                byte[] data = new byte[(bits + 7) / 8 + 1];
                rng.GetBytes(data);
                data[data.Length - 1] = 0;
                BigInteger v = new BigInteger(data);
                if (v < 0) v = -v;
                v %= bound;
                if (v >= 0 && v < bound) return v;
            }
        }

        // Miller-Rabin probable prime
        static BigInteger GenerateProbablePrime(int bits)
        {
            if (bits < 16) bits = 16;
            while (true)
            {
                byte[] bytes = new byte[(bits + 7) / 8 + 1];
                rng.GetBytes(bytes);
                bytes[bytes.Length - 1] = 0;
                BigInteger p = new BigInteger(bytes);
                if (p < 0) p = -p;
                // set top bit and make odd
                p |= (BigInteger.One << (bits - 1));
                if ((p & 1) == 0) p |= 1;
                if (IsProbablePrime(p, 10)) return p;
            }
        }

        static bool IsProbablePrime(BigInteger n, int k)
        {
            if (n < 2) return false;
            BigInteger[] small = { 2, 3, 5, 7, 11, 13, 17, 19, 23, 29, 31 };
            foreach (var s in small) if (n == s) return true;
            foreach (var s in small) if (n % s == 0) return false;

            BigInteger d = n - 1;
            int sCount = 0;
            while ((d & 1) == 0) { d >>= 1; sCount++; }

            for (int i = 0; i < k; i++)
            {
                BigInteger a;
                do
                {
                    a = RandomBigIntegerBelow(n - 3) + 2;
                } while (a <= 1 || a >= n - 1);
                BigInteger x = BigInteger.ModPow(a, d, n);
                if (x == 1 || x == n - 1) continue;
                bool composite = true;
                for (int r = 1; r < sCount; r++)
                {
                    x = BigInteger.ModPow(x, 2, n);
                    if (x == n - 1) { composite = false; break; }
                }
                if (composite) return false;
            }
            return true;
        }
    }

    // ---------------- Schnorr keypair and sign/verify ----------------
    class SchnorrKeyPair
    {
        public BigInteger P { get; private set; }
        public BigInteger Q { get; private set; }
        public BigInteger G { get; private set; }
        public BigInteger X { get; private set; } // priv
        public BigInteger Y { get; private set; } // pub = g^x mod p

        static readonly RandomNumberGenerator rng = RandomNumberGenerator.Create();

        SchnorrKeyPair() { }

        public static SchnorrKeyPair Generate(int qBits)
        {
            while (true)
            {
                BigInteger q = GenerateProbablePrime(qBits);
                for (int tries = 0; tries < 2000; tries++)
                {
                    BigInteger k = RandomBigInteger(qBits + 4);
                    if (k < 2) k = 2;
                    BigInteger p = k * q + 1;
                    if (p.BitLength() < qBits + 10) continue;
                    if (IsProbablePrime(p, 8))
                    {
                        for (BigInteger h = 2; h < 1000; h++)
                        {
                            BigInteger g = BigInteger.ModPow(h, (p - 1) / q, p);
                            if (g > 1)
                            {
                                BigInteger x = RandomBigIntegerBelow(q - 1) + 1;
                                BigInteger y = BigInteger.ModPow(g, x, p);
                                return new SchnorrKeyPair { P = p, Q = q, G = g, X = x, Y = y };
                            }
                        }
                    }
                }
            }
        }

        public (BigInteger E, BigInteger S) Sign(byte[] msg)
        {
            BigInteger k = RandomBigIntegerBelow(Q - 1) + 1;
            BigInteger r = BigInteger.ModPow(G, k, P);
            var e = HashToBigIntegerConcat(msg, r) % Q;
            BigInteger s = (k - X * e) % Q;
            if (s < 0) s += Q;
            return (e, s);
        }

        public bool Verify(byte[] msg, BigInteger e, BigInteger s)
        {
            BigInteger gs = BigInteger.ModPow(G, s, P);
            BigInteger ye = BigInteger.ModPow(Y, e, P);
            BigInteger rprime = (gs * ye) % P;
            BigInteger eprime = HashToBigIntegerConcat(msg, rprime) % Q;
            return eprime == e;
        }

        // ---------------- helpers ----------------

        static BigInteger HashToBigIntegerConcat(byte[] msg, BigInteger r)
        {
            using var sha = SHA256.Create();
            byte[] rbytes = r.ToByteArray(isUnsigned: true, isBigEndian: true);
            byte[] data = new byte[msg.Length + rbytes.Length];
            Buffer.BlockCopy(msg, 0, data, 0, msg.Length);
            Buffer.BlockCopy(rbytes, 0, data, msg.Length, rbytes.Length);
            var h = sha.ComputeHash(data);
            var arr = new byte[h.Length + 1];
            Array.Copy(h, 0, arr, 1, h.Length);
            return new BigInteger(arr.Reverse().ToArray());
        }

        static BigInteger RandomBigInteger(int bits)
        {
            if (bits <= 0) return 0;
            var bytes = new byte[(bits + 7) / 8 + 1];
            rng.GetBytes(bytes);
            bytes[bytes.Length - 1] = 0;
            BigInteger v = new BigInteger(bytes);
            if (v < 0) v = -v;
            return v;
        }

        static BigInteger RandomBigIntegerBelow(BigInteger bound)
        {
            if (bound <= 0) return BigInteger.Zero;
            int bits = bound.BitLength();
            while (true)
            {
                byte[] data = new byte[(bits + 7) / 8 + 1];
                rng.GetBytes(data);
                data[data.Length - 1] = 0;
                BigInteger v = new BigInteger(data);
                if (v < 0) v = -v;
                v %= bound;
                if (v >= 0 && v < bound) return v;
            }
        }

        // Miller-Rabin and prime generation
        static BigInteger GenerateProbablePrime(int bits)
        {
            if (bits < 16) bits = 16;
            while (true)
            {
                byte[] bytes = new byte[(bits + 7) / 8 + 1];
                rng.GetBytes(bytes);
                bytes[bytes.Length - 1] = 0;
                BigInteger p = new BigInteger(bytes);
                if (p < 0) p = -p;
                p |= (BigInteger.One << (bits - 1));
                if ((p & 1) == 0) p |= 1;
                if (IsProbablePrime(p, 10)) return p;
            }
        }

        static bool IsProbablePrime(BigInteger n, int k)
        {
            if (n < 2) return false;
            BigInteger[] small = { 2, 3, 5, 7, 11, 13, 17, 19, 23, 29, 31 };
            foreach (var s in small) if (n == s) return true;
            foreach (var s in small) if (n % s == 0) return false;

            BigInteger d = n - 1;
            int sCount = 0;
            while ((d & 1) == 0) { d >>= 1; sCount++; }

            for (int i = 0; i < k; i++)
            {
                BigInteger a;
                do
                {
                    a = RandomBigIntegerBelow(n - 3) + 2;
                } while (a <= 1 || a >= n - 1);
                BigInteger x = BigInteger.ModPow(a, d, n);
                if (x == 1 || x == n - 1) continue;
                bool composite = true;
                for (int r = 1; r < sCount; r++)
                {
                    x = BigInteger.ModPow(x, 2, n);
                    if (x == n - 1) { composite = false; break; }
                }
                if (composite) return false;
            }
            return true;
        }
    }

    // ----------------- Helpers -----------------
    static class Helpers
    {
        // Битовая длина
        public static int BitLength(this BigInteger a)
        {
            BigInteger v = a;
            if (v < 0) v = -v;
            if (v.IsZero) return 1;
            int bits = 0;
            while (v > 0)
            {
                bits++;
                v >>= 1;
            }
            return bits;
        }

        // Модульная обратная по Евклиду
        public static BigInteger ModInverse(this BigInteger a, BigInteger m)
        {
            BigInteger g = ExtendedGcd(a, m, out BigInteger x, out BigInteger y);
            if (g != 1 && g != -1) throw new Exception("Inverse does not exist");
            x %= m;
            if (x < 0) x += m;
            return x;
        }

        static BigInteger ExtendedGcd(BigInteger a, BigInteger b, out BigInteger x, out BigInteger y)
        {
            if (b.IsZero)
            {
                x = BigInteger.One; y = BigInteger.Zero; return a;
            }
            BigInteger g = ExtendedGcd(b, a % b, out BigInteger x1, out BigInteger y1);
            x = y1;
            y = x1 - (a / b) * y1;
            return g;
        }

        // BigInteger -> big-endian bytes
        public static byte[] ToBigEndianBytes(this BigInteger a)
        {
            return a.ToByteArray(isUnsigned: true, isBigEndian: true);
        }
    }
}
