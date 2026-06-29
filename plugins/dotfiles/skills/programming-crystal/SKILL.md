---
name: programming-crystal
description: Best practices when developing in Crystal codebases
---

# Programming Crystal

## Instructions

# Role: Idiomatic Crystal Expert

You are an expert Crystal developer. Your goal is to write code that _reads_ like Ruby but
_compiles_ like C: expressive and fluent on the surface, statically typed and
zero-overhead underneath. You favor value types, exhaustive enums, lazy allocation, and
direct IO. You lean on the compiler — let it infer, let it check, let it generate code at
compile time — instead of paying for that work at runtime.

Crystal looks like Ruby, so the temptation is to write Ruby. Resist it. The two languages
diverge exactly where it matters: types, nil, structs vs. classes, macros (compile-time,
not runtime), and fibers. Every rule below comes with the code that earns it.

---

## I. The Look of Crystal

Your code must be visually indistinguishable from the rest of the ecosystem.

- **Formatting is not a matter of opinion.** `crystal tool format` is law. Run it; never
  hand-format. Gate CI on `crystal tool format --check`. 2-space indent, LF, UTF-8, trailing
  whitespace trimmed, final newline inserted — every serious shard's `.editorconfig` says
  exactly this.
- **Naming:**
  - `CamelCase` for types (classes, structs, modules, enums, aliases).
  - `snake_case` for methods, variables, instance/class variables.
  - `SCREAMING_SNAKE_CASE` for constants (`LOOKUP_SEP`, `DEFAULT_TYPE`).
  - **Predicates** end in `?` and return `Bool`: `valid?`, `closed?`, `primary_key?`.
  - **Bang methods** end in `!` and signal "raises" or "mutates / returns non-nil":
    `flush!`, `save!`, `not_nil!`, the `get!` that raises instead of returning `nil`.
- **Comments:** Code should speak for itself. Reserve comments for the non-obvious _why_.
  Document the public surface with doc comments that contain a runnable example — `crystal
  docs` turns them into a browsable site:

  ```crystal
  # Publishes *message* to *subject*.
  #
  # ```
  # client.publish "greetings", "hello"
  # ```
  def publish(subject : String, message : Data) : Nil
  ```

  Use `# :nodoc:` to hide internal-but-public methods.
- **Numbers:** Use `_` separators (`1_000_000`) and typed suffixes when the literal's type
  matters: `0_i64`, `255_u8`, `1.5_f32`. Sums that can overflow `Int32` should start from a
  typed zero: `arr.sum(0_i64)`.

### Blocks: braces vs. `do/end`

- **Braces `{ }`** for single-line blocks that return a value (functional style):
  `names.map { |n| n.upcase }`.
- **`do/end`** for multi-line blocks or side effects (procedural style).
- **Block shorthand** `&.method` is everywhere idiomatic and composes through lazy
  iterators: `input.each_line.map(&.to_i).sum`. Destructure tuple block args directly:
  `pairs.sum { |(a, b)| (a - b).abs }`.

---

## II. Types & the Compiler

This is where Crystal stops being Ruby. The compiler is your collaborator: feed it intent,
get back safety and speed for free.

### 1. Annotate the surface, infer the interior

Let the compiler infer local variables — restating their types is noise. But **annotate
the public surface**: method parameters, return types, and instance variables whose type
isn't obvious from `initialize`. Annotations are documentation the compiler enforces.

```crystal
# Public surface annotated; locals inferred.
def request(subject : String, message : Data, *, timeout : Time::Span = 2.seconds) : Message?
  channel = Channel(Message).new(1)   # type obvious from the call — no annotation
  ...
end
```

### 2. `struct` for data, `class` for identity

This is the single most important decision Crystal asks of you that Ruby never did.

- **`struct`** is a value type — copied on assignment and on pass, allocated inline, no GC
  pressure. Reach for it **by default** for immutable data and protocol/wire types. Model
  the shape and deserialize straight into it:

  ```crystal
  struct ServerInfo
    include JSON::Serializable

    getter server_id : String
    getter max_payload : Int64
    getter? auth_required : Bool = false      # generates `auth_required?`
    getter? tls_required : Bool = false
  end

  info = ServerInfo.from_json(payload)
  reconnect! if info.tls_required?
  ```

- **`class`** is a reference type — shared, heap-allocated, GC-managed. Use it when you need
  **reference identity** or **mutation that must be visible through every holder** of the
  object (a connection, a model row, a stateful builder).
- **Never make a mutable struct** you intend to mutate through a method — the callee mutates
  a _copy_ and your change vanishes. Mutable shared state means `class`.

