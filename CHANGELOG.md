# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.5.0] - 2026-08-24

### Added

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
