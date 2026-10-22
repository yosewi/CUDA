#include <cuda_runtime.h>
#include <stdio.h>
#include <stdlib.h>
#include <time.h>

#define BLOCK 1024

__global__ void sumKernel(int *in, int *out, int n)
{
    __shared__ int s[BLOCK];

    int thread = threadIdx.x;
    int i = blockIdx.x * blockDim.x + threadIdx.x;

    if(i < n){
        s[thread] = in[i];
    }
    else{
        s[thread] = 0;
    }
    __syncthreads();

    int krok = blockDim.x / 2;

    while(krok > 0){
        if(thread < krok){
            s[thread] += s[thread + krok];
        }
        __syncthreads();
        krok /= 2;
    }

    if(thread == 0){
        out[blockIdx.x] = s[0];
    }
}

int main(int argc, char** argv)
{
    int n;
    if(argc > 1){
        n = atoi(argv[1]);
    }
    else{
        n = 1000000;
    }

    int* h_a = NULL;
    int h_sum = 0;
    int cpuSum = 0;
    int* d_in = NULL;
    int* d_out = NULL;
    int* tmp = NULL;
    int bloki;
    int zostalo;
    cudaError_t cudaStatus;

    h_a = (int*)malloc(n * sizeof(int));

    srand(time(NULL));

    for (int i = 0; i < n; i++) {
        h_a[i] = rand() % 100;
        cpuSum += h_a[i];
    }

    bloki = (n + BLOCK - 1) / BLOCK;

    cudaStatus = cudaSetDevice(0);
    if (cudaStatus != cudaSuccess) { goto Error; }

    cudaStatus = cudaMalloc((void**)&d_in, n * sizeof(int));
    if (cudaStatus != cudaSuccess) { goto Error; }

    cudaStatus = cudaMalloc((void**)&d_out, bloki * sizeof(int));
    if (cudaStatus != cudaSuccess) { goto Error; }

    cudaStatus = cudaMemcpy(d_in, h_a, n * sizeof(int), cudaMemcpyHostToDevice);
    if (cudaStatus != cudaSuccess) { goto Error; }

    zostalo = n;

    while(zostalo > 1){
        bloki = (zostalo + BLOCK - 1) / BLOCK;

        sumKernel<<<bloki, BLOCK>>>(d_in, d_out, zostalo);

        cudaStatus = cudaGetLastError();
        if (cudaStatus != cudaSuccess) {
            fprintf(stderr, "%s\n", cudaGetErrorString(cudaStatus));
            goto Error;
        }

        tmp = d_in;
        d_in = d_out;
        d_out = tmp;

        zostalo = bloki;
    }

    cudaStatus = cudaDeviceSynchronize();
    if (cudaStatus != cudaSuccess) {
        fprintf(stderr, "%d\n", cudaStatus);
        goto Error;
    }

    cudaStatus = cudaMemcpy(&h_sum, d_in, sizeof(int), cudaMemcpyDeviceToHost);
    if (cudaStatus != cudaSuccess) { goto Error; }

    printf("N = %d\n", n);
    printf("Suma cpu %d\n", cpuSum);
    printf("Suma gpu %d\n", h_sum);

Error:
    cudaFree(d_in);
    cudaFree(d_out);
    free(h_a);

    return cudaStatus;
}