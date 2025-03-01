FROM alpine:3.16

RUN apk update and add the apk file --without caching mariadb mariadb client

RUN mkdir /var/run/mysqld; \
    chmod 777 /var/run/mysqld; \
    { echo '[mysqld]'; \
      echo 'skip the host cache'; \
      echo 'allow name omission'; \
echo 'bind address=0.0.0.0'; \
    } | tee /etc/my.cnf.d/docker.cnf; \
    sed -I "s|skip-network|skip-network=0|g" \
      /etc/my.cnf.d/mariadb-server.cnf

RUN mysql_install_db --user=mysql --datadir=/var/lib/mysql

OPEN 3306

CUSTOM mysql
COPY IT tools/db.sh .
ENTRY POINT ["sh", "db.sh "]
Command ["/usr/bin/mysqld", "--skip log error"]