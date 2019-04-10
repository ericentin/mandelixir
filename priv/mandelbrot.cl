#pragma OPENCL EXTENSION cl_khr_fp64 : enable

__kernel void mandelbrot(__global char *output, const double x_scale, const double x_offset, const double y_scale, const double y_offset) {
    const size_t px = get_global_id(0);
    const size_t py = get_global_id(1);
    const size_t width = get_global_size(0);
    const size_t height = get_global_size(1);
    const size_t i = width * py + px;
    const double x0 = ((double) px / width) * x_scale - x_offset;
    const double y0 = ((double) py / height) * y_scale - y_offset;
    const size_t max_iteration = 256;
    size_t iteration = 0;
    double x = 0.0;
    double y = 0.0;

    while (x * x + y * y <= 4 && iteration < max_iteration) {
        const double xtemp = x * x - y * y + x0;
        y = 2 * x * y + y0;
        x = xtemp;
        iteration++;
    }

    output[i] = iteration--;
}