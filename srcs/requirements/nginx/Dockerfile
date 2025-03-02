FROM debian:bullseye

RUN apt-get update && apt-get install -y nginx

COPY conf/nginx.conf /etc/nginx/nginx.conf

COPY tools/pgomez-r.42.fr.crt /etc/nginx/ssl/pgomez-r.42.fr.crt

COPY tools/pgomez-r.42.fr.key /etc/nginx/ssl/pgomez-r.42.fr.key

EXPOSE 443

CMD ["nginx", "-g", "daemon off;"]

# TODO: show something rather than error in localhost:443
# TODO: when fixed, update guide!