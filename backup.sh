#!/bin/bash

# This folder
T_FOLDER="/root"

# Remote folder
R_FOLDER="/server.com"

# Sites dir
SITES_DIR="/var/www"

# MySQL settings
USER="root"
PASSWORD="mysqlpassword"
MYSQLDUMP="/usr/bin/mysqldump"
MYSQL="/usr/bin/mysql"

# MySQL databases
databases=`$MYSQL --user=$USER --password=$PASSWORD -e "SHOW DATABASES;" |\
grep -Ev "(Database|information_schema)" |\
grep -Ev "(Database|performance_schema)" |\
grep -Ev "(Database|mysql)"`

# For each db
for db in $databases; do
    $MYSQLDUMP --force --opt --lock-tables=false --user=$USER --password=$PASSWORD \
    --databases $db | gzip > "$db.sql.gz"

    # Upload to Dropbox
    /bin/bash $T_FOLDER/dropbox_uploader.sh upload $db.sql.gz $R_FOLDER/mysql/

    # Remove temp backup
    /bin/rm -f $T_FOLDER/$db.sql.gz
done

## Files backup
for i in `ls $SITES_DIR`; do
    tar czf $i.tar.gz --exclude-vcs $SITES_DIR/$i

    # Upload to Dropbox
    /bin/bash $T_FOLDER/dropbox_uploader.sh upload $i.tar.gz $R_FOLDER/www/

    # Remove temp backup
    /bin/rm -f $T_FOLDER/$i.tar.gz
done

## Conf backup
tar czf etc.tar.gz /etc
/bin/bash $T_FOLDER/dropbox_uploader.sh upload etc.tar.gz $R_FOLDER/
/bin/rm -f $T_FOLDER/etc.tar.gz

## Logs backup
tar czf log.tar.gz /var/log
/bin/bash $T_FOLDER/dropbox_uploader.sh upload log.tar.gz $R_FOLDER/
/bin/rm -f $T_FOLDER/log.tar.gz

# Remove users log
rm /var/www/*/logs/*.log

# Start new logs
service nginx reload
service apache2 reload
