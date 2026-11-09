#include <stdio.h>
#include <string.h>

#include "common.h"
#include "io.h"

static void printUsage(const char* programName)
{
    printf("Uzycie:\n");
    printf("    %s data_format computation_method input_file output_file\n\n", programName);
    printf("    data_format:        txt | bin\n");
    printf("    computation_method: gpu1 | gpu2 | cpu\n");
    printf("    input_file:         sciezka do pliku z danymi\n");
    printf("    output_file:        sciezka do pliku z wynikami\n\n");
    printf("Przyklad:\n");
    printf("    %s bin gpu1 dane.bin wynik.txt\n", programName);
}

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

    Dataset data;
    if (options.format == FORMAT_TXT) {
        if (!readTxt(options.inputPath, &data)) {
            return 1;
        }
    } else {
        printf("Format bin jeszcze nie jest obslugiwany.\n");
        return 1;
    }

    printf("Liczba punktow N: %d\n", data.N);
    printf("Wymiary d:        %d\n", data.d);
    printf("Klastry k:        %d\n", data.k);

    int shown = data.N < 3 ? data.N : 3;
    for (int i = 0; i < shown; i++) {
        printf("Punkt %d:", i);
        for (int j = 0; j < data.d; j++) {
            printf(" %g", data.points[(size_t)j * data.N + i]);
        }
        printf("\n");
    }

    freeDataset(&data);
    return 0;
}
