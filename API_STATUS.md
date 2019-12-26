# STATUS

Yes count: 91
No count: 130

# Connection

| Term | Support | Notes |
|-|-|-|
| r.connect() | Yes | Missing `timeout` and `ssl` options |
| conn.client_port() | No | |
| conn.client_address() | No | |
| conn.close() | Yes | Missing `noreply_wait` option |
| conn.noreply_wait() | No |  |
| conn.reconnect() | No |  |
| query.run(conn) | Yes | Isn't handling options |
| conn.server() | Yes |  |
| conn.use(db) | No |  |

# Administration

| Term | Support | Notes |
|-|-|-|
| table.config() | No |  |
| db.config() | No |  |
| r.grant() | No |  |
| db.grant() | No |  |
| table.grant() | No |  |
| db.rebalance() | No |  |
| table.rebalance() | No |  |
| db.reconfigure() | No |  |
| table.reconfigure() | No |  |
| table.status() | No |  |
| db.wait() | No |  |
| table.wait() | No |  |

# Aggregation

| Term | Support | Notes |
|-|-|-|
| sequence.avg() | No |  |
| sequence.contains(value) | No |  |
| sequence.contains(function) | No |  |
| sequence.count() | Yes |  |
| binary.count() | Yes |  |
| string.count() | Yes |  |
| object.count() | Yes |  |
| sequence.distinct() | Yes |  |
| table.distinct({index}) | No |  |
| sequence.fold(base, function, {emit, final_emit}) | No |  |
| sequence.group(function, {multi}) | No |  |
| table.group(function{index, multi}) | No |  |
| sequence.max() | No |  |
| table.max({index}) | No |  |
| sequence.min() | No |  |
| table.min({index}) | No |  |
| reduce.contains(function) | No |  |
| sequence.sum() | No |  |
| sequence.sum(function) | No |  |
| grouped_stream.ungroup() | No |  |

# Control Structures

| Term | Support | Notes |
|-|-|-|
| r.args | No |  |
| r.binary(data) | Yes |  |
| r.branch(...) | Yes |  |
| sequence.coerce_to("array") | Yes |  |
| value.coerce_to("string") | Yes |  |
| string.coerce_to("number") | Yes |  |
| array.coerce_to("object") | Yes |  |
| sequence.coerce_to("object") | Yes |  |
| object.coerce_to("array") | Yes |  |
| binary.coerce_to("string") | Yes |  |
| string.coerce_to("binary") | Yes |  |
| value.default(value) | Yes |  |
| value.do(..., function) | Yes |  |
| r.error(err) | Yes |  |
| r(value) | Yes |  |
| r.expr(value) | Yes |  |
| r.for_each(write_function) | No | Currently `.map` can be used for writes |
| r.http(url) | No |  |
| value.info() | No |  |
| r.js(code) | Yes | Not all return types are supported yet. |
| r.json(string) | No |  |
| r.range() | Yes |  |
| r.range(start) | Yes |  |
| r.range(start, end) | Yes |  |
| value.to_json_string() | No |  |
| value.type_of() | No |  |
| r.uuid() | Yes |  |

# Cursors

| Term | Support | Notes |
|-|-|-|
| cursor.close | Yes |  |
| cursor.each { ... } | Yes |  |
| cursor.next | Yes |  |
| cursor.next(timeout) | No |  |
| cursor.to_a | Yes |  |

# Dates and Times

| Term | Support | Notes |
|-|-|-|
| time.date() | No |  |
| time.day_of_week() | No |  |
| time.day_of_year() | No |  |
| time.day() | No |  |
| time.during(start, end) | No |  |
| r.epoch_time(number) | No |  |
| time.hours() | No |  |
| time.in_timezone(tz) | No |  |
| r.iso8601(string) | No |  |
| time.minutes() | No |  |
| time.month() | No |  |
| time.now() | No |  |
| time.seconds() | No |  |
| time.time_of_day() | No |  |
| r.time(...) | No |  |
| time.timezone() | No |  |
| time.to_epoch_time() | No |  |
| time.to_iso8601() | No |  |
| time.year() | No |  |

# Document Manipulation

| Term | Support | Notes |
|-|-|-|
| array.append(value) | Yes |  |
| sequence.bracket(index) | Yes |  |
| object.bracket(key) | Yes |  |
| sequence.get_field(key) | Yes |  |
| object.get_field(key) | Yes |  |
| array.change_at(offset, value) | Yes |  |
| array.delete_at(offset, end) | Yes |  |
| array.difference(array) | No |  |
| object.has_fields(...) | No |  |
| sequence.has_fields(...) | No |  |
| array.insert_at(offset, end) | Yes |  |
| object.keys() | No |  |
| r.literal(value) | No |  |
| sequence.merge(object) | Yes |  |
| sequence.merge(function) | Yes |  |
| object.merge(object) | Yes |  |
| object.merge(function) | Yes |  |
| r.object(...) | Yes |  |
| sequence.pluck(...) | No |  |
| object.pluck(...) | No |  |
| array.prepend(value) | No |  |
| array.set_difference(array) | No |  |
| array.set_insert(array) | No |  |
| array.set_intersection(array) | No |  |
| array.set_union(array) | No |  |
| array.splice_at(offset, array) | Yes |  |
| sequence.pluck(...) | No |  |
| object.values() | No |  |
| sequence.without(...) | No |  |
| object.without(...) | No |  |

