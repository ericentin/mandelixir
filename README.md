# Mandelixir

### A GPU-boosted Mandelbrot viewer implemented in Elixir, using the Scenic Framework and OpenCL. 

![mandelixir window](https://raw.githubusercontent.com/ericentin/mandelixir/master/mandelixir.png)

Just a fun free-time hack. OpenCL makes this possible, without it a naive Elixir implementation renders this same image hundreds of times slower.

Interfaces with OpenCL via the https://github.com/tonyrog/cl Erlang OpenCL binding.

#### Usage
1. Install prerequisites for scenic applications as described here: https://github.com/boydm/scenic_new#install-prerequisites
2. Install prerequisites for OpenCL. Check https://github.com/tonyrog/cl for more information if you have trouble finding the right packages. On most modern versions of macOS you should be good to go. For ubuntu 18, install the package `ocl-icd-opencl-dev`, at least, plus any packages for your OpenCL-capable device! Please open an issue if you think it should work and it doesn't, I'm interested in discovering more about how different OSes handle this. Thanks!
3. In the mandelixir dir, `MIX_ENV=prod mix do deps.get, scenic.run`