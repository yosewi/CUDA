#include <float.h>
#include <stdio.h>

#include <cuda_runtime.h>

#include "kmeans_gpu1.h"
#include "kmeans_cpu.h" 
#include "timer.h"

#define BLOCK_SIZE 256

static int cudaCheck(cudaError_t err, const char* what)
{
    if (err != cudaSuccess) {
        printf("Blad CUDA przy \"%s\": %s\n", what, cudaGetErrorString(err));
        return 0;
    }
    return 1;
}

// ---------------------------------------------------------------------------
// Kernel 1: przypisanie punktow do najblizszego centroidu.
// Jeden watek = jeden punkt (watek i liczy punkt i).
// Robi dokladnie to samo co petla w assignPoints na CPU.
// ---------------------------------------------------------------------------
__global__ void assignKernel(const double* points, const double* centroids,
                             int* labels, int* changed, int N, int d, int k)
{
    int i = blockIdx.x * blockDim.x + threadIdx.x;
    if (i >= N) {
        return;
    }

    int    best     = 0;
    double bestDist = DBL_MAX;

    for (int c = 0; c < k; c++) {
        double dist = 0.0;
        for (int j = 0; j < d; j++) {
            double diff = points[(size_t)j * N + i] - centroids[j * k + c];
            dist += diff * diff;
        }
        if (dist < bestDist) {
            bestDist = dist;
            best     = c;
        }
    }

    if (labels[i] != best) {
        labels[i] = best;
        atomicAdd(changed, 1);
    }
}

// ---------------------------------------------------------------------------
// Kernel 2: sumowanie punktow w klastrach.
// Jeden watek = jeden punkt: dodaje swoje wspolrzedne do sumy swojego klastra.
// Wiele watkow dodaje do tych samych komorek, wiec atomicAdd.
// ---------------------------------------------------------------------------
__global__ void accumulateKernel(const double* points, const int* labels,
                                 double* sums, int* counts, int N, int d, int k)
{
    int i = blockIdx.x * blockDim.x + threadIdx.x;
    if (i >= N) {
        return;
    }

    int c = labels[i];
    atomicAdd(&counts[c], 1);
    for (int j = 0; j < d; j++) {
        atomicAdd(&sums[j * k + c], points[(size_t)j * N + i]);
    }
}

// ---------------------------------------------------------------------------
// Kernel 3: nowe centroidy = suma / licznosc.
// Jeden watek = jedna liczba centroidu (k * d watkow, najwyzej 400).
// Watek t liczy centroids[t], gdzie t = j * k + c, wiec klaster to c = t % k.
// ---------------------------------------------------------------------------
__global__ void finalizeKernel(const double* sums, const int* counts,
                               double* centroids, int d, int k)
{
    int t = threadIdx.x;
    if (t >= k * d) {
        return;
    }

    int c = t % k;
    if (counts[c] > 0) {
        centroids[t] = sums[t] / counts[c];
    }
}

