# moodle-lb

Ambiente Vagrant com Nginx como reverse proxy / load balancer para três instâncias Moodle 4.5.1 compartilhando um banco de dados PostgreSQL e armazenamento de arquivos via NFS.

## Topologia

| VM | IP | Papel |
|---|---|---|
| proxy | 192.168.56.10 | Nginx reverse proxy / load balancer (porta 8080 no host) |
| moodle1 | 192.168.56.20 | Instância Moodle + servidor NFS (moodledata) |
| moodle2 | 192.168.56.30 | Instância Moodle + cliente NFS |
| moodle3 | 192.168.56.40 | Instância Moodle + cliente NFS |
| db | 192.168.56.50 | PostgreSQL |

Todas as VMs usam `debian/bookworm64`. O algoritmo de balanceamento padrão é `hash $http_x_forwarded_for consistent` para o ambiente de testes (comentar/descomentar `ip_hash` em `config/nginx/proxy.conf` para alternar).

---

## Requisitos

| Ferramenta | Versão mínima |
|---|---|
| VirtualBox | 6.1+ |
| Vagrant | 2.3+ |
| GNU Make | qualquer |
| Python | 3.10+ |

**Plugins Vagrant opcionais:**
- `vagrant-cachier` - faz cache de pacotes APT entre VMs (acelera reprovisioning)

**Dependências Python** (para stress test e relatório):

```bash
pip install requests pandas matplotlib
```

---

## Configuração inicial

O arquivo `.env` está versionado de forma intencional, as credenciais são fixas e de uso exclusivo neste ambiente de laboratório. Nenhuma configuração adicional é necessária para subir o ambiente.

O Moodle estará acessível em `http://localhost:8080` após o provisionamento.

---

## Comandos Make

### Ciclo de vida

| Comando | Descrição |
|---|---|
| `make up` | Sobe todas as VMs em ordem (db → moodle1 → moodle2+3 em paralelo → proxy) |
| `make down` | Para todas as VMs (`vagrant halt`) |
| `make restart` | `down` + `up` |
| `make destroy` | Destrói todas as VMs (`vagrant destroy -f`) |
| `make provision` | Reprovision em todas as VMs na ordem correta |
| `make status` | Estado atual das VMs |

### Acesso via SSH

| Comando | VM |
|---|---|
| `make ssh-proxy` | proxy |
| `make ssh-moodle1` | moodle1 |
| `make ssh-moodle2` | moodle2 |
| `make ssh-moodle3` | moodle3 |
| `make ssh-db` | db |

### Monitoramento

| Comando | Descrição |
|---|---|
| `make lb-check` | Envia 9 requisições e exibe o header `X-Upstream-Addr` de cada uma |
| `make lb-dist` | Lê o access log do proxy e exibe a contagem por backend |
| `make logs-proxy` | `tail -f` do access log do proxy |
| `make logs-moodle1` | `tail -f` do access log do moodle1 |

### Stress test e relatório

| Comando | Descrição |
|---|---|
| `make stress` | Executa `python/stress.py` - 1000 requisições, 20 threads, salva `stress_results.csv` |
| `make report` | Executa `python/report.py` - lê o CSV e gera `grafico-barras.png` e `grafico-setores.png` |
| `make benchmark` | `stress` + `report` em sequência |

---

## Comandos Vagrant úteis

```bash
# Subir VM específica
vagrant up moodle2

# Reprovisionar VM específica
vagrant provision proxy

# SSH direto (equivalente ao make ssh-*)
vagrant ssh moodle1

# Snapshot (antes de testes destrutivos)
vagrant snapshot save moodle1 pre-test
vagrant snapshot restore moodle1 pre-test

# Ver logs de boot
vagrant up proxy --debug 2>&1 | tail -50
```

---

## Testes via curl

### Pré-testes: verificar que as VMs estão respondendo

```bash
# Proxy acessível na porta 8080 do host
curl -I http://localhost:8080

# Acesso direto às instâncias - apenas do proxy (porta 80 restrita por firewall)
make ssh-proxy
curl -I http://192.168.56.20
curl -I http://192.168.56.30
curl -I http://192.168.56.40

# PostgreSQL respondendo
vagrant ssh db -c "pg_isready -U moodle -d moodle"

# NFS montado nos clientes
vagrant ssh moodle2 -c "df -h | grep moodledata"
vagrant ssh moodle3 -c "df -h | grep moodledata"

# Status do Nginx no proxy (apenas da rede interna)
make ssh-proxy
curl -s http://192.168.56.10/nginx_status
```

### Verificar isolamento das instâncias

```bash
# Do host - deve falhar (DROP na porta 80)
curl -m 3 http://192.168.56.20
curl -m 3 http://192.168.56.30
curl -m 3 http://192.168.56.40

# Pelo proxy - deve funcionar
make ssh-proxy
curl -si http://192.168.56.20 | head -1
```

### Testes de load balancing


```bash
# Ver qual backend atendeu cada requisição
curl -si http://localhost:8080 | grep -i x-upstream-addr

# Verificar distribuição com 9 requisições (mesmo que make lb-check)
for i in {1..9}; do curl -si http://localhost:8080 | grep -i x-upstream-addr; done

# Simular IPs distintos (verifica o hash por X-Forwarded-For)
curl -s -H "X-Forwarded-For: 10.0.0.1" http://localhost:8080 -o /dev/null -w "%{http_code}\n"
curl -s -H "X-Forwarded-For: 10.0.0.2" http://localhost:8080 -o /dev/null -w "%{http_code}\n"
curl -s -H "X-Forwarded-For: 10.0.0.3" http://localhost:8080 -o /dev/null -w "%{http_code}\n"

# Verificar afinidade: mesmo IP deve ir sempre para o mesmo backend
for i in {1..5}; do
  curl -si -H "X-Forwarded-For: 10.42.42.42" http://localhost:8080 | grep -i x-upstream-addr
done

# Checar headers de resposta completos
curl -si http://localhost:8080 | grep -E "HTTP|X-Upstream|X-Forwarded"
```

### Teste de failover

```bash
# Parar uma instância e verificar que o proxy redireciona para as demais
vagrant halt moodle2

make
```
