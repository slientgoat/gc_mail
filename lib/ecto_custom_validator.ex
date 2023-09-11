defmodule EctoCustomValidator do
  import Ecto.Changeset
  require Integer

  def validate_list_length_is_even(changeset, key) do
    val = get_field(changeset, key)

    with true <- val != nil,
         true <- is_list(val),
         true <- Integer.is_odd(length(val)) do
      add_error(changeset, :attaches, "expected length is even")
    else
      _ ->
        changeset
    end
  end
end
