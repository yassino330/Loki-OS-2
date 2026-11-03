CC ?= cc
CFLAGS ?= -Os -Wall -Wextra -Werror -static
all: lokios-init
lokios-init: init.c
	$(CC) $(CFLAGS) -o $@ $<
clean:
	rm -f lokios-init
.PHONY: all clean
