FROM frappe/erpnext:v13

COPY --chown=frappe:frappe abn_docker/sites /home/frappe/frappe-bench/sites
COPY --chown=frappe:frappe entrypoint.sh /entrypoint.sh

WORKDIR /home/frappe/frappe-bench

EXPOSE 8000 8080 9000

ENTRYPOINT ["/entrypoint.sh"]
