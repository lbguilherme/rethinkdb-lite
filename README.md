[![Travis](https://travis-ci.org/lbguilherme/rethinkdb-lite.svg?branch=master)](https://travis-ci.org/lbguilherme/rethinkdb-lite)

# RethinkDB-lite

This is a personal project aiming at reimplementing everything [RethinkDB](https://rethinkdb.com) currently does. At the same time, it is also a driver capable to connecting to the database to send queries.

### First use case: Database driver

You can connect to a running RethinkDB instance and send queries for data. Methods are pretty much equal to the official Ruby driver, for which you can find documentation here: https://rethinkdb.com/api/ruby/. This is not feature complete, a lot of functions are missing. Be aware of bugs (please report them).

```cr
require "rethinkdb-lite/src/driver/*"
include RethinkDB::DSL

conn = r.connect("localhost")

r.table_create("heros").run(conn)
r.table("heros").insert({name: "Iron Man", power: 17}).run(conn)
r.table("heros").insert({name: "Batman", power: 13}).run(conn)
r.table("heros").insert({name: "Superman", power: 650}).run(conn)
r.table("heros").insert({name: "Hulk", power: 103}).run(conn)

overpower_hero = r.table("heros").filter { |hero| hero["power"] == 650 }["name"][0].run(conn)

pp overpower_hero

```

## Second use case: Local database for your application

This is similar to SQLite. A single user database is run with a local path where data is stored. This is reimplementing the behavior of RethinkDB, but worked as a library. Eventually every query that you would do on the real RethinkDB will be available here, with similar semantics. This is not feature complete, a lot of functions are missing. Be aware of bugs (please report them).

```cr
require "rethinkdb-lite/src/driver/*"
include RethinkDB::DSL

# The data will be stored in this directory.
conn = r.local_database("test_database")

r.table_create("users").run(conn)
r.table("users").insert({name: "John", username: "john", password: "123"}).run(conn)

```

## Third use case: RethinkDB server

That local database from the second use case can also be run as a multi user full database, listening for RethinkDB driver connections and serving an Web UI for administration. It can receive connection from any other driver from https://rethinkdb.com/docs/install-drivers/.

```cr
require "rethinkdb-lite/src/server/*"
require "rethinkdb-lite/src/driver/*"
include RethinkDB::DSL

conn = r.local_database("/tmp/rethinkdb-lite/data")

RethinkDB::Server::HttpServer.new(8080, conn).start
RethinkDB::Server::DriverServer.new(28015, conn).start

# http://localhost:8080 will bring the Web UI
# localhost:28015 will be ready for driver connections

sleep
```

---

#### Goals

- Implement all current features of RethinkDB (changefeed, clustering and geoindex will come last)
- Be compactible with RethinkDB's drivers and WebUI (no need to reinvent anything here)
- Make small improvements along the way (with minimal user impact by default)
- Make it fast (this is a self imposed challenge)

#### Non-goals

- Replace RethinkDB itself for production use (you should simply use RethinkDB itself)
- Break compactibility to introduce features that would not fit the original RethinkDB

## Running

Install these dependencies:

- [Crystal](https://crystal-lang.org/) for compiling the main code
- [Node](https://nodejs.org/) for compiling the Web UI

Then run:

```sh
cd vendor/rethinkdb-webui
npm install
npm run build
cd ../..
crystal deps
crystal src/main.cr
```

And open your browser at http://localhost:8080.

Most of the Web UI doesn't work yet, but you can use the tabs _Tables_ and _Data Explorer_. Try some queries there.

You can also use any client driver to connect from another language, see https://rethinkdb.com/docs/install-drivers/.

## Running Tests

You should have a running real RethinkDB server for testing. Do not use one with data in it. You can start one with by simply running `rethinkdb` on the terminal, after [installing it](https://rethinkdb.com/).

```
crystal spec
```

## Thanks to

- https://github.com/rethinkdb/rethinkdb
- https://github.com/AtnNn/rethinkdb-webui
- https://github.com/crystal-lang/crystal
