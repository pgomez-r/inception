# OS base image
FROM debian:bullseye

# Install nginx package, plus openssl and ca-certificates so we can read/use our .crt and .key
RUN apt-get update && apt-get install -y nginx openssl ca-certificates

# Set nginx configuration by copying our own .conf file in default configuration directory
COPY conf/nginx.conf /etc/nginx/sites-available/default

# Copy our certificates into nginx ssl certificates directory
# Alternative: create the certificates at the very moment of building the image, by running the commands to do so
COPY tools/pgomez-r.42.fr.crt /etc/nginx/ssl/pgomez-r.42.fr.crt
COPY tools/pgomez-r.42.fr.key /etc/nginx/ssl/pgomez-r.42.fr.key

# Copy a basic index.html in the index directory used by our config, so we can test if the server is workig
# We will change this later, when wordpress is set and working
COPY index.html /var/www/html/index.html

EXPOSE 443

# CMD to be executed when docker-compose, to run nginx without daemon "mode"
CMD ["nginx", "-g", "daemon off;"]
