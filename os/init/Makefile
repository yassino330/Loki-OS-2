CC ?= cc
CFLAGS ?= -Os -Wall -Wextra -Werror -static
LDFLAGS ?=
all: lokios-init lokios-supervisor
lokios-init: init.c
	$(CC) $(CFLAGS) $(LDFLAGS) -o $@ $<
lokios-supervisor: supervisor.c
	$(CC) $(CFLAGS) $(LDFLAGS) -o $@ $<
clean:
	rm -f lokios-init lokios-supervisor
.PHONY: all clean
