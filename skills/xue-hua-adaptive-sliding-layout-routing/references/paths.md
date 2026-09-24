# Paths and patterns

Internal (not exported). Used by `RouteRegistry` / `namedLocation`.

## `joinPaths`

Source: `lib/src/utils/path_utils.dart`.

```dart
String joinPaths(String parent, String child)
```

Joins a parent full-path pattern with a child `AdaptiveRoute.path`.

- If `child` starts with `/`, return the normalized child (parent ignored).
- Otherwise append `child` to the normalized parent.
- Empty `child` returns the normalized parent.
- If the normalized parent is `/`, return `'/$child'`.
- Normalization: empty → `'/'`; `'/'` stays; a trailing `/` on any other path is stripped.

Used by `RouteRegistry` when compiling `fullPath`.

## `PathSegment`

Source: `lib/src/router/path_segment.dart`.

One segment of a compiled pattern: either a literal or a `:name` parameter.

### `PathSegment.literal`

```dart
const PathSegment.literal(String? literal)
```

Sets `paramName` to `null`. Example: `mail`.

### `PathSegment.param`

```dart
const PathSegment.param(String? paramName)
```

Sets `literal` to `null`. `paramName` does **not** include the colon.

### Fields

```dart
final String? literal;    // null on a param segment
final String? paramName;  // null on a literal segment
bool get isParam => paramName != null;
```

## `PathMatch`

Source: `lib/src/router/path_match.dart`.

Result of one `PathPattern.match` call.

```dart
const PathMatch({
  required int consumed,
  required Map<String, String> params,
})
```

| Field | Meaning |
| --- | --- |
| `consumed` | How many `pathSegments` were taken from `start`. |
| `params` | Parameters extracted **at this layer only** (not ancestors). |

## `PathPattern`

Source: `lib/src/router/path_pattern.dart`.

Compiles a pattern such as `/mail/:folder/:threadId` and matches by segment.

### Constructor

```dart
PathPattern(String pattern)
```

Stores `pattern` and `segments = _parse(pattern)`:

1. Strip one leading `/` and one trailing `/`.
2. Empty remainder → empty `segments` (matches only an empty path).
3. Split on `/`. A part that starts with `:` **and** has length > 1 becomes `PathSegment.param(part.substring(1))`; otherwise `PathSegment.literal(part)`.
4. `:` alone is a literal. There is no splat / regex segment.

### Fields

```dart
final String pattern;
final List<PathSegment> segments;
```

### `match`

```dart
PathMatch? match(List<String> pathSegments, {int start = 0})
```

- Empty pattern: succeeds only when `start == 0` **and** `pathSegments` is empty; `consumed` is 0, `params` is empty. Otherwise `null`.
- If `start + segments.length > pathSegments.length`, `null` (this layer cannot consume leftover child segments by itself; the registry then tries nested `routes`).
- For each segment: a param writes `Uri.decodeComponent(value)` under `paramName`; a literal must equal the path segment exactly (no decode).
- Success: `PathMatch(consumed: segments.length, params: …)`.

### `expand`

```dart
String expand(Map<String, String> pathParameters)
```

Fills the pattern for `namedLocation`.

- Empty `segments` → `'/'`.
- Param missing from `pathParameters` → `ArgumentError('Missing path parameter :$name')`.
- Param values are `Uri.encodeComponent`'d; literals are copied.
- Returns `'/' + parts.join('/')`.
