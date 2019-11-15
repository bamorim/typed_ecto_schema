defmodule TypedEctoSchema.MixProject do
  use Mix.Project

  def project do
    [
      app: :typed_ecto_schema,
      version: "0.1.1",
      elixir: "~> 1.7",
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

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      # Development and test dependencies
      {:credo, "~> 1.1", only: [:dev, :test], runtime: false},
      {:dialyxir, "~> 1.0-rc", only: [:dev, :test], runtime: false},
      {:excoveralls, "~> 0.11.1", only: :test, runtime: false},

      # Project dependencies
      {:ecto, "~> 3.0"},

      # Documentation dependencies
      {:ex_doc, "~> 0.21", only: :dev, runtime: false}
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
