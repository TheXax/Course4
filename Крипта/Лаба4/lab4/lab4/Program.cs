using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.Linq;
using System.Text;

class EnigmaSimple
{
    // Алфавит (английский A..Z) — модель классической Энигмы
    const string ALPH = "ABCDEFGHIJKLMNOPQRSTUVWXYZ";

    // --- Спецификация роторов (строка описывает проводку: входная буква -> выходная) ---
    static readonly Dictionary<string, string> ROTORS = new Dictionary<string, string>(StringComparer.OrdinalIgnoreCase)
    {
        {"I",   "EKMFLGDQVZNTOWYHXUSPAIBRCJ"},
        {"II",  "AJDKSIRUXBLHWTMCQGZNPYFVOE"},
        {"III", "BDFHJLCPRTXVZNYEIWGAKMUSQO"},
        {"IV",  "ESOVPZJAYQUIRHXLNFTGKDCMWB"},
        {"V",   "VZBRGITYUPSDNHLXAWMJQOFECK"},
        {"VI",  "JPGVOUMFYQBENHZRDKASXLICTW"},
        {"VII", "NZJHGRCXMYSWBOUFAIVLPEKQDT"},
        {"VIII","FKQHTLXOCBJSPDZRAMEWNIUYGV"},
        {"BETA","LEYJVCNIXWPBQMDRTAKZGFUHOS"},
        {"GAMMA","FSOKANUERHMBTIYCWLQPZXVGJD"}
    };

    // --- Отражатели ---
    static readonly Dictionary<string, string> REFLECTORS = new Dictionary<string, string>(StringComparer.OrdinalIgnoreCase)
    {
        {"B",    "YRUHQSLDPXNGOKMIEBFZCWVJAT"},
        {"C",    "FVPJIAOYEDRZXWGCTKUQSBNMHL"},
        {"B_DUNN","ENKQAUYWJICOPBLMDXZVFTHRGS"},
        {"C_DUNN","RDOBJNTKVEHMLFCWZAXGYIPSUQ"}
    };

    // --- Позиции вырезов (notches) для роторов I–VIII ---
    static readonly Dictionary<string, char> NOTCH = new Dictionary<string, char>(StringComparer.OrdinalIgnoreCase)
    {
        {"I",'Q'}, {"II",'E'}, {"III",'V'}, {"IV",'J'}, {"V",'Z'},
        {"VI",'Z'}, {"VII",'Z'}, {"VIII",'Z'},
        {"BETA", '\0'}, {"GAMMA", '\0'}
    };

    // Преобразовать строку проводки в массив индексов (0..25)
    static int[] WiringToMap(string wiring)
    {
        int[] map = new int[26];
        for (int i = 0; i < 26; i++) map[i] = ALPH.IndexOf(wiring[i]);
        return map;
    }

    // Получить обратное отображение
    static int[] InverseMap(int[] map)
    {
        int[] inv = new int[26];
        for (int i = 0; i < 26; i++) inv[map[i]] = i;
        return inv;
    }

    // Класс настроек машины
    public class Machine
    {
        public string Lrotor, Mrotor, Rrotor;   // левые, средние и правые роторы
        public string Reflector;               // отражатель
        public int ringL, ringM, ringR;        // кольцевые установки (1..26)
        public int posL, posM, posR;           // начальные позиции (0..25)
        public int stepL, stepM, stepR;        // шаги (0 = стандартное поведение)
    }

    // Индекс буквы (A=0..Z=25)
    static int CI(char ch) => ALPH.IndexOf(Char.ToUpperInvariant(ch));

    // Шифрование одного символа
    static char EncChar(char ch, Machine m,
        int[] mapL, int[] mapM, int[] mapR,
        int[] invL, int[] invM, int[] invR,
        int[] reflMap)
    {
        if (!Char.IsLetter(ch)) return ch;
        int c = CI(ch);

        bool stepRight = true;
        bool stepMiddle = false;
        bool stepLeft = false;

        if (m.stepR > 0 || m.stepM > 0 || m.stepL > 0)
        {
            m.posR = (m.posR + m.stepR) % 26;
            m.posM = (m.posM + m.stepM) % 26;
            m.posL = (m.posL + m.stepL) % 26;
        }
        else
        {
            char notchM = NOTCH.ContainsKey(m.Mrotor) ? NOTCH[m.Mrotor] : '\0';
            char notchR = NOTCH.ContainsKey(m.Rrotor) ? NOTCH[m.Rrotor] : '\0';
            if (notchM != '\0' && m.posM == CI(notchM)) { stepMiddle = true; stepLeft = true; }
            if (notchR != '\0' && m.posR == CI(notchR)) stepMiddle = true;
            stepRight = true;
            if (stepRight) m.posR = (m.posR + 1) % 26;
            if (stepMiddle) m.posM = (m.posM + 1) % 26;
            if (stepLeft) m.posL = (m.posL + 1) % 26;
        }

        int cR = (c + m.posR - (m.ringR - 1) + 26) % 26;
        int step1 = mapR[cR];
        int outR = (step1 - m.posR + (m.ringR - 1) + 26) % 26;

        int cM = (outR + m.posM - (m.ringM - 1) + 26) % 26;
        int step2 = mapM[cM];
        int outM = (step2 - m.posM + (m.ringM - 1) + 26) % 26;

        int cL = (outM + m.posL - (m.ringL - 1) + 26) % 26;
        int step3 = mapL[cL];
        int outL = (step3 - m.posL + (m.ringL - 1) + 26) % 26;

        int reflIn = (outL + 26) % 26;
        int reflOut = reflMap[reflIn];

        int inL = (reflOut + m.posL - (m.ringL - 1) + 26) % 26;
        int back1 = invL[inL];
        int outBack1 = (back1 - m.posL + (m.ringL - 1) + 26) % 26;

        int inM2 = (outBack1 + m.posM - (m.ringM - 1) + 26) % 26;
        int back2 = invM[inM2];
        int outBack2 = (back2 - m.posM + (m.ringM - 1) + 26) % 26;

        int inR2 = (outBack2 + m.posR - (m.ringR - 1) + 26) % 26;
        int back3 = invR[inR2];
        int outBack3 = (back3 - m.posR + (m.ringR - 1) + 26) % 26;

        return ALPH[outBack3];
    }

