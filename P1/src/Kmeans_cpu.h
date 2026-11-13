#ifndef KMEANS_CPU_H
#define KMEANS_CPU_H

#include "common.h"

// Centroidy maja ten sam uklad SoA co punkty, tylko zamiast N jest k:
// wspolrzedna j centroidu c to centroids[j * k + c]  (k * d liczb).

// Ustawia centroidy startowe: pierwsze k punktow z danych (wymog specyfikacji).
void initCentroids(const Dataset* data, double* centroids);

// Przypisuje kazdy punkt do najblizszego centroidu (zapisuje numer w labels).
// Zwraca liczbe punktow, ktore zmienily klaster.
int assignPoints(const Dataset* data, const double* centroids, int* labels);

// Liczy nowe centroidy: srednia punktow kazdego klastra.
// Pusty klaster zachowuje stary centroid.
void updateCentroids(const Dataset* data, const int* labels, double* centroids);

// Caly algorytm k-means na CPU: centroidy startowe, potem iteracje
// (przypisanie + aktualizacja) az do braku zmian albo MAX_ITERATIONS.
// labels musi miec miejsce na N liczb, centroids na k * d liczb.
// Zwraca liczbe wykonanych iteracji.
int kmeansCpu(const Dataset* data, double* centroids, int* labels);

#endif