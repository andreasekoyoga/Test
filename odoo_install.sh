#!/bin/bash
################################################################################
# Script for prepare install Odoo V10 on Ubuntu 16.04
# Author: Andreas
# Copyright: Modified from Original Script Yenthe Van Ginneken
#-------------------------------------------------------------------------------
# This script will install prequisite Odoo on your Ubuntu 14.04 server.
#-------------------------------------------------------------------------------
# sudo chmod +x odoo-install.sh
# Execute the script to install Odoo:
# ./odoo-install
# PARAM1 = USER_ODOO
# PARAM2 = PORT
# PARAM3 = USER_ODOO
# PARAM4 = USER_ODOO
################################################################################


ODOO_ROOT="/opt/odoo"
ODOO_PROD_ADDONS="/project/prod-addons"
ODOO_GROUP="odoo"

ODOO_INIT="False"
ODOO_USER="odoo"
ODOO_PORT="8069"

ODOO_VERSION="10.0"

INSTALL_WKHTMLTOPDF="False"
IS_ENTERPRISE="False"

ODOO_SUPERADMIN="4dm1n!123"

###  WKHTMLTOPDF download links
## === Ubuntu Trusty x64 & x32 === (for other distributions please replace these two links,
## in order to have correct version of wkhtmltox installed, for a danger note refer to 
## https://www.odoo.com/documentation/8.0/setup/install.html#deb ):

WKHTMLTOX_X64=http://download.gna.org/wkhtmltopdf/0.12/0.12.1/wkhtmltox-0.12.1_linux-trusty-amd64.deb
WKHTMLTOX_X32=http://download.gna.org/wkhtmltopdf/0.12/0.12.1/wkhtmltox-0.12.1_linux-trusty-i386.deb

getopt --test > /dev/null
if [[ $? -ne 4 ]]; then
    echo "I’m sorry, `getopt --test` failed in this environment."
    exit 1
fi

SHORT=ieu:p:s:v:
LONG=init,enterprise,user:,port:,super:,version:

# -temporarily store output to be able to check for errors
# -activate advanced mode getopt quoting e.g. via “--options”
# -pass arguments only via   -- "$@"   to separate them correctly
PARSED=`getopt --options $SHORT --longoptions $LONG --name "$0" -- "$@"`
if [[ $? -ne 0 ]]; then
    # e.g. $? == 1
    #  then getopt has complained about wrong arguments to stdout
    exit 2
fi
# use eval with "$PARSED" to properly handle the quoting
eval set -- "$PARSED"

# now enjoy the options in order and nicely split until we see --
while true; do
    case "$1" in
        -i|--init)
            ODOO_INIT="True"
            shift
            ;;
        -e|--enterprise)
            IS_ENTERPRISE="True"
            shift
            ;;
        -u|--user)
            ODOO_USER="$2"
            shift 2
            ;;
        -p|--port)
            ODOO_PORT="$2"
            shift 2
            ;;
        -s|--super)
            ODOO_SUPERADMIN="$2"
            shift 2
            ;;
        -v|--version)
            ODOO_VERSION="$2"
            shift 2
            ;;
        --)
            shift
            break
            ;;
        *)
            echo "Programming error"
            exit 3
            ;;
    esac
done


ODOO_HOME="${ODOO_ROOT}/$ODOO_USER"
ODOO_HOME_SRV="$ODOO_HOME/server"
ODOO_HOME_LOG="$ODOO_HOME/log"
ODOO_HOME_CONF="$ODOO_HOME/config"
ODOO_CONFIG="${ODOO_USER}-server"

CUSTOM_ADDONS_PATH="$ODOO_HOME/apps-addons"

echo "init: $ODOO_INIT, user: $ODOO_USER, port: $ODOO_PORT, sp: $ODOO_SUPERADMIN, version: $ODOO_VERSION"

#--------------------------------------------------
# Update Server
#--------------------------------------------------
if [ $ODOO_INIT = "True" ]; then
	echo -e "\n---- Update Server ----"
	sudo apt-get update
	sudo apt-get upgrade -y
#--------------------------------------------------
# Install PostgreSQL Server
#--------------------------------------------------
	echo -e "\n---- Install PostgreSQL Server ----"
	sudo apt-get install postgresql -y

#--------------------------------------------------
# Install Dependencies
#--------------------------------------------------
	echo -e "\n---- Install tool packages ----"
	sudo apt-get install wget git python-pip gdebi-core -y
		
	echo -e "\n---- Install python packages ----"
	sudo apt-get install python-dateutil python-feedparser python-ldap python-libxslt1 python-lxml python-mako python-openid python-psycopg2 python-pybabel python-pychart python-pydot python-pyparsing python-reportlab python-simplejson python-tz python-vatnumber python-vobject python-webdav python-werkzeug python-xlwt python-yaml python-zsi python-docutils python-psutil python-mock python-unittest2 python-jinja2 python-pypdf python-decorator python-requests python-passlib python-pil -y python-suds
		
	echo -e "\n---- Install python libraries ----"
	sudo pip install gdata psycogreen ofxparse XlsxWriter

	echo -e "\n--- Install other required packages"
	sudo apt-get install node-clean-css -y
	sudo apt-get install node-less -y
	sudo apt-get install python-gevent -y

