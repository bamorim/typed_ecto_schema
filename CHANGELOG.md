# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.5.0] - 2026-08-26

### Added

- Field documentation: fields accept a `:doc` option (always stripped before
  the underlying Ecto macro runs). Placing the
  `<!-- typed_ecto_schema: fields -->` marker in the module's `@moduledoc`
  replaces it at compile time with a markdown list of every field, its
  typespec and its doc — the marker is the only trigger, so without it the
  `:doc` options don't touch the `@moduledoc`. Independently of the marker,
  the generated `t/0` now gets a `@typedoc` with the same fields list when the
  module doesn't define one (a user-defined `@typedoc` is kept, with the same
  marker interpolation available)
  ([#68](https://github.com/bamorim/typed_ecto_schema/pull/68), closes
  [#41](https://github.com/bamorim/typed_ecto_schema/issues/41))
- Experimental: opt-in named types for `Ecto.Enum` fields via the
  `additional_types: true` schema option (per schema, e.g.
  `typed_schema "people", additional_types: true`) or the global default
  `config :typed_ecto_schema, additional_types: true`. Each enum field with
  statically-known values defines a public type with the union of its values,
  e.g. `@type role() :: :admin | :user`, usable from other modules' specs
  ([#63](https://github.com/bamorim/typed_ecto_schema/pull/63), closes
  [#39](https://github.com/bamorim/typed_ecto_schema/issues/39))
- Experimental: support for `polymorphic_embed`'s `polymorphic_embeds_one/2`
  and `polymorphic_embeds_many/2` inside `typed_schema` blocks, behind a
  compile-time flag (off by default):
  `config :typed_ecto_schema, polymorphic_embed: true`. The typespec is
  inferred as the union of the modules in the `:types` option, and the `::`
  override plus the `:null`/`:enforce` options are supported.
  `polymorphic_embed` does not become a dependency — the calls are matched by
  name ([#64](https://github.com/bamorim/typed_ecto_schema/pull/64), closes
  [#40](https://github.com/bamorim/typed_ecto_schema/issues/40))
- When both experimental features above are enabled, polymorphic embed fields
  also get a named type with the union of their `:types` modules, e.g.
  `@type channel() :: SMS.t() | Email.t()` (the element union for
  `polymorphic_embeds_many`; skipped when the types are not statically
  resolvable)

### Fixed

- Schema function options are no longer evaluated in the module body, so
  module aliases in pass-through options — e.g.
  `many_to_many(..., join_through: Book)` — no longer create compile-time
  dependencies (matching plain `Ecto.Schema`). Only the options the type
  builder actually reads are forwarded to it, and a compiler-tracer regression
  test guards against reintroducing such dependencies
  ([#67](https://github.com/bamorim/typed_ecto_schema/pull/67), closes
  [#38](https://github.com/bamorim/typed_ecto_schema/issues/38) and
  [#26](https://github.com/bamorim/typed_ecto_schema/issues/26))

## [0.4.4] - 2026-08-24

### Added

- `@primary_key` now accepts the enhanced `:null` and `:enforce` options to control
  the generated primary key typespec, e.g.
  `@primary_key {:id, :binary_id, autogenerate: true, null: false}`
  ([#61](https://github.com/bamorim/typed_ecto_schema/pull/61), closes
  [#42](https://github.com/bamorim/typed_ecto_schema/issues/42))
- `timestamps/1` now honors the enhanced `:null` and `:enforce` options, so
  `timestamps(null: false)` generates non-nullable timestamp typespecs
  ([#60](https://github.com/bamorim/typed_ecto_schema/pull/60), closes
  [#29](https://github.com/bamorim/typed_ecto_schema/issues/29))

### Fixed

- Compilation crash (`FunctionClauseError`) for `Ecto.Enum` fields with empty or
  non-literal `:values`: a `::` type override now always takes precedence over
  inference, and empty or non-literal values fall back to `any()` instead of
  crashing ([#62](https://github.com/bamorim/typed_ecto_schema/pull/62), closes
  [#57](https://github.com/bamorim/typed_ecto_schema/issues/57))
- Deprecation warnings and dependency incompatibilities on Elixir 1.19/1.20
  (`preferred_cli_env` moved to `def cli`, credo updated), thanks @saleyn
  ([#58](https://github.com/bamorim/typed_ecto_schema/pull/58))
- README example showed non-nullable timestamps; the actual (and intended)
  default is nullable
  ([#60](https://github.com/bamorim/typed_ecto_schema/pull/60))

### Changed

- CI now tests Elixir 1.14 through 1.20 with OTP 24 through 29
  ([#59](https://github.com/bamorim/typed_ecto_schema/pull/59))

## [0.4.3] and earlier

No changelog was kept up to and including 0.4.3. See the
[GitHub releases](https://github.com/bamorim/typed_ecto_schema/releases) and the
git history for what changed in earlier versions.

[Unreleased]: https://github.com/bamorim/typed_ecto_schema/compare/0.5.0...HEAD
[0.5.0]: https://github.com/bamorim/typed_ecto_schema/compare/0.4.4...0.5.0
[0.4.4]: https://github.com/bamorim/typed_ecto_schema/compare/0.4.3...0.4.4
[0.4.3]: https://github.com/bamorim/typed_ecto_schema/releases/tag/0.4.3
