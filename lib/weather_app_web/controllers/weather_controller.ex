defmodule WeatherAppWeb.WeatherController do
  use WeatherAppWeb, :controller

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
    case WeatherApp.WeatherCache.get_weather(city) do
      {:ok, cached_data} ->
        cached_data

      :cache_expired ->
        fetch_and_cache_weather(city)

      :not_found ->
        fetch_and_cache_weather(city)
    end
  end

  defp fetch_and_cache_weather(city) do
    api_key = System.get_env("OPENWEATHER_API_KEY")

    if is_nil(api_key) or api_key == "" do
      "API key not configured"
    else
      case make_api_request(city, api_key) do
        weather_data when is_map(weather_data) ->
          WeatherApp.WeatherCache.put_weather(city, weather_data)
          weather_data

        error_message ->
          error_message
      end
    end
  end

  defp make_api_request(city, api_key) do
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
        "Invalid API key"

      {:ok, %{status: 404}} ->
        "City '#{city}' not found"

      {:ok, %{status: 429}} ->
        "API rate limit exceeded"

      {:error, %{reason: :timeout}} ->
        "API request timeout"

      {:error, _reason} ->
        "Weather service connection error"
    end
  end

  defp parse_weather_response(api_response) do
    weather_info = List.first(api_response["weather"], %{})

    %{
      temperature: format_temperature(api_response["main"]["temp"]),
      condition: weather_info["description"] || "невідомо",
      humidity: "#{api_response["main"]["humidity"]}%",
      wind: format_wind_speed(api_response["wind"]["speed"]),
      precipitation: get_precipitation(api_response)
    }
  end

  defp format_temperature(temp) when is_number(temp) do
    "#{round(temp)}°C"
  end

  defp format_wind_speed(speed) when is_number(speed) do
    formatted_speed = Float.round(speed, 1)
    "#{formatted_speed} m/s"
  end

  defp get_precipitation(api_response) do
    cond do
      api_response["rain"] && api_response["rain"]["1h"] > 0 ->
        rain_amount = Float.round(api_response["rain"]["1h"], 1)
        "rain: #{rain_amount} mm/h"

      api_response["snow"] && api_response["snow"]["1h"] > 0 ->
        snow_amount = Float.round(api_response["snow"]["1h"], 1)
        "snow: #{snow_amount} mm/h"

      true ->
        "no precipitation"
    end
  end
end
