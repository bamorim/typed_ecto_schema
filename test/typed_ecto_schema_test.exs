defmodule TypedEctoSchemaTest do
  use ExUnit.Case

  alias Ecto.Association.NotLoaded
  alias Ecto.Schema.Metadata

  # Store the bytecode so we can get information from it.
  defmodule Embedded do
    use TypedEctoSchema

    typed_embedded_schema do
      field(:int, :integer)
    end
  end

  defmodule HasOne do
    use TypedEctoSchema

    typed_schema "has_one" do
      field(:table_id, :integer)
    end
  end

  defmodule HasMany do
    use TypedEctoSchema

    typed_schema "has_many" do
      field(:table_id, :integer)
    end
  end

  defmodule BelongsTo do
    use TypedEctoSchema

    typed_schema "belongs" do
      field(:int, :integer)
    end
  end

  defmodule ManyToMany do
    use TypedEctoSchema

    typed_schema "many_to_many" do
      field(:int, :integer)
    end
  end

  {:module, _name, bytecode, _exports} =
    defmodule TestStruct do
      use TypedEctoSchema

      typed_schema "table" do
        field(:int, :integer)
        field(:string)
        field(:non_nullable_string, :string, null: false)
        field(:enforced_int, :integer, enforce: true)
        field(:overriden_type, :integer) :: 1 | 2 | 3
        field(:overriden_string) :: any()
        field(:enum_type1, Ecto.Enum, values: [:foo1])
        field(:enum_type2, Ecto.Enum, values: [:foo1, :foo2])
        field(:enum_type3, Ecto.Enum, values: [:foo1, :foo2, :foo3])
        field(:enum_type_with_ints, Ecto.Enum, values: [foo1: 0, foo2: 1, foo3: 2])
        field(:enum_type_required, Ecto.Enum, values: [:foo1, :foo2, :foo3], null: false)
        embeds_one(:embed, Embedded)
        embeds_many(:embeds, Embedded)
        has_one(:has_one, HasOne)
        has_many(:has_many, HasMany)
        belongs_to(:belongs_to, BelongsTo)
        many_to_many(:many_to_many, ManyToMany, join_through: "join_table")
        timestamps()
      end

      def enforce_keys, do: @enforce_keys

      def get_types, do: Enum.reverse(@__typed_ecto_schema_types__)
    end

  {:module, _name, bytecode_opaque, _exports} =
    defmodule OpaqueTestStruct do
      use TypedEctoSchema

      @primary_key false
      typed_embedded_schema opaque: true do
        field(:int, :integer)
      end
    end

  defmodule EnforcedTypedEctoSchema do
    use TypedEctoSchema

    @primary_key false
    typed_embedded_schema enforce: true do
      field(:enforced_by_default, :integer)
      field(:not_enforced, :integer, enforce: false)
      field(:with_default, :integer, default: 1)
      field(:with_false_default, :boolean, default: false)
    end

    def enforce_keys, do: @enforce_keys
  end

  defmodule NotNullTypedEctoSchema do
    use TypedEctoSchema

    typed_schema "table", null: false do
      field(:normal, :integer)
      field(:enforced, :integer, enforce: false)
      field(:overriden, :integer, null: true)
      has_one(:has_one, HasOne)
      belongs_to(:belongs_to, BelongsTo)
      has_many(:has_many, HasMany)
    end

    def get_types, do: Enum.reverse(@__typed_ecto_schema_types__)
  end

  defmodule NullAssocTypedEctoSchema do
    use TypedEctoSchema

    typed_schema "table" do
      has_one(:has_one0, HasOne)
      has_one(:has_one1, HasOne, null: false)
      belongs_to(:belongs_to0, BelongsTo)
      belongs_to(:belongs_to1, BelongsTo, null: false)
      has_many(:has_many0, HasMany)
      has_many(:has_many1, HasMany, null: false)
      many_to_many(:many_to_many0, ManyToMany, join_through: "join_table")
      many_to_many(:many_to_many1, ManyToMany, join_through: "join_table", null: false)
    end

    def get_types, do: Enum.reverse(@__typed_ecto_schema_types__)
  end

  defmodule LotsOfBelonging do
    use TypedEctoSchema

    @primary_key false
    typed_schema "table" do
      belongs_to(:normal, BelongsTo)
      belongs_to(:with_custom_fk, BelongsTo, foreign_key: :custom_fk)
      belongs_to(:custom_type, BelongsTo, type: :binary_id)
      belongs_to(:no_define, BelongsTo, define_field: false)
    end

    def get_types, do: Enum.reverse(@__typed_ecto_schema_types__)
  end

  defmodule GloballyConfiguredKeys do
    use TypedEctoSchema

    @primary_key {:id, :binary_id, read_after_writes: true}
    @foreign_key_type :binary_id
    typed_schema "table" do
      belongs_to(:normal, BelongsTo)
      belongs_to(:custom_type, BelongsTo, type: :integer)
      belongs_to(:no_define, BelongsTo, define_field: false)
    end

    def get_types, do: Enum.reverse(@__typed_ecto_schema_types__)
  end

  @bytecode bytecode
  @bytecode_opaque bytecode_opaque

  # Standard struct name used when comparing generated types.
  @standard_struct_name TypedEctoSchemaTest.TestStruct

  ## Standard cases

  test "generates an Ecto.Schema" do
    assert TestStruct.__schema__(:fields) == [
             :id,
             :int,
             :string,
             :non_nullable_string,
             :enforced_int,
             :overriden_type,
             :overriden_string,
             :enum_type1,
             :enum_type2,
             :enum_type3,
             :enum_type_with_ints,
             :enum_type_required,
             :embed,
             :embeds,
             :belongs_to_id,
             :inserted_at,
             :updated_at
           ]
  end

  test "generates the struct with its defaults" do
    assert TestStruct.__struct__() == %TestStruct{
             id: nil,
             int: nil,
             string: nil,
             non_nullable_string: nil,
             enforced_int: nil,
             overriden_type: nil,
             overriden_string: nil,
             embed: nil,
             embeds: [],
             has_many: %unquote(NotLoaded){
               __field__: :has_many,
               __owner__: TestStruct,
               __cardinality__: :many
             },
             has_one: %unquote(NotLoaded){
               __field__: :has_one,
               __owner__: TestStruct,
               __cardinality__: :one
             },
             belongs_to_id: nil,
             belongs_to: %unquote(NotLoaded){
               __field__: :belongs_to,
               __owner__: TestStruct,
               __cardinality__: :one
             }
           }
  end

  test "enforces keys for fields with `enforce: true`" do
    assert TestStruct.enforce_keys() == [:enforced_int]
  end

  test "enforces keys by default if `enforce: true` is set at top-level" do
    assert :enforced_by_default in EnforcedTypedEctoSchema.enforce_keys()
  end

  test "does not enforce keys for fields explicitely setting `enforce: false" do
    refute :not_enforced in EnforcedTypedEctoSchema.enforce_keys()
  end

  test "does not enforce keys for fields with a default value" do
    refute :with_default in EnforcedTypedEctoSchema.enforce_keys()
  end

  test "does not enforce keys for fields with a default value set to `false`" do
    refute :with_false_default in EnforcedTypedEctoSchema.enforce_keys()
  end

  test "generates a type for the struct" do
    # Define a second struct with the type expected for TestStruct.
    {:module, _name, bytecode2, _exports} =
      defmodule TestStruct2 do
        use Ecto.Schema

        schema "table" do
          field(:int, :integer)
          field(:string)
          field(:non_nullable_string, :string, default: "default")
          field(:enforced_int, :integer)
          field(:overriden_type, :integer)
          field(:overriden_string)
          field(:enum_type1, Ecto.Enum, values: [:foo1])
          field(:enum_type2, Ecto.Enum, values: [:foo1, :foo2])
          field(:enum_type3, Ecto.Enum, values: [:foo1, :foo2, :foo3])
          field(:enum_type_with_ints, Ecto.Enum, values: [foo1: 0, foo2: 1, foo3: 2])
          field(:enum_type_required, Ecto.Enum, values: [:foo1, :foo2, :foo3], null: false)
          embeds_one(:embed, Embedded)
          embeds_many(:embeds, Embedded)
          has_one(:has_one, HasOne)
          has_many(:has_many, HasMany)
          belongs_to(:belongs_to, BelongsTo)
          many_to_many(:many_to_many, ManyToMany, join_through: "join_table")
          timestamps()
        end

        @type t() :: %__MODULE__{
                __meta__: unquote(Metadata).t(),
                id: integer() | nil,
                int: integer() | nil,
                string: String.t() | nil,
                non_nullable_string: String.t(),
                enforced_int: integer() | nil,
                overriden_type: 1 | 2 | 3,
                overriden_string: any(),
                enum_type1: :foo1 | nil,
                enum_type2: (:foo1 | :foo2) | nil,
                enum_type3: (:foo1 | :foo2 | :foo3) | nil,
                enum_type_with_ints: (:foo1 | :foo2 | :foo3) | nil,
                enum_type_required: :foo1 | :foo2 | :foo3,
                embed: Embedded.t() | nil,
                embeds: list(Embedded.t()),
                has_one: unquote(Ecto.Schema).has_one(HasOne.t()) | nil,
                has_many: unquote(Ecto.Schema).has_many(HasMany.t()),
                belongs_to: unquote(Ecto.Schema).belongs_to(BelongsTo.t()) | nil,
                belongs_to_id: integer() | nil,
                many_to_many: unquote(Ecto.Schema).many_to_many(ManyToMany.t()),
                inserted_at: unquote(NaiveDateTime).t() | nil,
                updated_at: unquote(NaiveDateTime).t() | nil
              }
      end

    # Get both types and standardise them (remove line numbers and rename
    # the second struct with the name of the first one).
    type1 = @bytecode |> extract_first_type() |> standardise()

    type2 =
      bytecode2
      |> extract_first_type()
      |> standardise(TypedEctoSchemaTest.TestStruct2)

    assert type1 == type2
  end

  test "generates an opaque type if `opaque: true` is set" do
    # Define a second struct with the type expected for TestStruct.
    {:module, _name, bytecode_expected, _exports} =
      defmodule TestStruct3 do
        defstruct [:int]

        @opaque t() :: %__MODULE__{
                  int: integer() | nil
                }
      end

    # Get both types and standardise them (remove line numbers and rename
    # the second struct with the name of the first one).
    type1 =
      @bytecode_opaque
      |> extract_first_type(:opaque)
      |> standardise(TypedEctoSchemaTest.OpaqueTestStruct)

    type2 =
      bytecode_expected
      |> extract_first_type(:opaque)
      |> standardise(TypedEctoSchemaTest.TestStruct3)

    assert type1 == type2
  end

  test "generates a function to get the struct types" do
    types =
      quote do
        [
          __meta__: unquote(Metadata).t(),
          id: integer() | nil,
          int: integer() | nil,
          string: unquote(String).t() | nil,
          non_nullable_string: unquote(String).t(),
          enforced_int: integer() | nil,
          overriden_type: 1 | 2 | 3,
          overriden_string: any(),
          enum_type1: :foo1 | nil,
          enum_type2: (:foo1 | :foo2) | nil,
          enum_type3: (:foo1 | :foo2 | :foo3) | nil,
          enum_type_with_ints: (:foo1 | :foo2 | :foo3) | nil,
          enum_type_required: :foo1 | :foo2 | :foo3,
          embed: Embedded.t() | nil,
          embeds: list(Embedded.t()),
          has_one: unquote(Ecto.Schema).has_one(HasOne.t()) | nil,
          has_many: unquote(Ecto.Schema).has_many(HasMany.t()),
          belongs_to: unquote(Ecto.Schema).belongs_to(BelongsTo.t()) | nil,
          belongs_to_id: integer() | nil,
          many_to_many: unquote(Ecto.Schema).many_to_many(ManyToMany.t()),
          inserted_at: unquote(NaiveDateTime).t() | nil,
          updated_at: unquote(NaiveDateTime).t() | nil
        ]
      end

    assert delete_context(TestStruct.get_types()) ==
             delete_context(types)
  end

  test "nulls can be specified by default" do
    types =
      quote do
        [
          __meta__: unquote(Metadata).t(),
          id: integer(),
          normal: integer(),
          enforced: integer(),
          overriden: integer() | nil,
          has_one: unquote(Ecto.Schema).has_one(HasOne.t()),
          belongs_to: unquote(Ecto.Schema).belongs_to(BelongsTo.t()),
          belongs_to_id: integer(),
          has_many: unquote(Ecto.Schema).has_many(HasMany.t())
        ]
      end

    assert delete_context(NotNullTypedEctoSchema.get_types()) ==
             delete_context(types)
  end

  test "nulls for belongs to and has one" do
    types =
      quote do
        [
          __meta__: unquote(Metadata).t(),
          id: integer() | nil,
          has_one0: unquote(Ecto.Schema).has_one(HasOne.t()) | nil,
          has_one1: unquote(Ecto.Schema).has_one(HasOne.t()),
          belongs_to0: unquote(Ecto.Schema).belongs_to(BelongsTo.t()) | nil,
          belongs_to0_id: integer() | nil,
          belongs_to1: unquote(Ecto.Schema).belongs_to(BelongsTo.t()),
          belongs_to1_id: integer(),
          has_many0: unquote(Ecto.Schema).has_many(HasMany.t()),
          has_many1: unquote(Ecto.Schema).has_many(HasMany.t()),
          many_to_many0: unquote(Ecto.Schema).many_to_many(ManyToMany.t()),
          many_to_many1: unquote(Ecto.Schema).many_to_many(ManyToMany.t())
        ]
      end

    assert delete_context(NullAssocTypedEctoSchema.get_types()) ==
             delete_context(types)
  end

  test "globally configured keys" do
    types =
      quote do
        [
          __meta__: unquote(Metadata).t(),
          id: binary() | nil,
          normal: unquote(Ecto.Schema).belongs_to(BelongsTo.t()) | nil,
          normal_id: binary() | nil,
          custom_type: unquote(Ecto.Schema).belongs_to(BelongsTo.t()) | nil,
          custom_type_id: integer() | nil,
          no_define: unquote(Ecto.Schema).belongs_to(BelongsTo.t()) | nil
        ]
      end

    assert delete_context(GloballyConfiguredKeys.get_types()) ==
             delete_context(types)
  end

  test "belongs_to types respect ecto options" do
    types =
      quote do
        [
          __meta__: unquote(Metadata).t(),
          normal: unquote(Ecto.Schema).belongs_to(BelongsTo.t()) | nil,
          normal_id: integer() | nil,
          with_custom_fk: unquote(Ecto.Schema).belongs_to(BelongsTo.t()) | nil,
          custom_fk: integer() | nil,
          custom_type: unquote(Ecto.Schema).belongs_to(BelongsTo.t()) | nil,
          custom_type_id: binary() | nil,
          no_define: unquote(Ecto.Schema).belongs_to(BelongsTo.t()) | nil
        ]
      end

    assert delete_context(LotsOfBelonging.get_types()) ==
             delete_context(types)
  end

  ## Problems

  test "the name of a field must be an atom" do
    assert_raise ArgumentError, "the :source for field `3` must be an atom, got: 3", fn ->
      defmodule InvalidStruct do
        use TypedEctoSchema

        typed_embedded_schema do
          field(3, :integer)
        end
      end
    end
  end

  test "it is not possible to add twice a field with the same name" do
    assert_raise ArgumentError,
                 "field/association :name already exists on schema, you must either remove the duplication or choose a different name",
                 fn ->
                   defmodule InvalidStruct do
                     use TypedEctoSchema

                     typed_embedded_schema do
                       field(:name, :string)
                       field(:name, :integer)
                     end
                   end
                 end
  end

  defmodule TimestampsWithAttributeConfig do
    use TypedEctoSchema

    @timestamps_opts [
      type: :utc_datetime,
      inserted_at: :my_inserted_at,
      updated_at: :my_updated_at,
      autogenerate: {DateTime, :utc_now, []}
    ]

    @primary_key false
    typed_schema "table" do
      timestamps()
    end

    def get_types, do: Enum.reverse(@__typed_ecto_schema_types__)
  end

  defmodule TimestampsNoUpdatedAt do
    use TypedEctoSchema

    @primary_key false
    typed_schema "table" do
      timestamps(updated_at: false)
    end

    def get_types, do: Enum.reverse(@__typed_ecto_schema_types__)
  end

  defmodule TimestampsNoInsertedAt do
    use TypedEctoSchema

    @primary_key false
    typed_schema "table" do
      timestamps(inserted_at: false)
    end

    def get_types, do: Enum.reverse(@__typed_ecto_schema_types__)
  end

  test "timestamp fields follow the specified name and type" do
    types =
      quote do
        [
          __meta__: unquote(Metadata).t(),
          my_inserted_at: unquote(DateTime).t() | nil,
          my_updated_at: unquote(DateTime).t() | nil
        ]
      end

    assert delete_context(TimestampsWithAttributeConfig.get_types()) ==
             delete_context(types)
  end

  test "inserted at field is not added when inserted_at: false" do
    types =
      quote do
        [
          __meta__: unquote(Metadata).t(),
          updated_at: unquote(NaiveDateTime).t() | nil
        ]
      end

    assert delete_context(TimestampsNoInsertedAt.get_types()) ==
             delete_context(types)
  end

  test "updated at field is not added when updated_at: false" do
    types =
      quote do
        [
          __meta__: unquote(Metadata).t(),
          inserted_at: unquote(NaiveDateTime).t() | nil
        ]
      end

    assert delete_context(TimestampsNoUpdatedAt.get_types()) ==
             delete_context(types)
  end

  defmodule InlineEmbedsOne do
    use TypedEctoSchema

    @primary_key false
    typed_embedded_schema do
      embeds_one(:one, One, []) do
        field(:int, :integer) :: non_neg_integer() | nil

        def get_types, do: Enum.reverse(@__typed_ecto_schema_types__)
      end
    end

    def get_types, do: Enum.reverse(@__typed_ecto_schema_types__)
  end

  test "we can use inline embeds_one" do
    types =
      quote do
        [one: unquote(InlineEmbedsOne.One).t() | nil]
      end

    assert delete_context(InlineEmbedsOne.get_types()) ==
             delete_context(types)

    embed_types =
      quote do
        [id: binary() | nil, int: non_neg_integer() | nil]
      end

    assert delete_context(InlineEmbedsOne.One.get_types()) ==
             delete_context(embed_types)
  end

  defmodule InlineEmbedsOneNoPK do
    use TypedEctoSchema

    @primary_key false
    typed_embedded_schema do
      embeds_one(:one, One, primary_key: false) do
        field(:int, :integer) :: non_neg_integer() | nil

        def get_types, do: Enum.reverse(@__typed_ecto_schema_types__)
      end
    end
  end

  test "we can use inline embeds_one with no primary keys" do
    embed_types =
      quote do
        [int: non_neg_integer() | nil]
      end

    assert delete_context(InlineEmbedsOneNoPK.One.get_types()) ==
             delete_context(embed_types)
  end

  defmodule InlineEmbedsMany do
    use TypedEctoSchema

    @primary_key false
    typed_embedded_schema do
      embeds_many(:many, Many, []) do
        field(:int, :integer) :: non_neg_integer() | nil

        def get_types, do: Enum.reverse(@__typed_ecto_schema_types__)
      end

      embeds_many(:many2, Many2) do
        field(:int, :integer) :: non_neg_integer() | nil

        def get_types, do: Enum.reverse(@__typed_ecto_schema_types__)
      end
    end

    def get_types, do: Enum.reverse(@__typed_ecto_schema_types__)
  end

  test "we can use inline embeds_many" do
    types =
      quote do
        [
          many: list(unquote(InlineEmbedsMany.Many).t()),
          many2: list(unquote(InlineEmbedsMany.Many2).t())
        ]
      end

    assert delete_context(InlineEmbedsMany.get_types()) ==
             delete_context(types)

    embed_types =
      quote do
        [id: binary() | nil, int: non_neg_integer() | nil]
      end

    assert delete_context(InlineEmbedsMany.Many.get_types()) ==
             delete_context(embed_types)

    assert delete_context(InlineEmbedsMany.Many2.get_types()) ==
             delete_context(embed_types)
  end

  defmodule InlineEmbedsManyNoPK do
    use TypedEctoSchema

    @primary_key false
    typed_embedded_schema do
      embeds_many(:many, Many, primary_key: false) do
        field(:int, :integer) :: non_neg_integer() | nil

        def get_types, do: Enum.reverse(@__typed_ecto_schema_types__)
      end
    end
  end

  test "we can use inline embeds_many with no primary keys" do
    embed_types =
      quote do
        [int: non_neg_integer() | nil]
      end

    assert delete_context(InlineEmbedsManyNoPK.Many.get_types()) ==
             delete_context(embed_types)
  end

  defmodule RelationWithCustomSource do
    use TypedEctoSchema

    typed_schema "foo" do
      has_many(:many, {"some_source", HasMany}, foreign_key: :table_id)
    end

    def get_types, do: Enum.reverse(@__typed_ecto_schema_types__)
  end

  test "we can use the source override support of Ecto when referring to schema's" do
    types =
      quote do
        [
          __meta__: unquote(Metadata).t(),
          id: integer() | nil,
          many: unquote(Ecto.Schema).has_many(HasMany.t())
        ]
      end

    assert delete_context(types) == delete_context(RelationWithCustomSource.get_types())
  end

  defmodule WithMacrosInsideBlock do
    use TypedEctoSchema

    import TypedEctoSchema.TestMacros

    @primary_key false
    typed_schema "foo" do
      add_single_field(:foo, :integer)
      TypedEctoSchema.TestMacros.add_single_field(:bar, :float)
      TypedEctoSchema.TestMacros.add_two_fields(:f0, :boolean, :f1, :string)
      field(:baz, :boolean)
    end

    def get_types, do: Enum.reverse(@__typed_ecto_schema_types__)
  end

  test "we can use macros inside the block" do
    assert [
             _,
             foo: {:|, [], [{:integer, [], []}, nil]},
             bar: {:|, [], [{:float, [], []}, nil]},
             f0: {:|, [], [{:boolean, [], []}, nil]},
             f1: {:|, [], [{{:., [], [String, :t]}, [], []}, nil]},
             baz: {:|, [], [{:boolean, [], []}, nil]}
           ] = delete_context(WithMacrosInsideBlock.get_types())
  end

  test "syntactic sugar for embedded fields is correct" do
    assert %Ecto.Changeset{} =
             Ecto.Changeset.change(%InlineEmbedsOne{})
             |> Ecto.Changeset.put_embed(:one, %{int: 123})
  end

  ##
  ## Helpers
  ##

  # Extracts the first type from a module.
  defp extract_first_type(bytecode, type_keyword \\ :type) do
    case Code.Typespec.fetch_types(bytecode) do
      {:ok, types} -> Keyword.get(types, type_keyword)
      _ -> nil
    end
  end

  # Standardises a type (removes line numbers and renames the struct to the
  # standard struct name).
  defp standardise(type_info, struct \\ @standard_struct_name)

  defp standardise({name, type, params}, struct) when is_tuple(type),
    do: {name, standardise(type, struct), params}

  defp standardise({:type, _, type, params}, struct),
    do: {:type, :line, type, standardise(params, struct)}

  defp standardise({:remote_type, _, params}, struct),
    do: {:remote_type, :line, standardise(params, struct)}

  defp standardise({:atom, _, struct}, struct),
    do: {:atom, :line, @standard_struct_name}

  defp standardise({type, _, litteral}, _struct),
    do: {type, :line, litteral}

  defp standardise(list, struct) when is_list(list),
    do: Enum.map(list, &standardise(&1, struct))

  # Deletes the context from a quoted expression.
  defp delete_context(list) when is_list(list),
    do: Enum.map(list, &delete_context/1)

  defp delete_context({a, b}),
    do: {delete_context(a), delete_context(b)}

  defp delete_context({fun, _context, args}),
    do: {delete_context(fun), [], delete_context(args)}

  defp delete_context(other), do: other
end
