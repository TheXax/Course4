import argparse
import json
import math
import random
import statistics
import time
from dataclasses import dataclass, asdict
from pathlib import Path
from typing import List, Dict

import matplotlib.pyplot as plt

@dataclass #храним данные как объекты
class RunResult:
    a: int
    n_bits: int
    n_hex_prefix: str
    x_value: int
    x_log10: float
    trials: int
    times_ms: List[float]
    time_ms_avg: float
    time_ms_median: float
    time_ms_min: float
    time_ms_max: float

def gen_random_n(bits: int) -> int:
    #Сгенерировать нечётное n заданной битности (не обязательно простое).
    assert bits >= 8
    n = random.getrandbits(bits)
    # Установим старший бит, сделаем нечётным
    n |= (1 << (bits - 1))
    if n % 2 == 0:
        n += 1
    return n

def measure_pow(a: int, x: int, n: int, trials: int = 5) -> List[float]:
    #Замер времени pow(a, x, n) в миллисекундах, несколько прогонов.
    times = []
    for _ in range(trials):
        t0 = time.perf_counter_ns()
        _ = pow(a, x, n) #быстрое модульное возведение через алгоритм повторного возведения в квадрат
        t1 = time.perf_counter_ns()
        times.append((t1 - t0) / 1e6)
    return times

def main():
    parser = argparse.ArgumentParser(description="Бенчмарк y ≡ a^x mod n")
    parser.add_argument("--a", type=int, nargs="+", default=[5, 17], help="Значения a (десятичные)")
    parser.add_argument("--x-mode", choices=["preset"], default="preset",
                        help="Режим выбора x. Сейчас доступен только preset (равномерно по лог-шкале от 1e3 до 1e100).")
    parser.add_argument("--trials", type=int, default=5, help="Количество повторов каждого замера")
    parser.add_argument("--out", type=str, default="modexp_results", help="Базовое имя выходных файлов")
    args = parser.parse_args()

    #Равномерно по log10 из диапазона [1e3, 1e100]
    x_values = [int(10**p) for p in [3, 5, 7, 9, 20, 40, 60, 80, 100]]
    n_bit_options = [1024, 2048]

    random.seed(42)
    results: List[RunResult] = []

    for n_bits in n_bit_options:
        n = gen_random_n(n_bits)
        n_hex_prefix = hex(n)[:18] + "..."
        for a in args.a:
            for x in x_values:
                times = measure_pow(a, x, n, trials=args.trials)
                rr = RunResult(
                    a=a,
                    n_bits=n_bits,
                    n_hex_prefix=n_hex_prefix,
                    x_value=x,
                    x_log10=math.log10(x),
                    trials=args.trials,
                    times_ms=times,
                    time_ms_avg=statistics.fmean(times),
                    time_ms_median=statistics.median(times),
                    time_ms_min=min(times),
                    time_ms_max=max(times),
                )
                results.append(rr)

    out_base = Path(args.out)
    out_base_json = out_base.with_suffix(".json")
    out_base_csv = out_base.with_suffix(".csv")
    out_base_png = out_base.with_suffix(".png")

    # JSON
    with open(out_base_json, "w", encoding="utf-8") as f:
        json.dump([asdict(r) for r in results], f, ensure_ascii=False, indent=2)

    # CSV
    import csv
    with open(out_base_csv, "w", newline="", encoding="utf-8") as f:
        w = csv.writer(f, delimiter=";")
        w.writerow(["a", "n_bits", "x_value", "x_log10", "trials", "time_ms_avg", "time_ms_median", "time_ms_min", "time_ms_max", "n_hex_prefix"])
        for r in results:
            w.writerow([r.a, r.n_bits, r.x_value, f"{r.x_log10:.2f}", r.trials,
                        f"{r.time_ms_avg:.3f}", f"{r.time_ms_median:.3f}", f"{r.time_ms_min:.3f}", f"{r.time_ms_max:.3f}",
                        r.n_hex_prefix])

    # График: по оси X — log10(x), по оси Y — median time; раздельные линии для каждой пары (a, n_bits)
    # Правило: один график, без сабплотов, без указания цветов.
    series: Dict[tuple, List[RunResult]] = {}
    for r in results:
        key = (r.a, r.n_bits)
        series.setdefault(key, []).append(r)

    plt.figure()
    for key, items in series.items():
        items_sorted = sorted(items, key=lambda z: z.x_log10)
        xs = [it.x_log10 for it in items_sorted]
        ys = [it.time_ms_median for it in items_sorted]
        label = f"a={key[0]}, n_bits={key[1]}"
        plt.plot(xs, ys, marker="o", label=label)
    plt.xlabel("log10(x)")
    plt.ylabel("Время, мс (median)")
    plt.title("Время вычисления y ≡ a^x mod n (pow)")
    plt.legend()
    plt.grid(True)
    plt.tight_layout()
    plt.savefig(out_base_png, dpi=160)

    print(f"Готово:\n JSON: {out_base_json}\n CSV:  {out_base_csv}\n PNG:  {out_base_png}")

if __name__ == "__main__":
    main()
