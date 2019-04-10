defmodule Mandelixir.Scene.Home do
  use Scenic.Scene
  require Logger

  alias Scenic.Graph
  alias Scenic.ViewPort

  import Scenic.Primitives

  @initial_transform {3.5, 2.5, 2.0, 1.0}
  @move_factor 0.1
  @scale_factor 1.5

  @note """
  Controls:
    Zoom In: W
    Zoom Out: S
    Move: Arrow keys
    Save mandelixir.pgm: F1
  """

  @text_size 24

  def init(_, opts) do
    {:ok, %ViewPort.Status{size: {width, height}}} = ViewPort.info(opts[:viewport])

    output_buffer_size = Mandelixir.OpenCL.ensure_output_buffer(width, height)

    state = %{
      width: width,
      height: height,
      output_buffer_size: output_buffer_size,
      transform: @initial_transform
    }

    render_mandelbrot(state)

    graph =
      Graph.build(font: :roboto, font_size: @text_size)
      |> add_specs_to_graph([
        rect_spec({width, height}, fill: {:dynamic, "mandelbrot"}),
        text_spec(@note, translate: {7, @text_size})
      ])

    {:ok, put_in(state[:graph], graph), push: graph}
  end

  def handle_input({:key, {direction, :release, _}}, _context, state)
      when direction in ["up", "down", "left", "right"] do
    transform = move_transform(state.transform, direction)
    state = put_in(state[:transform], transform)
    render_mandelbrot(state)

    {:noreply, state}
  end

  def handle_input({:key, {key, :release, _}}, _context, state) when key in ["W", "S"] do
    {x_scale, x_offset, y_scale, y_offset} = state.transform

    scale_factor =
      case key do
        "W" -> @scale_factor
        "S" -> 1 / @scale_factor
      end

    x_scale_new = x_scale / scale_factor
    y_scale_new = y_scale / scale_factor
    x_offset_new = (x_scale_new + 2 * x_offset - x_scale) / 2
    y_offset_new = (y_scale_new + 2 * y_offset - y_scale) / 2

    state = put_in(state[:transform], {x_scale_new, x_offset_new, y_scale_new, y_offset_new})
    render_mandelbrot(state)

    {:noreply, state}
  end

  def handle_input({:key, {"f1", :release, _}}, _context, state) do
    :ok = save_image()
    {:noreply, state}
  end

  def handle_input(_event, _context, state) do
    {:noreply, state}
  end

  defp move_transform({x_scale, x_offset, y_scale, y_offset}, "up"),
    do: {x_scale, x_offset, y_scale, y_offset + y_scale * @move_factor}

  defp move_transform({x_scale, x_offset, y_scale, y_offset}, "down"),
    do: {x_scale, x_offset, y_scale, y_offset - y_scale * @move_factor}

  defp move_transform({x_scale, x_offset, y_scale, y_offset}, "left"),
    do: {x_scale, x_offset + x_scale * @move_factor, y_scale, y_offset}

  defp move_transform({x_scale, x_offset, y_scale, y_offset}, "right"),
    do: {x_scale, x_offset - x_scale * @move_factor, y_scale, y_offset}

  defp render_mandelbrot(state) do
    {:ok, data_out_bin} = Mandelixir.OpenCL.render(state.transform)

    Scenic.Cache.Dynamic.Texture.put(
      "mandelbrot",
      {:g, state.width, state.height, data_out_bin, []},
      :global
    )
  end

  defp save_image do
    {:g, width, height, data, _} = Scenic.Cache.Dynamic.Texture.get!("mandelbrot")
    File.write!("mandelixir.pgm", ["P5\n#{width} #{height}\n255\n", data], [:raw])
  end
end
