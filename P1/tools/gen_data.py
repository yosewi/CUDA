"""Generator danych testowych dla KMeans (pliki txt i bin z tymi samymi punktami).

Uzycie:
    python3 tools/gen_data.py N d k nazwa
Tworzy nazwa.txt i nazwa.bin. Punkty sa skupione wokol k losowych srodkow,
wiec k-means ma co znajdowac.

Przyklad:
    python3 tools/gen_data.py 1000000 3 5 data/test1m
"""
import random
import struct
import sys

if len(sys.argv) != 5:
    print(__doc__)
    sys.exit(1)

N, d, k = int(sys.argv[1]), int(sys.argv[2]), int(sys.argv[3])
name = sys.argv[4]
random.seed(2026)  # zawsze te same dane dla tych samych parametrow

centers = [[random.uniform(-100, 100) for _ in range(d)] for _ in range(k)]

with open(name + ".txt", "w") as txt, open(name + ".bin", "wb") as bin_file:
    txt.write(f"{N} {d} {k}\n")
    bin_file.write(struct.pack("<3i", N, d, k))          # 3 x int (4 B)
    for _ in range(N):
        c = centers[random.randrange(k)]
        point = [round(random.gauss(x, 10.0), 6) for x in c]
        txt.write(" ".join(f"{x:.6f}" for x in point) + "\n")
        bin_file.write(struct.pack(f"<{d}d", *point))    # d x double (8 B)

print(f"Zapisano {name}.txt i {name}.bin (N={N}, d={d}, k={k})")