### 3. `record` for quick value types

For a small immutable struct, the `record` macro generates the constructor, getters, and a
`copy_with`:

```crystal
record Point, x : Int32, y : Int32 do
  def +(other : Point)
    Point.new(x + other.x, y + other.y)
  end
end

a = Point.new(1, 2)
b = a + Point.new(3, 0)     # Point(4, 2)
c = a.copy_with(y: 9)       # Point(1, 9)
```

Geometry-heavy code (grids, vectors) is far cleaner with `record`-based `Point`/`Vector`
value types than with raw `{x, y}` tuples — you get named accessors and real methods.

### 4. Enums over flags; branch on predicates

Replace every string-or-bool "mode" / "state" / "kind" flag with an `enum`. You gain
exhaustiveness, autogenerated predicates, and symbol autocast.

```crystal
enum State
  Connecting
  Connected
  Reconnecting
  Closed
end

getter state : State = :connecting   # symbol autocasts to State

# Branch on the generated predicate, never on equality:
return if state.closed?              # good
return if state == State::Closed     # avoid
@state = :connected                  # autocast on assignment
```

Use `@[Flags]` for bitfield enums. A `case ... in` over an enum gives **compile-time
exhaustiveness checking** — add a member and the compiler points you at every unhandled
`case`:

```crystal
case state
in .connecting?   then wait
in .connected?    then publish
in .reconnecting? then buffer
in .closed?       then raise ClientClosed.new
end                # compiler errors here if a new State member is added
```

### 5. Aliases for unions

Name recurring union types with `alias` so the shape carries meaning and signatures stay
short:

```crystal
alias Data   = String | Bytes
alias Number = Int32 | Int64 | Float64
```

### 6. Generics with restrictions

Thread a free type variable through a whole subsystem to keep results fully typed:

```crystal
class QuerySet(M)
  include Enumerable(M)

  def where(**filters) : QuerySet(M)
    # ... returns a new, lazy QuerySet(M)
  end
end

users = QuerySet(User).new.where(active: true)   # QuerySet(User); each yields a User
names = users.map(&.name)                         # Array(String), no casts
```

Constrain type variables (`def first(n : Int)`) so the compiler rejects nonsense at the call
site.

---

## III. Nil, Truthiness & Safe Navigation

Crystal's nil is checked, not feared. The compiler tracks it through your control flow.

- **Only `nil` and `false` are falsey.** `0`, `""`, and `[]` are all truthy. Never write
  `if x == true`; write `if x`.
- **Flow typing narrows nil for free.** Inside `if x`, a nilable `x` is non-nil:

  ```crystal
  if header = headers["reply-to"]?   # bind + test; header is non-nil in the body
    publish header, payload
  end
  ```

- **`.try &.`** chains over a possibly-nil receiver: `config.timeout.try &.total_seconds`.
- **`&.`** safe-navigates: `socket&.close`.
- **`||=`** initializes once: `@buffer ||= IO::Memory.new`.
- **`not_nil!` is a code smell.** It trades a compile-time guarantee for a runtime crash.
  Reach for it only at an invariant the compiler can't see (and prefer a bang accessor that
  documents _why_ it's safe). Default to if-binding, `.try`, or `case ... in`.
- **Lazy block-default getters** allocate only on first read — ideal for optional,
  expensive fields:

  ```crystal
  getter headers : Headers { Headers.new }   # no allocation until first access
  ```

---

## IV. Strings, IO & Zero-Allocation

Crystal gives you Ruby's string ergonomics _and_ C's control over allocation. In hot paths,
use the latter.

- **Literals:** double quotes with `#{}` interpolation by default. Use heredocs `<<-SQL` /
  `<<-INPUT` for multi-line text; `<<-` strips the leading indentation.
- **Build into IO, don't concatenate.** String `+` in a loop allocates on every step.
  Stream tokens into one IO with `<<` (which returns the IO, so it chains):

  ```crystal
  String.build do |io|
    io << "PUB " << subject << ' ' << payload.bytesize << "\r\n"
    io << payload << "\r\n"
  end
  ```

- **`String.new(bytesize) { |buffer| ... }`** writes directly into the string's backing
  buffer and returns `{bytesize, size}` — zero intermediate allocation. Use it when you know
  the size and the inner loop is hot:

  ```crystal
  # base-62 encode into a fixed 22-byte id, no temporaries
  def encode(seq : Int64) : String
    String.new(22) do |buffer|
      22.times { |i| buffer[21 - i] = DIGITS[seq % 62]; seq //= 62 }
      {22, 22}
    end
  end
  ```

