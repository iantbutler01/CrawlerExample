defmodule CrawlerExample.Queue do
  use GenServer

  @work_interval 5000
  @write_interval 5000
  @depth_limit 5

  #client
  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, nil, opts)
  end

  def load_from_file(file_path) do
    GenServer.cast(__MODULE__, {:load_state_from_disk, file_path})
  end

  def push(url) when is_binary(url) do
    GenServer.cast(__MODULE__, {:push, [url, 0]})
  end

  def push([depth, url]) when is_binary(url) and is_integer(depth) do
    GenServer.cast(__MODULE__, {:push, [url, depth]})
  end

  def pop() do
    GenServer.call(__MODULE__, :pop)
  end

  #server
  @impl true
  def init(_init_arg) do
    schedule_write_to_disk(5000)
    schedule_work(5000)
    {:ok, :queue.new}
  end

  @impl true
  def handle_info(:schedule_write_to_disk, state) do
    current_state = :queue.to_list(state)

    state_json = Poison.encode!(current_state)

    File.write("/tmp/crawler_state.json", state_json)

    schedule_write_to_disk(@write_interval)

    {:noreply, state}
  end

  def handle_info(:schedule_work, state) do
    unless :queue.is_empty(state) do
      for _ <- 0..System.schedulers_online() do
        Task.Supervisor.async_nolink(CrawlerExample.WorkerSupervisor, fn ->
            CrawlerExample.Worker.work(@depth_limit)
        end)
      end
    end

    schedule_work(@work_interval)

    {:noreply, state}
  end

  def handle_info({_, :ok}, state), do: {:noreply, state}
  def handle_info({:DOWN, _, :process, _pid, _exception}, state), do: {:noreply, state}


  @impl true
  def handle_cast({:load_state_from_disk, file_path}, _) do
    contents = File.read!(file_path)
    from_json = Poison.decode!(contents)

    {:noreply, :queue.from_list(from_json)}
  end

  def handle_cast({:push, [url, depth]}, state) do
    new_state = :queue.in([url, depth], state)

    {:noreply, new_state}
  end

  @impl true
  def handle_call(:pop, _, state) do
    {val, new_queue} = :queue.out(state)
    {:reply, val, new_queue}
  end

  defp schedule_write_to_disk(interval), do: :erlang.send_after(interval, self(), :schedule_write_to_disk)
  defp schedule_work(interval), do: :erlang.send_after(interval, self(), :schedule_work)
end
