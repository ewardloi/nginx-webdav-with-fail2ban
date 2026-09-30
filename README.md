# NGINX WebDAV with Fail2Ban

This project runs a container with NGINX, WebDAV enabled, basic authentication, and brute-force protection via Fail2Ban. Data is stored in a directory mounted into the container, and web access is provided through HTTP Basic Auth.

## Features

- WebDAV access to the /data directory
- Support for PUT, DELETE, MKCOL, COPY, MOVE, PROPFIND, and OPTIONS methods
- Basic authentication via .htpasswd
- IP blocking through Fail2Ban based on failed HTTP authentication attempts
- Simple setup using docker-compose

## Project structure

- docker-compose.yaml — container startup
- src/Dockerfile — image build
- src/entrypoint.sh — creates .htpasswd and validates configuration
- src/nginx.conf — base NGINX configuration
- src/conf.d/webdav.conf — WebDAV server configuration
- src/fail2ban/jail.local — Fail2Ban rules
- src/scripts/nginx-ban.sh — add/remove blocked IPs

## Quick start

There are two supported ways to configure credentials.

### Option 1: Create credentials from environment variables

1. Open docker-compose.yaml and set your username and password:

   ```yaml
   environment:
     TRUSTED_PROXY_CIDR: "10.10.1.0/24"
     WEBDAV_USER: username
     WEBDAV_PASSWORD: password
   ```

2. Make sure the mounted directory exists and is accessible:

   ```bash
   mkdir -p /mnt/storage
   ```

3. Start the container:

   ```bash
   docker compose up --build -d
   ```

4. WebDAV will be available at:

   ```text
   http://localhost:10007/
   ```

5. Use the username and password specified in WEBDAV_USER and WEBDAV_PASSWORD to log in.

### Option 2: Pre-create a .htpasswd file and mount it manually

If you do not want to use environment variables, create the file before starting the container. The entrypoint checks whether /etc/nginx/.htpasswd already exists and will not overwrite it.

Create a file named `.htpasswd` on the host machine:

```bash
mkdir -p ./config
printf "username:$(openssl passwd -apr1 'your_password')\n" > ./config/.htpasswd
```

Then mount it into the container in docker-compose.yaml:

```yaml
services:
  webdav:
    build: ./src
    container_name: webdav
    restart: unless-stopped
    ports:
      - "10007:8080"
    volumes:
      - /mnt/storage:/data
      - ./config/.htpasswd:/etc/nginx/.htpasswd:ro
    environment:
      TRUSTED_PROXY_CIDR: "10.10.1.0/24"
```

After that, start the container:

```bash
docker compose up --build -d
```

You can replace `username` and `your_password` with your own values.

## Environment variables

### TRUSTED_PROXY_CIDR

CIDR range of trusted proxies. Used for correct X-Real-IP handling. By default, the entrypoint sets 172.16.0.0/12.

### WEBDAV_USER / WEBDAV_PASSWORD

These are used to create the /etc/nginx/.htpasswd file automatically when the container starts.

If a ready-made .htpasswd file is already mounted into the container, the environment variables are not required.

> Important: when using a pre-created .htpasswd file, do not set WEBDAV_USER and WEBDAV_PASSWORD unless you want the container to create a new one only if the file is absent. The current entrypoint logic only creates a file when /etc/nginx/.htpasswd does not exist.

## Data mount point

The following is used in docker-compose.yaml:

```yaml
volumes:
  - /mnt/storage:/data
```

This means the contents of /mnt/storage are exposed in WebDAV as /data inside the container.

## Fail2Ban

The container is configured to block IPs after several failed HTTP Basic Auth attempts.

Key settings in src/fail2ban/jail.local:

- maxretry = 5
- findtime = 10m
- bantime = 1h

To check the status:

```bash
docker exec -it webdav fail2ban-client status
```

To manually add an IP to the blacklist:

```bash
docker exec -it webdav nginx-ban.sh add 203.0.113.10
```

To remove it:

```bash
docker exec -it webdav nginx-ban.sh del 203.0.113.10
```

## Security notes

- Be sure to change WEBDAV_USER and WEBDAV_PASSWORD before exposing the container publicly.
- Do not expose WebDAV publicly without TLS and network restrictions.
- If you are using a reverse proxy, you can enable X-Real-IP support through TRUSTED_PROXY_CIDR.
- Port 10007 on the host is forwarded to port 8080 inside the container.

## Stop and cleanup

```bash
docker compose down
```

If you want to remove the container along with its volumes and created resources, use:

```bash
docker compose down -v
```
