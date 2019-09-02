#include <X11/Xlib.h>
#include <X11/Xutil.h>

#include <assert.h>
#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <string.h>

void save_pixels_as_ppm(uint32_t *pixels,
                        int width,
                        int height,
                        const char *filepath)
{
    FILE *f = fopen(filepath, "wb");
    if (!f) {
        fprintf(stderr, "Could not open file `%s`\n", filepath);
        exit(1);
    }

    fprintf(f,
            "P6\n"
            "%d %d\n"
            "255\n",
            width, height);

    for (int row = 0; row < height; ++row) {
        for (int col = 0; col < width; ++col) {
            uint32_t pixel = pixels[row * width + col];
            uint8_t c1 = pixel & 0xFF;
            uint8_t c2 = (pixel >> 8) & 0xFF;
            uint8_t c3 = (pixel >> 16) & 0xFF;

            putc(c3, f);
            putc(c2, f);
            putc(c1, f);
        }
    }

    fflush(f);

    fclose(f);
}

int main(int argc, char *argv[])
{
    Display *display = XOpenDisplay(NULL);
    Window root = DefaultRootWindow(display);

    XWindowAttributes attributes = {0};
    XGetWindowAttributes(display, root, &attributes);
    XImage *img = XGetImage(display, root, 0, 0, attributes.width, attributes.height, AllPlanes, ZPixmap);

    printf("Width: %d\n", attributes.width);
    printf("Height: %d\n", attributes.height);
    printf("BPP: %d\n", img->bits_per_pixel);
    printf("Corner pixel: %u\n", *((uint32_t *)img->data));

    assert(img->bits_per_pixel == 32);

    save_pixels_as_ppm((uint32_t *)img->data, attributes.width, attributes.height, "screenshot.ppm");

    XDestroyImage(img);
    XCloseDisplay(display);

    return 0;
}
