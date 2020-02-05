defmodule CrawlerExampleTest do
  use ExUnit.Case
  doctest CrawlerExample

  test "greets the world" do
    assert CrawlerExample.hello() == :world
  end
end
