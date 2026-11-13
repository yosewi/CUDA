#include <float.h>
#include <stddef.h>
#include <stdio.h>

#include "kmeans_cpu.h"

void initCentroids(const Dataset* data, double* centroids)
{
    const int N = data->N;
    const int d = data->d;
    const int k = data->k;

    // Centroid c = punkt c (dla c = 0 .. k-1), przepisany wspolrzedna po wspolrzednej.
    for (int c = 0; c < k; c++) {
        for (int j = 0; j < d; j++) {
            centroids[j * k + c] = data->points[(size_t)j * N + c];
        }
    }
}

int assignPoints(const Dataset* data, const double* centroids, int* labels)
{
    const int N = data->N;
    const int d = data->d;
    const int k = data->k;

    int changed = 0;

    for (int i = 0; i < N; i++) {
        // Szukamy centroidu o najmniejszej odleglosci od punktu i.
        int    best     = 0;
        double bestDist = DBL_MAX;

        for (int c = 0; c < k; c++) {
            // Kwadrat odleglosci: pierwiastek nie jest potrzebny,
            // bo najmniejszy kwadrat ma ten sam centroid co najmniejsza odleglosc.
            double dist = 0.0;
            for (int j = 0; j < d; j++) {
                double diff = data->points[(size_t)j * N + i] - centroids[j * k + c];
                dist += diff * diff;
            }

            // Scisle "<": przy remisie wygrywa centroid o mniejszym numerze.
            if (dist < bestDist) {
                bestDist = dist;
                best     = c;
            }
        }

        if (labels[i] != best) {
            labels[i] = best;
            changed++;
        }
    }

    return changed;
}

void updateCentroids(const Dataset* data, const int* labels, double* centroids)
{
    const int N = data->N;
    const int d = data->d;
    const int k = data->k;

    // Sumy wspolrzednych i licznosci klastrow. k i d sa najwyzej 20,
    // wiec wystarcza male tablice na stosie (uklad jak centroidy: [j * k + c]).
    double sums[MAX_DIM * MAX_K] = {0.0};
    int    counts[MAX_K]         = {0};

    // 1. Kazdy punkt dodaje swoje wspolrzedne do sumy swojego klastra.
    for (int i = 0; i < N; i++) {
        int c = labels[i];
        counts[c]++;
        for (int j = 0; j < d; j++) {
            sums[j * k + c] += data->points[(size_t)j * N + i];
        }
    }

    // 2. Nowy centroid = suma / licznosc. Pusty klaster zostaje bez zmian
    //    (dzielenie przez 0 daloby NaN).
    for (int c = 0; c < k; c++) {
        if (counts[c] == 0) {
            continue;
        }
        for (int j = 0; j < d; j++) {
            centroids[j * k + c] = sums[j * k + c] / counts[c];
        }
    }
}

int kmeansCpu(const Dataset* data, double* centroids, int* labels)
{
    // -1 = punkt jeszcze nie nalezy do zadnego klastra,
    // wiec w pierwszej iteracji wszystkie punkty licza sie jako zmienione.
    for (int i = 0; i < data->N; i++) {
        labels[i] = -1;
    }

    initCentroids(data, centroids);

    int iteration = 0;
    while (iteration < MAX_ITERATIONS) {
        iteration++;

        int changed = assignPoints(data, centroids, labels);
        updateCentroids(data, labels, centroids);

        printf("Iteracja %3d: zmienilo klaster %d punktow\n", iteration, changed);

        // Warunek stopu ze specyfikacji: zaden punkt nie zmienil klastra.
        if (changed == 0) {
            break;
        }
    }

    return iteration;
}