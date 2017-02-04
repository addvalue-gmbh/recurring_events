defmodule RecurringEvents do
  alias RecurringEvents.{Date, Guards,
                         Yearly, Monthly, Weekly, Daily,
                         ByMonth, ByDay}
  use Guards

  def unfold(_date, %{count: _, until: _}) do
    {:error, "Can have either, count or until"}
  end

  def unfold(date, %{freq: freq} = params) when is_freq_valid(freq) do
    {:ok, unfold!(date, params)}
  end

  def unfold(_date, %{freq: _}), do: {:error, "Frequency is invalid"}
  def unfold(_date, _rrule), do: {:error, "Frequency is missing"}

  def unfold!(date, %{freq: freq} = params) do
    date
    |> get_freq_module(freq).unfold!(params)
    |> Stream.flat_map(&ByMonth.unfold &1, params)
    |> Stream.flat_map(&ByDay.unfold &1, params)
    |> drop_before(date)
    |> prepend(date)
    |> drop_after(params)
  end

  defp drop_before(list, date) do
    Stream.drop_while(list, &(Date.compare(date, &1) != :lt))
  end

  defp drop_after(list, %{until: date}) do
    Stream.take_while(list, &(Date.compare(date, &1) != :lt))
  end
  defp drop_after(list, %{count: count}), do: Stream.take(list, count)
  defp drop_after(list, %{}), do: list

  defp prepend(list, element), do: Stream.concat([element], list)

  defp get_freq_module(:yearly), do: Yearly
  defp get_freq_module(:monthly), do: Monthly
  defp get_freq_module(:weekly), do: Weekly
  defp get_freq_module(:daily), do: Daily
end
