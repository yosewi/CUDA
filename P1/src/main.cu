#include <stdio.h>
#include <string.h>

#include "common.h"

static int parseFormat(const char* text, DataFormat* format)
{
    if (strcmp(text, "txt") == 0) { *format = FORMAT_TXT; return 1; }
    if (strcmp(text, "bin") == 0) { *format = FORMAT_BIN; return 1; }
    return 0;
}

static int parseMethod(const char* text, Method* method)
{
    if (strcmp(text, "cpu")  == 0) { *method = METHOD_CPU;  return 1; }
    if (strcmp(text, "gpu1") == 0) { *method = METHOD_GPU1; return 1; }
    if (strcmp(text, "gpu2") == 0) { *method = METHOD_GPU2; return 1; }
    return 0;
}

static int parseArguments(int argc, char** argv, Options* options)
{
    if (argc != 5) {
        printf("Blad: oczekiwano 4 argumentow, podano %d.\n\n", argc - 1);
        return 0;
    }

    if (!parseFormat(argv[1], &options->format)) {
        printf("Blad: nieznany format danych \"%s\" (dozwolone: txt, bin).\n\n", argv[1]);
        return 0;
    }

    if (!parseMethod(argv[2], &options->method)) {
        printf("Blad: nieznana metoda \"%s\" (dozwolone: gpu1, gpu2, cpu).\n\n", argv[2]);
        return 0;
    }

    options->inputPath  = argv[3];
    options->outputPath = argv[4];
    return 1;
}

static const char* formatName(DataFormat format) { return format == FORMAT_TXT ? "txt" : "bin"; }

static const char* methodName(Method method)
{
    switch (method) {
        case METHOD_CPU:  return "cpu";
        case METHOD_GPU1: return "gpu1";
        case METHOD_GPU2: return "gpu2";
    }
    return "?";
}

int main(int argc, char** argv)
{
    Options options;

    if (!parseArguments(argc, argv, &options)) {
        printUsage(argv[0]);
        return 1;
    }

    printf("Format danych:  %s\n", formatName(options.format));
    printf("Metoda:         %s\n", methodName(options.method));
    printf("Plik wejsciowy: %s\n", options.inputPath);
    printf("Plik wynikowy:  %s\n", options.outputPath);

    return 0;
}
