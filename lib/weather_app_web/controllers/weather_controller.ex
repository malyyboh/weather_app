defmodule WeatherAppWeb.WeatherController do
  use WeatherAppWeb, :controller

  @cities_weather %{
    "Київ" => %{
      temperature: "22°C",
      condition: "хмарно",
      humidity: "65%",
      wind: "5 м/с",
      precipitation: "без опадів"
    },
    "Львів" => %{
      temperature: "18°C",
      condition: "сонячно",
      humidity: "45%",
      wind: "3 м/с",
      precipitation: "без опадів"
    },
    "Варшава" => %{
      temperature: "15°C",
      condition: "дощ",
      humidity: "85%",
      wind: "8 м/с",
      precipitation: "легкий дощ"
    }
  }

  def index(conn, %{"city" => city}) do
    normalized_city = String.capitalize(city)
    weather_data = fetch_weather_data(normalized_city)

    render(conn, :index,
      weather: weather_data,
      city: normalized_city,
      layout: false
    )
  end

  def index(conn, _params) do
    render(conn, :index, layout: false)
  end

  defp fetch_weather_data(city) do
    api_key = System.get_env("OPENWEATHER_API_KEY")

    url = "https://api.openweathermap.org/data/2.5/weather"

    case Req.get(url,
           params: [
             q: city,
             appid: api_key,
             units: "metric",
             lang: "en"
           ]
         ) do
      {:ok, %{status: 200, body: body}} ->
        parse_weather_response(body)

      {:ok, %{status: 401}} ->
        "Помилка: перевірте API ключ"

      {:ok, %{status: 404}} ->
        "Місто не знайдено"

      {:ok, %{status: status}} ->
        "Помилка API: #{status}"

      {:error, _reason} ->
        "Помилка з'єднання з API погоди"
    end
  end

  defp parse_weather_response(api_response) do
    weather_info = List.first(api_response["weather"], %{})

    %{
      temperature: "#{api_response["main"]["temp"]}°C",
      condition: weather_info["description"] || "невідомо",
      humidity: "#{api_response["main"]["humidity"]}%",
      wind: "#{api_response["wind"]["speed"]} м/с",
      precipitation: get_precipitation(api_response)
    }
  end

  defp get_precipitation(api_response) do
    cond do
      api_response["rain"] && api_response["rain"]["1h"] > 0 ->
        "дощ: #{api_response["rain"]["1h"]} мм/год"

      api_response["snow"] && api_response["snow"]["1h"] > 0 ->
        "сніг: #{api_response["snow"]["1h"]} мм/год"

      true ->
        "без опадів"
    end
  end
end