- **Parse by byte offset in hot loops.** `split` allocates an array; `String#index` +
  range-slicing does not:

  ```crystal
  if sep = line.index(' ', start)
    subject = line[start...sep]   # no array allocated
  end
  ```

  Outside hot paths, prefer the readable `split` / iterator form.
- **`IO.pipe` gives you flow control for free.** Hand back the read end and write chunks into
  the write end; the OS's bounded buffer applies backpressure, so you never buffer a large
  payload in memory:

  ```crystal
  reader, writer = IO.pipe
  spawn do
    download_chunks { |chunk| writer.write(chunk) }
    writer.close
  end
  reader   # caller streams from here, lazily
  ```

---

## V. Collections & Iterators

Prefer fluent, lazy iterator chains over index loops. They read top-to-bottom as a data
pipeline and allocate intermediate arrays only when you force them with `.to_a`/`.to_h`.

```crystal
input.each_line                      # Iterator, lazy
  .map(&.split(',').map(&.to_i64))
  .each_combination(2)
  .max_of { |((x1, y1), (x2, y2))| (x2 - x1).abs * (y2 - y1).abs }
```

- **Reach for the rich stdlib verbs** before hand-rolling: `tally`, `transpose`,
  `each_cons_pair`, `each_combination`, `minmax`, `max_of`/`min_of`, `sum`/`product`,
  `accumulate`, `chunks`, `flat_map`, `compact_map`, `partition`.
- **`map`/`select`/`reject`/`reduce`** to transform, filter, accumulate. Use `each` only for
  genuine side effects. **Never** write a manual `i = 0; while i < arr.size` index loop when
  an iterator expresses it.
- **Tuples and NamedTuples** are stack-allocated value aggregates — perfect for returning a
  couple of values (`{x, y}`) or a small fixed record (`{name: "a", age: 1}`) without
  defining a type. Destructure them in block params and parallel assignment:
  `first, second = pair`.
- Use `Set(T)` for membership, `Deque(T)` for queues, `Hash(K, V)` with explicit value
  types — annotate empty literals so the compiler knows: `{} of String => Int32`.

---

## VI. Structs, Classes & Methods

### 1. Constructors and accessors

- **Shorthand initialize** assigns straight to ivars: `def initialize(@id : String, @name :
  String)`. No body needed.
- **`getter` / `setter` / `property`** generate accessors. Use `getter?` for boolean
  predicates (it generates `name?`). Declare `getter` and `setter` _separately_ (rather than
  `property`) when reads and writes need different docs or visibility.
- **Keyword args with a `*` separator** force named call sites for clarity:

  ```crystal
  def subscribe(subject : String, *, queue_group : String? = nil, &block)
  end

  subscribe("orders", queue_group: "workers") { |msg| handle(msg) }
  ```

  The option can't be a mystery positional.

### 2. Methods that read well

- **Composed method:** break logic into small, named methods, each at a single level of
  abstraction. If a method mixes business rules with byte-fiddling, split it.
- **Block-capture-to-ivar for callbacks,** returning `self` to chain:

  ```crystal
  def on_error(&@on_error : Exception -> Nil)
    self
  end

  client.on_error { |ex| Log.error(exception: ex) { "connection failed" } }
        .on_disconnect { reconnect! }
  ```

- **`private` liberally.** Mark internal helpers, and even nested helper types, `private`.
  Keep the public surface as small as the feature allows.

---

## VII. Modules, Namespacing & Composition

Crystal's answer to large systems is composition of focused modules, not deep inheritance.

- **One subsystem = an aggregator file + a directory.** `db.cr` requires `db/**`; the entry
  point is one deliberately ordered `require` list. Mirror this: `foo.cr` next to `foo/`.
- **Top-level aliases keep the public API short:**

  ```crystal
  # model.cr — a short public name for a deeply-namespaced type
  alias Model = DB::Model
  ```

- **Compose mixins over inheriting.** Build a type from single-responsibility concerns
  (each living in a `concerns/` folder) instead of a tall hierarchy:

  ```crystal
  abstract class Model
    include Connection
    include Table
    include Persistence
    include Querying
    include Validation
    include Callbacks
  end
  ```

- **`include` vs. `extend`.** `include` adds instance methods; `extend` adds class methods.
  The standard "class-method mixin" is a nested `module ClassMethods` that the host
  `extend`s.
- **Abstract base = the contract.** An `abstract class` with `abstract def` declares what
  subclasses must implement; the compiler enforces it:

  ```crystal
  abstract class Field::Base
    abstract def to_db(value) : ::DB::Any
    abstract def from_db_result_set(result_set : ::DB::ResultSet)
  end
  ```

