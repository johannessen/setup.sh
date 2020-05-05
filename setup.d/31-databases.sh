#!bash


### Set up databases

MYSQL_ROOT_PASSWORD=${MYSQL_ROOT_PASSWORD:-`setup_insecure_password mysql-root`}
MYSQL_BACKUP_PASSWORD=${MYSQL_BACKUP_PASSWORD:-`setup_insecure_password mysql-backup`}
MYSQL_POSTFIX_PASSWORD=${MYSQL_POSTFIX_PASSWORD:-`setup_insecure_password mysql-postfix`}

# MySQL
# local access is provided to root via socket connection
# for remote access (SSH only), a rootssh user is added
mysqladmin flush-privileges
#SET PASSWORD FOR 'root'@'localhost' = PASSWORD('$MYSQL_ROOT_PASSWORD');
##SET PASSWORD FOR 'root'@'127.0.0.1' = PASSWORD('$MYSQL_ROOT_PASSWORD');
##SET PASSWORD FOR 'root'@'::1' = PASSWORD('$MYSQL_ROOT_PASSWORD');
#DELETE FROM user WHERE user = 'root' AND password = '';
mysql mysql --user=root <<EOF
CREATE USER 'rootssh'@'127.0.0.1' IDENTIFIED BY '$MYSQL_ROOT_PASSWORD';
GRANT ALL PRIVILEGES ON *.* TO 'rootssh'@'127.0.0.1' WITH GRANT OPTION;
FLUSH PRIVILEGES;
EOF

#setup_copy /root/.my.cnf 600
#sed -e "/^password = .*/s//password = \"$MYSQL_ROOT_PASSWORD\"/" -i /root/.my.cnf

mysql mysql --user=root <<EOF
CREATE USER 'backup'@'localhost' IDENTIFIED BY '$MYSQL_BACKUP_PASSWORD';
GRANT SELECT, SHOW DATABASES, LOCK TABLES ON *.* TO 'backup'@'localhost';
CREATE USER 'postfix'@'127.0.0.1' IDENTIFIED BY '$MYSQL_POSTFIX_PASSWORD';
GRANT SELECT ON postfix.* TO 'postfix'@'127.0.0.1';
FLUSH PRIVILEGES;
EOF

