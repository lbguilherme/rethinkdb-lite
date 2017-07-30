[![Travis](https://travis-ci.org/lbguilherme/rethinkdb-lite.svg?branch=master)](https://travis-ci.org/lbguilherme/rethinkdb-lite)

# RethinkDB-lite

This is a personal project aiming at reimplementing everything [RethinkDB](https://rethinkdb.com) currently does, for the sake of learning the challanges of creating such a product. Of course, this is not production ready in any way (and I don't plan it to be).

#### Goals

- Implement all current features of RethinkDB (changefeed, clustering and geoindex will come last)
- Be compactible with RethinkDB's drivers and WebUI (no need to reinvent anything here)
- Make small improvements along the way (with minimal user impact by default)
- Make it fast (this is a self imposed challenge)

#### Non-goals

- Make it stable and ready for production use (unless you want to shot your self in the head... with a machine gun.. you should simply use RethinkDB)
- Break compactibility to introduce features that would not fit the original RethinkDB

## Running

```
cd vendor/rethinkdb-webui
npm install
npm run build
cd ../..
crystal deps
crystal src/main.cr
```

And open your browser on http://localhost:8080.

## Running Tests

```
crystal specs
```

## Thanks

- https://github.com/rethinkdb/rethinkdb
- https://github.com/AtnNn/rethinkdb-webui
- https://github.com/crystal-lang/crystal
