#!/usr/bin/env python3

import csv
import random
import ipaddress
import requests
from concurrent.futures import ThreadPoolExecutor

PROXY = "http://192.168.56.10"

TOTAL_REQUESTS = 1000
THREADS = 20

OUTPUT_FILE = "stress_results.csv"


def random_ip():
    net = ipaddress.ip_network("10.0.0.0/8")
    host = random.randint(1, net.num_addresses - 2)
    return str(net.network_address + host)


def make_request(_):
    ip = random_ip()

    try:
        response = requests.get(
            PROXY,
            headers={
                "X-Forwarded-For": ip
            },
            timeout=5
        )

        backend = response.headers.get(
            "X-Upstream-Addr",
            "UNKNOWN"
        )

        return [
            ip,
            backend,
            response.status_code
        ]

    except Exception:
        return [
            ip,
            "ERROR",
            0
        ]


def main():
    print(f"Executando {TOTAL_REQUESTS} requisições...")

    with ThreadPoolExecutor(max_workers=THREADS) as pool:
        results = list(
            pool.map(make_request, range(TOTAL_REQUESTS))
        )

    with open(
        OUTPUT_FILE,
        "w",
        newline="",
        encoding="utf-8"
    ) as f:

        writer = csv.writer(f)

        writer.writerow([
            "ip",
            "backend",
            "status"
        ])

        writer.writerows(results)

    print(f"CSV salvo em {OUTPUT_FILE}")


if __name__ == "__main__":
    main()