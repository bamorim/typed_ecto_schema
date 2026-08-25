defmodule TypedEctoSchema do
  @moduledoc """
  TypedEctoSchema provides a DSL on top of `Ecto.Schema` to define schemas with typespecs without
  all the boilerplate code.

  ## Rationale

  Normally, when defining an `Ecto.Schema` you probably want to define:
    * the schema itself
    * the list of enforced keys (which helps reducing problems)
    * its associated type (`Ecto.Schema` doesn't define it for you)

  It ends up in something like this:
      defmodule Person do
        use Ecto.Schema

        @enforce_keys [:name]

        schema "people" do
          field(:name, :string)
          field(:age, :integer)
          field(:happy, :boolean, default: true)
          field(:phone, :string)
          belongs_to(:company, Company)
          timestamps(type: :naive_datetime_usec)
        end

        @type t() :: %__MODULE__{
                __meta__: Ecto.Schema.Metadata.t(),
                id: integer() | nil,
                name: String.t(),
                age: non_neg_integer() | nil,
                happy: boolean(),
                phone: String.t() | nil,
                company_id: integer() | nil,
                company: Company.t() | Ecto.Association.NotLoaded.t() | nil,
                inserted_at: NaiveDateTime.t() | nil,
                updated_at: NaiveDateTime.t() | nil
              }
      end

    This is problematic for a a lot of reasons, summing up:

    - A lot of repetition. Field names appear in 3 different places, so in order to understand one
      field, a reader needs to go up and down the code to get that.
    - Ecto has some "hidden" fields that are added behind the scenes to the struct, such as the
      primary key `id`, the foreign key `company_id`, the timestamps and the `__meta__` field for
      schemas. Knowing all those rules can be hard to remember and would probably be easily
      forgotten when changing the schema. Also, Ecto has strange types for associations and metadata that
      need to be remembered.

  All of this makes this process extremely repetitive and error prone. Sometimes, you want to
  enforce factory functions to control defaults in a better way, you would probably add all fields
  to `@enforce_keys`. This would make the `@enforce_keys` big and repetitive, once again.

  This module aims to help with that, by providing some syntax sugar that allow you to define this
  in a more compact way.

      defmodule Person do
        use TypedEctoSchema

        typed_schema "people" do
          field(:name, :string, enforce: true, null: false)
          field(:age, :integer) :: non_neg_integer() | nil
          field(:happy, :boolean, default: true, null: false)
          field(:phone, :string)
          belongs_to(:company, Company)
          timestamps(type: :naive_datetime_usec)
        end
      end

  This is way simpler and less error prone. There is a lot going under the hoods here.

  ## Extra Options

  All ecto macros are called under the hood with the options you pass, with exception of a few
  added options:

  - `:null` - when `true`, adds a `| nil` to the typespec. Default is `true`. Has no effect on
    `has_one/3` because it can always be `nil`. On `belongs_to/3` only add `| nil` to the
    underlying foreign key.
  - `:enforce` - when `true` adds the field to the `@enforce_keys`. Default is `false`
  - `:doc` - a documentation string for the field, rendered into the `@moduledoc` when it
    contains the fields marker (see the "Documenting Fields" section below). It is always
    stripped before the underlying Ecto macro runs.

  ## Schema Options

  When calling `typed_schema/3` or `typed_embedded_schema/2` you can pass some options, as
  defined:

  - `:null` - Set the default `:null` field option, which normally is true. Note that it is still
    can be overwritten by passing `:null` to the field itself.
    Also, `embeds_many` and `has_many` can never be null, because they are always initialized to
    empty string, so they never receive the `| nil` on the typespec.
    In addition to that, `has_one/3` and `belongs_to/3` always receive `| nil` because the related
    schema may be deleted from the repo so it is safe to always assume they can be `nil`.
  - `:enforce` - When `true`, enforces all fields unless they explicitly set `enforce: false` or
    defines a default (`default: value`), since it makes no sense to have a default value for an
    enforced field.
  - `:opaque` - When `true` makes the generated type `t` be an opaque type.
  - `:additional_types` - (Experimental) When `true`, defines a public named type for each
    `Ecto.Enum` and polymorphic embed field, which can be referenced from other modules' specs.
    Default is `false`, or the value of the `:additional_types` application config when set.
    See the section below.

  ## Additional Named Types (Experimental)

  > #### Experimental {: .warning}
  >
  > This feature is experimental and its behavior may change in future releases.

  When the `:additional_types` option is enabled, each `Ecto.Enum` field generates a public type
  named after the field, containing the union of its values:

      defmodule Person do
        use TypedEctoSchema

        typed_schema "people", additional_types: true do
          field(:role, Ecto.Enum, values: [:admin, :user])
        end
      end

  This defines `@type role() :: :admin | :user`, which can be referenced from other modules as
  `Person.role()`.

  For keyword values (`values: [foo: 1, bar: 2]`) the type is the union of the atom keys
  (`:foo | :bar`). For `{:array, Ecto.Enum}` fields the named type is also the union of the
  element values, since that is what is useful in other specs.

  Instead of enabling it per schema, it can also be enabled globally through compile-time
  application config, with the schema-level option still taking precedence in both directions:

      # config/config.exs
      config :typed_ecto_schema, additional_types: true

  Like the `:polymorphic_embed` flag (see below), it is read via `Application.compile_env/4`, so
  it must be set in compile-time config (`config.exs`, not `runtime.exs`).

  When the PolymorphicEmbed integration is enabled (see the section below),
  `polymorphic_embeds_one/2` and `polymorphic_embeds_many/2` fields also generate a named type,
  containing the union of the modules in their `:types` option:

      typed_schema "reminders", additional_types: true do
        polymorphic_embeds_one(:channel,
          types: [sms: SMS, email: Email],
          on_replace: :update
        )
      end

  This defines `@type channel() :: SMS.t() | Email.t()`. As with `{:array, Ecto.Enum}`,
  `polymorphic_embeds_many/2` also generates the union of the element types (without the
  `list(...)` wrapper).

  Some fields are silently skipped:

  - fields that are neither `Ecto.Enum` nor polymorphic embeds;
  - `Ecto.Enum` fields whose `:values` cannot be resolved to a list of atoms at compile time;
  - polymorphic embed fields whose `:types` modules cannot be resolved at compile time;
  - fields named `t`, since the type would conflict with the schema's own `t/0`.

  Note that a generated type can still collide with another type defined in the module (a field
  named after a user-defined type, or after a built-in type such as `node`). In that case the
  compiler errors naturally with a "type is already defined" message and you can either rename
  the field or disable the option and define the type manually.

  ## Documenting Fields

  Fields accept a `:doc` option with a documentation string. To render the collected docs,
  put the `<!-- typed_ecto_schema: fields -->` marker anywhere in the module's `@moduledoc`
  and it is replaced at compile time with a markdown list describing every field:

      defmodule Person do
        @moduledoc \"\"\"
        A person.

        ## Fields

        <!-- typed_ecto_schema: fields -->
        \"\"\"

        use TypedEctoSchema

        typed_schema "people" do
          field(:name, :string, null: false, doc: "The person's full name")
          field(:age, :integer)
        end
      end

  This generates documentation equivalent to:

      @moduledoc \"\"\"
      A person.

      ## Fields

      - `id` (`integer() | nil`)
      - `name`: The person's full name (`String.t()`)
      - `age` (`integer() | nil`)
      \"\"\"

  Some details:

  - The marker is the only trigger: without it (or without a `@moduledoc`), the `:doc`
    options are simply ignored. Since the marker is an HTML comment, it is invisible in
    rendered documentation even when left unreplaced.
  - The marker is replaced by the list alone, without any heading, so the surrounding
    structure (headings, placement) is entirely yours.
  - The list includes all fields with their typespecs, whether they have a `:doc` or not,
    including the generated ones (the primary key, `belongs_to` foreign keys and
    timestamps). The internal `__meta__` field is skipped.
  - The `@moduledoc` must be defined before the `typed_schema` call (its conventional
    position at the top of the module).
  - The `:doc` option is accepted everywhere `:null` and `:enforce` are: `field/3`,
    associations, embeds, polymorphic embeds and the `@primary_key` attribute.

  ### The generated `@typedoc`

  Independently of the marker, the generated `t/0` type gets a `@typedoc` containing a
  "Fields" heading and the same list — for the example above, equivalent to:

      @typedoc \"\"\"
      ## Fields

      - `id` (`integer() | nil`)
      - `name`: The person's full name (`String.t()`)
      - `age` (`integer() | nil`)
      \"\"\"

  This happens for every schema, whether or not any field has a `:doc`, so field docs are
  never lost: they show up in `t Person.t()` in IEx, on hover in editors, and on the type
  itself in the generated documentation. It only happens when the module defines no
  `@typedoc` of its own: a `@typedoc` defined before the schema block is kept (with the
  marker interpolated in it the same way as in the `@moduledoc`), and `@typedoc false` is
  respected.

  ## Type Inference

  TypedEctoSchema does its best job to guess the typespec for the field. It does so by following
  the Elixir types as defined in [`Ecto.Schema`](https://hexdocs.pm/ecto/Ecto.Schema.html#module-primitive-types).
  For custom `Ecto.Type` and related schemas (embedded and associations), which are always a
  module, it assumes the schemas has a type `t/0` defined, so for a schema called `MySchema`, it
  will assume the type is `MySchema.t/0`, which is also, the default type generated by this
  library.

  ## Overriding the Typespec for a field

  If for somereason you want to narrow the type or the automatic type inference is incorrect,
  the `::` operator allows the typespec to be overriden.
  This is done as you would when defining typespecs.

  So, for example, instead of

  ```elixir
  field(:my_int, :integer)
  ```

  Which would generate a `integer() | nil` typespec, you can:

  ```elixir
  field(:my_int, :integer) :: non_neg_integer() | nil
  ```

  And then have a `non_neg_integer()` type for it.

  ## Integration with PolymorphicEmbed (experimental)

  The `polymorphic_embeds_one/2` and `polymorphic_embeds_many/2` macros from the
  [`polymorphic_embed`](https://hexdocs.pm/polymorphic_embed) library are supported behind a
  compile-time flag, disabled by default:

      # config/config.exs
      config :typed_ecto_schema, polymorphic_embed: true

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

      typed_schema "reminders" do
        polymorphic_embeds_one(:channel,
          types: [sms: SMS, email: Email],
          on_replace: :update
        )
      end

  This generates `channel: (SMS.t() | Email.t()) | nil`. `polymorphic_embeds_many/2` generates
  a list of the union instead (and, as usual for "many" fields, never receives `| nil`). Both
  the `types: [name: Module]` and the `types: [name: [module: Module, ...]]` forms are
  supported, as are the `::` type override and the `:null` and `:enforce` options:

      polymorphic_embeds_one(:channel,
        types: [sms: SMS, email: Email],
        on_replace: :update
      ) :: SMS.t() | Email.t()

  `:null` and `:enforce` behave exactly like they do for `field/3` (and are stripped before
  the real `polymorphic_embed` macro runs, since it rejects unknown options). So the
  following generates a `SMS.t() | Email.t()` typespec (without `| nil`) and adds `:channel`
  to `@enforce_keys`:

      polymorphic_embeds_one(:channel,
        types: [sms: SMS, email: Email],
        on_replace: :update,
        null: false,
        enforce: true
      )

  As with `embeds_many/3`, `:null` has no effect on `polymorphic_embeds_many/2`, since it is
  always initialized to an empty list.

  When the `:types` option cannot be resolved at compile time (for example, when it is a module
  attribute), the type falls back to `any()`.

  Since `polymorphic_embed` is not a dependency of this library, you still need to add it to
  your own deps and import it in your schema modules yourself.

  ## Non explicit generated fields

  Ecto generates some fields for you in a lot of cases, they are:

  - For primary keys
  - When using a `belongs_to/3`
  - When calling `timestamps/1`

  The `__meta__` typespec is automatically generated and cannot be overriden. That is because
  there is no point on overriding it.

  ### Primary Keys

  Primary keys are generated by default and can be customized by the `@primary_key` module
  attribute, just as defined by Ecto. We handle `@primary_key` the same way we handle `field/3`, so you
  can pass the same field options to it, including the extra `:null` and `:enforce` options
  (they are stripped before Ecto sees them):

  ```elixir
  @primary_key {:id, :binary_id, autogenerate: true, null: false}
  ```

  However, if you want to customize the type, you need to set `@primary_key false` and define a
  field with `primary_key: true`.

  ### Belongs To

  `belongs_to` generates an underlying foreign key that is dependent on a few Ecto options, as
  defined on [`Ecto.Schema`](https://hexdocs.pm/ecto/Ecto.Schema.html#belongs_to/3-options).

  The options we are interested in are `:foreign_key`, `:define_field` and `:type`

  When `:null` is passed,  it will add `| nil` to the generated `foreign_key`'s typespec.

  The `:enforce` option enforces the association field instead.
  If you want to `:enforce` the foreign key to be set, you should probably pass `define_field:
  false` and define the foreign key by hand, setting another `field/3`, the same way as
  described by Ecto's doc.

  ### Timestamps

  In the case of the timestamps, we currently don't allow overriding the type by using the `::` operator.
  That being said, however, we define the type of the fields using the `:type` option
  ([as defined by Ecto doc](https://hexdocs.pm/ecto/Ecto.Schema.html#timestamps/1-options))

  The timestamp fields are nullable by default, since a struct that was not inserted yet has `nil`
  timestamps. You can pass the `:null` and `:enforce` options to override that:

      timestamps(null: false)
  """

  alias TypedEctoSchema.SyntaxSugar
  alias TypedEctoSchema.TypeBuilder

  @doc false
  defmacro __using__(_) do
    quote do
      import TypedEctoSchema,
        only: [
          typed_embedded_schema: 1,
          typed_embedded_schema: 2,
          typed_schema: 2,
          typed_schema: 3
        ]

      use Ecto.Schema
    end
  end

  @doc """
  Replaces `Ecto.Schema.embedded_schema/1`
  """
  defmacro typed_embedded_schema(opts \\ [], do: block) do
    quote do
      unquote(prelude(opts))

      Ecto.Schema.embedded_schema do
        unquote(inner(block, __CALLER__))
      end

      unquote(postlude(opts))
    end
  end

  @doc """
  Replaces `Ecto.Schema.schema/2`
  """
  defmacro typed_schema(table_name, opts \\ [], do: block) do
    quote do
      unquote(prelude(opts))

      unquote(TypeBuilder).add_meta(__MODULE__)

      Ecto.Schema.schema unquote(table_name) do
        unquote(inner(block, __CALLER__))
      end

      unquote(postlude(opts))
    end
  end

  defp prelude(opts) do
    quote do
      require unquote(TypeBuilder)
      unquote(TypeBuilder).init(unquote(opts))
      unquote(TypeBuilder).strip_primary_key_opts(__MODULE__)
    end
  end

  defp inner(block, env) do
    quote do
      unquote(TypeBuilder).add_primary_key(__MODULE__)
      unquote(SyntaxSugar.apply_to_block(block, env))
      unquote(TypeBuilder).enforce_keys()
    end
  end

  defp postlude(opts) do
    quote do
      unquote(TypeBuilder).define_type(unquote(opts))
    end
  end
end
