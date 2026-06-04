---
name: programming-go
description: Best practices when developing in Go codebases
---

# Programming Go

## Instructions

- Don't use `interface{}` -- use `any` instead

- Use the "-" tag when Marshalling JSON will cause the field to be omitted. Use this when we have private data on a field that’s meant to be excluded from an API response.

- Use the Go 1.22 syntax for `for` loops:

Write this:

```go
for i := range 10 {
    fmt.Println(i+1)
}
```

NOT THIS:

```go
for i := 1; i <= 10; i++ {
    fmt.Println(i)
}
```

- Use the Go 1.25 `waitgroup.Go` function that lets you add Go routines to a waitgroup more easily. It takes the place of using the go keyword, it looks like this:

```go
wg.Go(func() {
    // your goroutine code here
})
```

```go
The implementation is just a wrapper around this:
func (wg *WaitGroup) Go(f func()) {
    wg.Add(1)
    go func() {
        defer wg.Done()
        f()
    }()
}
```

### Renaming Packages

You can use Go’s LSP to rename packages, not just regular variables. The newly named package will be updated in all references. As a bonus, it even renames the directory!

### Package names

Good package names are short and clear. They are lower case, with no under_scores or mixedCaps. They are often simple nouns, such as:

- time (provides functionality for measuring and displaying time)
- list (implements a doubly linked list)
- http (provides HTTP client and server implementations)

The style of names typical of another language might not be idiomatic in a Go program. Here are two examples of names that might be good style in other languages but do not fit well in Go:

- computeServiceClient
- priority_queue

_Abbreviate judiciously_. Package names may be abbreviated when the abbreviation is familiar to the programmer. Widely-used packages often have compressed names:

- strconv (string conversion)
- syscall (system call)
- fmt (formatted I/O)

On the other hand, if abbreviating a package name makes it ambiguous or unclear, don’t do it.

Similarly, the function to make new instances of ring.Ring — which is the definition of a constructor in Go—would normally be called NewRing, but since Ring is the only type exported by the package, and since the package is called ring, it's called just New, which clients of the package see as ring.New. Use the package structure to help you choose good names.

Another short example is once.Do; once.Do(setup) reads well and would not be improved by writing once.DoOrWaitUntilDone(setup). Long names don't automatically make things more readable. A helpful doc comment can often be more valuable than an extra long name.

_Don’t steal good names from the user_. Avoid giving a package a name that is commonly used in client code. For example, the buffered I/O package is called bufio, not buf, since buf is a good variable name for a buffer.

## Command-line interfaces

- For Go CLIs, use `github.com/urfave/cli/v3` instead of the stdlib `flag` package when adding new commands or binaries in this repo.
- When building `urfave/cli` commands:
  - Define positional args with `Arguments` and `Destination`. Don't manually pull required args out of `cmd.Args()` inside `Action`.
  - Don't backfill positional `Destination` fields from `cmd.Args()`. Account for the parser lifecycle instead, and validate those destinations after argument parsing.
  - Initialize `Config` with its defaults in one place, then use the same field for both the flag's `Value` and `Destination`.
  - Put validation and setup that doesn't depend on parsed positional args in the command's `Before` hook. Keep `Action` focused on final validation and execution.
  - Prefer predicate methods on the command config, such as `HasAgentName`, for validation checks that describe config state.
- Keep CLI subcommands thin: they translate flags, args, and environment into focused internal packages. Put substantial subcommands in their own subpackages when the parent package gets crowded.

## Configuration and types

- When passing config into lower layers, prefer a small interface implemented by the caller's config type over copying fields into another near-identical struct.
- Keep user-facing configuration names provider-neutral when the provider detail can live behind a catalog, adapter, or backend-specific payload. Users should choose capabilities or abilities, not provider implementation paths.
- Avoid `any` and `map[string]any` in public or cross-package types when a more concrete type is possible. If an upstream JSON schema is still loose, define named wrapper types so the shape carries domain meaning.
- Avoid brittle nil normalization spread through business logic. Canonicalize at comparison or boundary points, and reach for current Go features where they clarify intent, such as `new(false)` for bool pointers.
- Model finite command/config domains with concrete enum types so `switch` exhaustiveness checks catch missing cases.
- Document exported types and exported struct fields with their expected behavior, defaults, and ownership.

## Validation, paths, and errors

- Validate path-like configuration before deriving new paths from it. Reject surprising input — globs, traversal, empty values, absolute paths — at the boundary and return a semantic error instead of constructing paths from unchecked strings.
- For validation failures that cross package boundaries, prefer exported concrete error types with fields and `Unwrap`/`Is` support so callers can inspect semantics.
- Use structured parsing helpers such as `net.SplitHostPort` for host and port handling instead of ad hoc string splitting, especially where IPv6 is possible.

## Concurrency

- Prefer `errgroup` over hand-rolled goroutine synchronization when concurrent work needs error propagation. (For fire-and-forget fan-out, the Go 1.25 `WaitGroup.Go` above is enough.)

## Logging and error handling

- Don't silently discard operational errors. Log recoverable runtime failures at the boundary that handles them; only ignore errors that are truly unhelpful or impossible, and make that choice clear.
- Use stdlib `log/slog` for new structured logs. Prefer context-aware calls and structured attributes such as `slog.Any("err", err)` over custom log writers or interpolated error strings.

## HTTP servers

- Use `http.Server.Shutdown(ctx)` with a bounded context for teardown instead of an abrupt `Close` when graceful shutdown is possible.

## Naming

- Avoid naming methods `Write` unless the type intentionally behaves like an `io.Writer`. Prefer domain verbs such as `Record`, `Render`, or `WriteProfile`.
- Use receiver names that match the receiver type — usually one or two letters — and keep them consistent across a type's methods.

## Package organization

- Split packages by concept when a file starts carrying multiple distinct public types, policies, loggers, transports, and helpers. Keep helpers near the bottom of their focused file.

## Performance

- Preallocate slices when appending from known inputs and the capacity is easy to compute, especially in aggregation code that combines catalog/config fragments with inline entries.

## Testing

- Use fixture files plus `embed` for non-trivial test inputs — TOML, SQL, JSON, request/response bodies. Avoid large inline fixture strings in test files.
- Put bulky test helpers and fakes in separate `*_test.go` helper files when they obscure the tests. Keep the test cases themselves near the top and easy to scan.
- Avoid `assert*` helpers that hide the expected behavior. Keep checks inline and left-aligned when that makes the happy path easier to scan.
- Use `cmp.Diff` for structured comparisons instead of several hand-written field checks when the diff will be easier to diagnose.
- Don't string-match errors in tests. Prefer `errors.Is` or `errors.As` with exported sentinel errors or concrete error types, especially when tests live outside the package.
- Test helpers should accept `testing.TB`, not only `*testing.T`, so they work for tests, benchmarks, and fuzz targets.
- Prefer external test packages, such as `package deployer_test`, when tests don't need unexported internals. This keeps package boundaries honest.
- Avoid wall-clock sleeps and short timeouts in tests. Prefer deterministic synchronization or `testing/synctest` when time must advance.
- Don't call `t.Fatal` or `FailNow` from goroutines or HTTP handler callbacks. Report with `t.Error` and return, or signal the test goroutine.
- Use Go build tags for OS-specific test files instead of runtime OS guards when the file shouldn't build or run on other platforms.

## Tooling

- Local developer workflows should be `just` recipes. Don't add shell scripts that only wrap `go run` — add a recipe instead.
