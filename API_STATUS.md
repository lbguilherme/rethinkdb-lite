# STATUS

- 95x :heavy_check_mark:
- 126x :x:

# Connection

| Term | Support | Notes |
|-|-|-|
| r.connect() | :heavy_check_mark: | Missing `timeout` and `ssl` options |
| conn.client_port() | :x: | |
| conn.client_address() | :x: | |
| conn.close() | :heavy_check_mark: | Missing `noreply_wait` option |
| conn.noreply_wait() | :x: |  |
| conn.reconnect() | :x: |  |
| query.run(conn) | :heavy_check_mark: | Isn't handling options |
| conn.server() | :heavy_check_mark: |  |
| conn.use(db) | :x: |  |

# Administration

| Term | Support | Notes |
|-|-|-|
| table.config() | :x: |  |
| db.config() | :x: |  |
| r.grant() | :x: |  |
| db.grant() | :x: |  |
| table.grant() | :x: |  |
| db.rebalance() | :x: |  |
| table.rebalance() | :x: |  |
| db.reconfigure() | :x: |  |
| table.reconfigure() | :x: |  |
| table.status() | :x: |  |
| db.wait() | :x: |  |
| table.wait() | :x: |  |

# Aggregation

| Term | Support | Notes |
|-|-|-|
| sequence.avg() | :x: |  |
| sequence.contains(value) | :x: |  |
| sequence.contains(function) | :x: |  |
| sequence.count() | :heavy_check_mark: |  |
| binary.count() | :heavy_check_mark: |  |
| string.count() | :heavy_check_mark: |  |
| object.count() | :heavy_check_mark: |  |
| sequence.distinct() | :heavy_check_mark: |  |
| table.distinct({index}) | :x: |  |
| sequence.fold(base, function, {emit, final_emit}) | :x: |  |
| sequence.group(function, {multi}) | :x: |  |
| table.group(function{index, multi}) | :x: |  |
| sequence.max() | :x: |  |
| table.max({index}) | :x: |  |
| sequence.min() | :x: |  |
| table.min({index}) | :x: |  |
| reduce.contains(function) | :x: |  |
| sequence.sum() | :heavy_check_mark: |  |
| sequence.sum(function) | :x: |  |
| grouped_stream.ungroup() | :x: |  |

# Control Structures

| Term | Support | Notes |
|-|-|-|
| r.args | :x: |  |
| r.binary(data) | :heavy_check_mark: |  |
| r.branch(...) | :heavy_check_mark: |  |
| sequence.coerce_to("array") | :heavy_check_mark: |  |
| value.coerce_to("string") | :heavy_check_mark: |  |
| string.coerce_to("number") | :heavy_check_mark: |  |
| array.coerce_to("object") | :heavy_check_mark: |  |
| sequence.coerce_to("object") | :heavy_check_mark: |  |
| object.coerce_to("array") | :heavy_check_mark: |  |
| binary.coerce_to("string") | :heavy_check_mark: |  |
| string.coerce_to("binary") | :heavy_check_mark: |  |
| value.default(value) | :heavy_check_mark: |  |
| value.do(..., function) | :heavy_check_mark: |  |
| r.error(err) | :heavy_check_mark: |  |
| r(value) | :heavy_check_mark: |  |
| r.expr(value) | :heavy_check_mark: |  |
| r.for_each(write_function) | :x: | Currently `.map` can be used for writes |
| r.http(url) | :x: |  |
| value.info() | :x: |  |
| r.js(code) | :heavy_check_mark: | Not all return types are supported yet. |
| r.json(string) | :x: |  |
| r.range() | :heavy_check_mark: |  |
| r.range(start) | :heavy_check_mark: |  |
| r.range(start, end) | :heavy_check_mark: |  |
| value.to_json_string() | :x: |  |
| value.type_of() | :x: |  |
| r.uuid() | :heavy_check_mark: |  |

# Cursors

| Term | Support | Notes |
|-|-|-|
| cursor.close | :heavy_check_mark: |  |
| cursor.each { ... } | :heavy_check_mark: |  |
| cursor.next | :heavy_check_mark: |  |
| cursor.next(timeout) | :x: |  |
| cursor.to_a | :heavy_check_mark: |  |

# Dates and Times

