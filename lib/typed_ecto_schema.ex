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
                inserted_at: NaiveDateTime.t(),
                updated_at: NaiveDateTime.t()
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
  - `:type_check` - Enable [experimental integration with
    TypeCheck](#module-typecheck-integration-experimental)

  ## TypeCheck Integration (Experimental)

  We are currently experimenting with a [TypeCheck](https://hexdocs.pm/type_check/) integration,
  but because it might break, we are making it opt-in. You can either specify on the
  [schema options](#module-schema-options) or globally using config:

      config :typed_ecto_schema, type_check: true

  What this integration enables is that by doing

      defmodule InteropWithTypeCheck do
        use TypedEctoSchema
        use TypeCheck

        typed_embedded_schema type_check: true do
          field(:year, :number)
        end
      end

  You then should be able to

      iex> InteropWithTypeCheck.t()
      #TypeCheck.Type< InteropWithTypeCheck.t() :: %InteropWithTypeCheck{id: binary() | nil, year: integer() | nil} >

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
  can pass the same field options to it.

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
