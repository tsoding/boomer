#include <assert.h>
#include <stdio.h>
#include <stdlib.h>

#include <GL/gl.h>
#include <GL/glx.h>

#include <unistd.h>

#define TARGET_WIDTH 256
#define TARGET_HEIGHT 256

#define SOURCE_WIDTH 100
#define SOURCE_HEIGHT 100

#define CHECK_ERROR(context)                                         \
    do {                                                             \
        int error = glGetError();                                    \
            if (error) {                                             \
                fprintf(stderr, "GL error 0x%x while " context "\n", \
                        error);                                      \
            }                                                        \
    } while (0)

typedef void (APIENTRY *DEBUGPROC)(GLenum source,
                                   GLenum type,
                                   GLuint id,
                                   GLenum severity,
                                   GLsizei length,
                                   const GLchar *message,
                                   const void *userParam);

void glDebugMessageCallback(DEBUGPROC callback, const void * userParam);

int doubleBufferAttributess[] = {
    GLX_DRAWABLE_TYPE, GLX_WINDOW_BIT,
    GLX_RENDER_TYPE,   GLX_RGBA_BIT,
    GLX_DOUBLEBUFFER,  True,
    GLX_RED_SIZE,      1,
    GLX_GREEN_SIZE,    1,
    GLX_BLUE_SIZE,     1,
    None
};

void debug_message(GLenum source,
                   GLenum type,
                   GLuint id,
                   GLenum severity,
                   GLsizei length,
                   const GLchar *message,
                   const void *userParam)
{
    fprintf(stderr, "%.*s\n", length, message);
}

static Bool wait_for_notify(Display *dpy,
                            XEvent *event,
                            XPointer arg)
{
    return (event->type == MapNotify) && (event->xmap.window = (Window) arg);
}

int main(int argc, char *argv[])
{
    Display *dpy = XOpenDisplay(NULL);
    if (!dpy) {
        fprintf(stderr, "Unable to open a connection to the X server. Are you still using DOS. 4HEad\n");
        exit(EXIT_FAILURE);
    }

    int numReturned = 0;
    GLXFBConfig *fbConfigs = glXChooseFBConfig(dpy, DefaultScreen(dpy), doubleBufferAttributess, &numReturned);
    if (!fbConfigs) {
        fprintf(stderr, "No Double Buffering in 2019 OMEGALUL\n");
        exit(EXIT_FAILURE);
    }

    XVisualInfo *vInfo = glXGetVisualFromFBConfig(dpy, fbConfigs[0]);

    XSetWindowAttributes swa;
    swa.border_pixel = 0;
    swa.event_mask = StructureNotifyMask;
    swa.colormap = XCreateColormap(dpy, RootWindow(dpy, vInfo->screen), vInfo->visual, AllocNone);

    GLXWindow xWin = XCreateWindow(
        dpy,
        RootWindow(dpy, vInfo->screen),
        0, 0, TARGET_WIDTH, TARGET_HEIGHT, 0,
        vInfo->depth,
        InputOutput,
        vInfo->visual,
        CWBorderPixel | CWColormap | CWEventMask,
        &swa);
    GLXContext context = glXCreateNewContext(dpy, fbConfigs[0], GLX_RGBA_TYPE, NULL, True);

    GLXWindow glxWin = glXCreateWindow(dpy, fbConfigs[0], xWin, NULL);


    XMapWindow(dpy, xWin);
    XEvent event;
    XIfEvent(dpy, &event, wait_for_notify, (XPointer) xWin);

    glXMakeContextCurrent(dpy, glxWin, glxWin, context);

    glViewport(0, 0, TARGET_WIDTH, TARGET_HEIGHT);

    glEnable(GL_DEBUG_OUTPUT);
    glDebugMessageCallback(debug_message, NULL);

    GLuint textures = 0;
    glGenTextures(1, &textures);
    CHECK_ERROR("making texture");

    /* All texture operations function in terms of a "current
     * texture".  Set it here */
    glBindTexture(GL_TEXTURE_2D, textures);
    CHECK_ERROR("binding texture");

    /* Prep a test texture image, grabbing a small chunk of the root
     * window */
    {
        XImage *img = XGetImage(dpy, DefaultRootWindow(dpy), 0, 0, SOURCE_WIDTH, SOURCE_HEIGHT, AllPlanes, ZPixmap);
        assert(img->bits_per_pixel == 32);
        glTexImage2D(GL_TEXTURE_2D, 0, GL_RGB, SOURCE_WIDTH, SOURCE_HEIGHT, 0, GL_BGRA, GL_UNSIGNED_BYTE, img->data);
        CHECK_ERROR("loading texture");
        XDestroyImage(img);
    }

    glEnable(GL_TEXTURE_2D);

    /* Set up the display coordinate space as orthographic */
    glOrtho(0.0d, TARGET_WIDTH, TARGET_HEIGHT, 0.0d, -1.0d, 1.0d);
    CHECK_ERROR("setting transforms");

    /* If we don't set the mapping filters, we get a blank image */
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);

    /* Use the "legacy" (deprecated, possibly no longer supported by
     * open-source drivers) "immediate mode" APIs to render a
     * window-sized rectangle from the texture image */
    glBegin(GL_QUADS);
    /* Texture coordinates are from 0 to 1, output coordinates are
     * from 0 to width/height */
    glTexCoord2i(0, 0);
    glVertex2i(0, 0);
    glTexCoord2i(1, 0);
    glVertex2i(TARGET_WIDTH, 0);
    glTexCoord2i(1, 1);
    glVertex2i(TARGET_WIDTH, TARGET_HEIGHT);
    glTexCoord2i(0, 1);
    glVertex2i(0, TARGET_HEIGHT);
    glEnd();
    CHECK_ERROR("rasterizing the quadrangle");

    glFlush();
    CHECK_ERROR("flush");

    glXSwapBuffers(dpy, glxWin);
    sleep(10);

    return 0;
}
