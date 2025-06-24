# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Development Commands

- **Dependencies**: `mix deps.get`
- **Tests**: `mix test`
- **Test with coverage**: `mix coveralls` or `mix coveralls.github`
- **Dialyzer (type checking)**: `mix dialyzer`
- **Code quality**: `mix credo --strict`
- **Documentation**: `mix docs`
- **Full CI check**: `mix test && mix dialyzer && mix credo --strict`

## Architecture Overview

TypedEctoSchema is an Elixir library that provides a DSL on top of Ecto.Schema to define schemas with automatic typespec generation. The library eliminates boilerplate by automatically generating `@type t()` definitions and `@enforce_keys` from field definitions.

### Core Components

1. **TypedEctoSchema** (`lib/typed_ecto_schema.ex`): Main module providing `typed_schema/2-3` and `typed_embedded_schema/1-2` macros
2. **TypeBuilder** (`lib/typed_ecto_schema/type_builder.ex`): Handles typespec generation and field tracking using module attributes
3. **EctoTypeMapper** (`lib/typed_ecto_schema/ecto_type_mapper.ex`): Maps Ecto types to Elixir typespecs with proper nullable/association handling
4. **SyntaxSugar** (`lib/typed_ecto_schema/syntax_sugar.ex`): Transforms enhanced field definitions into standard Ecto calls plus typespec tracking

### Key Patterns

- **Macro Pipeline**: `typed_schema` → `prelude` → `inner` → `postlude` sequence
- **Module Attributes**: Uses `@__typed_ecto_schema_types__` and `@__typed_ecto_schema_enforced_keys__` to accumulate field information
- **AST Transformation**: `SyntaxSugar.apply_to_block/2` processes the schema block to intercept field definitions
- **Type Inference**: Automatic mapping from Ecto types to Elixir types with special handling for associations, embeds, and nullable fields

### Enhanced Field Options

- `:null` - Controls `| nil` in typespec (default: true)
- `:enforce` - Adds field to `@enforce_keys` (default: false)  
- `:: type()` - Override inferred typespec
- Schema-level `:enforce` and `:null` defaults

### Testing

Tests are comprehensive and include typespec validation. Use `mix test` to run the full suite. The library supports Elixir 1.9+ with OTP 24-27.