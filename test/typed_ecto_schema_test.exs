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
        field(:enum_type_int, Ecto.Enum, values: [foo1: 1, foo2: 2, foo3: 3])
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
      field(:overriden_with_opts, :integer, enforce: false) :: 1 | 2
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

  defmodule NonNullPrimaryKey do
    use TypedEctoSchema

    @primary_key {:id, :binary_id, autogenerate: true, null: false}
    typed_schema "table" do
      field(:int, :integer)
    end

    def get_types, do: Enum.reverse(@__typed_ecto_schema_types__)
  end

  defmodule EnforcedPrimaryKey do
    use TypedEctoSchema

    @primary_key {:id, :id, null: false, enforce: true}
    typed_schema "table" do
      field(:int, :integer)
    end

    def enforce_keys, do: @enforce_keys

    def get_types, do: Enum.reverse(@__typed_ecto_schema_types__)
  end

  defmodule EmbeddedNonNullPrimaryKey do
    use TypedEctoSchema

    @primary_key {:id, :binary_id, autogenerate: true, null: false}
    typed_embedded_schema do
      field(:int, :integer)
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
             :enum_type_int,
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
          field(:enum_type_int, Ecto.Enum, values: [foo1: 1, foo2: 2, foo3: 3])
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
                enum_type_int: (:foo1 | :foo2 | :foo3) | nil,
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
          enum_type_int: (:foo1 | :foo2 | :foo3) | nil,
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
          overriden_with_opts: 1 | 2,
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

  test "primary key with null: false is non-nullable and still autogenerated" do
    types =
      quote do
        [
          __meta__: unquote(Metadata).t(),
          id: binary(),
          int: integer() | nil
        ]
      end

    assert delete_context(NonNullPrimaryKey.get_types()) == delete_context(types)
    assert {:id, _source, :binary_id} = NonNullPrimaryKey.__schema__(:autogenerate_id)
  end

  test "primary key with enforce: true is enforced" do
    types =
      quote do
        [
          __meta__: unquote(Metadata).t(),
          id: integer(),
          int: integer() | nil
        ]
      end

    assert delete_context(EnforcedPrimaryKey.get_types()) == delete_context(types)
    assert EnforcedPrimaryKey.enforce_keys() == [:id]
  end

  test "embedded schema primary key accepts null: false" do
    types =
      quote do
        [
          id: binary(),
          int: integer() | nil
        ]
      end

    assert delete_context(EmbeddedNonNullPrimaryKey.get_types()) == delete_context(types)
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

  defmodule TimestampsNotNull do
    use TypedEctoSchema

    @primary_key false
    typed_schema "table" do
      timestamps(null: false)
    end

    def get_types, do: Enum.reverse(@__typed_ecto_schema_types__)
  end

  defmodule TimestampsCustomTypeNotNull do
    use TypedEctoSchema

    @primary_key false
    typed_schema "table" do
      timestamps(type: :utc_datetime, null: false)
    end

    def get_types, do: Enum.reverse(@__typed_ecto_schema_types__)
  end

  defmodule TimestampsVariableOpts do
    use TypedEctoSchema

    opts = [type: :utc_datetime, null: false]

    @primary_key false
    typed_schema "table" do
      timestamps(opts)
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

  test "timestamps with null: false are not nullable" do
    types =
      quote do
        [
          __meta__: unquote(Metadata).t(),
          inserted_at: unquote(NaiveDateTime).t(),
          updated_at: unquote(NaiveDateTime).t()
        ]
      end

    assert delete_context(TimestampsNotNull.get_types()) ==
             delete_context(types)
  end

  test "timestamps with custom type and null: false are not nullable" do
    types =
      quote do
        [
          __meta__: unquote(Metadata).t(),
          inserted_at: unquote(DateTime).t(),
          updated_at: unquote(DateTime).t()
        ]
      end

    assert delete_context(TimestampsCustomTypeNotNull.get_types()) ==
             delete_context(types)
  end

  test "timestamps handles AST variable opts" do
    types =
      quote do
        [
          __meta__: unquote(Metadata).t(),
          inserted_at: unquote(DateTime).t(),
          updated_at: unquote(DateTime).t()
        ]
      end

    assert delete_context(TimestampsVariableOpts.get_types()) ==
             delete_context(types)

    assert TimestampsVariableOpts.__schema__(:type, :inserted_at) == :utc_datetime
  end

  test "timestamps options are passed to Ecto without the null option" do
    assert TimestampsCustomTypeNotNull.__schema__(:type, :inserted_at) == :utc_datetime
    assert TimestampsCustomTypeNotNull.__schema__(:type, :updated_at) == :utc_datetime

    assert [{[:inserted_at, :updated_at], {Ecto.Schema, :__timestamps__, [:utc_datetime]}}] =
             TimestampsCustomTypeNotNull.__schema__(:autogenerate)
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

  test "SyntaxSugar.apply_to_block/2 work with expanded nested AST" do
    block =
      {:__block__, [],
       [
         {:field, [line: 2], [:name, :string]},
         {:field, [line: 3], [:age, :integer]},
         {:__block__, [],
          [{:field, [], [:embed_flag, :boolean]}, {:field, [], [:embed_name, :string]}]}
       ]}

    result = TypedEctoSchema.SyntaxSugar.apply_to_block(block, :env)

    assert {
             :__block__,
             [],
             [
               {:__block__, [],
                [
                  {:field, [], [:name, :string]},
                  {{:., [], [TypedEctoSchema.TypeBuilder, :add_field]}, [],
                   [{:__MODULE__, [], TypedEctoSchema.SyntaxSugar}, :field, :name, :string, []]}
                ]},
               {:__block__, [],
                [
                  {:field, [], [:age, :integer]},
                  {{:., [], [TypedEctoSchema.TypeBuilder, :add_field]}, [],
                   [{:__MODULE__, [], TypedEctoSchema.SyntaxSugar}, :field, :age, :integer, []]}
                ]},
               {:__block__, [],
                [
                  {:__block__, [],
                   [
                     {:field, [], [:embed_flag, :boolean]},
                     {{:., [], [TypedEctoSchema.TypeBuilder, :add_field]}, [],
                      [
                        {:__MODULE__, [], TypedEctoSchema.SyntaxSugar},
                        :field,
                        :embed_flag,
                        :boolean,
                        []
                      ]}
                   ]},
                  {:__block__, [],
                   [
                     {:field, [], [:embed_name, :string]},
                     {{:., [], [TypedEctoSchema.TypeBuilder, :add_field]}, [],
                      [
                        {:__MODULE__, [], TypedEctoSchema.SyntaxSugar},
                        :field,
                        :embed_name,
                        :string,
                        []
                      ]}
                   ]}
                ]}
             ]
           } == result
  end

  defmodule Custom.Schema do
    @schema_function_names [
      :field,
      :embeds_one,
      :embeds_many,
      :belongs_to
    ]

    defmacro __using__(_opts) do
      quote do
        use TypedEctoSchema
        import TypedEctoSchema, except: [typed_schema: 2]
        import unquote(__MODULE__), only: [typed_schema: 2]
      end
    end

    defmacro typed_schema(name, do: {function_name, ctx, args}) do
      fields = {function_name, ctx, Enum.map(args, &put_null_false/1)}

      quote do
        TypedEctoSchema.typed_schema unquote(name) do
          unquote(fields)
        end
      end
    end

    defp put_null_false({function_name, ctx, args})
         when function_name in @schema_function_names do
      {name, type, opts} =
        case args do
          [name, type] -> {name, type, []}
          [name, type, opts] -> {name, type, opts}
        end

      {function_name, ctx, [name, type, Keyword.put_new(opts, :null, false)]}
    end

    defp put_null_false({:__block__, ctx, args}) do
      {:__block__, ctx, Enum.map(args, &put_null_false/1)}
    end

    defp put_null_false(ast), do: ast
  end

  defmodule CustomMacroSchema do
    use Custom.Schema

    typed_schema "custom_macro_schemas" do
      field(:name, :string)
      field(:age, :integer)

      (
        field(:foo, :string)
        field(:bar, :integer)
      )
    end
  end

  test "pre macro passed schema" do
    assert CustomMacroSchema.__schema__(:fields) == [
             :id,
             :name,
             :age,
             :foo,
             :bar
           ]

    assert CustomMacroSchema.__struct__() == %CustomMacroSchema{
             id: nil,
             name: nil,
             age: nil,
             foo: nil,
             bar: nil
           }
  end

  # Issue #52: 0.4.2 breaks usage in defmacro when opts becomes AST variable reference
  defmodule Issue52TestMacro do
    defmacro problematic_field(name, type, var_opts) do
      quote do
        # This creates opts as an AST variable reference, causing Keyword.drop to fail
        field(unquote(name), unquote(type), unquote(var_opts))
      end
    end

    defmacro __using__(_) do
      quote do
        use TypedEctoSchema
        import unquote(__MODULE__)
      end
    end
  end

  test "issue #52: should handle AST variable opts in macros" do
    # This should now work with the fix applied
    [{module, _}] =
      Code.compile_quoted(
        quote do
          defmodule Issue52FixedSchema do
            use Issue52TestMacro

            # Variable opts becomes AST reference, but now handled properly by the fix
            opts = [null: false, enforce: true]

            typed_embedded_schema do
              problematic_field(:field_name, :string, opts)
            end
          end
        end
      )

    # Verify the schema was created correctly
    assert module == Issue52FixedSchema
    fields = module.__schema__(:fields)
    assert :field_name in fields
  end

  # Issue #57: empty Ecto.Enum values crashed type inference even when the type was overridden
  defmodule EmptyEnumValuesWithOverride do
    use TypedEctoSchema

    typed_embedded_schema do
      field(:foo, {:array, Ecto.Enum}, values: [], default: []) :: list(String.t())
    end

    def get_types, do: Enum.reverse(@__typed_ecto_schema_types__)
  end

  defmodule EmptyEnumValues do
    use TypedEctoSchema

    typed_embedded_schema do
      field(:foo, Ecto.Enum, values: [])
    end

    def get_types, do: Enum.reverse(@__typed_ecto_schema_types__)
  end

  defmodule EnumValuesFromAttribute do
    use TypedEctoSchema

    @role_values [:admin, :user]

    typed_embedded_schema do
      field(:role, Ecto.Enum, values: @role_values)
    end

    def get_types, do: Enum.reverse(@__typed_ecto_schema_types__)
  end

  test "issue #57: empty Ecto.Enum values compile when the type is overridden" do
    types =
      quote do
        [
          id: binary() | nil,
          foo: list(String.t())
        ]
      end

    assert delete_context(EmptyEnumValuesWithOverride.get_types()) == delete_context(types)
  end

  test "issue #57: empty Ecto.Enum values without a type override fall back to any()" do
    types =
      quote do
        [
          id: binary() | nil,
          foo: any() | nil
        ]
      end

    assert delete_context(EmptyEnumValues.get_types()) == delete_context(types)
  end

  test "Ecto.Enum values given through a module attribute generate the exact union type" do
    types =
      quote do
        [
          id: binary() | nil,
          role: (:admin | :user) | nil
        ]
      end

    assert delete_context(EnumValuesFromAttribute.get_types()) == delete_context(types)
  end

  test "Ecto.Enum values that are not a literal list fall back to any()" do
    values_ast = quote(do: @role_values)

    type = TypedEctoSchema.EctoTypeMapper.type_for(Ecto.Enum, :field, false, values: values_ast)

    assert delete_context(type) == delete_context(quote(do: any()))
  end

  ## PolymorphicEmbed integration (issue #40)

  defmodule PolymorphicSms do
    use TypedEctoSchema

    typed_embedded_schema do
      field(:number, :string)
    end
  end

  defmodule PolymorphicEmail do
    use TypedEctoSchema

    typed_embedded_schema do
      field(:address, :string)
    end
  end

  defmodule WithPolymorphicEmbeds do
    use TypedEctoSchema

    import PolymorphicEmbed

    @sms_module PolymorphicSms

    typed_schema "with_polymorphic" do
      polymorphic_embeds_one(:one,
        types: [sms: PolymorphicSms, email: PolymorphicEmail],
        on_type_not_found: :raise,
        on_replace: :update
      )

      polymorphic_embeds_many(:many,
        types: [sms: PolymorphicSms, email: PolymorphicEmail],
        on_type_not_found: :raise,
        on_replace: :delete
      )

      polymorphic_embeds_one(:one_overriden,
        types: [sms: PolymorphicSms],
        on_replace: :update
      ) :: map() | nil

      polymorphic_embeds_many(:many_overriden,
        types: [sms: PolymorphicSms],
        on_replace: :delete
      ) :: list(map())

      polymorphic_embeds_one(:with_module_opts,
        types: [
          sms: [module: PolymorphicSms, identify_by_fields: [:number]]
        ],
        on_replace: :update
      )

      polymorphic_embeds_one(:enforced,
        types: [sms: PolymorphicSms],
        on_replace: :update,
        enforce: true,
        null: false
      )

      polymorphic_embeds_one(:atom_module,
        types: [sms: :"Elixir.TypedEctoSchemaTest.PolymorphicSms"],
        on_replace: :update
      )

      polymorphic_embeds_one(:unresolvable_module,
        types: [sms: [module: @sms_module]],
        on_replace: :update
      )

      polymorphic_embeds_one(:unresolvable_entry,
        types: [{"sms", PolymorphicSms}],
        on_replace: :update
      )
    end

    def enforce_keys, do: @enforce_keys

    def get_types, do: Enum.reverse(@__typed_ecto_schema_types__)
  end

  test "generates polymorphic embed types from the :types option" do
    types =
      quote do
        [
          __meta__: unquote(Metadata).t(),
          id: integer() | nil,
          one: (PolymorphicSms.t() | PolymorphicEmail.t()) | nil,
          many: list(PolymorphicSms.t() | PolymorphicEmail.t()),
          one_overriden: map() | nil,
          many_overriden: list(map()),
          with_module_opts: PolymorphicSms.t() | nil,
          enforced: PolymorphicSms.t(),
          atom_module: unquote(PolymorphicSms).t() | nil,
          unresolvable_module: any() | nil,
          unresolvable_entry: any() | nil
        ]
      end

    assert delete_context(WithPolymorphicEmbeds.get_types()) == delete_context(types)
  end

  test "polymorphic embeds can be enforced" do
    assert WithPolymorphicEmbeds.enforce_keys() == [:enforced]
  end

  test "still runs the polymorphic_embed macros" do
    assert WithPolymorphicEmbeds.__schema__(:fields) == [
             :id,
             :one,
             :many,
             :one_overriden,
             :many_overriden,
             :with_module_opts,
             :enforced,
             :atom_module,
             :unresolvable_module,
             :unresolvable_entry
           ]

    struct = struct(WithPolymorphicEmbeds)
    assert struct.one == nil
    assert struct.many == []
  end

  defmodule PolymorphicWithModuleAttributeTypes do
    use TypedEctoSchema

    import PolymorphicEmbed

    @types [sms: PolymorphicSms]

    typed_schema "with_polymorphic_attr" do
      polymorphic_embeds_one(:one, types: @types, on_replace: :update)
    end

    def get_types, do: Enum.reverse(@__typed_ecto_schema_types__)
  end

  test "falls back to any() when polymorphic types are not statically known" do
    types =
      quote do
        [
          __meta__: unquote(Metadata).t(),
          id: integer() | nil,
          one: any() | nil
        ]
      end

    assert delete_context(PolymorphicWithModuleAttributeTypes.get_types()) ==
             delete_context(types)
  end

  defmodule ImportsPolymorphicButDoesNotUse do
    use TypedEctoSchema

    import PolymorphicEmbed, warn: false

    typed_schema "no_polymorphic" do
      field(:int, :integer)
    end

    def get_types, do: Enum.reverse(@__typed_ecto_schema_types__)
  end

  test "schemas that don't use polymorphic embeds are unaffected" do
    types =
      quote do
        [
          __meta__: unquote(Metadata).t(),
          id: integer() | nil,
          int: integer() | nil
        ]
      end

    assert delete_context(ImportsPolymorphicButDoesNotUse.get_types()) ==
             delete_context(types)
  end

  test "leaves polymorphic embed calls with non-literal opts untouched" do
    one = {:polymorphic_embeds_one, [], [:form, {:opts, [], nil}]}

    many_with_type =
      {:"::", [], [{:polymorphic_embeds_many, [], [:forms, {:opts, [], nil}]}, {:map, [], []}]}

    block = {:__block__, [], [one, many_with_type]}

    assert TypedEctoSchema.SyntaxSugar.apply_to_block(block, __ENV__) ==
             {:__block__, [], [one, many_with_type]}
  end

  test "with the flag disabled, same-named macros from other libraries are untouched" do
    disable_polymorphic_embed()

    [{module, _}] =
      Code.compile_quoted(
        quote do
          defmodule OtherPolymorphicLibSchema do
            use TypedEctoSchema

            import TypedEctoSchema.OtherPolymorphicLib

            typed_schema "other_lib" do
              polymorphic_embeds_one(:form, null: false)
            end

            def get_types, do: Enum.reverse(@__typed_ecto_schema_types__)
          end
        end
      )

    types =
      quote do
        [
          __meta__: unquote(Metadata).t(),
          id: integer() | nil,
          form: unquote(String).t()
        ]
      end

    assert delete_context(module.get_types()) == delete_context(types)
  end

  test "with the flag disabled, real polymorphic_embed calls keep the old behavior" do
    disable_polymorphic_embed()

    [{module, _}] =
      Code.compile_quoted(
        quote do
          defmodule DisabledPolymorphicSchema do
            use TypedEctoSchema

            import PolymorphicEmbed

            typed_schema "disabled_polymorphic" do
              polymorphic_embeds_one(:form,
                types: [sms: TypedEctoSchemaTest.PolymorphicSms],
                on_replace: :update
              )
            end

            def get_types, do: Enum.reverse(@__typed_ecto_schema_types__)
          end
        end
      )

    types =
      quote do
        [
          __meta__: unquote(Metadata).t(),
          id: integer() | nil,
          form: PolymorphicEmbed.t() | nil
        ]
      end

    assert delete_context(module.get_types()) == delete_context(types)
  end

  test "with the flag disabled, apply_to_block leaves polymorphic calls alone" do
    disable_polymorphic_embed()

    one = {:polymorphic_embeds_one, [], [:form, [types: []]]}

    many_with_type =
      {:"::", [], [{:polymorphic_embeds_many, [], [:forms, [types: []]]}, {:map, [], []}]}

    block = {:__block__, [], [one, many_with_type]}

    assert TypedEctoSchema.SyntaxSugar.apply_to_block(block, __ENV__) ==
             {:__block__, [], [one, many_with_type]}
  end

  ## Internal type mapping edge cases

  test "EctoTypeMapper infers composite, evaluated and unknown types" do
    assert mapped_type({:array, :string}) ==
             delete_context(quote(do: list(unquote(String).t()) | nil))

    assert mapped_type({:map, :integer}) ==
             delete_context(quote(do: %{optional(any()) => integer()} | nil))

    assert mapped_type(Ecto.Enum, values: [:foo, :bar]) ==
             delete_context(quote(do: (:foo | :bar) | nil))

    assert mapped_type(Ecto.Enum, values: ["not", "atoms"]) ==
             delete_context(quote(do: any() | nil))

    assert mapped_type(:some_unknown_type) == delete_context(quote(do: any() | nil))

    assert mapped_type({:parameterized, {PolymorphicEmbed, %{}}}) ==
             delete_context(quote(do: any() | nil))
  end

  test "TypeBuilder.add_field raises when the field name is not an atom" do
    assert_raise ArgumentError, ~s(a field name must be an atom, got "bad"), fn ->
      TypedEctoSchema.TypeBuilder.add_field(__MODULE__, :field, "bad", :string, [])
    end
  end

  ## Additional types for Ecto.Enum fields (issue #39)

  {:module, _name, bytecode_additional_types, _exports} =
    defmodule WithAdditionalTypes do
      use TypedEctoSchema

      @role_values [:admin, :user]

      @primary_key false
      typed_schema "table", additional_types: true do
        field(:simple, Ecto.Enum, values: [:foo, :bar])
        field(:keyed, Ecto.Enum, values: [one: 1, two: 2])
        field(:array, {:array, Ecto.Enum}, values: [:a, :b])
        field(:from_attribute, Ecto.Enum, values: @role_values)
        field(:t, Ecto.Enum, values: [:skipped])
        field(:not_enum, :integer)
      end
    end

  {:module, _name, bytecode_embedded_additional_types, _exports} =
    defmodule EmbeddedWithAdditionalTypes do
      use TypedEctoSchema

      @primary_key false
      typed_embedded_schema additional_types: true do
        field(:status, Ecto.Enum, values: [:on, :off])
      end
    end

  @bytecode_additional_types bytecode_additional_types
  @bytecode_embedded_additional_types bytecode_embedded_additional_types

  test "generates named types for enum fields when additional_types is enabled" do
    assert {:type, delete_context(quote(do: simple() :: :foo | :bar))} in extract_all_types(
             @bytecode_additional_types
           )
  end

  test "generates the union of keys as named type for keyed enum values" do
    assert {:type, delete_context(quote(do: keyed() :: :one | :two))} in extract_all_types(
             @bytecode_additional_types
           )
  end

  test "generates the element union as named type for arrays of enums" do
    assert {:type, delete_context(quote(do: array() :: :a | :b))} in extract_all_types(
             @bytecode_additional_types
           )
  end

  test "generates named types for enum values resolved from module attributes" do
    assert {:type, delete_context(quote(do: from_attribute() :: :admin | :user))} in extract_all_types(
             @bytecode_additional_types
           )
  end

  test "does not generate a named type for enum fields named t" do
    # If a `t` type was generated for the field it would conflict with the
    # schema's own `t/0` and the module wouldn't even compile.
    type_names =
      for {_kind, {:"::", _, [{name, _, _} | _]}} <- extract_all_types(@bytecode_additional_types),
          do: name

    assert Enum.count(type_names, &(&1 == :t)) == 1
  end

  test "does not generate named types for non-enum fields" do
    type_names =
      for {_kind, {:"::", _, [{name, _, _} | _]}} <- extract_all_types(@bytecode_additional_types),
          do: name

    refute :not_enum in type_names
  end

  test "generates named types for enum fields on typed_embedded_schema" do
    assert {:type, delete_context(quote(do: status() :: :on | :off))} in extract_all_types(
             @bytecode_embedded_additional_types
           )
  end

  test "does not generate named types for enum fields by default" do
    type_names =
      for {_kind, {:"::", _, [{name, _, _} | _]}} <- extract_all_types(@bytecode), do: name

    assert type_names == [:t]
  end

  test "silently skips enum fields whose values are not statically resolvable" do
    # Simulates `:values` reaching the builder as unevaluated AST
    # (e.g. through a macro escaping its options) or as values `Ecto.Enum`
    # itself would reject, like a list of integers.
    defmodule UnresolvableValues do
      require TypedEctoSchema.TypeBuilder

      TypedEctoSchema.TypeBuilder.init(additional_types: true)

      TypedEctoSchema.TypeBuilder.add_field(
        __MODULE__,
        :field,
        :status,
        Ecto.Enum,
        values: {:@, [], [{:role_values, [], nil}]}
      )

      TypedEctoSchema.TypeBuilder.add_field(
        __MODULE__,
        :field,
        :not_atoms,
        Ecto.Enum,
        values: [1, 2, 3]
      )

      def additional_types, do: @__typed_ecto_schema_additional_types__
    end

    assert UnresolvableValues.additional_types() == []
  end

  test "the additional_types default can be enabled globally via application config" do
    enable_global_additional_types()

    {:module, _name, bytecode, _exports} =
      defmodule GloballyEnabledAdditionalTypes do
        use TypedEctoSchema

        @primary_key false
        typed_embedded_schema do
          field(:status, Ecto.Enum, values: [:on, :off])
        end
      end

    assert {:type, delete_context(quote(do: status() :: :on | :off))} in extract_all_types(
             bytecode
           )
  end

  test "the schema-level additional_types option overrides the global config" do
    enable_global_additional_types()

    {:module, _name, bytecode, _exports} =
      defmodule GloballyEnabledButLocallyDisabled do
        use TypedEctoSchema

        @primary_key false
        typed_embedded_schema additional_types: false do
          field(:status, Ecto.Enum, values: [:on, :off])
        end
      end

    type_names =
      for {_kind, {:"::", _, [{name, _, _} | _]}} <- extract_all_types(bytecode), do: name

    assert type_names == [:t]
  end

  {:module, _name, bytecode_polymorphic_additional_types, _exports} =
    defmodule PolymorphicWithAdditionalTypes do
      use TypedEctoSchema

      import PolymorphicEmbed

      @sms_module PolymorphicSms

      @primary_key false
      typed_schema "polymorphic_additional", additional_types: true do
        polymorphic_embeds_one(:channel,
          types: [sms: PolymorphicSms, email: PolymorphicEmail],
          on_replace: :update
        )

        polymorphic_embeds_many(:channels,
          types: [sms: PolymorphicSms, email: PolymorphicEmail],
          on_replace: :delete
        )

        polymorphic_embeds_one(:unresolvable,
          types: [sms: [module: @sms_module]],
          on_replace: :update
        )
      end
    end

  @bytecode_polymorphic_additional_types bytecode_polymorphic_additional_types

  test "generates named types for polymorphic embeds" do
    assert {:type,
            delete_context(
              quote(do: channel() :: unquote(PolymorphicSms).t() | unquote(PolymorphicEmail).t())
            )} in extract_all_types(@bytecode_polymorphic_additional_types)
  end

  test "generates the element union as named type for polymorphic_embeds_many" do
    assert {:type,
            delete_context(
              quote(do: channels() :: unquote(PolymorphicSms).t() | unquote(PolymorphicEmail).t())
            )} in extract_all_types(@bytecode_polymorphic_additional_types)
  end

  test "does not generate named types for polymorphic embeds with unresolvable types" do
    type_names =
      for {_kind, {:"::", _, [{name, _, _} | _]}} <-
            extract_all_types(@bytecode_polymorphic_additional_types),
          do: name

    refute :unresolvable in type_names
  end

  ## Field docs in the moduledoc (issue #41)

  {:module, _name, bytecode_field_docs, _exports} =
    defmodule WithFieldDocs do
      @moduledoc """
      A person.

      ## Fields

      <!-- typed_ecto_schema: fields -->
      """

      use TypedEctoSchema

      @primary_key {:id, :id, autogenerate: true, doc: "The record id"}
      typed_schema "people" do
        field(:name, :string, null: false, doc: "The person's full name")
        field(:age, :integer)
      end
    end

  {:module, _name, bytecode_marker_without_field_docs, _exports} =
    defmodule WithMarkerButNoFieldDocs do
      @moduledoc "<!-- typed_ecto_schema: fields -->"

      use TypedEctoSchema

      @primary_key false
      typed_embedded_schema do
        field(:name, :string)
      end
    end

  {:module, _name, bytecode_field_docs_no_marker, _exports} =
    defmodule WithFieldDocsButNoMarker do
      @moduledoc "A person."

      use TypedEctoSchema

      @primary_key false
      typed_embedded_schema do
        field(:name, :string, doc: "The person's full name")
      end
    end

  {:module, _name, bytecode_field_docs_no_moduledoc, _exports} =
    defmodule WithFieldDocsButNoModuledoc do
      use TypedEctoSchema

      @primary_key false
      typed_embedded_schema do
        field(:name, :string, doc: "The person's full name")
      end
    end

  {:module, _name, bytecode_field_docs_hidden, _exports} =
    defmodule WithFieldDocsButHiddenModuledoc do
      @moduledoc false

      use TypedEctoSchema

      @primary_key false
      typed_embedded_schema do
        field(:name, :string, doc: "The person's full name")
      end
    end

  {:module, _name, bytecode_field_docs_assoc, _exports} =
    defmodule WithFieldDocsAssoc do
      @moduledoc "<!-- typed_ecto_schema: fields -->"

      use TypedEctoSchema

      @primary_key false
      typed_schema "docs_assoc" do
        belongs_to(:company, BelongsTo, doc: "The employer")
        embeds_many(:embeds, Embedded, doc: "Embedded things")
        field(:age, :integer, doc: "Age in years") :: non_neg_integer()
      end
    end

  {:module, _name, bytecode_field_docs_polymorphic, _exports} =
    defmodule WithFieldDocsPolymorphic do
      @moduledoc "<!-- typed_ecto_schema: fields -->"

      use TypedEctoSchema

      import PolymorphicEmbed

      @primary_key false
      typed_schema "docs_polymorphic" do
        polymorphic_embeds_one(:channel,
          types: [sms: PolymorphicSms, email: PolymorphicEmail],
          on_replace: :update,
          doc: "How the person is notified"
        )
      end
    end

  {:module, _name, bytecode_own_typedoc, _exports} =
    defmodule WithOwnTypedoc do
      use TypedEctoSchema

      @typedoc "My own typedoc."
      @primary_key false
      typed_embedded_schema do
        field(:name, :string, doc: "The person's full name")
      end
    end

  {:module, _name, bytecode_typedoc_marker, _exports} =
    defmodule WithTypedocMarker do
      use TypedEctoSchema

      @typedoc """
      My type.

      <!-- typed_ecto_schema: fields -->
      """
      @primary_key false
      typed_embedded_schema do
        field(:name, :string, doc: "The person's full name")
      end
    end

  {:module, _name, bytecode_previous_typedoc, _exports} =
    defmodule WithTypedocOnPreviousType do
      use TypedEctoSchema

      @typedoc "A name."
      @type name() :: String.t()

      @primary_key false
      typed_embedded_schema do
        field(:name, :string, doc: "The person's full name")
      end
    end

  {:module, _name, bytecode_typedoc_false, _exports} =
    defmodule WithTypedocFalse do
      use TypedEctoSchema

      @typedoc false
      @primary_key false
      typed_embedded_schema do
        field(:name, :string, doc: "The person's full name")
      end
    end

  @bytecode_field_docs bytecode_field_docs
  @bytecode_marker_without_field_docs bytecode_marker_without_field_docs
  @bytecode_field_docs_no_marker bytecode_field_docs_no_marker
  @bytecode_field_docs_no_moduledoc bytecode_field_docs_no_moduledoc
  @bytecode_field_docs_hidden bytecode_field_docs_hidden
  @bytecode_field_docs_assoc bytecode_field_docs_assoc
  @bytecode_field_docs_polymorphic bytecode_field_docs_polymorphic
  @bytecode_own_typedoc bytecode_own_typedoc
  @bytecode_typedoc_marker bytecode_typedoc_marker
  @bytecode_previous_typedoc bytecode_previous_typedoc
  @bytecode_typedoc_false bytecode_typedoc_false

  test "replaces the fields marker in the moduledoc with the field list" do
    assert %{"en" => doc} = extract_moduledoc(@bytecode_field_docs)

    assert doc == """
           A person.

           ## Fields

           - `id`: The record id (`integer() | nil`)
           - `name`: The person's full name (`String.t()`)
           - `age` (`integer() | nil`)
           """
  end

  test "replaces the marker even when no field has a doc" do
    assert extract_moduledoc(@bytecode_marker_without_field_docs) ==
             %{"en" => "- `name` (`String.t() | nil`)"}
  end

  test "leaves the moduledoc untouched without the marker" do
    assert extract_moduledoc(@bytecode_field_docs_no_marker) == %{"en" => "A person."}
  end

  test "the doc option is stripped and ignored without a moduledoc" do
    assert extract_moduledoc(@bytecode_field_docs_no_moduledoc) == :none
  end

  test "the doc option is stripped and ignored with moduledoc false" do
    assert extract_moduledoc(@bytecode_field_docs_hidden) == :hidden
  end

  test "documents associations and embeds without copying the doc to the foreign key" do
    assert %{"en" => doc} = extract_moduledoc(@bytecode_field_docs_assoc)

    assert doc =~ ~r/^- `company`: The employer \(`.+`\)$/m
    assert doc =~ ~r/^- `company_id` \(`integer\(\) \| nil`\)$/m
    assert doc =~ ~r/^- `embeds`: Embedded things \(`.+`\)$/m
    assert doc =~ ~r/^- `age`: Age in years \(`non_neg_integer\(\)`\)$/m
  end

  test "documents polymorphic embed fields" do
    assert %{"en" => doc} = extract_moduledoc(@bytecode_field_docs_polymorphic)

    assert doc =~ ~r/^- `channel`: How the person is notified \(`.+`\)$/m
  end

  test "generates a typedoc with a Fields section for t/0" do
    assert %{"en" => doc} = extract_typedoc(@bytecode_field_docs)

    assert doc == """
           ## Fields

           - `id`: The record id (`integer() | nil`)
           - `name`: The person's full name (`String.t()`)
           - `age` (`integer() | nil`)
           """
  end

  test "generates the typedoc even when no field has a doc" do
    assert extract_typedoc(@bytecode_marker_without_field_docs) ==
             %{"en" => "## Fields\n\n- `name` (`String.t() | nil`)\n"}
  end

  test "generates the typedoc regardless of the moduledoc marker" do
    assert extract_typedoc(@bytecode_field_docs_no_marker) ==
             %{"en" => "## Fields\n\n- `name`: The person's full name (`String.t() | nil`)\n"}
  end

  test "keeps an open typedoc untouched when it has no marker" do
    assert extract_typedoc(@bytecode_own_typedoc) == %{"en" => "My own typedoc."}
  end

  test "replaces the fields marker in an open typedoc" do
    assert %{"en" => doc} = extract_typedoc(@bytecode_typedoc_marker)

    assert doc == """
           My type.

           - `name`: The person's full name (`String.t() | nil`)
           """
  end

  test "respects typedoc false" do
    assert extract_typedoc(@bytecode_typedoc_false) == :hidden
  end

  test "a typedoc consumed by a previous type does not count as an open typedoc" do
    assert extract_typedoc(@bytecode_previous_typedoc, :name) == %{"en" => "A name."}

    assert extract_typedoc(@bytecode_previous_typedoc) ==
             %{"en" => "## Fields\n\n- `name`: The person's full name (`String.t() | nil`)\n"}
  end

  test "the generated typedoc attaches to t/0 and not to additional types" do
    assert %{"en" => "## Fields" <> _} = extract_typedoc(@bytecode_embedded_additional_types)
    assert extract_typedoc(@bytecode_embedded_additional_types, :status) == :none
  end

  ##
  ## Helpers
  ##

  defp mapped_type(ecto_type, opts \\ []) do
    delete_context(TypedEctoSchema.EctoTypeMapper.type_for(ecto_type, :field, true, opts))
  end

  # Disables the polymorphic_embed integration (enabled in test_helper.exs) for
  # the duration of a test.
  defp disable_polymorphic_embed do
    Application.put_env(:typed_ecto_schema, :polymorphic_embed, false)
    on_exit(fn -> Application.put_env(:typed_ecto_schema, :polymorphic_embed, true) end)
  end

  # Enables the global additional_types default for the duration of a test.
  defp enable_global_additional_types do
    Application.put_env(:typed_ecto_schema, :additional_types, true)
    on_exit(fn -> Application.delete_env(:typed_ecto_schema, :additional_types) end)
  end

  # Extracts the moduledoc from a module's bytecode.
  defp extract_moduledoc(bytecode) do
    {:docs_v1, _anno, :elixir, _format, moduledoc, _meta, _docs} = docs_chunk(bytecode)
    moduledoc
  end

  # Extracts a typedoc from a module's bytecode.
  defp extract_typedoc(bytecode, name \\ :t) do
    {:docs_v1, _anno, :elixir, _format, _moduledoc, _meta, docs} = docs_chunk(bytecode)

    Enum.find_value(docs, fn
      {{:type, ^name, 0}, _anno, _signature, doc, _meta} -> doc
      _ -> nil
    end)
  end

  defp docs_chunk(bytecode) do
    {:ok, {_module, [{~c"Docs", chunk}]}} = :beam_lib.chunks(bytecode, [~c"Docs"])
    :erlang.binary_to_term(chunk)
  end

  # Extracts the first type from a module.
  defp extract_first_type(bytecode, type_keyword \\ :type) do
    case Code.Typespec.fetch_types(bytecode) do
      {:ok, types} -> Keyword.get(types, type_keyword)
      _ -> nil
    end
  end

  # Extracts all types from a module as context-free quoted expressions.
  defp extract_all_types(bytecode) do
    {:ok, types} = Code.Typespec.fetch_types(bytecode)

    for {kind, type} <- types do
      {kind, delete_context(Code.Typespec.type_to_quoted(type))}
    end
  end

  # Standardises a type (removes line numbers and renames the struct to the
  # standard struct name).
  defp standardise(type_info, struct \\ @standard_struct_name)

  defp standardise({:type, _, type, params}, struct),
    do: {:type, :line, type, standardise(params, struct)}

  defp standardise({:remote_type, _, params}, struct),
    do: {:remote_type, :line, standardise(params, struct)}

  defp standardise({:atom, _, struct}, struct),
    do: {:atom, :line, @standard_struct_name}

  defp standardise({name, type, params}, struct) when is_tuple(type),
    do: {name, standardise(type, struct), params}

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
