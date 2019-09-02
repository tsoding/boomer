CFLAGS=`pkg-config --cflags x11 gl`
LIBS=`pkg-config --libs x11 gl`

all: fbconfig screenshot

%: %.c
	gcc -Wall -Werror $(CFLAGS) -o $@ $< $(LIBS)
