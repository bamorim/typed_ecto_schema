# Experimental Features

These features are opt-in and experimental: their behavior may change in future releases.

## Additional Named Types

> #### Experimental {: .warning}
>
> This feature is experimental and its behavior may change in future releases.

When the `:additional_types` option is enabled, each `Ecto.Enum` field generates a public type
named after the field, containing the union of its values:

```elixir
defmodule Person do
  use TypedEctoSchema

  typed_schema "people", additional_types: true do
    field(:role, Ecto.Enum, values: [:admin, :user])
  end
end

```
This defines `@type role() :: :admin | :user`, which can be referenced from other modules as
`Person.role()`.

For keyword values (`values: [foo: 1, bar: 2]`) the type is the union of the atom keys
(`:foo | :bar`). For `{:array, Ecto.Enum}` fields the named type is also the union of the
element values, since that is what is useful in other specs.

> #### List fields generate the element type {: .warning}
>
> The type is named after the field, but for list fields it represents a **single element**,
> not the list. Since list fields usually have plural names, the name can be misleading:
>
>     field(:roles, {:array, Ecto.Enum}, values: [:admin, :user])
>
> defines `@type roles() :: :admin | :user` — the type of one role. When you need the list
> type, write `list(Person.roles())`. The same applies to `polymorphic_embeds_many/2` fields
> (see below).

Instead of enabling it per schema, it can also be enabled globally through compile-time
application config, with the schema-level option still taking precedence in both directions:

```elixir
# config/config.exs
config :typed_ecto_schema, additional_types: true

```
Like the `:polymorphic_embed` flag (see below), it is read via `Application.compile_env/4`, so
it must be set in compile-time config (`config.exs`, not `runtime.exs`).

When the PolymorphicEmbed integration is enabled (see the section below),
`polymorphic_embeds_one/2` and `polymorphic_embeds_many/2` fields also generate a named type,
containing the union of the modules in their `:types` option:

```elixir
typed_schema "reminders", additional_types: true do
  polymorphic_embeds_one(:channel,
    types: [sms: SMS, email: Email],
    on_replace: :update
  )
end

```
This defines `@type channel() :: SMS.t() | Email.t()`. As with `{:array, Ecto.Enum}`,
`polymorphic_embeds_many/2` also generates the union of the element types (without the
`list(...)` wrapper) — so a plural field like `:channels` defines
`@type channels() :: SMS.t() | Email.t()`, the type of a single channel.

Some fields are silently skipped:

- fields that are neither `Ecto.Enum` nor polymorphic embeds;
- `Ecto.Enum` fields whose `:values` cannot be resolved to a list of atoms at compile time;
- polymorphic embed fields whose `:types` modules cannot be resolved at compile time;
- fields named `t`, since the type would conflict with the schema's own `t/0`.

Note that a generated type can still collide with another type defined in the module (a field
named after a user-defined type, or after a built-in type such as `node`). In that case the
compiler errors naturally with a "type is already defined" message and you can either rename
the field or disable the option and define the type manually.

## PolymorphicEmbed Integration

The `polymorphic_embeds_one/2` and `polymorphic_embeds_many/2` macros from the
[`polymorphic_embed`](https://hexdocs.pm/polymorphic_embed) library are supported behind a
compile-time flag, disabled by default:

```elixir
# config/config.exs
config :typed_ecto_schema, polymorphic_embed: true

```
The integration recognizes the calls purely by name (so that `polymorphic_embed` never
becomes a dependency of this library). The flag exists because another library could define
same-named macros with different behavior, which the integration would then break — enable
it only if you use `polymorphic_embed`. With the flag disabled, these calls behave exactly
as they did before the integration existed. The flag is read at compile time via
`Application.compile_env/4`, so it must be set in compile-time config (`config.exs`, not
`runtime.exs`) and requires Elixir 1.14+. This integration is experimental and its behavior
may change in a future release.

Once enabled, the typespec is inferred as the union of the modules listed in the `:types`
option:

```elixir
typed_schema "reminders" do
  polymorphic_embeds_one(:channel,
    types: [sms: SMS, email: Email],
    on_replace: :update
  )
end

```
This generates `channel: (SMS.t() | Email.t()) | nil`. `polymorphic_embeds_many/2` generates
a list of the union instead (and, as usual for "many" fields, never receives `| nil`). Both
the `types: [name: Module]` and the `types: [name: [module: Module, ...]]` forms are
supported, as are the `::` type override and the `:null` and `:enforce` options:

```elixir
polymorphic_embeds_one(:channel,
  types: [sms: SMS, email: Email],
  on_replace: :update
) :: SMS.t() | Email.t()

```
`:null` and `:enforce` behave exactly like they do for `field/3` (and are stripped before
the real `polymorphic_embed` macro runs, since it rejects unknown options). So the
following generates a `SMS.t() | Email.t()` typespec (without `| nil`) and adds `:channel`
to `@enforce_keys`:

```elixir
polymorphic_embeds_one(:channel,
  types: [sms: SMS, email: Email],
  on_replace: :update,
  null: false,
  enforce: true
)

```
As with `embeds_many/3`, `:null` has no effect on `polymorphic_embeds_many/2`, since it is
always initialized to an empty list.

When the `:types` option cannot be resolved at compile time (for example, when it is a module
attribute), the type falls back to `any()`.

Since `polymorphic_embed` is not a dependency of this library, you still need to add it to
your own deps and import it in your schema modules yourself.
