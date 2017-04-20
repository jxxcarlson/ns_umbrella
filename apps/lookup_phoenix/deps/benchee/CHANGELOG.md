# 0.6.0 (November 30, 2016)

One of the biggest releases yet. Great stuff in here - more elixir like API for `Benchee.run/2` with the jobs as the primary argument and the optional options as the second argument and now also as the more idiomatic keyword list!

The biggest feature apart from that is the possibility to use multiple inputs - which you all should do now as quite many functions behave differently with bigger, smaller or differently shaped inputs. Apart from that a bulk of work has gone into making and supporting [benchee_html](https://github.com/PragTob/benchee_html)!

## Features (User Facing)

* New `:inputs` configuration key that allows you to specify a map from input name to input value so that each defined benchmarking job is then executed with this input. For this to work the benchmarking function is called with the appropriate `input` as an argument. See [`samples/multiple_inputs.exs`](https://github.com/PragTob/benchee/blob/master/samples/multiple_inputs.exs) for an example. [#21]( https://github.com/PragTob/benchee/issues/21)
* The highlevel `Benchee.run/2` is now more idiomatic elixir and takes the map of jobs as the first argument and a keywordlist of options as the second (and last) argument. The old way of passing config as a map as the first argument and the jobs as the second argument still works, **but might be deprecated later on** [#47](https://github.com/PragTob/benchee/issues/47)
* Along with that `Benchee.init/1` now also accepts keyword lists of course

## Breaking Changes (User Facing)

* The old way of providing the jobs as a list of tuples now removed, please switch to using a map from string to functions

## Features (Plugins)

* `Benchee.Utility.FileCreation` module to help with creating files from a map of multiple inputs (or other descriptors) mapping to input and an `interleave` function that spits out the correct file names especially if the `:__no_input` marker is used
* `Benchee.System` is available to retrieve elixir and erlang versions but it's
also already added to the suite during `Benchee.run/2`

## Breaking Changes (Plugins)

* The structure of the output from `Benchee.Benchmark.measure/1` to `Benchee.Statistics.statistics/1` has changed to accommodate the new inputs feature there is now an additional level where in a map the input name then points to the appropriate results of the jobs. When there were no inputs the key is the value returned by `Benchee.Benchmark.no_input/0`.

## Bugfixes

* prewarming (discarding the first result due to some timer issues) during run time was removed, as it should already happen during the warmup period and would discard actual useful results especially for longer running macro benchmarks.
* when the execution time of the benchmarking job exceeds the given `:time` it will now execute exactly once (used to be 2) [#49](https://github.com/PragTob/benchee/issues/49)
* `run_times` are now in the order as recorded (used to be reverse) - important when wants to graph them/look at them to see if there are any anomalities during benchmarking
* Remove elixir 1.4.0-rc.0 warnings

# 0.5.0 (October 13, 2016)

This release focuses on scaling units to more appropriate sizes. Instead of always working with base one for counts and microseconds those values are scaled accordingly to thousands, milliseconds for better readability. This work was mostly done by new contributor @wasnotrice.

## Features (User Facing)

* Console output now scales units to be more friendly. Examples:
    * instead of "44556677" ips, you would see "44.56 M"
    * instead of "44556.77 μs" run time, you would see "44.56 ms"
* Console output for standard deviation omits the parentheses
* Scaling of console output can be configured with the 4 different strategies `:best`, `:largest`, `:smallest` and `:none`. Refer to the documentation for their different properties.
* Shortened the fast function warning and instead [linked to the wiki](https://github.com/PragTob/benchee/wiki/Benchee-Warnings#fast-execution-warning)

## Features (Plugins)

* The statistics module now computes the `minimum`, `maximum` and `sample_size` (not yet shown in the console formatter)
* you can rely on `Benchee.Conversion.Duration`, `Benchee.Conversion.Count` and `Benchee.Conversion.DeviationPercent` for help with formatting and scaling units

## Breaking Changes (Plugins)

* The `Benchee.Time`module is gone, if you relied on it for one reason or another it's succeeded by the more powerful `Benchee.Conversion.Duration`

# 0.4.0 (September 11, 2016)

Focuses on making what benchee print out configurable to make it fit to your preferences :)

## Features (User Facing)
* The configuration now has a `:print` key where it is possible to configure in a map what benchee prints out during benchmarking. All options are enabled by default (true). Options are:
  * `:benchmarking`  - print when Benchee starts benchmarking a new job (Benchmarking name ..)
  * `:configuration` - a summary of configured benchmarking options including estimated total run time is printed before benchmarking starts
  * `:fast_warning` - warnings are displayed if functions are executed too    fast leading to inaccurate measures
* There is also a new configuration option for the built-in console formatter. Which is also enabled by default:
  * `:comparison` - if the comparison of the different benchmarking jobs (x times slower than) is shown
* The pre-benchmarking output of the configuration now also prints the currently used Erlang and Elixir versions (similar to `elixir -v`)
* Add a space between the benchmarked time and the unit (microseconds)

# 0.3.0 (July 11, 2016)

This release switches internal data structures from lists of tuples to maps, allows the configuration of formatters, aggregates all values and hands them down so formatters can access the whole configuration, prints general configuration information and much more great stuff :)

## Breaking Changes (User Facing)
* The recommended data structure handed to `Benchee.run` was changed from a list of 2-element tuples to a map (`"Name" => benchmark_function`). However, **the old list of tuples still works but may be removed in future releases** (so it's not "breaking" _strictly_ speaking).
* You **can not have bench jobs with the same names anymore**, the last one wins here. This was the reason why previously the data structure was a list of tuples. However, having benchmarks with the same name is nonsensical as you can't discern their results in the output any way.

## Breaking Changes (Plugins)
* main data structure to hold benchmarks and results was changed from a list of 2-element tuples to a map (`"Name" => values`). That is for the jobs, the run times as well as the statistics. However, if you used something like `Enum.each(data, fn({name, value}) -> .. end)` you are still fine though, cause Elixir is awesome :)

## Features (User Facing)
* now takes a `parallel: number` configuration option and will then execute each job in parallel in as many parallel processes as specified in `number`. This way you can gather more samples in the same time and also simulate a system more under load. This is tricky, however. One of the use cases is also stress testing a system. Thanks @ldr
* the name column width is now determined based on the longest name. Thanks @alvinlindstam
* Print general configuration information at the start of the bench, including warmup, time, parallel and an estimated total run time
* New method `Benchee.Formatters.Console.output/1` that immediately prints to the console
* now takes a `formatters: [&My.Format.function/1, &Benchee.Formatters.console.output/1]` configuration option with which multiple formatters for the same benchmarking run can be configured when using `Benchee.run/2`. E.g. you can print results to the console and create a csv from that same run. Defaults to the builtin Console formatter.

## Features (Plugins)
* All previous configuration options are preserved after `Benchee.Statistics.statistics/1`, meaning there is access to raw run times as well as custom options etc. E.g. you could grab custom options like `%{csv: %{file: "my_file_name.csv"}}` to use.

## Bugfixes
* name columns are no longer truncated after 30 characters. Thanks @alvinlindstam

# 0.2.0 (June 11, 2016)

This release introduces warmup for benchmarks, nicer console output and the new `Benchee.measure` that runs the benchmarks previously defined instead of running them instantly.

## Breaking Changes (User Facing)
* `Benchee.bench/3` now doesn't run the bench anymore but simply adds it to `:jobs` in the config. The whole bench suite is then run via `Benchee.measure/1`. This only affects you if you used the more verbose way of defining benchmarks, `Benchee.run/2` still work as before.

## Breaking Changes (Plugins)
* the defined benchmarking are now preserved after running the bench under the `:jobs` key of the suite. Run times are added to the `:run_times` key of the suite (important for alternative statistics implementations)

## Features (User Facing)

* configuring a warmup time to run functions before measurements are taken can be configured via the `warmup` key in the config defaulting to 2 (seconds)

* statistics in console output are aligned right now for better comparisons
* last blank line of console output removed

## Features (Plugins)
* additionally supply the total standard deviation of iterations per second as `std_dev_ips` after `Benchee.Statistics.statistics`

## Bugfixes

* if no time/warmup is specified the function won't be called at all

# 0.1.0 (June 5, 2016)

Initial release
