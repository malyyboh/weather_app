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

    render(conn, :index,
      weather:
        Map.get(
          @cities_weather,
          normalized_city,
          "Дані про це місто недоступні, спробуйте інше місто"
        ),
      city: normalized_city,
      layout: false
    )
  end

  def index(conn, _params) do
    render(conn, :index)
  end
end
