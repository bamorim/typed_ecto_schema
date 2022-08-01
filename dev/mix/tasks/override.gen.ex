defmodule Mix.Tasks.Override.Gen do
  @moduledoc """
  Automatically generates TypeCheck override modules from a particular
  dependency and puts them in the appropriate place
  """

  @shortdoc "Automatically generates TypeCheck override modules"
  @requirements ["app.start"]

  use Mix.Task

  @impl Mix.Task
  def run(_args) do
    TypedEctoSchema.TypeCheckGen.generate()
  end
end
