defmodule Benchee.Conversion.Scale do
  @moduledoc """
  Functions for scaling values to other units. Different domains handle
  this task differently, for example durations and counts.

  See `Benchee.Conversion.Count` and `Benchee.Conversion.Duration` for examples
  """

  alias Benchee.Conversion.Unit

  @type unit :: Unit.t
  @type unit_atom :: atom
  @type any_unit :: unit | unit_atom
  @type scaled_number :: {number, unit}

  # In 1.3, this could be declared as `keyword`, but use a custom type so it
  # will also compile in 1.2
  @type options ::[{atom, atom}]

  @doc """
  Scales a number in a domain's base unit to an equivalent value in the best
  fit unit. Results are a `{number, unit}` tuple. See `Benchee.Conversion.Count` and
  `Benchee.Conversion.Duration` for examples
  """
  @callback scale(number) :: scaled_number

  @doc """
  Scales a number in a domain's base unit to an equivalent value in the
  specified unit. Results are a `{number, unit}` tuple. See
  `Benchee.Conversion.Count` and `Benchee.Conversion.Duration` for examples
  """
  @callback scale(number, any_unit) :: number

  @doc """
  Finds the best fit unit for a list of numbers in a domain's base unit.
  "Best fit" is the most common unit, or (in case of tie) the largest of the
  most common units.
  """
  @callback best(list, options) :: unit

  @doc """
  Returns the base_unit in which Benchee takes its measurements, which in
  general is the smallest supported unit.
  """
  @callback base_unit :: unit

  @doc """
  Given the atom representation of a unit (`:hour`) return the appropriate
  `Benchee.Conversion.Unit` struct.
  """
  @callback unit_for(unit_atom) :: unit

  # Generic scaling functions

  @doc """
  Used internally by implemented units to handle their scaling with units and
  without.

  ## Examples

      iex> Benchee.Conversion.Scale.scale(12345, :thousand, Benchee.Conversion.Count)
      12.345
  """
  def scale(value, unit = %Unit{}, _module) do
    scale(value, unit)
  end
  def scale(value, unit_atom, module) do
    scale value, module.unit_for(unit_atom)
  end

  @doc """
  Used internally for scaling but only supports scaling with actual units.

  ## Examples

      iex> unit = %Benchee.Conversion.Unit{magnitude: 1000}
      iex> Benchee.Conversion.Scale.scale 12345, unit
      12.345
  """
  def scale(value, %Unit{magnitude: magnitude}) do
    value / magnitude
  end

  @doc """
  Lookup a unit by its `atom` presentation for the representation of supported
  units. Used by `Benchee.Conversion.Duration` and `Benchee.Conversion.Count`.
  """
  def unit_for(units, unit) do
    Map.fetch! units, unit
  end

  @doc """
  Given a `list` of number values and a `module` describing the domain of the
  values (e.g. Duration, Count), finds the "best fit" unit for the list as a
  whole.

  The best fit unit for a given value is the smallest unit in the domain for
  which the scaled value is at least 1. For example, the best fit unit for a
  count of 1_000_000 would be `:million`.

  The best fit unit for the list as a whole depends on the `:strategy` passed
  in `opts`:

  * `:best`     - the most frequent best fit unit. In case of tie, the
  largest of the most frequent units
  * `:largest`  - the largest best fit unit
  * `:smallest` - the smallest best fit unit
  * `:none`     - the domain's base (unscaled) unit

  ## Examples

      iex> list = [1, 101, 1_001, 10_001, 100_001, 1_000_001]
      iex> Benchee.Conversion.Scale.best_unit(list, Benchee.Conversion.Count, strategy: :best).name
      :thousand

      iex> list = [1, 101, 1_001, 10_001, 100_001, 1_000_001]
      iex> Benchee.Conversion.Scale.best_unit(list, Benchee.Conversion.Count, strategy: :smallest).name
      :one

      iex> list = [1, 101, 1_001, 10_001, 100_001, 1_000_001]
      iex> Benchee.Conversion.Scale.best_unit(list, Benchee.Conversion.Count, strategy: :largest).name
      :million
  """
  def best_unit(list, module, opts) do
    case Keyword.get(opts, :strategy, :best) do
      :best     -> best_unit(list, module)
      :largest  -> largest_unit(list, module)
      :smallest -> smallest_unit(list, module)
      :none     -> module.base_unit
    end
  end

  # Finds the most common unit in the list. In case of tie, chooses the
  # largest of the most common
  defp best_unit(list, module) do
    list
    |> Enum.map(fn n -> scale_unit(n, module) end)
    |> Enum.group_by(fn unit -> unit end)
    |> Enum.map(fn {unit, occurrences} -> {unit, length(occurrences)} end)
    |> Enum.sort(fn unit, freq -> by_frequency_and_magnitude(unit, freq) end)
    |> hd
    |> elem(0)
  end

  # Finds the smallest unit in the list
  defp smallest_unit(list, module) do
    list
    |> Enum.map(fn n -> scale_unit(n, module) end)
    |> Enum.min_by(fn unit -> magnitude(unit) end)
  end

  # Finds the largest unit in the list
  defp largest_unit(list, module) do
    list
    |> Enum.map(fn n -> scale_unit(n, module) end)
    |> Enum.max_by(fn unit -> magnitude(unit) end)
  end

  defp scale_unit(count, module) do
    {_, unit} = module.scale(count)
    unit
  end

  # Fetches the magnitude for the given unit
  defp magnitude(%Unit{magnitude: magnitude}) do
    magnitude
  end

  # Sorts two elements first by total, then by magnitude of the unit in case
  # of tie
  defp by_frequency_and_magnitude({unit_a, frequency}, {unit_b, frequency}) do
    magnitude(unit_a) > magnitude(unit_b)
  end
  defp by_frequency_and_magnitude({_, frequency_a}, {_, frequency_b}) do
    frequency_a > frequency_b
  end
end
