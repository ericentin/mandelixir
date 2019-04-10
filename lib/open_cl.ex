defmodule Mandelixir.OpenCL do
  @kernel_path Path.join([__DIR__, "..", "priv", "mandelbrot.cl"])
  @external_resource @kernel_path
  @kernel File.read!(@kernel_path)

  def init do
    {:ok, [platform | _]} = :cl.get_platform_ids()
    {:ok, [device | _]} = :cl.get_device_ids(platform, :gpu)
    {:ok, context} = :cl.create_context([device])
    {:ok, queue} = :cl.create_queue(context, device, [])
    {:ok, program} = :cl.create_program_with_source(context, @kernel)
    :ok = :cl.build_program(program, [device], '')
    {:ok, kernel} = :cl.create_kernel(program, 'mandelbrot')
    :persistent_term.put(__MODULE__.Context, context)
    :persistent_term.put(__MODULE__.Queue, queue)
    :persistent_term.put(__MODULE__.Kernel, kernel)
  end

  def ensure_output_buffer(width, height) do
    case :persistent_term.get(__MODULE__.Output, false) do
      false ->
        context = :persistent_term.get(__MODULE__.Context)
        output_buffer_size = width * height
        {:ok, output} = :cl.create_buffer(context, [:write_only], output_buffer_size)
        :persistent_term.put(__MODULE__.Output, {output, output_buffer_size, width, height})
        output_buffer_size

      {_, output_buffer_size, _, _} ->
        output_buffer_size
    end
  end

  def render({x_scale, x_offset, y_scale, y_offset}) do
    kernel = :persistent_term.get(__MODULE__.Kernel)
    queue = :persistent_term.get(__MODULE__.Queue)
    {output, output_buffer_size, width, height} = :persistent_term.get(__MODULE__.Output)

    :ok = :cl.set_kernel_arg(kernel, 0, output)
    :ok = :cl.set_kernel_arg(kernel, 1, {:double, x_scale})
    :ok = :cl.set_kernel_arg(kernel, 2, {:double, x_offset})
    :ok = :cl.set_kernel_arg(kernel, 3, {:double, y_scale})
    :ok = :cl.set_kernel_arg(kernel, 4, {:double, y_offset})

    {:ok, _} = :cl.enqueue_nd_range_kernel(queue, kernel, [width, height], [], [])
    {:ok, data_out_event} = :cl.enqueue_read_buffer(queue, output, 0, output_buffer_size, [])

    :ok = :cl.flush(queue)

    :cl.wait(data_out_event)
  end
end
