using System;
using System.Diagnostics;
using System.IO;
using System.Linq;
using System.Security.Cryptography;
using System.Text;
using System.Windows.Forms;

namespace lab9
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
        ComboBox cmbAlgo;
        TextBox txtInput;
        Button btnHashText;
        Button btnSelectFile;
        TextBox txtFilePath;
        Button btnHashFile;
        TextBox txtOutput;
        Button btnBenchmark;
        NumericUpDown nudIterations;
        Label lblIter;

        public MainForm()
        {
            Text = "Hash Lab — MD / SHA (текст, файл, бенчмарк)";
            Width = 900;
            Height = 700;
            StartPosition = FormStartPosition.CenterScreen;
            InitializeComponents();
        }

        void InitializeComponents()
        {
            // Algorithm selection
            Label lblAlgo = new Label { Text = "Алгоритм:", Left = 10, Top = 14, Width = 80 };
            Controls.Add(lblAlgo);

            cmbAlgo = new ComboBox { Left = 100, Top = 10, Width = 160, DropDownStyle = ComboBoxStyle.DropDownList };
            cmbAlgo.Items.AddRange(new object[] { "MD5", "SHA1", "SHA256", "SHA384", "SHA512" });
            cmbAlgo.SelectedIndex = 2; // SHA256 по умолчанию
            Controls.Add(cmbAlgo);

            // Input text
            Label lblInput = new Label { Text = "Текст для хеширования:", Left = 10, Top = 50, Width = 200 };
            Controls.Add(lblInput);

            txtInput = new TextBox { Left = 10, Top = 70, Width = 860, Height = 120, Multiline = true, ScrollBars = ScrollBars.Vertical };
            txtInput.Text = "Стрелковская Вероника Андреевна";
            Controls.Add(txtInput);

            btnHashText = new Button { Text = "Хешировать текст", Left = 10, Top = 200, Width = 160 };
            btnHashText.Click += BtnHashText_Click;
            Controls.Add(btnHashText);

            // File area
            btnSelectFile = new Button { Text = "Выбрать файл...", Left = 200, Top = 200, Width = 140 };
            btnSelectFile.Click += BtnSelectFile_Click;
            Controls.Add(btnSelectFile);

            txtFilePath = new TextBox { Left = 360, Top = 200, Width = 510 };
            Controls.Add(txtFilePath);

            btnHashFile = new Button { Text = "Хешировать файл", Left = 10, Top = 240, Width = 160 };
            btnHashFile.Click += BtnHashFile_Click;
            Controls.Add(btnHashFile);

            // Benchmark controls
            lblIter = new Label { Text = "Итераций среднего:", Left = 200, Top = 245, Width = 150 };
            Controls.Add(lblIter);
            nudIterations = new NumericUpDown { Left = 360, Top = 240, Width = 80, Minimum = 1, Maximum = 1000, Value = 5 };
            Controls.Add(nudIterations);

            btnBenchmark = new Button { Text = "Бенчмарк (генерация тестовых блоков)", Left = 460, Top = 240, Width = 240 };
            btnBenchmark.Click += BtnBenchmark_Click;
            Controls.Add(btnBenchmark);

            // Output area
            Label lblOut = new Label { Text = "Результат / Лог:", Left = 10, Top = 280, Width = 200 };
            Controls.Add(lblOut);

            txtOutput = new TextBox { Left = 10, Top = 300, Width = 860, Height = 340, Multiline = true, ScrollBars = ScrollBars.Both, ReadOnly = false, Font = new System.Drawing.Font("Consolas", 10) };
            Controls.Add(txtOutput);
        }

        // ---------------- Handlers ----------------

        private void BtnHashText_Click(object sender, EventArgs e)
        {
            try
            {
                string alg = cmbAlgo.SelectedItem.ToString();
                string input = txtInput.Text ?? "";
                byte[] bytes = Encoding.UTF8.GetBytes(input);
                var sw = Stopwatch.StartNew();
                byte[] hash = ComputeHash(bytes, alg);
                sw.Stop();
                string hex = ToHex(hash);
                txtOutput.AppendText($"[{DateTime.Now:HH:mm:ss}] {alg} (текст) = {hex}\r\n");
                txtOutput.AppendText($"Время: {sw.Elapsed.TotalMilliseconds:F3} ms\r\n\r\n");
            }
            catch (Exception ex)
            {
                MessageBox.Show("Ошибка: " + ex.Message);
            }
        }

        private void BtnSelectFile_Click(object sender, EventArgs e)
        {
            using OpenFileDialog dlg = new OpenFileDialog();
            if (dlg.ShowDialog() == DialogResult.OK)
            {
                txtFilePath.Text = dlg.FileName;
            }
        }

        private void BtnHashFile_Click(object sender, EventArgs e)
        {
            try
            {
                string path = txtFilePath.Text;
                if (string.IsNullOrEmpty(path) || !File.Exists(path))
                {
                    MessageBox.Show("Выберите существующий файл.");
                    return;
                }
                string alg = cmbAlgo.SelectedItem.ToString();
                var sw = Stopwatch.StartNew();
                byte[] hash = ComputeFileHash(path, alg);
                sw.Stop();
                txtOutput.AppendText($"[{DateTime.Now:HH:mm:ss}] {alg} (файл: {Path.GetFileName(path)}) = {ToHex(hash)}\r\n");
                txtOutput.AppendText($"Время: {sw.Elapsed.TotalMilliseconds:F3} ms\r\n\r\n");
            }
            catch (Exception ex)
            {
                MessageBox.Show("Ошибка: " + ex.Message);
            }
        }

        private void BtnBenchmark_Click(object sender, EventArgs e)
        {
            try
            {
                int iterations = (int)nudIterations.Value;
                string alg = cmbAlgo.SelectedItem.ToString();

                // размеры блоков для теста (байт)
                int[] sizes = new int[] { 1 * 1024, 10 * 1024, 100 * 1024, 1024 * 1024 }; // 1KB, 10KB, 100KB, 1MB
                txtOutput.AppendText($"[{DateTime.Now:HH:mm:ss}] Бенчмарк {alg}, итераций={iterations}\r\n");
                txtOutput.AppendText("size(bytes);avg_ms;min_ms;max_ms\n");

                foreach (int size in sizes)
                {
                    // подготовка тестового блока
                    byte[] data = new byte[size];
                    Random rnd = new Random(12345); // детерминированно
                    rnd.NextBytes(data);

                    double[] ms = new double[iterations];
                    for (int i = 0; i < iterations; i++)
                    {
                        var sw = Stopwatch.StartNew();
                        // хешируем
                        byte[] h = ComputeHash(data, alg);
                        sw.Stop();
                        ms[i] = sw.Elapsed.TotalMilliseconds;
                        Application.DoEvents(); // чтобы UI не "повис"
                    }
                    double avg = ms.Average();
                    double min = ms.Min();
                    double max = ms.Max();
                    txtOutput.AppendText($"{size};{avg:F3};{min:F3};{max:F3}\r\n");
                }

                txtOutput.AppendText("\r\n");
            }
            catch (Exception ex)
            {
                MessageBox.Show("Ошибка при бенчмарке: " + ex.Message);
            }
        }

        // ---------------- Hash helpers ----------------

        private static byte[] ComputeHash(byte[] data, string alg)
        {
            // Используем System.Security.Cryptography
            return alg switch
            {
                "MD5" => MD5.Create().ComputeHash(data),
                "SHA1" => SHA1.Create().ComputeHash(data),
                "SHA256" => SHA256.Create().ComputeHash(data),
                "SHA384" => SHA384.Create().ComputeHash(data),
                "SHA512" => SHA512.Create().ComputeHash(data),
                _ => throw new ArgumentException("Неизвестный алгоритм"),
            };
        }

        private static byte[] ComputeFileHash(string path, string alg)
        {
            // Читаем файл потоково (chunked) и вычисляем хеш без загрузки всего в память
            using FileStream fs = new FileStream(path, FileMode.Open, FileAccess.Read, FileShare.Read);
            switch (alg)
            {
                case "MD5":
                    using (var h1 = MD5.Create()) { return h1.ComputeHash(fs); }
                case "SHA1":
                    using (var h2 = SHA1.Create()) { return h2.ComputeHash(fs); }
                case "SHA256":
                    using (var h3 = SHA256.Create()) { return h3.ComputeHash(fs); }
                case "SHA384":
                    using (var h4 = SHA384.Create()) { return h4.ComputeHash(fs); }
                case "SHA512":
                    using (var h5 = SHA512.Create()) { return h5.ComputeHash(fs); }
                default:
                    throw new ArgumentException("Неизвестный алгоритм");
            }
        }

        private static string ToHex(byte[] bs)
        {
            StringBuilder sb = new StringBuilder(bs.Length * 2);
            foreach (var b in bs) sb.AppendFormat("{0:x2}", b);
            return sb.ToString();
        }
    }
}