    // Построить массивы для выбранных роторов и отражателя
    static void BuildMaps(Machine m,
        out int[] mapL, out int[] mapM, out int[] mapR,
        out int[] invL, out int[] invM, out int[] invR,
        out int[] reflMap)
    {
        string wL = ROTORS[m.Lrotor];
        string wM = ROTORS[m.Mrotor];
        string wR = ROTORS[m.Rrotor];
        mapL = WiringToMap(wL);
        mapM = WiringToMap(wM);
        mapR = WiringToMap(wR);
        invL = InverseMap(mapL);
        invM = InverseMap(mapM);
        invR = InverseMap(mapR);

        string rstr = REFLECTORS[m.Reflector];
        reflMap = WiringToMap(rstr);
    }

    // Шифрование текста целиком (возвращает шифртекст и время в мс)
    public static (string ciphertext, long ms) EncryptText(string plaintext, Machine m)
    {
        BuildMaps(m, out var mapL, out var mapM, out var mapR, out var invL, out var invM, out var invR, out var refl);
        var sb = new StringBuilder();
        Stopwatch sw = Stopwatch.StartNew();
        foreach (char ch in plaintext.ToUpperInvariant())
        {
            if (!ALPH.Contains(ch)) { sb.Append(ch); continue; }
            char outc = EncChar(ch, m, mapL, mapM, mapR, invL, invM, invR, refl);
            sb.Append(outc);
        }
        sw.Stop();
        return (sb.ToString(), sw.ElapsedMilliseconds);
    }

    // Точка входа
    static void Main()
    {
        Console.OutputEncoding = Encoding.UTF8;
        var machine = new Machine
        {
            Lrotor = "III",
            Mrotor = "GAMMA",
            Rrotor = "V",
            Reflector = "C_DUNN",
            ringL = 1,
            ringM = 1,
            ringR = 1,
            posL = CI('A'),
            posM = CI('A'),
            posR = CI('A'),
            stepL = 1,
            stepM = 1,
            stepR = 2
        };

        Console.WriteLine("Введите текст (латиница A-Z).");
        Console.Write("Текст: ");
        string plain = Console.ReadLine() ?? "";

        var presets = new List<(char a, char b, char c)> {
            ('A','A','A'), ('A','B','C'), ('X','J','M'), ('Z','Z','Z'), ('M','M','M')
        };

        int i = 1;
        foreach (var p in presets)
        {
            machine.posL = CI(p.a);
            machine.posM = CI(p.b);
            machine.posR = CI(p.c);
            var (ct, ms) = EncryptText(plain, machine);
            Console.WriteLine($"\nВариант #{i}: L{machine.Lrotor}@{p.a} M{machine.Mrotor}@{p.b} R{machine.Rrotor}@{p.c} Отражатель={machine.Reflector}");
            Console.WriteLine($"Шифртекст: {ct}");
            Console.WriteLine($"Время: {ms} мс");
            var freq = ComputeFreq(ct);
            Console.WriteLine("Частоты (в %) в шифртексте:");
            foreach (var kv in freq) Console.WriteLine($"{kv.Key}:{kv.Value:F2}%");
            i++;
        }
    }

    // Частотный анализ текста (по буквам A..Z)
    static List<KeyValuePair<char, double>> ComputeFreq(string text)
    {
        var dict = new Dictionary<char, int>();
        int total = 0;
        foreach (char c in text)
        {
            if (!ALPH.Contains(c)) continue;
            if (!dict.ContainsKey(c)) dict[c] = 0;
            dict[c]++;
            total++;
        }
        return dict.OrderBy(kv => kv.Key)
                   .Select(kv => new KeyValuePair<char, double>(kv.Key, kv.Value * 100.0 / Math.Max(1, total)))
                   .ToList();
    }
}
