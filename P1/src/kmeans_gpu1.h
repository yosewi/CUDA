#ifndef KMEANS_GPU1_H
#define KMEANS_GPU1_H

#include "common.h"

// K-means na GPU, wersja gpu1 (wlasne kernele).
// Wynik w tym samym ukladzie co kmeansCpu: centroids (k * d, SoA), labels (N).
// Liczba wykonanych iteracji trafia do *iterations.
// Zwraca 1, gdy sie udalo, 0 przy bledzie CUDA (komunikat jest juz wypisany).
int kmeansGpu1(const Dataset* data, double* centroids, int* labels, int* iterations);

#endif