| Term | Support | Notes |
|-|-|-|
| time.date() | :x: |  |
| time.day_of_week() | :x: |  |
| time.day_of_year() | :x: |  |
| time.day() | :x: |  |
| time.during(start, end) | :x: |  |
| r.epoch_time(number) | :x: |  |
| time.hours() | :x: |  |
| time.in_timezone(tz) | :x: |  |
| r.iso8601(string) | :x: |  |
| time.minutes() | :x: |  |
| time.month() | :x: |  |
| time.now() | :x: |  |
| time.seconds() | :x: |  |
| time.time_of_day() | :x: |  |
| r.time(...) | :x: |  |
| time.timezone() | :x: |  |
| time.to_epoch_time() | :x: |  |
| time.to_iso8601() | :x: |  |
| time.year() | :x: |  |

# Document Manipulation

| Term | Support | Notes |
|-|-|-|
| array.append(value) | :heavy_check_mark: |  |
| sequence.bracket(index) | :heavy_check_mark: |  |
| object.bracket(key) | :heavy_check_mark: |  |
| sequence.get_field(key) | :heavy_check_mark: |  |
| object.get_field(key) | :heavy_check_mark: |  |
| array.change_at(offset, value) | :heavy_check_mark: |  |
| array.delete_at(offset, end) | :heavy_check_mark: |  |
| array.difference(array) | :x: |  |
| object.has_fields(...) | :x: |  |
| sequence.has_fields(...) | :x: |  |
| array.insert_at(offset, end) | :heavy_check_mark: |  |
| object.keys() | :x: |  |
| r.literal(value) | :x: |  |
| sequence.merge(object) | :heavy_check_mark: |  |
| sequence.merge(function) | :heavy_check_mark: |  |
| object.merge(object) | :heavy_check_mark: |  |
| object.merge(function) | :heavy_check_mark: |  |
| r.object(...) | :heavy_check_mark: |  |
| sequence.pluck(...) | :x: |  |
| object.pluck(...) | :x: |  |
| array.prepend(value) | :x: |  |
| array.set_difference(array) | :x: |  |
| array.set_insert(array) | :x: |  |
| array.set_intersection(array) | :x: |  |
| array.set_union(array) | :x: |  |
| array.splice_at(offset, array) | :heavy_check_mark: |  |
| sequence.pluck(...) | :x: |  |
| object.values() | :x: |  |
| sequence.without(...) | :x: |  |
| object.without(...) | :x: |  |

# Geo Spatial

| Term | Support | Notes |
|-|-|-|
| r.circle(...) | :x: |  |
| geo.distance(geo) | :x: |  |
| line.fill() | :x: |  |
| r.geojson(json) | :x: |  |
| table.get_intersecting(geo, {index}) | :x: |  |
| table.get_nearest(point, {index}) | :x: |  |
| sequence.includes(geo) | :x: |  |
| geo.includes(geo) | :x: |  |
| sequence.intersects(geo) | :x: |  |
| geo.intersects(geo) | :x: |  |
| r.line(...) | :x: |  |
| r.point(long, lat) | :x: |  |
| ploy.polygon_sub(poly) | :x: |  |
| r.polygon(...) | :x: |  |
| geo.to_geojson() | :x: |  |

# Joins

| Term | Support | Notes |
|-|-|-|
| sequence.eq_join(field, table, {index, ordered}) | :x: |  |
| sequence.eq_join(function, table, {index, ordered}) | :x: |  |
| sequence.inner_join(sequence, function) | :x: |  |
| sequence.outer_join(sequence, function) | :x: |  |
| sequence.zip() | :x: |  |

# Manipulating Databases

| Term | Support | Notes |
|-|-|-|
| r.db_create(name) | :heavy_check_mark: |  |
| r.db_drop(name) | :x: |  |
| r.db_list() | :x: |  |

# Manipulating Tables

| Term | Support | Notes |
|-|-|-|
| stream.changes() | :x: |  |
| table.get_write_hook() | :x: |  |
| table.index_create(...) | :heavy_check_mark: |  |
| table.index_drop(name) | :x: |  |
| table.index_list() | :x: |  |
| table.index_rename(old, new) | :x: |  |
| table.index_status(...) | :heavy_check_mark: |  |
| table.index_wait(...) | :x: |  |
| table.set_write_hook(function) | :x: |  |
| db.table_create(name) | :heavy_check_mark: |  |
| db.table_list() | :x: |  |

