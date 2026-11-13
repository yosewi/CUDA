#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "timer.h"
#include "common.h"
#include "io.h"
#include "kmeans_cpu.h"
#include "kmeans_gpu1.h"

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

    printf("Metoda:         %s\n", methodName(options.method));
    printf("Plik wejsciowy: %s\n", options.inputPath);
    printf("Plik wynikowy:  %s\n", options.outputPath);

    if (options.method == METHOD_GPU2) {
        printf("Metoda %s jeszcze nie jest obslugiwana.\n", methodName(options.method));
        return 1;
    }

    Timer timer;

    printf("\n[1/3] Wczytywanie danych (format %s)\n", formatName(options.format));
    timer.start();

    Dataset data;
    int loaded;
    if (options.format == FORMAT_TXT) {
        loaded = readTxt(options.inputPath, &data);
    } else {
        loaded = readBin(options.inputPath, &data);
    }
    if (!loaded) {
        return 1;
    }

    printf("Czas wczytywania: %.1f ms\n", timer.stopMs());
    printf("Dane: N = %d punktow, d = %d wymiarow, k = %d klastrow\n", data.N, data.d, data.k);

    // Centroidy: k * d liczb (SoA, jak punkty). Etykiety: numer klastra kazdego punktu.
    double* centroids = (double*)malloc((size_t)data.k * data.d * sizeof(double));
    int*    labels    = (int*)malloc((size_t)data.N * sizeof(int));
    if (centroids == NULL || labels == NULL) {
        printf("Blad: brak pamieci na centroidy lub etykiety.\n");
        free(centroids);
        free(labels);
        freeDataset(&data);
        return 1;
    }

    printf("\n[2/3] Obliczenia (%s)\n", methodName(options.method));
    timer.start();

    int iterations = 0;
    if (options.method == METHOD_CPU) {
        iterations = kmeansCpu(&data, centroids, labels);
    } else {
        if (!kmeansGpu1(&data, centroids, labels, &iterations)) {
            free(centroids);
            free(labels);
            freeDataset(&data);
            return 1;
        }
    }

    printf("Koniec po %d iteracjach.\n", iterations);
    printf("Czas obliczen: %.1f ms\n", timer.stopMs());

    printf("\n[3/3] Zapis wynikow do pliku %s\n", options.outputPath);
    timer.start();

    int saved = writeResult(options.outputPath, &data, centroids, labels);
    if (saved) {
        printf("Czas zapisu: %.1f ms\n", timer.stopMs());
    }

    free(centroids);
    free(labels);
    freeDataset(&data);
    return saved ? 0 : 1;
}