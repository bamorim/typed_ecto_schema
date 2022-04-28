defmodule TypedEctoSchema.MixProject do
  use Mix.Project

  def project do
    [
      app: :typed_ecto_schema,
      version: "0.4.1",
      elixir: "~> 1.9",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      package: package(),
      docs: docs(),
      description:
        "A library to define Ecto schemas with typespecs without all the boilerplate code."
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      # Development and test dependencies
      {:credo, "~> 1.6", only: [:dev, :test], runtime: false},
      {:dialyxir, "~> 1.0", only: [:dev, :test], runtime: false},
      {:excoveralls, "~> 0.11.1", only: :test, runtime: false},

      # Project dependencies
      {:ecto, "~> 3.5"},

      # Documentation dependencies
      {:ex_doc, "~> 0.28", only: :dev, runtime: false}
    ]
  end

  defp docs do
    [
      main: "TypedEctoSchema",
      source_url: "https://github.com/bamorim/typed_ecto_schema"
    ]
  end

  defp package do
    [
      maintainers: ["Bernardo Amorim"],
      licenses: ["Apache-2.0"],
      links: %{
        "GitHub" => "https://github.com/bamorim/typed_ecto_schema"
      }
    ]
  end
end
