namespace lab7
{
    partial class Form1
    {
        private System.ComponentModel.IContainer components = null;

        protected override void Dispose(bool disposing)
        {
            if (disposing && (components != null))
            {
                components.Dispose();
            }
            base.Dispose(disposing);
        }

        #region Windows Form Designer generated code

        private void InitializeComponent()
        {
            numN = new NumericUpDown();
            btnPriv = new Button();
            btnPub = new Button();
            rbBase64 = new RadioButton();
            rbAscii = new RadioButton();
            txtInput = new TextBox();
            btnEncrypt = new Button();
            btnDecrypt = new Button();
            txtCipher = new TextBox();
            txtOutput = new TextBox();
            txtLog = new TextBox();
            label1 = new Label();
            label2 = new Label();
            label3 = new Label();
            label4 = new Label();
            ((System.ComponentModel.ISupportInitialize)numN).BeginInit();
            SuspendLayout();

            // numN
            numN.Location = new Point(15, 15);
            numN.Maximum = new decimal(new int[] { 1024, 0, 0, 0 });
            numN.Minimum = new decimal(new int[] { 8, 0, 0, 0 });
            numN.Name = "numN";
            numN.Size = new Size(90, 27);
            numN.Value = new decimal(new int[] { 100, 0, 0, 0 });

            // btnPriv
            btnPriv.Location = new Point(120, 10);
            btnPriv.Size = new Size(150, 30);
            btnPriv.Text = "Создать A (приватный)";
            btnPriv.Click += btnPriv_Click;

            // btnPub
            btnPub.Location = new Point(280, 10);
            btnPub.Size = new Size(150, 30);
            btnPub.Text = "Создать B (публичный)";
            btnPub.Click += btnPub_Click;

            // rbBase64
            rbBase64.AutoSize = true;
            rbBase64.Checked = true;
            rbBase64.Location = new Point(450, 15);
            rbBase64.Text = "Base64 (z=6)";

            // rbAscii
            rbAscii.AutoSize = true;
            rbAscii.Location = new Point(550, 15);
            rbAscii.Text = "ASCII (z=8)";

            // txtInput
            txtInput.Location = new Point(15, 80);
            txtInput.Multiline = true;
            txtInput.Size = new Size(630, 60);

            // btnEncrypt
            btnEncrypt.Location = new Point(15, 150);
            btnEncrypt.Size = new Size(130, 30);
            btnEncrypt.Text = "Зашифровать";
            btnEncrypt.Click += btnEncrypt_Click;

            // btnDecrypt
            btnDecrypt.Location = new Point(155, 150);
            btnDecrypt.Size = new Size(130, 30);
            btnDecrypt.Text = "Расшифровать";
            btnDecrypt.Click += btnDecrypt_Click;

            // txtCipher
            txtCipher.Location = new Point(15, 215);
            txtCipher.Multiline = true;
            txtCipher.ScrollBars = ScrollBars.Both;
            txtCipher.Size = new Size(630, 60);

            // txtOutput
            txtOutput.Location = new Point(15, 305);
            txtOutput.Multiline = true;
            txtOutput.Size = new Size(630, 40);

            // txtLog
            txtLog.Location = new Point(15, 375);
            txtLog.Multiline = true;
            txtLog.ReadOnly = true;
            txtLog.ScrollBars = ScrollBars.Both;
            txtLog.Size = new Size(630, 150);

            // labels
            label1.AutoSize = true;
            label1.Location = new Point(15, 60);
            label1.Text = "Исходный текст:";

            label2.AutoSize = true;
            label2.Location = new Point(15, 195);
            label2.Text = "Шифртекст:";

            label3.AutoSize = true;
            label3.Location = new Point(15, 285);
            label3.Text = "Расшифровка:";

            label4.AutoSize = true;
            label4.Location = new Point(15, 355);
            label4.Text = "Лог выполнения:";

            // Form1
            ClientSize = new Size(670, 540);
            Controls.Add(label4);
            Controls.Add(label3);
            Controls.Add(label2);
            Controls.Add(label1);
            Controls.Add(txtLog);
            Controls.Add(txtOutput);
            Controls.Add(txtCipher);
            Controls.Add(btnDecrypt);
            Controls.Add(btnEncrypt);
            Controls.Add(txtInput);
            Controls.Add(rbAscii);
            Controls.Add(rbBase64);
            Controls.Add(btnPub);
            Controls.Add(btnPriv);
            Controls.Add(numN);
            Name = "Form1";
            Text = "Merkle–Hellman Knapsack";
            Load += Form1_Load;   // <-- исправлено, метод теперь существует

            ((System.ComponentModel.ISupportInitialize)numN).EndInit();
            ResumeLayout(false);
            PerformLayout();
        }

        #endregion

        private NumericUpDown numN;
        private Button btnPriv;
        private Button btnPub;
        private RadioButton rbBase64;
        private RadioButton rbAscii;
        private TextBox txtInput;
        private Button btnEncrypt;
        private Button btnDecrypt;
        private TextBox txtCipher;
        private TextBox txtOutput;
        private TextBox txtLog;
        private Label label1;
        private Label label2;
        private Label label3;
        private Label label4;
    }
}
