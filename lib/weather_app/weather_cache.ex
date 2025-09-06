defmodule WeatherApp.WeatherCache do
  use GenServer

  def start_link(_opts) do
    GenServer.start_link(__MODULE__, %{}, name: __MODULE__)
  end

  def get_weather(city) do
    GenServer.call(__MODULE__, {:get_weather, city})
  end

  def put_weather(city, weather_data) do
    GenServer.cast(__MODULE__, {:put_weather, city, weather_data})
  end

  def clear_cache do
    GenServer.cast(__MODULE__, :clear_cache)
  end

  @impl true
  def init(state) do
    {:ok, state}
  end

  @impl true
  def handle_call({:get_weather, city}, _from, state) do
    case Map.get(state, city) do
      {data, timestamp} ->
        if cache_valid?(timestamp) do
          {:reply, {:ok, data}, state}
        else
          {:reply, :cache_expired, state}
        end

      nil ->
        {:reply, :not_found, state}
    end
  end

  @impl true
  def handle_cast({:put_weather, city, weather_data}, state) do
    timestamp = System.system_time(:second)
    new_state = Map.put(state, city, {weather_data, timestamp})
    {:noreply, new_state}
  end

  @impl true
  def handle_cast(:clear_cache, _state) do
    {:noreply, %{}}
  end

  defp cache_valid?(timestamp) do
    current_time = System.system_time(:second)
    current_time - timestamp < 600
  end
end
