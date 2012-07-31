#!/bin/bash

# Don't allow unset variables to be used
set -o nounset

# Exit upon any non-zero return code
set -o errexit

# only run with no arguments
init() {
    
    APT="apt-get -y --quiet"
    
    sudo $APT install htop
    sudo $APT install postgresql-9.1
    sudo $APT install postgresql-9.1-postgis
    sudo $APT install solr-jetty
    sudo $APT install openjdk-6-jre
    sudo $APT install openjdk-6-jdk
    sudo $APT install ufw
    sudo $APT install pgtune
    
    sudo sed -i 's/#JAVA_HOME=/JAVA_HOME=\/usr\/lib\/jvm\/java-1.6.0-openjdk-amd64\//g' /etc/default/jetty
    sudo sed -i 's/#JETTY_PORT=8080/JETTY_PORT=8983/g' /etc/default/jetty
    sudo sed -i 's/#JETTY_HOST.*/JETTY_HOST=0.0.0.0/g' /etc/default/jetty
    sudo sed -i 's/NO_START=1/NO_START=0/g' /etc/default/jetty
    
    sudo sed -i 's/^#kernel\.shmmax =.*/kernel.shmmax = 1143210240/' /etc/sysctl.d/30-postgresql-shm.conf
    
    sudo sysctl -p /etc/sysctl.d/30-postgresql-shm.conf
    
    sudo mv /etc/solr/conf/schema.xml /etc/solr/conf/schema.xml.bak
    
    sudo cp /etc/postgresql/9.1/main/postgresql.conf  /etc/postgresql/9.1/main/postgresql.conf.bak
    sudo pgtune -i /etc/postgresql/9.1/main/postgresql.conf -o /etc/postgresql/9.1/main/postgresql.conf
    
    sudo sed -i "s/^#listen_addresses =.*/listen_addresses = '*'/" /etc/postgresql/9.1/main/postgresql.conf
    
    wget https://raw.github.com/okfn/ckan/master/ckan/config/solr/schema-1.4.xml
    
    sudo cp schema-1.4.xml /etc/solr/conf/schema.xml
    rm schema-1.4.xml
    
    sudo service jetty restart
    
    if sudo grep -q "samenet md5" /etc/postgresql/9.1/main/pg_hba.conf
    then
       echo "samenet was found in /etc/postgresql/9.1/main/pg_hba.conf"
    else
       echo "host all all samenet md5" | sudo tee -a /etc/postgresql/9.1/main/pg_hba.conf
    fi
    
    sudo service postgresql restart

    echo 'Setting up default firewall configuration...'
    sudo ufw default deny
    sudo ufw allow openssh
    sudo ufw enable
    echo 'Done setting up default firewall configuration.'

    return 0
}


randpass() {
    CHAR="[:alnum:]" || CHAR="[:graph:]"
    cat /dev/urandom | tr -cd "$CHAR" | head -c ${1:-32} | base64
    echo
}

createdb() {
    local PASSWORD
    local DB_NAME
    DB_NAME=$1

    # Check if the database already exists.
    COMMAND_OUTPUT=`sudo -u postgres psql -c "SELECT datname FROM pg_database WHERE datname='${DB_NAME}'"`
    if [[ "$COMMAND_OUTPUT" =~ ${DB_NAME} ]] ; then
	echo "ERROR: Database \"${DB_NAME}\" already exists.  Aborting."
	return 1
    fi

    # Check if the user already exists.
    COMMAND_OUTPUT=`sudo -u postgres psql -c "SELECT 'True' FROM pg_user WHERE usename='${DB_NAME}'"`
    if [[ "$COMMAND_OUTPUT" =~ True ]] ; then
        echo "ERROR: User \"${DB_NAME}\" already exists.  Aborting."
	return 1
    fi

    PASSWORD=`randpass`
    echo "Suggested password is:"
    echo $PASSWORD
    sudo -u postgres createuser -DRSP $DB_NAME
    sudo -u postgres createdb -O $DB_NAME $DB_NAME

    return 0
}

PG_PORT="5432"
SOLR_PORT="8983"

addweb() {
    local IP_ADDRESS
    IP_ADDRESS=$1

   sudo ufw allow in on eth1 proto tcp from "$IP_ADDRESS" to any port "$PG_PORT"
   sudo ufw allow in on eth1 proto tcp from "$IP_ADDRESS" to any port "$SOLR_PORT"

   return 0
}

removeweb() {
    local IP_ADDRESS
    IP_ADDRESS=$1

   sudo ufw delete allow in on eth1 proto tcp from "$IP_ADDRESS" to any port "$PG_PORT"
   sudo ufw delete allow in on eth1 proto tcp from "$IP_ADDRESS" to any port "$SOLR_PORT"

   return 0
}

case ${1-} in
    init) init ;;
    createdb) createdb $2 ;;
    dropdb) dropdb ;;
    listdb) listdb ;;
    addweb) addweb $2 ;;
    removeweb) removeweb $2 ;;
    listweb) listweb ;;
    *) echo "

Commands are:
init # Install and configure database services: postgres and solr
createdb 'dbname' # createdb and user
drobdb 'dbname' # drop db and user
addweb ipaddress # allow firewall to connect to webserver
removeweb ipaddress # stop filerewall from connecting to webserver
"

esac


#sudo ufw default deny
#sudo ufw allow OpenSSH

# Setup firewall
#LOCAL_PRIVATE_IP=`/sbin/ifconfig eth1 | grep 'inet addr:' | cut -d: -f2 | awk '{ print $1}'`
#WEB_SERVER_IPS=TODO
#sudo ufw allow proto tcp from 10.181.160.49 to 10.176.32.42 port 9200
#cat ${WEB_SERVER_IPS} | cut -f1,1 | xargs -n 1 -I sudo ufw allow proto tcp from {} to ${LOCAL_PRIVATE_IP} port 5432
#
#
#sudo ufw allow in on eth1 proto tcp from 10.181.160.49 to any port 5432



