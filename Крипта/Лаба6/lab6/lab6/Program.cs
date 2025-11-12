using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.Drawing;
using System.Linq;
using System.Text;
using System.Windows.Forms;

namespace PRNG_RC4_Tools
{
    static class Program
    {
        [STAThread]
        static void Main()
        {
            Application.EnableVisualStyles();
            Application.SetCompatibleTextRenderingDefault(false);
            Application.Run(new MainForm());
        }
    }

    // ---------- Главная форма с двумя вкладками ----------
    public class MainForm : Form
    {
        TabControl tab;
        // LCG
        TextBox txtLCGCount;
        Button btnGenerateLCG;
        TextBox txtLCGOutput;
        Label lblLCGInfo;
        Button btnLCGMeasure;

        // RC4
        TextBox txtPlain;
        TextBox txtCipherHex;
        Button btnEncryptRC4;
        Button btnDecryptRC4;
        Label lblRC4Time;
        TextBox txtKey;

        public MainForm()
        {
            Text = "PRNG (LCG) и RC4 — лабораторная";
            Width = 900;
            Height = 700;
            StartPosition = FormStartPosition.CenterScreen;

            tab = new TabControl { Dock = DockStyle.Fill };
            tab.TabPages.Add(CreateLCGPage());
            tab.TabPages.Add(CreateRC4Page());
            Controls.Add(tab);
        }

        // ---------------- LCG Page ----------------
        TabPage CreateLCGPage()
        {
            var page = new TabPage("LCG — генератор ПСП");

            const long a = 430;
            const long c = 2531;
            const long n = 11979; // модуль

            var lblParams = new Label()
            {
                Text = $"Параметры LCG: a={a}, c={c}, n={n}\nФормула: X_{{i + 1}} = (a * X_i + c) mod n",
                Location = new Point(10, 10),
                AutoSize = true
            };
            page.Controls.Add(lblParams);

            var lblSeed = new Label { Text = "Семя (seed, целое ≥0):", Location = new Point(10, 60), AutoSize = true };
            page.Controls.Add(lblSeed);
            var txtSeed = new TextBox { Location = new Point(160, 57), Width = 120, Text = "1" };
            page.Controls.Add(txtSeed);

            var lblCount = new Label { Text = "Кол-во значений:", Location = new Point(300, 60), AutoSize = true };
            page.Controls.Add(lblCount);
            txtLCGCount = new TextBox { Location = new Point(420, 57), Width = 80, Text = "1000" };
            page.Controls.Add(txtLCGCount);

            btnGenerateLCG = new Button { Text = "Сгенерировать", Location = new Point(520, 55), Width = 130 };
            page.Controls.Add(btnGenerateLCG);

            btnLCGMeasure = new Button { Text = "Замерить скорость", Location = new Point(660, 55), Width = 160 };
            page.Controls.Add(btnLCGMeasure);

            lblLCGInfo = new Label { Text = "Информация:", Location = new Point(10, 90), Size = new Size(820, 30) };
            page.Controls.Add(lblLCGInfo);

            txtLCGOutput = new TextBox { Location = new Point(10, 130), Width = 820, Height = 460, Multiline = true, ScrollBars = ScrollBars.Both, Font = new Font("Consolas", 10) };
            page.Controls.Add(txtLCGOutput);

            // Events
            btnGenerateLCG.Click += (s, e) =>
            {
                if (!long.TryParse(txtSeed.Text, out long seed) || seed < 0)
                {
                    MessageBox.Show("Семя должно быть неотрицательным целым.", "Ошибка", MessageBoxButtons.OK, MessageBoxIcon.Error);
                    return;
                }
                if (!int.TryParse(txtLCGCount.Text, out int count) || count <= 0) { MessageBox.Show("Кол-во должно быть положительным целым.", "Ошибка", MessageBoxButtons.OK, MessageBoxIcon.Error); return; }
                var seq = LCGGenerate(seed, a, c, n, count);
                txtLCGOutput.Text = string.Join(", ", seq.Take(500)); // показываем до 500 значений
                if (count > 500) txtLCGOutput.AppendText($"\r\n... (всего {count} значений)");
                // простая статистика
                double avg = seq.Average();
                int min = seq.Min(); int max = seq.Max();
                lblLCGInfo.Text = $"Сгенерировано {count} значений. min={min}, max={max}, avg={avg:F3}";
            };

            btnLCGMeasure.Click += (s, e) =>
            {
                if (!long.TryParse(txtSeed.Text, out long seed) || seed < 0) { MessageBox.Show("Семя должно быть неотрицательным целым.", "Ошибка", MessageBoxButtons.OK, MessageBoxIcon.Error); return; }
                if (!int.TryParse(txtLCGCount.Text, out int count) || count <= 0) { MessageBox.Show("Кол-во должно быть положительным целым.", "Ошибка", MessageBoxButtons.OK, MessageBoxIcon.Error); return; }

                // Несколько прогонов для средней оценки
                int runs = 5;
                long totalMs = 0;
                for (int r = 0; r < runs; r++)
                {
                    var sw = Stopwatch.StartNew();
                    var seq = LCGGenerate(seed, a, c, n, count);
                    sw.Stop();
                    totalMs += sw.ElapsedMilliseconds;
                }
                double avgMs = totalMs / (double)runs;
                lblLCGInfo.Text = $"Среднее время генерации {count} значений LCG (за {runs} прогонов): {avgMs:F2} ms";
            };

            return page;
        }

