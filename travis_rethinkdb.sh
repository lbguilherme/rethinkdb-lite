source /etc/lsb-release && echo "deb https://download.rethinkdb.com/apt $DISTRIB_CODENAME main" | sudo tee /etc/apt/sources.list.d/rethinkdb.list
apt-get update -qq
apt-get install wget -y --force-yes
wget -qO- https://download.rethinkdb.com/apt/pubkey.gpg | sudo apt-key add -
apt-get update -qq
apt-get install rethinkdb -y --force-yes
rethinkdb --daemon
