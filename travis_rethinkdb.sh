source /etc/lsb-release && echo "deb http://download.rethinkdb.com/apt $DISTRIB_CODENAME main" | tee /etc/apt/sources.list.d/rethinkdb.list
curl http://download.rethinkdb.com/apt/pubkey.gpg | apt-key add -
apt-get update -qq
apt-get install rethinkdb -y --force-yes
rethinkdb --daemon