        static List<int> LCGGenerate(long seed, long a, long c, long mod, int count)
        {
            var list = new List<int>(count);
            long x = seed % mod;
            for (int i = 0; i < count; i++)
            {
                x = (a * x + c) % mod;
                list.Add((int)x);
            }
            return list;
        }

        // ---------------- RC4 Page ----------------
        TabPage CreateRC4Page()
        {
            var page = new TabPage("RC4 — потоковый шифр");

            var lblIntro = new Label { Text = "RC4: n=8 (байтовая версия). Ключ по заданию: 122,125,48,84,201", Location = new Point(10, 10), AutoSize = true };
            page.Controls.Add(lblIntro);

            var lblKey = new Label { Text = "Ключ (байты, через запятую):", Location = new Point(10, 40), AutoSize = true };
            page.Controls.Add(lblKey);
            txtKey = new TextBox { Location = new Point(220, 37), Width = 300, Text = "122,125,48,84,201" };
            page.Controls.Add(txtKey);

            var lblPlain = new Label { Text = "Исходный текст:", Location = new Point(10, 80), AutoSize = true };
            page.Controls.Add(lblPlain);
            txtPlain = new TextBox { Location = new Point(10, 100), Width = 820, Height = 160, Multiline = true, ScrollBars = ScrollBars.Vertical, Font = new Font("Segoe UI", 10) };
            txtPlain.Text = "Это тестовое сообщение для шифрования RC4 (можно заменить).";
            page.Controls.Add(txtPlain);

            btnEncryptRC4 = new Button { Text = "Зашифровать (RC4)", Location = new Point(10, 270), Width = 160 };
            page.Controls.Add(btnEncryptRC4);
            btnDecryptRC4 = new Button { Text = "Расшифровать (RC4 по hex)", Location = new Point(180, 270), Width = 220 };
            page.Controls.Add(btnDecryptRC4);

            lblRC4Time = new Label { Text = "Время:", Location = new Point(420, 270), AutoSize = true };
            page.Controls.Add(lblRC4Time);

            var lblCipher = new Label { Text = "Шифртекст (hex):", Location = new Point(10, 310), AutoSize = true };
            page.Controls.Add(lblCipher);
            txtCipherHex = new TextBox { Location = new Point(10, 330), Width = 820, Height = 260, Multiline = true, ScrollBars = ScrollBars.Both, Font = new Font("Consolas", 10) };
            page.Controls.Add(txtCipherHex);

            // Events
            btnEncryptRC4.Click += (s, e) =>
            {
                byte[] key;
                try
                {
                    key = ParseKey(txtKey.Text);
                    if (key.Length == 0) throw new Exception("Ключ пуст.");
                }
                catch (Exception ex) { MessageBox.Show("Ошибка парсинга ключа: " + ex.Message); return; }

                string plain = txtPlain.Text ?? "";
                byte[] plainBytes = Encoding.UTF8.GetBytes(plain);

                var sw = Stopwatch.StartNew();
                byte[] cipher = RC4Crypt(plainBytes, key);
                sw.Stop();
                lblRC4Time.Text = $"Время шифрования: {sw.ElapsedMilliseconds} ms ({sw.ElapsedTicks} ticks)";

                txtCipherHex.Text = BitConverter.ToString(cipher).Replace("-", " ");
            };

            btnDecryptRC4.Click += (s, e) =>
            {
                byte[] key;
                try
                {
                    key = ParseKey(txtKey.Text);
                    if (key.Length == 0) throw new Exception("Ключ пуст.");
                }
                catch (Exception ex) { MessageBox.Show("Ошибка парсинга ключа: " + ex.Message); return; }

                string hex = txtCipherHex.Text ?? "";
                byte[] cipher;
                try { cipher = HexToBytes(hex); }
                catch { MessageBox.Show("Неверный hex-ввод."); return; }

                var sw = Stopwatch.StartNew();
                byte[] recovered = RC4Crypt(cipher, key); // RC4 симметричен
                sw.Stop();
                lblRC4Time.Text = $"Время расшифрования: {sw.ElapsedMilliseconds} ms ({sw.ElapsedTicks} ticks)";

                txtPlain.Text = Encoding.UTF8.GetString(recovered);
            };

            return page;
        }

