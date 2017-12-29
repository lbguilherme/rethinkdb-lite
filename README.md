[![Travis](https://travis-ci.org/lbguilherme/rethinkdb-lite.svg?branch=master)](https://travis-ci.org/lbguilherme/rethinkdb-lite)

# RethinkDB-lite

This is a personal project aiming at reimplementing everything [RethinkDB](https://rethinkdb.com) currently does, for the sake of learning the challanges of creating such a product. Of course, this is not production ready in any way.

#### Goals

- Implement all current features of RethinkDB (changefeed, clustering and geoindex will come last)
- Be compactible with RethinkDB's drivers and WebUI (no need to reinvent anything here)
- Make small improvements along the way (with minimal user impact by default)
- Make it fast (this is a self imposed challenge)

#### Non-goals

- Make it stable and ready for production use (you should simply use RethinkDB itself)
- Break compactibility to introduce features that would not fit the original RethinkDB

## Running

Install these dependencies:

- [Crystal](https://crystal-lang.org/) for compiling the main code
- [Node](https://nodejs.org/) for compiling the Web UI

Then run:

```
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

```
crystal spec
```

## Thanks to

- https://github.com/rethinkdb/rethinkdb
- https://github.com/AtnNn/rethinkdb-webui
- https://github.com/crystal-lang/crystal
