FROM frappe/erpnext:v13

COPY abn_docker/sites /home/frappe/frappe-bench/sites

WORKDIR /home/frappe/frappe-bench

RUN chown -R frappe:frappe /home/frappe

EXPOSE 8000 8080 9000

CMD ["nginx-entrypoint.sh"]
