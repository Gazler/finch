_ = """
Run with:

elixir --erl "+S 1:1" finch_pool.exs 10

To run until it fails or succeeds 50 times:

for i in {1..50}; do elixir --erl "+S 1:1" finch_pool.exs 10 || break; done
"""

Mix.install([{:req, "~> 0.5.0"}, {:finch, path: "./", override: true}])

Application.ensure_all_started(:req)

count =
  case System.argv() do
    [x] -> String.to_integer(x)
    _ -> 10
  end

results =
  Enum.map(1..count, fn i ->
    Task.async(fn -> {i, self(), Req.get("https://example.com", max_retries: 0)} end)
  end)
  |> Task.await_many(:timer.seconds(60))
  |> Enum.map(fn
    {i, pid, {:error, _} = error} -> IO.inspect({i, pid, error})
    {i, pid, {:ok, _}} -> IO.inspect({i, pid, :ok})
  end)

if Enum.any?(results, &match?({_, _, {:error, _}}, &1)) do
  System.halt(1)
end
