# UNRELEASED (0.2.0)

- Implement secondary indexes with `index_create`/`index_status`/`get_all`.
- Implement table.update().
- Implement custom primary keys on tables and configurable durability setting.
- Implement r.db("rethinkdb").table("db_config").insert({name: "aa"}) to create databases.
- Replace storage engine with RocksDB, improving write performance by a factor of 2x.
- Use `sock.sync = false` for socket IO, improving simple query performance by a factor of 15x.
- Upgrade from Crystal 0.24.1 to Crystal 0.33.0.
- Remove Datum::Type recursive type to improve code quality and avoid compiler bugs. Term::Type still needs to be removed.
- Several bug fixes.

# 0.1.0 - 2018-01-15

- First release.