#--------------------------------------------------
# Install Wkhtmltopdf if needed
#--------------------------------------------------
	if [ $INSTALL_WKHTMLTOPDF = "True" ]; then
	  echo -e "\n---- Install wkhtml and place shortcuts on correct place for ODOO 10 ----"
	  #pick up correct one from x64 & x32 versions:
	  if [ "`getconf LONG_BIT`" == "64" ];then
	      _url=$WKHTMLTOX_X64
	  else
	      _url=$WKHTMLTOX_X32
	  fi
	  sudo wget $_url
	  sudo gdebi --n `basename $_url`
	  sudo ln -s /usr/local/bin/wkhtmltopdf /usr/bin
	  sudo ln -s /usr/local/bin/wkhtmltoimage /usr/bin
	else
	  echo "Wkhtmltopdf isn't installed due to the choice of the user!"
	fi

#--------------------------------------------------
# Install Enterprise requirement
#--------------------------------------------------
	if [ $IS_ENTERPRISE = "True" ]; then
	    # Odoo Enterprise install!
	    echo -e "\n--- Create symlink for node"
	    sudo ln -s /usr/bin/nodejs /usr/bin/node

	    echo -e "\n---- Installing Enterprise specific libraries ----"
	    sudo apt-get install nodejs npm -y
	    sudo npm install -g less
	    sudo npm install -g less-plugin-clean-css
	fi

#--------------------------------------------------
# Odoo HOME and Group
#--------------------------------------------------
    echo -e "\n---- Create Odoo Group ----"
	sudo groupadd $ODOO_GROUP
	echo -e "\nODOO GROUP="$ODOO_GROUP
    echo -e "\n---- Create Odoo home directory ----"
	sudo mkdir -p $ODOO_ROOT
	sudo chown root:$ODOO_GROUP -R $ODOO_ROOT
	echo -e "\nODOO HOME="$ODOO_ROOT

	echo -e "\n---- Create Odoo Apps home directory ----"
	sudo mkdir -p $ODOO_HOME
	echo -e "\nODOO HOME DIRECTORY="$ODOO_HOME

	echo -e "\n---- Create Odoo Production Addons directory ----"
	sudo mkdir -p $ODOO_PROD_ADDONS
	echo -e "\nODOO PROD DIRECTORY="$ODOO_PROD_ADDONS
fi

echo -e "\n---- Create ODOO system user ----"
sudo adduser --system --quiet --shell=/bin/bash --home=$ODOO_HOME --gecos 'ODOO' --group $ODOO_USER
#The user should also be added to the sudo'ers group.
sudo adduser $ODOO_USER sudo
sudo chown $ODOO_USER:$ODOO_USER $ODOO_HOME

echo -e "\n---- Create Log directory ----"
sudo mkdir -p $ODOO_HOME_LOG
sudo chown $ODOO_USER:$ODOO_USER $ODOO_HOME_LOG

#--------------------------------------------------
# Create User PostgreSQL Server
#--------------------------------------------------
echo -e "\n---- Creating the ODOO PostgreSQL User  ----"
sudo su - postgres -c "createuser -s $ODOO_USER" 2> /dev/null || true

#--------------------------------------------------
# Install ODOO
#--------------------------------------------------
echo -e "\n==== Installing ODOO Server ===="
sudo git clone --depth 1 --branch $ODOO_VERSION https://www.github.com/odoo/odoo $ODOO_HOME_SRV/

echo -e "* Change custom folder addons"
sudo mkdir -p $CUSTOM_ADDONS_PATH
echo -e "\nODOO CUSTOM ADDONS DIRECTORY="$CUSTOM_ADDONS_PATH

