FROM alpine:3.18

RUN apk update && apk add --no-cache nginx openssl

RUN adduser -D -H -s /sbin/nologin nginx 2>/dev/null || true

RUN mkdir -p /etc/nginx/ssl

RUN openssl req -x509 -nodes -out /etc/nginx/ssl/inception.crt -keyout /etc/nginx/ssl/inception.key -subj "/C=FR/ST=IDF/L=Paris/O=42/OU=42/CN=hauchida.42.fr/UID=hauchida"

RUN mkdir -p /var/run/nginx

COPY conf/nginx.conf /etc/nginx/nginx.conf

EXPOSE 443

CMD ["nginx", "-g", "daemon off;"]