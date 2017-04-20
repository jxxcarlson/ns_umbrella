defmodule Benchee.Formatters.Console do
  @moduledoc """
  Formatter to transform the statistics output into a structure suitable for
  output through `IO.puts` on the console.
  """

  alias Benchee.Statistics
  alias Benchee.Conversion.{Count, Duration, DeviationPercent}

  @default_label_width 4 # Length of column header
  @ips_width 13
  @average_width 15
  @deviation_width 11
  @median_width 15

  @doc """
  Formats the bench statistis using `Benchee.Formatters.Console.format/1`
  and then prints it out directly to the console using `IO.puts/2`
  """
  def output(suite) do
    suite
    |> format
    |> IO.write
  end

  @doc """
  Formats the bench statistics to a report suitable for output on the CLI.

  Returns a list of lists, where each list element is a group belonging to one
  specific input. So if there only was one (or no) input given through `:inputs`
  then there's just one list inside.

  ## Examples

  ```
  iex> jobs = %{ "My Job" =>%{average: 200.0, ips: 5000.0,std_dev_ratio: 0.1, median: 190.0}, "Job 2" => %{average: 400.0, ips: 2500.0, std_dev_ratio: 0.2, median: 390.0}}
  iex> inputs = %{"My input" => jobs}
  iex> Benchee.Formatters.Console.format(%{statistics: inputs, config: %{console: %{comparison: false, unit_scaling: :best}}})
  [["\n##### With input My input #####", "\nName             ips        average  deviation         median\n",
  "My Job        5.00 K      200.00 μs    ±10.00%      190.00 μs\n",
  "Job 2         2.50 K      400.00 μs    ±20.00%      390.00 μs\n"]]

  ```

  """
  def format(%{statistics: jobs_per_input, config: %{console: config}}) do
    jobs_per_input
    |> Enum.map(fn({input, jobs_stats}) ->
         [input_header(input) | format_jobs(jobs_stats, config)]
       end)
  end

  defp input_header(input) do
    no_input_marker = Benchee.Benchmark.no_input
    case input do
      ^no_input_marker -> ""
      _                -> "\n##### With input #{input} #####"
    end
  end

  @doc """
  Formats the job statistics to a report suitable for output on the CLI.

  ## Examples

  ```
  iex> jobs = %{ "My Job" =>%{average: 200.0, ips: 5000.0,std_dev_ratio: 0.1, median: 190.0}, "Job 2" => %{average: 400.0, ips: 2500.0, std_dev_ratio: 0.2, median: 390.0}}
  iex> Benchee.Formatters.Console.format_jobs(jobs, %{comparison: false, unit_scaling: :best})
  ["\nName             ips        average  deviation         median\n",
  "My Job        5.00 K      200.00 μs    ±10.00%      190.00 μs\n",
  "Job 2         2.50 K      400.00 μs    ±20.00%      390.00 μs\n"]

  ```

  """
  def format_jobs(job_stats, config) do
    sorted_stats = Statistics.sort(job_stats)
    units = units(sorted_stats, config)
    label_width = label_width job_stats

    [column_descriptors(label_width) |
      job_reports(sorted_stats, units, label_width)
      ++ comparison_report(sorted_stats, units, label_width, config)]
  end

  defp column_descriptors(label_width) do
    "\n~*s~*s~*s~*s~*s\n"
    |> :io_lib.format([-label_width, "Name", @ips_width, "ips",
                       @average_width, "average",
                       @deviation_width, "deviation", @median_width, "median"])
    |> to_string
  end

  defp label_width(jobs) do
    max_label_width = jobs
      |> Enum.map(fn({job_name, _}) -> String.length(job_name) end)
      |> Stream.concat([@default_label_width])
      |> Enum.max
    max_label_width + 1
  end

  defp job_reports(jobs, units, label_width) do
    Enum.map(jobs, fn(job) -> format_jobs job, units, label_width end)
  end

  defp units(jobs, %{unit_scaling: scaling_strategy}) do
    # Produces a map like
    #   %{run_time: [12345, 15431, 13222], ips: [1, 2, 3]}
    measurements =
      jobs
      |> Enum.flat_map(fn({_name, job}) -> Map.to_list(job) end)
      # TODO: Simplify when dropping support for 1.2
      # For compatibility with Elixir 1.2. In 1.3, the following group-reduce-map
      # can b replaced by a single call to `group_by/3`
      #   Enum.group_by(fn({stat_name, _}) -> stat_name end, fn({_, value}) -> value end)
      |> Enum.group_by(fn({stat_name, _value}) -> stat_name end)
      |> Enum.reduce(%{}, fn({stat_name, occurrences}, acc) ->
        Map.put(acc, stat_name, Enum.map(occurrences, fn({_stat_name, value}) -> value end))
      end)

    %{
      run_time: Duration.best(measurements.average, strategy: scaling_strategy),
      ips:      Count.best(measurements.ips, strategy: scaling_strategy),
    }
  end

  defp format_jobs({name, %{average:       average,
                           ips:           ips,
                           std_dev_ratio: std_dev_ratio,
                           median:        median}
                         },
                         %{run_time:      run_time_unit,
                           ips:           ips_unit,
                         }, label_width) do
    "~*s~*ts~*ts~*ts~*ts\n"
    |> :io_lib.format([-label_width, name, @ips_width, ips_out(ips, ips_unit),
                       @average_width, run_time_out(average, run_time_unit),
                       @deviation_width, deviation_out(std_dev_ratio),
                       @median_width, run_time_out(median, run_time_unit)])
    |> to_string
  end

  defp ips_out(ips, unit) do
    Count.format({Count.scale(ips, unit), unit})
  end

  defp run_time_out(average, unit) do
    Duration.format({Duration.scale(average, unit), unit})
  end

  defp deviation_out(std_dev_ratio) do
    DeviationPercent.format(std_dev_ratio)
  end

  defp comparison_report([_reference], _, _, _config) do
    [] # No need for a comparison when only one bench was run
  end
  defp comparison_report(_, _, _, %{comparison: false}) do
    []
  end
  defp comparison_report([reference | other_jobs], units, label_width, _config) do
    [
      comparison_descriptor(),
      reference_report(reference, units, label_width) |
      comparisons(reference, units, label_width, other_jobs)
    ]
  end

  defp reference_report({name, %{ips: ips}}, %{ips: ips_unit}, label_width) do
    "~*s~*s\n"
    |> :io_lib.format([-label_width, name, @ips_width, ips_out(ips, ips_unit)])
    |> to_string
  end

  defp comparisons({_, reference_stats}, units, label_width, jobs_to_compare) do
    Enum.map jobs_to_compare, fn(job = {_, job_stats}) ->
      format_comparison(job, units, label_width, (reference_stats.ips / job_stats.ips))
    end
  end

  defp format_comparison({name, %{ips: ips}}, %{ips: ips_unit}, label_width, times_slower) do
    "~*s~*s - ~.2fx slower\n"
    |> :io_lib.format([-label_width, name, @ips_width, ips_out(ips, ips_unit), times_slower])
    |> to_string
  end

  defp comparison_descriptor do
    "\nComparison: \n"
  end
end
