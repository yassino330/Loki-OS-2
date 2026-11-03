#define _GNU_SOURCE
#include <errno.h>
#include <signal.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/types.h>
#include <sys/wait.h>
#include <unistd.h>

#define MAX_SERVICES 24
#define MAX_ARGS 16
#define LINE_SIZE 512
struct service { char *argv[MAX_ARGS + 1]; pid_t pid; unsigned restarts; };
static struct service services[MAX_SERVICES];
static size_t count;
static volatile sig_atomic_t stopping;
static void on_signal(int sig) { stopping = sig; }

static void read_services(void) {
    FILE *f = fopen("/etc/lokios/services.conf", "r");
    char line[LINE_SIZE];
    if (!f) return;
    while (fgets(line, sizeof line, f) && count < MAX_SERVICES) {
        char *p = line;
        while (*p == ' ' || *p == '\t') ++p;
        if (!*p || *p == '#' || *p == '\n') continue;
        p[strcspn(p, "\r\n")] = 0;
        struct service *s = &services[count];
        char *save = NULL;
        for (char *t = strtok_r(p, " \t", &save); t; t = strtok_r(NULL, " \t", &save)) {
            size_t n = 0;
            while (s->argv[n]) ++n;
            if (n == MAX_ARGS) break;
            s->argv[n] = strdup(t);
            if (!s->argv[n]) break;
        }
        if (s->argv[0]) ++count;
    }
    fclose(f);
}
static pid_t start_service(struct service *s) {
    pid_t p = fork();
    if (p == 0) {
        signal(SIGTERM, SIG_DFL);
        signal(SIGINT, SIG_DFL);
        execvp(s->argv[0], s->argv);
        dprintf(2, "LokiOS: cannot start %s: %s\n", s->argv[0], strerror(errno));
        _exit(127);
    }
    if (p < 0) perror("LokiOS: fork");
    return p;
}
int main(void) {
    if (getpid() != 1) { fputs("LokiOS supervisor must be PID 1\n", stderr); return 1; }
    struct sigaction sa = {0};
    sa.sa_handler = on_signal; sigemptyset(&sa.sa_mask);
    sigaction(SIGTERM, &sa, NULL); sigaction(SIGINT, &sa, NULL); sigaction(SIGQUIT, &sa, NULL);
    read_services();
    if (!count) {
        fputs("LokiOS: no services configured; recovery console\n", stderr);
        services[0].argv[0] = strdup("/bin/sh");
        if (services[0].argv[0]) count = 1;
    }
    for (size_t i = 0; i < count; ++i) services[i].pid = start_service(&services[i]);
    while (!stopping) {
        int status;
        pid_t dead = waitpid(-1, &status, 0);
        if (dead < 0) { if (errno == EINTR) continue; if (errno == ECHILD) { pause(); continue; } perror("LokiOS: waitpid"); continue; }
        for (size_t i = 0; i < count; ++i) if (services[i].pid == dead) {
            services[i].pid = 0;
            if (++services[i].restarts > 5) { fprintf(stderr, "LokiOS: %s exceeded restart limit\n", services[i].argv[0]); stopping = SIGTERM; }
            else if (!stopping) services[i].pid = start_service(&services[i]);
            break;
        }
    }
    for (size_t i = 0; i < count; ++i) if (services[i].pid > 0) kill(services[i].pid, SIGTERM);
    while (waitpid(-1, NULL, 0) > 0 || errno == EINTR) {}
    sync();
    return 0;
}