        // ------------- RC4 реализация -------------
        static byte[] ParseKey(string text)
        {
            var parts = text.Split(new[] { ',', ';', ' ' }, StringSplitOptions.RemoveEmptyEntries);
            var list = new List<byte>();
            foreach (var p in parts)
            {
                if (byte.TryParse(p.Trim(), out byte b)) list.Add(b);
                else throw new Exception($"Невозможно разобрать '{p}' как байт (0..255).");
            }
            return list.ToArray();
        }

        // RC4: KSA + PRGA
        static byte[] RC4Crypt(byte[] data, byte[] key)
        {
            // KSA
            byte[] S = new byte[256];
            for (int i = 0; i < 256; i++) S[i] = (byte)i;
            int j = 0;
            for (int i = 0; i < 256; i++)
            {
                j = (j + S[i] + key[i % key.Length]) & 0xFF;
                Swap(S, i, j);
            }

            // PRGA
            byte[] outb = new byte[data.Length];
            int ii = 0; j = 0;
            for (int k = 0; k < data.Length; k++)
            {
                ii = (ii + 1) & 0xFF;
                j = (j + S[ii]) & 0xFF;
                Swap(S, ii, j);
                int t = (S[ii] + S[j]) & 0xFF;
                byte kbyte = S[t];
                outb[k] = (byte)(data[k] ^ kbyte);
            }
            return outb;
        }

        static void Swap(byte[] S, int i, int j)
        {
            byte tmp = S[i]; S[i] = S[j]; S[j] = tmp;
        }

        static byte[] HexToBytes(string hex)
        {
            var parts = hex.Split(new[] { ' ', '\t', '\r', '\n' }, StringSplitOptions.RemoveEmptyEntries);
            var bytes = new List<byte>();
            foreach (var p in parts)
            {
                string s = p.Trim();
                if (s.Length % 2 != 0) s = "0" + s;
                for (int i = 0; i < s.Length; i += 2)
                {
                    bytes.Add(Convert.ToByte(s.Substring(i, 2), 16));
                }
            }
            return bytes.ToArray();
        }
    }
}
