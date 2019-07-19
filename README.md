# TypedEctoSchema

TypedEctoSchema provides a DSL on top of `Ecto.Schema` to define schemas with typespecs without all
the boilerplate code.

There is still a lot of things to do, but soon I'll release this on hex.pm and add more details
here.

For now, for documentation, you can check the `typed_ecto_schema.ex` file here.

# TODO

- [x] Works with
  - [x] `schema` through `typed_schema` macro
  - [x] `embedded_schema` through `typed_embedded_schema` macro
- [x] Generate basic typespecs for:
  - [x] `field/1`, `field/2`, `field/3`
  - [x] `belongs_to/2`, `belongs_to/3`
  - [x] `has_many/2`, `has_many/3`
  - [x] `has_one/2`, `has_one/3`
  - [x] `embeds_one/2`, `embeds_one/3`
  - [x] `embeds_one/4` (inline)
  - [x] `embeds_many/2`, `embeds_many/3`
  - [x] `embeds_many/4` (inline)
  - [x] `@primary_key`
  - [x] `timestamps/0`, `timestamps/1`
  - [x] `__meta__`
- [x] Allows overriding types using `::` operator
- [x] Schema options:
  - [x] `enforce`
  - [x] `null`
  - [x] `opaque`
- [x] Schema options:
  - [x] `enforce`
  - [x] `null`
  - [x] `opaque`

## Credits

This project started as a fork of the awesome [`typed_struct`](github.com/ejpcmac/typed_struct).

That being said, I'd like to give some special thanks to

- [Jean-Philippe Cugnet](https://github.com/ejpcmac) for laying the ground for this work.
- [Carlos Brito Lage](https://github.com/cblage) for helping me with planning and ideas about the
  DSL.