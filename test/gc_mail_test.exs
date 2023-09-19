defmodule GCMailTest do
  use ExUnit.Case
  doctest GCMail

  # describe "pull_global_ids/1" do
  #   test "return [] if mail cache is empty" do
  #     assert [] == GCMail.pull_global_ids(nil)
  #     assert [] == GCMail.pull_global_ids(199)
  #   end

  #   test "return the newest 100 items if `id = nil` and mail cache has 200 items" do
  #     assert Enum.to_list(200..101) == GCMail.pull_global_ids(nil)
  #   end

  #   test "return the newest 100 items if `id = 199` and mail cache has 200 items" do
  #     assert [200] == GCMail.pull_global_ids(199)
  #   end
  # end
end
