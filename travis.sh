# Install RethinkDB
source /etc/lsb-release && echo "deb https://download.rethinkdb.com/apt $DISTRIB_CODENAME main" | tee /etc/apt/sources.list.d/rethinkdb.list
apt-get update -qq
apt-get install wget -y --force-yes
wget -qO- https://download.rethinkdb.com/apt/pubkey.gpg | apt-key add -
apt-get update -qq
apt-get install rethinkdb -y --force-yes

# Run RethinkDB in background
rethinkdb --daemon

# Install duktape
apt-get install duktape-dev -y --force-yes

# Install dependencies
shards

# Run spec
crystal spec --error-trace
