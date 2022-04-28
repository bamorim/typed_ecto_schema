# TypedEctoSchema

[![Build Status](https://travis-ci.org/bamorim/typed_ecto_schema.svg?branch=master)](https://travis-ci.org/bamorim/typed_ecto_schema)

TypedEctoSchema provides a DSL on top of `Ecto.Schema` to define schemas with typespecs without all
the boilerplate code.

For example, if you want to add type information about your `Ecto.Schema`, you normally do something
like this:
```elixir
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
```

With `typed_ecto_schema` you can just do:

```elixir
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
```

## Usage

Install it, add to your deps:

```elixir
{:typed_ecto_schema, "~> 0.4.1", runtime: false}
```

And change your `use Ecto.Schema` for `use TypedEctoSchema` and change the calls to `schema` for
`typed_schema` and `embedded_schema` to `typed_embedded_schema`.

Check the [online documentation](https://hexdocs.pm/typed_ecto_schema) for further details.

## Credits

This project started as a fork of the awesome [`typed_struct`].

That being said, I'd like to give some special thanks to

- [Jean-Philippe Cugnet](https://github.com/ejpcmac) for laying the ground for this work.
- [Carlos Brito Lage](https://github.com/cblage) for helping me with planning and ideas about the
  DSL.

[`typed_struct`]: https://github.com/ejpcmac/typed_struct