echo -e "\n---- Setting permissions on home folder ----"
sudo chown -R $ODOO_USER:$ODOO_USER $ODOO_HOME/*

echo -e "* Create server config file"
sudo mkdir -p $ODOO_HOME_CONF
sudo cp $ODOO_HOME_SRV/debian/odoo.conf $ODOO_HOME_CONF/${ODOO_CONFIG}.conf
sudo chown $ODOO_USER:$ODOO_USER $ODOO_HOME_CONF/${ODOO_CONFIG}.conf
sudo chmod 640 $ODOO_HOME_CONF/${ODOO_CONFIG}.conf

echo -e "* Change server config file"
sudo sed -i s/"db_user = .*"/"db_user = $ODOO_USER"/g $ODOO_HOME_CONF/${ODOO_CONFIG}.conf
sudo sed -i s/"; admin_passwd.*"/"admin_passwd = $ODOO_SUPERADMIN"/g $ODOO_HOME_CONF/${ODOO_CONFIG}.conf
sudo su root -c "echo '[options]' >> $ODOO_HOME_CONF/${ODOO_CONFIG}.conf"
sudo su root -c "echo 'logfile = $ODOO_HOME_LOG/$ODOO_CONFIG$1.log' >> $ODOO_HOME_CONF/${ODOO_CONFIG}.conf"
sudo su root -c "echo 'addons_path=$ODOO_PROD_ADDONS,$ODOO_HOME_SRV/addons,$CUSTOM_ADDONS_PATH' >> $ODOO_HOME_CONF/${ODOO_CONFIG}.conf"

echo -e "* Create startup file"
sudo su root -c "echo '#!/bin/sh' >> $ODOO_HOME_SRV/start.sh"
sudo su root -c "echo 'sudo -u $ODOO_USER $ODOO_HOME_SRV/openerp-server --config=$ODOO_HOME_CONF/${ODOO_CONFIG}.conf' >> $ODOO_HOME_SRV/start.sh"
sudo chmod 755 $ODOO_HOME_SRV/start.sh

#--------------------------------------------------
# Adding ODOO as a deamon (initscript)
#--------------------------------------------------

echo -e "* Create init file"
cat <<EOF > ~/$ODOO_CONFIG
#!/bin/sh
### BEGIN INIT INFO
# Provides: $ODOO_CONFIG
# Required-Start: \$remote_fs \$syslog
# Required-Stop: \$remote_fs \$syslog
# Should-Start: \$network
# Should-Stop: \$network
# Default-Start: 2 3 4 5
# Default-Stop: 0 1 6
# Short-Description: Enterprise Business Applications
# Description: ODOO Business Applications
### END INIT INFO
PATH=/bin:/sbin:/usr/bin
DAEMON=$ODOO_HOME_SRV/odoo-bin
NAME=$ODOO_CONFIG
DESC=$ODOO_CONFIG

# Specify the user name (Default: odoo).
USER=$ODOO_USER

# Specify an alternate config file (Default: /etc/openerp-server.conf).
CONFIGFILE="$ODOO_HOME_CONF/${ODOO_CONFIG}.conf"

# pidfile
PIDFILE=/var/run/\${NAME}.pid

# Additional options that are passed to the Daemon.
DAEMON_OPTS="-c \$CONFIGFILE"
[ -x \$DAEMON ] || exit 0
[ -f \$CONFIGFILE ] || exit 0
checkpid() {
[ -f \$PIDFILE ] || return 1
pid=\`cat \$PIDFILE\`
[ -d /proc/\$pid ] && return 0
return 1
}

case "\${1}" in
start)
echo -n "Starting \${DESC}: "
start-stop-daemon --start --quiet --pidfile \$PIDFILE \
--chuid \$USER:\$USER --background --make-pidfile \
--exec \$DAEMON -- \$DAEMON_OPTS
echo "\${NAME}."
;;
stop)
echo -n "Stopping \${DESC}: "
start-stop-daemon --stop --quiet --pidfile \$PIDFILE \
--oknodo
echo "\${NAME}."
;;

restart|force-reload)
echo -n "Restarting \${DESC}: "
start-stop-daemon --stop --quiet --pidfile \$PIDFILE \
--oknodo
sleep 1
start-stop-daemon --start --quiet --pidfile \$PIDFILE \
--chuid \$USER:\$USER --background --make-pidfile \
--exec \$DAEMON -- \$DAEMON_OPTS
echo "\${NAME}."
;;
*)
N=/etc/init.d/\$NAME
echo "Usage: \$NAME {start|stop|restart|force-reload}" >&2
exit 1
;;

esac
exit 0
EOF

echo -e "* Security Init File"
sudo mv ~/$ODOO_CONFIG /etc/init.d/$ODOO_CONFIG
sudo chmod 755 /etc/init.d/$ODOO_CONFIG
sudo chown root: /etc/init.d/$ODOO_CONFIG

echo -e "* Change default xmlrpc port"
sudo su root -c "echo 'xmlrpc_port = $ODOO_PORT' >> $ODOO_HOME_CONF/${ODOO_CONFIG}.conf"

echo -e "* Start ODOO on Startup"
sudo update-rc.d $ODOO_CONFIG defaults

echo -e "* Starting Odoo Service"
sudo su root -c "/etc/init.d/$ODOO_CONFIG start"
echo "-----------------------------------------------------------"
echo "Done! The Odoo server is up and running. Specifications:"
echo "Home location: $ODOO_HOME"
echo "Server location: $ODOO_HOME_SRV"
echo "Config file: $ODOO_HOME_CONF/${ODOO_CONFIG}.conf"
echo "Port: $ODOO_PORT"
echo "User service: $ODOO_USER"
echo "User PostgreSQL: $ODOO_USER"
echo "Addons folder: $CUSTOM_ADDONS_PATH"
echo "Start Odoo service: sudo service $ODOO_CONFIG start"
echo "Stop Odoo service: sudo service $ODOO_CONFIG stop"
echo "Restart Odoo service: sudo service $ODOO_CONFIG restart"
echo "-----------------------------------------------------------"


