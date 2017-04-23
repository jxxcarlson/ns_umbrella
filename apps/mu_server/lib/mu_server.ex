defmodule MU.Server do

  alias LookupPhoenix.Utility

  @name MUServer

  @module_doc """
  The call `MU.Server.render("This _is_ a test"}` returns

  {:ok, "<p>\n This <i>is</i> test. \n</p>\n\n"}

  by calling MU.RenderText.transform(text).  That is,
  MU
"""
   use GenServer

    def start_link(opts \\ []) do
      IO.puts "Starting MU.Server ..."
      GenServer.start_link(__MODULE__, :ok, opts ++ [name: MUServer])
    end

    def stop do
        GenServer.cast(@name, :stop)
    end

    def render(message) do
      IO.puts "Rendering ... "
      GenServer.call(@name, {:render, message})
    end

    def get_stats do
      GenServer.call(@name, :get_stats)
    end

    def reset_stats do
      GenServer.cast(@name, :reset_stats)
    end


 # SERVER

   def init(:ok) do
       {:ok, %{requests: 0, characters: 0, processing_time: 0.0, rate: 0.0, t_per_request: 0.0}}
     end


    def handle_call({:render, message}, _from, stats) do
      start_time = Timex.now

      rendered_text = MU.RenderText.transform(message.text, message.options)
      # {:ok, rendered_text} = RubyBridge.render_asciidoc(message.text)
      # rendered_text = rendered_text <> "\n\n" <> MU.MathSci.inject_mathjax2()
      # IO.puts "ASCIIDOC => ???"
#      if message.options["processs"] == "asciidoctor" do
#        rendered_text = RubyBridge.render_asciidoc(message.text)
#      else
#        # rendered_text = RubyBridge.render_asciidoc(message.text)
#        rendered_text = MU.RenderText.transform(message.text, message.options)
#      end


      finish_time = Timex.now

      elapsed_time = Timex.diff( finish_time, start_time, :microseconds)
      requests = stats.requests + 1
      total_elapsed_time = stats.processing_time + elapsed_time
      characters = String.length(rendered_text)
      total_characters = stats.characters + characters
      rate = 1000*total_elapsed_time/total_characters

      t_per_request = total_elapsed_time/requests

      new_stats = %{ requests: stats.requests + 1,
        characters: total_characters,
        processing_time: total_elapsed_time,
        rate: rate, t_per_request: t_per_request}
      {:reply, {:ok, rendered_text}, new_stats}
    end

    def handle_call(:get_stats, _from, stats) do

       characters = stats.characters/1000.0 |> Float.round(0)
       processing_time = stats.processing_time/(1000.0*1000.0) |> Float.round(3)
       rate = stats.rate/1000.0 |> Float.round(1)
       time_per_request = stats.t_per_request/1000.0 |> Float.round(1)


       reply = %{requests: stats.requests,
                 kchars: characters,
                 processing_time: processing_time,
                 rate: rate,
                 t_per_request: time_per_request
                 }
       Utility.report("reply", reply)
       {:reply, reply, stats}
    end

    def handle_cast(:reset_stats, _stats) do
      {:noreply, %{}}
    end

    def handle_cast(:stop, stats) do
      {:stop, :normal, stats}
    end

    def handle_info(msg, stats) do
      IO.puts "received #{inspect msg}"
      {:noreply, stats}
    end


end