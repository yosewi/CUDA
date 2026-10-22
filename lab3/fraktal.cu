// Modify the following C code to draw w fractal using CUDA threads.
// Area should be defined by rectagle (-10, -10)(10, 10).
// MaxIters should be 80.
// Size defines number of columns and rows in the resulting image. Start with 40.

#include <cuda_runtime.h>
#include "stdio.h"
#include "math.h"
#include "stdlib.h"

#define BLOK 1024

cudaError_t sprzataj(char *h_wynik, char *d_wynik, cudaError_t cudaStatus){
    cudaFree(d_wynik);
    free(h_wynik);

    return cudaStatus;
}


__global__ void Kernel(char *wynik, double LEFT, double BOTTOM, double RIGHT, double TOP, int SIZE, int MaxIters)
{
    int i = blockIdx.x * blockDim.x + threadIdx.x;

    if(i >= SIZE * SIZE){
        return;
    }

    int x = i % SIZE;
    int y = i / SIZE;
    int count;
    double zr, zi, betar, betai, a, b;
    double rsquared, isquared, mr, mi, msquared;

    zr = 1.0;
    zi = 0.0;
    betar = LEFT + x * (RIGHT - LEFT) / SIZE;
    betai = BOTTOM + y * (TOP - BOTTOM) / SIZE;

    a = 0.5 * (1 - betar);
    b = -0.5 * betai;
    rsquared = zr * zr;
    isquared = zi * zi;

    for(count = 0; rsquared + isquared >= 2.25 / (betar * betar + betai * betai) && count < MaxIters; count++){
        mr = 2 * a - 1 + exp(a * zr - b * zi) * cos(a * zi + b * zr);
        mi = 2 * b + exp(a * zr - b * zi) * sin(a * zi + b * zr);
        msquared = mr * mr + mi * mi;
        zr = 1 - 2 * (a * mr + b * mi) / msquared;
        zi = 2 * (a * mi - b * mr) / msquared;
        rsquared = zr * zr;
        isquared = zi * zi;
    }

    if(rsquared + isquared >= 2.25 / (betar * betar + betai * betai)){
        wynik[i] = '*';
    }
    else{
        wynik[i] = '.';
    }
}

int main(int argc, char *argv[])
{
    double LEFT, BOTTOM, RIGHT, TOP;
    int SIZE, MaxIters;

    if(argc == 1){
        LEFT = -10.;
        BOTTOM = -10.;
        RIGHT = 10.;
        TOP = 10.;
        SIZE = 40;
        MaxIters = 80;
    }
    else{
        LEFT = atof(argv[1]);
        BOTTOM = atof(argv[2]);
        RIGHT = atof(argv[3]);
        TOP = atof(argv[4]);
        SIZE = atoi(argv[5]);
        MaxIters = atoi(argv[6]);
    }

    char *h_fraktal = NULL;
    char *d_fraktal = NULL;
    int Size_sq = SIZE * SIZE;
    int blok_num = (Size_sq + BLOK - 1) / BLOK;
    cudaError_t cudaStatus;

    h_fraktal = (char*)malloc(Size_sq);

    cudaStatus = cudaSetDevice(0);
    if (cudaStatus != cudaSuccess) {
        fprintf(stderr, "%s\n", cudaGetErrorString(cudaStatus));
        return sprzataj(h_fraktal, d_fraktal, cudaStatus);
    }

    cudaStatus = cudaMalloc((void**)&d_fraktal, Size_sq);
    if (cudaStatus != cudaSuccess) {
        fprintf(stderr, "%s\n", cudaGetErrorString(cudaStatus));
        return sprzataj(h_fraktal, d_fraktal, cudaStatus);
    }

    Kernel<<<blok_num, BLOK>>>(d_fraktal, LEFT, BOTTOM, RIGHT, TOP, SIZE, MaxIters);

    cudaStatus = cudaGetLastError();
    if (cudaStatus != cudaSuccess) {
        fprintf(stderr, "%s\n", cudaGetErrorString(cudaStatus));
        return sprzataj(h_fraktal, d_fraktal, cudaStatus);
    }

    cudaStatus = cudaDeviceSynchronize();
    if (cudaStatus != cudaSuccess) {
        fprintf(stderr, "%s\n", cudaGetErrorString(cudaStatus));
        return sprzataj(h_fraktal, d_fraktal, cudaStatus);
    }

    cudaStatus = cudaMemcpy(h_fraktal, d_fraktal, Size_sq, cudaMemcpyDeviceToHost);
    if (cudaStatus != cudaSuccess) {
        fprintf(stderr, "%s\n", cudaGetErrorString(cudaStatus));
        return sprzataj(h_fraktal, d_fraktal, cudaStatus);
    }

    for(int y = 0; y < SIZE; y++){
        for(int x = 0; x < SIZE; x++){
            printf("%c", h_fraktal[y * SIZE + x]);
        }
        printf("\n");
    }

    return sprzataj(h_fraktal, d_fraktal, cudaStatus);
}
