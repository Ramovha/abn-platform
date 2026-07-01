FROM frappe/erpnext:v13

COPY --chown=frappe:frappe abn_docker/sites /home/frappe/frappe-bench/sites
COPY entrypoint.sh /entrypoint.sh

WORKDIR /home/frappe/frappe-bench

RUN chmod +x /entrypoint.sh

EXPOSE 8000 8080 9000

ENTRYPOINT ["/entrypoint.sh"]
