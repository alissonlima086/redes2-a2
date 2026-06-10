.PHONY: up down restart destroy provision status \
        ssh-proxy ssh-moodle1 ssh-moodle2 ssh-moodle3 ssh-db \
        lb-check logs-proxy logs-moodle1 lb-dist \
        stress stress-heavy dashboard test


PYTHON_DIR := python
PYTHON := python3

up:
	vagrant up db
	vagrant up moodle1
	vagrant up moodle2 moodle3 --parallel
	vagrant up proxy

down:
	vagrant halt

restart:
	vagrant halt
	$(MAKE) up

destroy:
	vagrant destroy -f

provision:
	vagrant provision db
	vagrant provision moodle1
	vagrant provision moodle2 moodle3
	vagrant provision proxy

status:
	vagrant status

ssh-proxy:
	vagrant ssh proxy

ssh-moodle1:
	vagrant ssh moodle1

ssh-moodle2:
	vagrant ssh moodle2

ssh-moodle3:
	vagrant ssh moodle3

ssh-db:
	vagrant ssh db

lb-check:
	@echo "Verificando load balance (9 requisicoes)..."
	@for i in 1 2 3 4 5 6 7 8 9; do \
		curl -si http://localhost:8080 | grep -i x-upstream-addr; \
	done

lb-dist:
	@echo "Distribuicao nos logs do proxy:"
	vagrant ssh proxy -c "sudo awk '{print \$$8}' /var/log/nginx/proxy_access.log | sort | uniq -c | sort -rn"

logs-proxy:
	vagrant ssh proxy -c "sudo tail -f /var/log/nginx/proxy_access.log"

logs-moodle1:
	vagrant ssh moodle1 -c "sudo tail -f /var/log/nginx/access.log"

stress:
	cd $(PYTHON_DIR) && $(PYTHON) stress.py

report:
	cd $(PYTHON_DIR) && $(PYTHON) report.py

benchmark:
	cd $(PYTHON_DIR) && $(PYTHON) stress.py && $(PYTHON) report.py