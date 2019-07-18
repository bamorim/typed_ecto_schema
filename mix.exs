defmodule TypedEctoSchema.MixProject do
  use Mix.Project

  def project do
    [
      app: :typed_ecto_schema,
      version: "0.1.0",
      elixir: "~> 1.7",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      docs: [
        main: "TypedEctoSchema"
      ]
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
      {:credo, "~> 1.1", only: :dev, runtime: false},
      {:dialyxir, "~> 1.0-rc", only: :dev, runtime: false},
      {:excoveralls, "~> 0.11.1", only: :test, runtime: false},

      # Project dependencies
      {:ecto, "~> 3.1.7"},

      # Documentation dependencies
      {:ex_doc, "~> 0.21", only: :dev, runtime: false}
    ]
  end
end
