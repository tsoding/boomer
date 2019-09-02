#include <stdio.h>
#include <stdlib.h>

#include <GL/gl.h>
#include <GL/glx.h>

#include <unistd.h>

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
        0, 0, 256, 256, 0,
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

    glEnable(GL_DEBUG_OUTPUT);
    glDebugMessageCallback(debug_message, NULL);

    GLuint textures = 0;
    glGenTextures(1, &textures);
    glBindTexture(GL_TEXTURE_2D, textures);

    glClearColor(1.0f, 0.0f, 0.0f, 1.0f);
    glClear(GL_COLOR_BUFFER_BIT);
    glFlush();

    glXSwapBuffers(dpy, glxWin);
    sleep(10);

    return 0;
}