# Math and Logic

| Term | Support | Notes |
|-|-|-|
| number.add(number, ...) | :heavy_check_mark: |  |
| string.add(string, ...) | :heavy_check_mark: |  |
| array.add(array, ...) | :heavy_check_mark: |  |
| time.add(number, ...) | :x: |  |
| value.and(value, ...) | :heavy_check_mark: |  |
| number.bit_and(number, ...) | :x: |  |
| number.bit_not() | :x: |  |
| number.bit_or(number, ...) | :x: |  |
| number.bit_sal(number, ...) | :x: |  |
| number.bit_sar(number, ...) | :x: |  |
| number.bit_xor(number, ...) | :x: |  |
| number.ceil() | :heavy_check_mark: |  |
| number.div(number, ...) | :heavy_check_mark: |  |
| value.eq(value, ...) | :heavy_check_mark: |  |
| number.floor() | :heavy_check_mark: |  |
| value.ge(value, ...) | :heavy_check_mark: |  |
| value.gt(value, ...) | :heavy_check_mark: |  |
| value.le(value, ...) | :heavy_check_mark: |  |
| value.lt(value, ...) | :heavy_check_mark: |  |
| number.nod(number, ...) | :heavy_check_mark: |  |
| number.mul(number, ...) | :heavy_check_mark: |  |
| array.mul(number, ...) | :heavy_check_mark: |  |
| string.mul(number, ...) | :heavy_check_mark: |  |
| value.ne(value, ...) | :heavy_check_mark: |  |
| value.not() | :heavy_check_mark: |  |
| value.or(value, ...) | :heavy_check_mark: |  |
| r.random() | :x: |  |
| number.round() | :heavy_check_mark: |  |
| number.sub(number, ...) | :heavy_check_mark: |  |

# Selecting Data

| Term | Support | Notes |
|-|-|-|
| table.between(lower, upper, ...) | :x: |  |
| table_slice.between(lower, upper, ...) | :x: |  |
| r.db(name) | :heavy_check_mark: |  |
| sequence.filter(object) | :heavy_check_mark: |  |
| sequence.filter(function) | :heavy_check_mark: |  |
| table.get_all(key, ...) | :heavy_check_mark: |  |
| table.get(key) | :heavy_check_mark: |  |
| db.table(name) | :heavy_check_mark: |  |

# String Manipulation

| Term | Support | Notes |
|-|-|-|
| string.downcase() | :heavy_check_mark: |  |
| string.match(regexp) | :x: |  |
| string.split(separator, max) | :heavy_check_mark: |  |
| string.upcase() | :heavy_check_mark: |  |

# Transformations

| Term | Support | Notes |
|-|-|-|
| sequence.concat_map(function) | :x: |  |
| sequence.is_empty() | :x: |  |
| sequence.limit(number) | :heavy_check_mark: |  |
| sequence.map(function) | :heavy_check_mark: |  |
| sequence.nth(number) | :heavy_check_mark: |  |
| sequence.offsets_of(value) | :x: |  |
| sequence.offsets_of(function) | :x: |  |
| table.order_by({index}) | :x: |  |
| sequence.order_by(key) | :heavy_check_mark: |  |
| sequence.order_by(function) | :heavy_check_mark: |  |
| sequence.sample(number) | :x: |  |
| sequence.skip(number) | :heavy_check_mark: |  |
| sequence.slice(start) | :heavy_check_mark: |  |
| sequence.slice(start, end) | :heavy_check_mark: |  |
| sequence.union(sequence, ...) | :x: |  |
| sequence.with_fields(field, ...) | :x: |  |

# Writing Data

| Term | Support | Notes |
|-|-|-|
| table_slice.delete() | :heavy_check_mark: |  |
| row.delete() | :heavy_check_mark: |  |
| table.insert(...) | :heavy_check_mark: |  |
| table_slice.replace(...) | :x: |  |
| row.replace(...) | :x: |  |
| table.sync() | :x: |  |
| table_slice.update(...) | :heavy_check_mark: |  |
| row.update(...) | :heavy_check_mark: |  |
