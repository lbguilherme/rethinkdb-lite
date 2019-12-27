[![GitHub Actions](https://github.com/lbguilherme/rethinkdb-lite/workflows/Crystal%20CI/badge.svg)](https://github.com/lbguilherme/rethinkdb-lite/actions?query=workflow%3A%22Crystal+CI%22)  [![Crystal Version](https://img.shields.io/badge/crystal%20-0.32.1-brightgreen.svg)](https://github.com/crystal-lang/crystal/releases/tag/0.32.1)

# RethinkDB-lite

This is a personal project aiming at reimplementing everything [RethinkDB](https://rethinkdb.com) currently does. At the same time, it is also a driver capable of connecting to a database and sending queries.

## First use case: Database driver

You can connect to a running RethinkDB instance and send queries. Methods are pretty much equal to the official Ruby driver, for which you can find documentation here: https://rethinkdb.com/api/ruby/. This is not feature complete yet, a lot of functions are missing. Be aware of bugs (please report them).

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

This is similar to SQLite. A single-user database is run with a local path where data is stored. This is reimplementing the behavior of RethinkDB, but working as an embeddable library. The goal is to have every query that you would do on the real RethinkDB working here, with similar semantics. This is not feature complete yet, a lot of functions are missing. Be aware of bugs (please report them).

```cr
require "rethinkdb-lite/src/driver/*"
include RethinkDB::DSL

# The data will be stored in this directory.
conn = r.local_database("path/to/data")

r.table_create("users").run(conn)
r.table("users").insert({name: "John", username: "john", password: "123"}).run(conn)

```

## Third use case: RethinkDB server

That local database from the second use case can also be served as a full multi-user database, listening for RethinkDB driver connections and also serving the Web UI for administration. It can receive connection from any official or non-official RethinkDB driver from https://rethinkdb.com/docs/install-drivers/.

```cr
require "rethinkdb-lite/src/server/*"
require "rethinkdb-lite/src/driver/*"
include RethinkDB::DSL

conn = r.local_database("path/to/data")

RethinkDB::Server::WebUiServer.new(8080, conn).start
RethinkDB::Server::DriverServer.new(28015, conn).start

# http://localhost:8080 will bring the Web UI
# localhost:28015 will be ready for driver connections

sleep
```

---

## Goals

- Implement all current features of RethinkDB (all query functions, clustering, changefeed, geoindex, ...)
- Be fully compatible with RethinkDB's drivers and WebUI
- Make small improvements along the way (with minimal user impact)
- Make it fast
- Add new features (query optimizer? autorebalancing?)

## Roadmap

- Replace the current storage backend with RocksDB
- Pass successfuly on RethinkDB's spec suite
- Add some better newer tests
- Benchmark and improve performance
- Implement epic features: clustering, changefeeds
- Implement new features: query optimizer?

## Running

Install these dependencies:

- [Crystal](https://crystal-lang.org/) for compiling the main code
- [Node](https://nodejs.org/) for compiling the Web UI
- [Duktape](https://duktape.org/) for a embeddable javascript runtime for `r.js()` (`apt install duktape-dev`)
- [RocksDB](https://rocksdb.org/) for the storage engine (`apt install librocksdb-dev`)

Then run:

```sh
cd vendor/rethinkdb-webui
npm install
npm run build
cd ../..
shards
crystal src/main.cr
```

And open your browser at http://localhost:8080.

Most of the Web UI doesn't work yet, but you can use the tabs _Tables_ and _Data Explorer_. Try some queries there.

You can also use any client driver to connect from another language, see https://rethinkdb.com/docs/install-drivers/.

## Running Tests

You should have a running real empty RethinkDB server for testing. Do not use one with data in it. You can start one with by simply running `rethinkdb` on the terminal, after [installing it](https://rethinkdb.com/).

```
crystal spec
```

## References

- https://github.com/rethinkdb/rethinkdb
- https://github.com/AtnNn/rethinkdb-webui
- https://github.com/crystal-lang/crystal
