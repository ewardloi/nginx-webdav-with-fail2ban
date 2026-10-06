FROM debian:bookworm-slim

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y --no-install-recommends \
        nginx-extras \
        fail2ban \
        apache2-utils \
        supervisor \
        gettext-base \
        util-linux \
        procps \
    && rm -rf /var/lib/apt/lists/* \
    && rm -f /etc/nginx/sites-enabled/default /etc/nginx/sites-available/default \
    && rm -f /etc/fail2ban/jail.d/defaults-debian.conf

COPY nginx.conf /etc/nginx/nginx.conf.template
COPY conf.d/webdav.conf /etc/nginx/conf.d/webdav.conf
COPY conf.d/banned_ips.conf /etc/nginx/conf.d/banned_ips.conf

COPY fail2ban/jail.local /etc/fail2ban/jail.local
COPY fail2ban/nginx-deny.conf /etc/fail2ban/action.d/nginx-deny.conf

COPY scripts/nginx-ban.sh /usr/local/bin/nginx-ban.sh
RUN chmod +x /usr/local/bin/nginx-ban.sh

COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

RUN mkdir -p /data /var/log/nginx /var/log/fail2ban /run/fail2ban /tmp/nginx_dav_temp /tmp/nginx_client_temp \
    && touch /var/log/nginx/access.log /var/log/nginx/error.log

EXPOSE 8080

ENTRYPOINT ["/entrypoint.sh"]
CMD ["/usr/bin/supervisord", "-n", "-c", "/etc/supervisor/conf.d/supervisord.conf"]
