CFLAGS=`pkg-config --cflags x11 gl`
LIBS=`pkg-config --libs x11 gl`

fbconfig-probe: main.c
	gcc -Wall -Werror $(CFLAGS) -o fbconfig-probe main.c $(LIBS)