int kmeansGpu1(const Dataset* data, double* centroids, int* labels, int* iterations)
{
    const int N = data->N;
    const int d = data->d;
    const int k = data->k;

    const size_t pointsBytes    = (size_t)N * d * sizeof(double);
    const size_t centroidsBytes = (size_t)k * d * sizeof(double);
    const size_t labelsBytes    = (size_t)N * sizeof(int);

    const int blocks = (N + BLOCK_SIZE - 1) / BLOCK_SIZE;

    double* d_points    = NULL;     // przedrostek d_ = pamiec na GPU (device)
    double* d_centroids = NULL;
    int*    d_labels    = NULL;
    double* d_sums      = NULL;     // k * d sum wspolrzednych
    int*    d_counts    = NULL;     // k licznosci klastrow
    int*    d_changed   = NULL;     // licznik punktow, ktore zmienily klaster

    int    ok        = 0;
    int    iteration = 0;
    int    changed   = 0;
    Timer  timer;

    initCentroids(data, centroids);

    printf("Kopiowanie danych CPU -> GPU\n");
    timer.start();

    if (!cudaCheck(cudaMalloc(&d_points, pointsBytes), "cudaMalloc d_points")) goto cleanup;
    if (!cudaCheck(cudaMalloc(&d_centroids, centroidsBytes), "cudaMalloc d_centroids")) goto cleanup;
    if (!cudaCheck(cudaMalloc(&d_labels, labelsBytes), "cudaMalloc d_labels")) goto cleanup;
    if (!cudaCheck(cudaMalloc(&d_sums, centroidsBytes), "cudaMalloc d_sums")) goto cleanup;
    if (!cudaCheck(cudaMalloc(&d_counts, k * sizeof(int)), "cudaMalloc d_counts")) goto cleanup;
    if (!cudaCheck(cudaMalloc(&d_changed, sizeof(int)), "cudaMalloc d_changed")) goto cleanup;

    if (!cudaCheck(cudaMemcpy(d_points, data->points, pointsBytes, cudaMemcpyHostToDevice), "cudaMemcpy d_points")) goto cleanup;
    if (!cudaCheck(cudaMemcpy(d_centroids, centroids, centroidsBytes, cudaMemcpyHostToDevice), "cudaMemcpy d_centroids")) goto cleanup;

    if (!cudaCheck(cudaMemset(d_labels, 0xFF, labelsBytes), "cudaMemset d_labels")) goto cleanup;

    printf("Czas kopiowania CPU -> GPU: %.1f ms\n", timer.stopMs());

    while (iteration < MAX_ITERATIONS) {
        iteration++;

        if (!cudaCheck(cudaMemset(d_changed, 0, sizeof(int)), "cudaMemset d_changed")) goto cleanup;
        if (!cudaCheck(cudaMemset(d_sums, 0, centroidsBytes), "cudaMemset d_sums")) goto cleanup;
        if (!cudaCheck(cudaMemset(d_counts, 0, k * sizeof(int)), "cudaMemset d_counts")) goto cleanup;

        assignKernel<<<blocks, BLOCK_SIZE>>>(d_points, d_centroids, d_labels, d_changed, N, d, k);
        if (!cudaCheck(cudaGetLastError(), "uruchomienie assignKernel")) goto cleanup;

        accumulateKernel<<<blocks, BLOCK_SIZE>>>(d_points, d_labels, d_sums, d_counts, N, d, k);
        if (!cudaCheck(cudaGetLastError(), "uruchomienie accumulateKernel")) goto cleanup;

        finalizeKernel<<<1, k * d>>>(d_sums, d_counts, d_centroids, d, k);
        if (!cudaCheck(cudaGetLastError(), "uruchomienie finalizeKernel")) goto cleanup;

        if (!cudaCheck(cudaMemcpy(&changed, d_changed, sizeof(int), cudaMemcpyDeviceToHost), "cudaMemcpy changed")) goto cleanup;

        printf("Iteracja %3d: zmienilo klaster %d punktow\n", iteration, changed);

        if (changed == 0) {
            break;
        }
    }

    printf("Kopiowanie wynikow GPU -> CPU\n");
    timer.start();

    if (!cudaCheck(cudaMemcpy(labels, d_labels, labelsBytes, cudaMemcpyDeviceToHost), "cudaMemcpy labels")) goto cleanup;
    if (!cudaCheck(cudaMemcpy(centroids, d_centroids, centroidsBytes, cudaMemcpyDeviceToHost), "cudaMemcpy centroids")) goto cleanup;

    printf("Czas kopiowania GPU -> CPU: %.1f ms\n", timer.stopMs());

    ok = 1;

cleanup:
    cudaFree(d_points);
    cudaFree(d_centroids);
    cudaFree(d_labels);
    cudaFree(d_sums);
    cudaFree(d_counts);
    cudaFree(d_changed);

    *iterations = iteration;
    return ok;
}