defmodule PrintDecorator do
  use Decorator.Define, print: 0

  def print(body, context) do
    quote do
      IO.puts(unquote(inspect(context)))
      IO.puts("Function called: " <> Atom.to_string(unquote(context.name)))
      unquote(body)
    end
  end
end

defmodule GCMail do
  use PrintDecorator
  # build_mail()
  # put_attaches/2
  # put_from/2
  # put_to/2
  #

  @moduledoc """
  Documentation for `GCMail`.
  """

  @doc """
  Hello world.

  ## Examples

      iex> GCMail.hello()
      :world

  """
  @decorate print()
  def hello() do
    :world
  end

  def submit_request(attrs) do
    attrs
  end

  @decorate print()
  def square(a) do
    a * a
  end
end
