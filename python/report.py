#!/usr/bin/env python3

import pandas as pd
import matplotlib.pyplot as plt

CSV_FILE = "stress_results.csv"

df = pd.read_csv(CSV_FILE)

df = df[df["backend"] != "ERROR"]

print()
print("=" * 50)
print("RESULTADOS")
print("=" * 50)

print()

print(df["backend"].value_counts())

print()

total = len(df)

print(f"Total de requisições: {total}")

print()

# Afinidade do ip_hash

violacoes = 0

mapping = {}

for _, row in df.iterrows():

    ip = row["ip"]
    backend = row["backend"]

    if ip not in mapping:
        mapping[ip] = backend

    elif mapping[ip] != backend:
        violacoes += 1

print(f"IPs únicos: {len(mapping)}")
print(f"Mudanças de backend: {violacoes}")

if violacoes == 0:
    print("ip_hash funcionando")
else:
    print("ip_hash inconsistente")

# Gráfico em barrras

backend_counts = df["backend"].value_counts()

plt.figure(figsize=(8, 5))

backend_counts.plot(kind="bar")

plt.title("Distribuição por Backend")
plt.ylabel("Requisições")

plt.tight_layout()

plt.savefig("grafico-barras.png")

plt.close()

# Gráfico de setores

plt.figure(figsize=(7, 7))

backend_counts.plot(
    kind="pie",
    autopct="%1.1f%%"
)

plt.ylabel("")

plt.title("Distribuição por Backend")

plt.tight_layout()

plt.savefig("grafico-setores.png")

plt.close()

print()
print("Arquivos gerados:")
print(" - backend_bar.png")
print(" - backend_pie.png")