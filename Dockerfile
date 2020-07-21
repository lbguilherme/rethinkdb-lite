FROM debian AS duktape
RUN apt-get update && apt-get install curl xz-utils python2 python-pip -y
RUN pip install pyyaml
RUN curl https://duktape.org/duktape-2.5.0.tar.xz | tar xJ
WORKDIR /duktape-2.5.0
RUN python2 tools/configure.py --output-directory out
RUN gcc -O3 -c out/duktape.c -o out/duktape.o
RUN ar -rv out/libduktape.a out/duktape.o
RUN mv out/libduktape.a /libduktape.a

FROM debian AS rocksdb
RUN apt-get update && apt-get install curl libgflags-dev make g++ -y
RUN curl -L https://github.com/facebook/rocksdb/archive/v6.6.4.tar.gz | tar xz
WORKDIR /rocksdb-6.6.4
RUN make static_lib -j6
RUN make install-headers
RUN mv librocksdb.a /

FROM node:12 AS webui
COPY vendor/rethinkdb-webui /webui
WORKDIR /webui
RUN npm ci
RUN npm run build

FROM crystallang/crystal:0.35.1 AS builder
COPY --from=duktape /libduktape.a /usr/lib
COPY --from=rocksdb /librocksdb.a /usr/lib
COPY --from=rocksdb /usr/local/include/rocksdb /usr/include/rocksdb
RUN ls -lhs /usr/lib/librocksdb.a
WORKDIR /app
COPY shard.yml shard.lock ./
RUN shards
COPY src src
RUN crystal build -Dpreview_mt --release src/main.cr
RUN strip /app/main

FROM crystallang/crystal:0.35.1
COPY --from=builder /app/main /rethinkdb-lite
COPY --from=webui /webui/dist /vendor/rethinkdb-webui/dist
CMD ["/rethinkdb-lite"]
