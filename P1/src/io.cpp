#include <stdio.h>
#include <stdlib.h>

#include "io.h"

static int checkHeader(int N, int d, int k)
{
    if (N < 1)            { printf("Blad: liczba punktow N = %d musi byc >= 1.\n", N); return 0; }
    if (d < 1 || d > 20)  { printf("Blad: liczba wymiarow d = %d spoza zakresu 1-20.\n", d); return 0; }
    if (k < 2 || k > 20)  { printf("Blad: liczba klastrow k = %d spoza zakresu 2-20.\n", k); return 0; }
    if (k > N)            { printf("Blad: klastrow (k = %d) jest wiecej niz punktow (N = %d).\n", k, N); return 0; }
    return 1;
}

int readTxt(const char* path, Dataset* data)
{
    data->points = NULL;

    FILE* file = fopen(path, "r");
    if (file == NULL) {
        printf("Blad: nie mozna otworzyc pliku \"%s\".\n", path);
        return 0;
    }

    if (fscanf(file, "%d %d %d", &data->N, &data->d, &data->k) != 3) {
        printf("Blad: pierwsza linia pliku musi zawierac trzy liczby: N d k.\n");
        fclose(file);
        return 0;
    }

    if (!checkHeader(data->N, data->d, data->k)) {
        fclose(file);
        return 0;
    }

    const int N = data->N;
    const int d = data->d;

    size_t bytes = (size_t)N * d * sizeof(double);
    data->points = (double*)malloc(bytes);
    if (data->points == NULL) {
        printf("Blad: brak pamieci na %zu bajtow danych.\n", bytes);
        fclose(file);
        return 0;
    }

    int step = N / 10;
    if (step == 0) step = 1;

    for (int i = 0; i < N; i++) {
        for (int j = 0; j < d; j++) {
            if (fscanf(file, "%lf", &data->points[(size_t)j * N + i]) != 1) {
                printf("\nBlad: nie udalo sie wczytac wspolrzednej %d punktu %d.\n", j, i);
                freeDataset(data);
                fclose(file);
                return 0;
            }
        }

        if ((i + 1) % step == 0) {
            printf("\rWczytywanie: %3d%%", (int)((i + 1) * 100LL / N));
            fflush(stdout);
        }
    }
    printf("\n");

    fclose(file);
    return 1;
}

void freeDataset(Dataset* data)
{
    free(data->points);
    data->points = NULL;
}
