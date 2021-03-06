defmodule Forecastr.Renderer.ASCII do
  @moduledoc false

  @relevant_times %{
    "09:00:00" => "Morning",
    "12:00:00" => "Noon",
    "18:00:00" => "Afternoon",
    "21:00:00" => "Evening",
    "00:00:00" => "Night"
  }

  @weather_codes %{
    200 => :codethunderyshowers,
    201 => :codethunderyshowers,
    210 => :codethunderyshowers,
    230 => :codethunderyshowers,
    231 => :codethunderyshowers,
    202 => :codethunderyheavyrain,
    211 => :codethunderyheavyrain,
    212 => :codethunderyheavyrain,
    221 => :codethunderyheavyrain,
    232 => :codethunderyheavyrain,
    300 => :codelightrain,
    301 => :codelightrain,
    310 => :codelightrain,
    311 => :codelightrain,
    313 => :codelightrain,
    321 => :codelightrain,
    302 => :codeheavyrain,
    312 => :codeheavyrain,
    314 => :codeheavyrain,
    500 => :codelightshowers,
    501 => :codelightshowers,
    502 => :codeheavyshowers,
    503 => :codeheavyshowers,
    504 => :codeheavyshowers,
    511 => :codelightsleet,
    520 => :codelightshowers,
    521 => :codelightshowers,
    522 => :codeheavyshowers,
    531 => :codeheavyshowers,
    600 => :codelightsnow,
    601 => :codelightsnow,
    602 => :codeheavysnow,
    611 => :codelightsleet,
    612 => :codelightsleetshowers,
    615 => :codelightsleet,
    616 => :codelightsleet,
    620 => :codelightsnowshowers,
    621 => :codelightsnowshowers,
    622 => :codeheavysnowshowers,
    701 => :codefog,
    711 => :codefog,
    721 => :codefog,
    741 => :codefog,
    # sand, dust whirls
    731 => :codeunknown,
    # sand
    751 => :codeunknown,
    # dust
    761 => :codeunknown,
    # volcanic ash
    762 => :codeunknown,
    # squalls
    771 => :codeunknown,
    # tornado
    781 => :codeunknown,
    800 => :codesunny,
    801 => :codepartlycloudy,
    802 => :codecloudy,
    803 => :codeverycloudy,
    804 => :codeverycloudy,
    # tornado
    900 => :codeunknown,
    # tropical storm
    901 => :codeunknown,
    # hurricane
    902 => :codeunknown,
    # cold
    903 => :codeunknown,
    # hot
    904 => :codeunknown,
    # windy
    905 => :codeunknown,
    # hail
    906 => :codeunknown,
    # calm
    951 => :codeunknown,
    # light breeze
    952 => :codeunknown,
    # gentle breeze
    953 => :codeunknown,
    # moderate breeze
    954 => :codeunknown,
    # fresh breeze
    955 => :codeunknown,
    # strong breeze
    956 => :codeunknown,
    # high wind, near gale
    957 => :codeunknown,
    # gale
    958 => :codeunknown,
    # severe gale
    959 => :codeunknown,
    # storm
    960 => :codeunknown,
    # violent storm
    961 => :codeunknown,
    # hurricane
    962 => :codeunknown
  }

  @type weather :: map()
  @spec render(weather) :: :ok | list()
  def render(weather)
  @doc "Render today weather condition"
  def render(
        %{
          "name" => name,
          "sys" => %{"country" => country},
          "coord" => %{"lat" => lat, "lon" => lon},
          "weather" => weather,
          "main" => %{"temp" => temp, "temp_max" => temp_max, "temp_min" => temp_min}
        }
      ) do
    %{"description" => main_weather_condition, "id" => weather_id} = extract_main_weather(weather)
    weather_code = Map.get(@weather_codes, weather_id, :codeunknown)

    [
      ~s(Weather report: #{name}, #{country}\n),
      ~s(lat: #{lat}, lon: #{lon}\n),
      "\n",
      Table.table(
        [
          weather_code
          |> ascii_for()
          |> append_weather_info(main_weather_condition, temp, temp_max, temp_min)
        ],
        :unicode
      )
    ]
  end

  @doc "Render five days weather condition"
  def render(
        %{
          "city" => %{
            "name" => name,
            "country" => country,
            "coord" => %{"lat" => lat, "lon" => lon}
          },
          "list" => forecast_list
        }
      )
      when is_list(forecast_list) do
    forecasts =
      forecast_list
      |> extract_relevant_times()
      |> group_by_date()
      |> prepare_forecasts_for_rendering()

    # TODO: align correctly tabular output when we have different ASCII art
    # shapes
    [
      [
        ~s(Weather report: #{name}, #{country}\n),
        ~s(lat: #{lat}, lon: #{lon}\n),
        "\n"
      ] | [forecasts]
    ]
  end

  # TODO: re-organize weather info with humidity etc
  # We should pass a map as a parameter
  def append_weather_info(ascii, description, temperature, temp_max, temp_min) do
    # The weather information to append to the ASCII art
    weather_info = [
      "#{description}     ",
      "#{temperature} °C  ",
      "max: #{temp_max} °C",
      "min: #{temp_min} °C"
    ]

    # Convert the ASCII to a list
    ascii_list = String.split(ascii, "\n")

    ascii_art_longest_line =
      ascii_list
      |> Stream.map(&String.length/1)
      |> Enum.max()

    weather_length = Enum.count(weather_info)

    ascii_art_length = Enum.count(ascii_list)

    # ASCII that we want to process together with weather_info
    ascii_subset = Enum.slice(ascii_list, 0..weather_length)

    # Concatenate the ascii subset with the weather info
    # Add the rest of the ascii art
    ascii_with_weather_info =
      ascii_subset
      |> concat_ascii_with_weather_info(weather_info, ascii_art_longest_line)

    [ascii_with_weather_info | Enum.slice(ascii_list, weather_length..ascii_art_length)]
    |> List.flatten()
    |> Enum.join("\n")
  end

  @spec ascii_for(atom()) :: String.t()
  def ascii_for(:codeunknown) do
    """
    .-.
    __)
    (
    `-᾿
      •
    """
  end

  def ascii_for(:codecloudy) do
    """
       .--.
    .-(    ).
    (___.__)__)

    """
  end

  def ascii_for(:codefog) do
    """
    _ - _ - _ -
    _ - _ - _
    _ - _ - _ -

    """
  end

  def ascii_for(:codeheavyrain) do
    """
         .-.
        (   ).
      (___(__)
    ‚ʻ‚ʻ‚ʻ‚ʻ
    ‚ʻ‚ʻ‚ʻ‚ʻ
    """
  end

  def ascii_for(:codeheavyshowers) do
    """
    _`/\"\".-.
     ,\\_(   ).
     /\(___(__)
       ‚ʻ‚ʻ‚ʻ‚ʻ
       ‚ʻ‚ʻ‚ʻ‚ʻ
    """
  end

  def ascii_for(:codeheavysnow) do
    """
       .-.
      (   ).
      (___(__)
      * * * *
    * * * *
    """
  end

  def ascii_for(:codeheavysnowshowers) do
    """
    _`/\"\".-.
     ,\\_(   ).
      /(___(__)
          * * * *
        * * * *
    """
  end

  def ascii_for(:codelightrain) do
    """
       .-.
      (   ).
    (___(__)
      ʻ ʻ ʻ ʻ
    ʻ ʻ ʻ ʻ
    """
  end

  def ascii_for(:codelightshowers) do
    """
    _`/\"\".-.
     ,\\_(   ).
     /(___(__)
       ʻ ʻ ʻ ʻ
       ʻ ʻ ʻ ʻ
    """
  end

  def ascii_for(:codelightsleet) do
    """
      .-.
     (   ).
    (___(__)
     ʻ * ʻ *
    * ʻ * ʻ
    """
  end

  def ascii_for(:codelightsleetshowers) do
    """
    _`/\"\".-.
     ,\\_\(   ).
      /(___(__)
       ʻ * ʻ *
      * ʻ * ʻ
    """
  end

  def ascii_for(:codelightsnow) do
    """
       .-.
      (   ).
    (___(__)
      *  *  *
    *  *  *
    """
  end

  def ascii_for(:codelightsnowshowers) do
    """
    _`/\"\".-.
     ,\\_\(   ).
     /(___(__)
       *  *  *
       *  *  *
    """
  end

  def ascii_for(:codepartlycloudy) do
    """
      \\  /
    _ /\"\".-.
      \\_(   ).
      /(___(__)
    """
  end

  def ascii_for(:codesunny) do
    """
      \\   /
       .-.
    ‒ (   ) ‒
       `-᾿
      /   \\
    """
  end

  def ascii_for(:codethunderyheavyrain) do
    """
         .-.
        (   ).
      (___(__)
    ‚ʻ⚡ʻ‚⚡‚ʻ
    ‚ʻ‚ʻ⚡ʻ‚ʻ
    """
  end

  def ascii_for(:codethunderyshowers) do
    """
    _`/\"\".-.
     ,\\_(   ).
     /(___(__)
       ⚡ʻ ʻ⚡ʻ
     ʻ ʻ ʻ ʻ
    """
  end

  def ascii_for(:codethunderysnowshowers) do
    """
    _`/\"\".-.
     ,\\_(   ).
     /(___(__)
       *⚡ *⚡
       *  *  *
    """
  end

  def ascii_for(:codeverycloudy) do
    """
       .--.
    .-(    ).
    (___.__)__)

    """
  end

  defp concat_ascii_with_weather_info(ascii_subset, weather_info, ascii_art_longest_line) do
    blank_space = 1

    Enum.map(
      Stream.zip(ascii_subset, weather_info), fn {ascii, weather} ->
        current_length = String.length(ascii)
        additional_blank_spaces = ascii_art_longest_line - current_length + blank_space
        to_pad = current_length + additional_blank_spaces

        ascii
        |> String.pad_trailing(to_pad)
        |> Kernel.<>(weather)
    end)
  end

  defp prepare_forecasts_for_rendering(forecasts) do
    forecasts
    |> Enum.map(fn {date, forecasts} ->
      forecasts =
        forecasts
        |> Enum.reduce([], fn %{
                                "weather" => weather,
                                "dt_txt" => date_time,
                                "main" => %{
                                  "temp" => temp,
                                  "temp_max" => temp_max,
                                  "temp_min" => temp_min
                                }
                              },
                              acc ->
          %{"description" => main_weather_condition, "id" => weather_id} =
            extract_main_weather(weather)

          weather_code = Map.get(@weather_codes, weather_id, :codeunknown)
          time = extract_time(date_time)
          period_of_the_day = Map.get(@relevant_times, time)

          ascii =
            weather_code
            |> ascii_for()
            |> append_weather_info(main_weather_condition, temp, temp_max, temp_min)

          ["#{period_of_the_day} [#{time}]\n" <> ascii | acc]
        end)
        |> Enum.reverse()

      [Table.table([date], :unicode), Table.table([forecasts], :unicode)]
    end)
  end

  defp group_by_date(list) do
    Enum.group_by(list, fn element ->
      <<year::bytes-size(4)>> <>
        "-" <> <<month::bytes-size(2)>> <> "-" <> <<day::bytes-size(2)>> <> _rest =
        element["dt_txt"]

      year <> "-" <> month <> "-" <> day
    end)
  end

  defp extract_relevant_times(forecast_list) do
    forecast_list
    |> Stream.filter(fn element ->
      time = extract_time(element["dt_txt"])
      time in Map.keys(@relevant_times) == true
    end)
  end

  defp extract_main_weather(weather) do
    List.first(weather)
  end

  defp extract_time(date) do
    <<_year::bytes-size(4)>> <>
      "-" <> <<_month::bytes-size(2)>> <> "-" <> <<_day::bytes-size(2)>> <> " " <> time = date

    time
  end
end