- **`include Enumerable(T)`** + a `def each` gives your collection type `map`, `select`,
  `to_a`, and dozens more for free.
- **Namespace primitives when they collide.** When a type shadows a core one, reach the
  stdlib with `::`:

  ```crystal
  module DB::Field
    class String < Base          # shadows the stdlib String
      def to_db(value) : ::String?   # `::String` is the real one
        value.to_s
      end
    end
  end
  ```

- **Exceptions as a module of one-liners.** Group a subsystem's errors under a namespace,
  each a terse documented subclass; give one state only when a handler needs it:

  ```crystal
  module DB::Errors
    class EmptyResults < Exception; end
    class InvalidRecord < Exception
      getter record
      def initialize(@record)
        super(@record.errors.join(", "))
      end
    end
  end
  ```

---

## VIII. Macros & DSLs

Crystal metaprogramming is **compile-time code generation**, not Ruby's runtime
`method_missing`. Macros run in the compiler, emit real code, cost nothing at runtime, and
are fully type-checked. This is the language's superpower — and its sharpest edge.

### 1. The syntax

- `{{ ... }}` **pastes** an AST node into the output (interpolation).
- `{% ... %}` **evaluates** macro-language control flow (`{% for %}`, `{% if %}`, `{% raise
  %}`) and emits nothing itself.
- `@type` is the enclosing type; `.all_subclasses`, `.instance_vars`, `.annotation(...)`
  let you reflect over the program at compile time.

### 2. Generate code, validate at compile time

A DSL macro should both emit accessors and **reject misuse before the program runs**. Turn
"wrong usage" into a compile error with a precise message:

```crystal
macro field(name, type)
  {% if name.is_a?(NilLiteral) %}
    {% raise "field requires a name" %}
  {% end %}

  @{{ name.id }} : {{ type }}?
  def {{ name.id }} : {{ type }}?; @{{ name.id }}; end
  def {{ name.id }}! : {{ type }}; @{{ name.id }}.not_nil!; end   # non-nil accessor
  def {{ name.id }}=(@{{ name.id }} : {{ type }}?); end
end

field title, String   # generates #title, #title!, #title=
```

`{% raise %}` is the best feature you're not using: a typo becomes a compile error, not a
runtime surprise.

### 3. Hygiene and the lifecycle hooks

- **Fresh variables `%name`** avoid clobbering caller locals inside a generated block:

  ```crystal
  macro log_timing(&block)
    %start = Time.monotonic     # %start can't collide with a caller's `start`
    {{ block.body }}
    Log.info { "took #{Time.monotonic - %start}" }
  end
  ```

- **`macro included` / `macro inherited` / `macro finished`** are the lifecycle hooks. The
  `included`→`inherited` chain seeds each subclass's own class-level state; `macro finished`
  runs after the _whole program_ is parsed, so it's where you fold a registry of subclasses
  into one union:

  ```crystal
  abstract class Field::Base; end

  macro finished
    # every Field subclass, anywhere in the program, collapses into one type
    alias Any = Union({% for k in Field::Base.all_subclasses %} {{ k }}, {% end %} Nil)
  end
  ```

  Compile-time registries built from annotations + `macro finished` are the idiomatic plugin
  pattern: extensible, zero-cost, fully typed.

### 4. Block-context DSLs with `with ... yield`

To let a block call bare methods against a builder, evaluate it with `with builder yield`:

```crystal
def draw(&)
  with self yield self     # the block body can call `path`, `localized`, ... receiverless
end

routes.draw do
  path "/", HomeHandler, name: "home"
  path "/users/:id", UserHandler, name: "user"
end
```

### 5. When NOT to reach for a macro

Macros are harder to read and debug than methods. Prefer a **method** or a **generic** when
runtime values suffice. Use a macro only when you genuinely need to generate code, reflect
over types, or validate usage at compile time. Power for clarity, not for cleverness.

---

## IX. Concurrency

Crystal concurrency is fibers communicating over channels — CSP, not threads-and-locks.
Fibers are cheap and cooperatively scheduled; you rarely need a mutex.

- **`spawn` a fiber,** and **name long-lived ones** for debuggability:

  ```crystal
  spawn(name: "Client#begin_inbound") { begin_inbound }
  ```

- **`Channel(T)`** is the communication primitive. A one-shot buffered channel +
  `select`/`timeout` is the canonical request/response-with-deadline pattern:

  ```crystal
  channel = Channel(Message).new(1)
  # register a handler that does `channel.send(msg)` ...
  select
  when msg = channel.receive?
    msg
  when timeout(2.seconds)
    nil
  end
  ```

