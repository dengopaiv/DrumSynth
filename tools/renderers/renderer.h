/* Common interface for the .ds -> .wav renderers used to compare engines.
 * Each renderer provides these three; renderer_main.c is shared. */
#ifndef RENDERER_H
#define RENDERER_H

extern const char* RENDERER_NAME;

/* option is the value of --dll (or NULL); returns 0 on success. */
int renderer_init(const char* option);

/* Paths are absolute. Returns the engine's result code (0 = success). */
int render_one(const char* dsfile, const char* wavfile);

#endif
