# UNRELEASED (0.2.0)

- Replace storage engine with RocksDB, improving write performance by a factor of 10x.
- Use `sync = false` for socket IO, improving simple query performance by a factor of 15x.
- Fixes and improvements on sending query responses.
- Upgrade from Crystal 0.24.1 to Crystal 0.32.1.
- Remove recursive types to improve code quality and avoid compiler bugs.

# 0.1.0 - 2018-01-15

- First release.