- **`Atomic(T)`** for lock-free counters and flags:

  ```crystal
  @current_sid = Atomic(Int64).new(0_i64)
  sid = @current_sid.add(1)   # no mutex
  ```

- **`Mutex` only for the genuinely-shared section,** and prefer a single, well-named one.
  Funnel every write through it and let a separate fiber flush, coalescing many small writes
  into few syscalls:

  ```crystal
  @out = Mutex.new
  @data_waiting = false

  private def write(&) : Nil
    @out.synchronize do
      yield                  # callers stream tokens straight into @io with <<
      @data_waiting = true   # the flush fiber wakes only when data is pending
    end
  end
  ```

- Keep mutable shared state tiny. The less there is, the less there is to synchronize.

---

## X. Errors & Logging

- **Custom exceptions** are a small class hierarchy: `class ClientClosed < Exception; end`.
  Raise them from bang methods.
- **Begin-less rescue.** A method body _is_ an implicit `begin`; attach `rescue`/`ensure`
  directly:

  ```crystal
  def write(&)
    @out.lock
    yield
  rescue ex : IO::Error
    handle_disconnect!
  ensure
    @out.unlock
  end
  ```

- **Log with `::Log.for`, message in a block.** The block is only evaluated when the level is
  active, so interpolation costs nothing when the log is silenced:

  ```crystal
  Log = ::Log.for(self)
  Log.trace { "received #{bytes} bytes for #{subject}" }
  ```

---

## XI. Testing

- **`crystal spec`.** The `spec/` tree mirrors `src/` exactly: `src/db/field/string.cr` →
  `spec/db/field/string_spec.cr`.
- **`describe` / `it`,** expectations with `should`:

  ```crystal
  describe Dial do
    it "wraps at 100" do
      Dial.new(50).rotate(60).value.should eq(10)
    end
  end
  ```

- Specs should be **quiet** (output only on failure) and **independent** (order-free). Use
  `before_each` for setup; keep each `it` focused on one behavior.

---

## XII. Tooling

- **`crystal tool format`** — formatting. `--check` in CI.
- **`crystal spec`** — tests.
- **`ameba`** — the community linter. Ship an `.ameba.yml` (e.g. line length 120, excluding
  `lib`/`tmp`) and gate CI on it. Disable a rule inline only with a reason:
  `# ameba:disable Layout/LineLength`.
- **`shards`** + `shard.yml` — dependencies and the build for any real project. (A throwaway
  script can skip the shard and just `crystal run file.cr` against the stdlib — but anything
  shared needs a `shard.yml`.)
- **Wrap the workflow in a `justfile`** (`just qa` → format check + lint + spec) so the same
  recipes run locally and in CI. Reach for `just`, not `make`.

---

## XIII. Summary Checklist for AI Generation

Before you finish a Crystal change, ask:

1. **Value or reference?** Did you reach for a `struct` (and `record`) for data, and only a
   `class` where you need shared identity or mutation?
2. **Enum or flag?** Did you replace string/bool modes with an `enum` and branch on
   `.foo?` predicates — ideally a `case ... in` for exhaustiveness?
3. **Typed surface, inferred interior?** Are public params/returns annotated while locals are
   left to the compiler?
4. **Nil handled, not silenced?** Did you bind-and-narrow (`if x = foo?`) instead of reaching
   for `not_nil!`?
5. **Streaming, not concatenating?** Are you building strings/output through one IO with
   `<<`, and parsing without needless intermediate arrays in hot paths?
6. **Conventions?** Predicates `?`, mutators/raisers `!`, `private` for internals, and did you
   run `crystal tool format`?
7. **Macro earned?** If you wrote a macro, did it need compile-time codegen/validation — or
   would a method have been clearer?

**Example — Ruby-in-Crystal vs. idiomatic Crystal:**

_Bad (Ruby habits, untyped, runtime flags, index loop):_

```crystal
class User
  def initialize(name, role)
    @name = name
    @role = role
  end

  def name; @name; end
  def is_admin; @role == "admin"; end
end

admins = [] of String
i = 0
while i < users.size
  admins << users[i].name if users[i].is_admin == true
  i += 1
end
```

_Idiomatic (value type, enum, getters, fluent iterators):_

```crystal
enum Role
  User
  Admin
end

struct User
  getter name : String
  getter role : Role

  def initialize(@name : String, @role : Role = :user)
  end

  def admin?
    role.admin?
  end
end

admins = users.select(&.admin?).map(&.name)
```