# Geo Spatial

| Term | Support | Notes |
|-|-|-|
| r.circle(...) | No |  |
| geo.distance(geo) | No |  |
| line.fill() | No |  |
| r.geojson(json) | No |  |
| table.get_intersecting(geo, {index}) | No |  |
| table.get_nearest(point, {index}) | No |  |
| sequence.includes(geo) | No |  |
| geo.includes(geo) | No |  |
| sequence.intersects(geo) | No |  |
| geo.intersects(geo) | No |  |
| r.line(...) | No |  |
| r.point(long, lat) | No |  |
| ploy.polygon_sub(poly) | No |  |
| r.polygon(...) | No |  |
| geo.to_geojson() | No |  |

# Joins

| Term | Support | Notes |
|-|-|-|
| sequence.eq_join(field, table, {index, ordered}) | No |  |
| sequence.eq_join(function, table, {index, ordered}) | No |  |
| sequence.inner_join(sequence, function) | No |  |
| sequence.outer_join(sequence, function) | No |  |
| sequence.zip() | No |  |

# Manipulating Databases

| Term | Support | Notes |
|-|-|-|
| r.db_create(name) | Yes |  |
| r.db_drop(name) | No |  |
| r.db_list() | No |  |

# Manipulating Tables

| Term | Support | Notes |
|-|-|-|
| stream.changes() | No |  |
| table.get_write_hook() | No |  |
| table.index_create(...) | No |  |
| table.index_drop(name) | No |  |
| table.index_list() | No |  |
| table.index_rename(old, new) | No |  |
| table.index_status(...) | No |  |
| table.index_wait(...) | No |  |
| table.set_write_hook(function) | No |  |
| db.table_create(name) | Yes |  |
| db.table_list() | No |  |

# Math and Logic

| Term | Support | Notes |
|-|-|-|
| number.add(number, ...) | Yes |  |
| string.add(string, ...) | Yes |  |
| array.add(array, ...) | Yes |  |
| time.add(number, ...) | No |  |
| value.and(value, ...) | Yes |  |
| number.bit_and(number, ...) | No |  |
| number.bit_not() | No |  |
| number.bit_or(number, ...) | No |  |
| number.bit_sal(number, ...) | No |  |
| number.bit_sar(number, ...) | No |  |
| number.bit_xor(number, ...) | No |  |
| number.ceil() | Yes |  |
| number.div(number, ...) | Yes |  |
| value.eq(value, ...) | Yes |  |
| number.floor() | Yes |  |
| value.ge(value, ...) | Yes |  |
| value.gt(value, ...) | Yes |  |
| value.le(value, ...) | Yes |  |
| value.lt(value, ...) | Yes |  |
| number.nod(number, ...) | Yes |  |
| number.mul(number, ...) | Yes |  |
| array.mul(number, ...) | Yes |  |
| string.mul(number, ...) | Yes |  |
| value.ne(value, ...) | Yes |  |
| value.not() | Yes |  |
| value.or(value, ...) | Yes |  |
| r.random() | No |  |
| number.round() | Yes |  |
| number.sub(number, ...) | Yes |  |

# Selecting Data

| Term | Support | Notes |
|-|-|-|
| table.between(lower, upper, ...) | No |  |
| table_slice.between(lower, upper, ...) | No |  |
| r.db(name) | Yes |  |
| sequence.filter(object) | Yes |  |
| sequence.filter(function) | Yes |  |
| table.get_all(key, ...) | No |  |
| table.get(key) | Yes |  |
| db.table(name) | Yes |  |

# String Manipulation

| Term | Support | Notes |
|-|-|-|
| string.downcase() | Yes |  |
| string.match(regexp) | No |  |
| string.split(separator, max) | Yes |  |
| string.upcase() | Yes |  |

# Transformations

| Term | Support | Notes |
|-|-|-|
| sequence.concat_map(function) | No |  |
| sequence.is_empty() | No |  |
| sequence.limit(number) | Yes |  |
| sequence.map(function) | Yes |  |
| sequence.nth(number) | Yes |  |
| sequence.offsets_of(value) | No |  |
| sequence.offsets_of(function) | No |  |
| table.order_by({index}) | No |  |
| sequence.order_by(key) | Yes |  |
| sequence.order_by(function) | Yes |  |
| sequence.sample(number) | No |  |
| sequence.skip(number) | Yes |  |
| sequence.slice(start) | Yes |  |
| sequence.slice(start, end) | Yes |  |
| sequence.union(sequence, ...) | No |  |
| sequence.with_fields(field, ...) | No |  |

# Writing Data

| Term | Support | Notes |
|-|-|-|
| table_slice.delete() | No |  |
| row.delete() | No |  |
| table.insert(...) | Yes |  |
| table_slice.replace(...) | Yes |  |
| row.replace(...) | Yes |  |
| table.sync() | No |  |
| table_slice.update(...) | Yes |  |
| row.update(...) | Yes |  |
