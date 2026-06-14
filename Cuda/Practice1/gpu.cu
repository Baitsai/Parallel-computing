#include <stdio.h>
#include <stdlib.h>

void Allocate_Memory(float **h_a, float **h_b, float **d_a, float **d_b, int N) {
    size_t size = N*sizeof(float);
    cudaError_t Error;
    cudaError_t Error1;
    // Host memory
    *h_a = (float*)malloc(size); 
    *h_b = (float*)malloc(size); 
    // Device memory
    Error = cudaMalloc((void**)d_a, size); 
    Error1 = cudaMalloc((void**)d_b, size);
    printf("CUDA error (malloc d_a) = %s\n", cudaGetErrorString(Error));
    printf("CUDA error (malloc d_b) = %s\n", cudaGetErrorString(Error1));
}

void Free_Memory(float **h_a, float **h_b, float **d_a, float **d_b) {
    if (*h_a) free(*h_a);
    if (*h_b) free(*h_b);
    if (*d_a) cudaFree(*d_a);
    if (*d_b) cudaFree(*d_b);
}

void Send_To_Device(float **h_a, float **d_a, int N) {
    // Size of data to send
    size_t size = N*sizeof(float);
    // Grab a error type
    cudaError_t Error;

    // Send A to the GPU
    Error = cudaMemcpy(*d_a, *h_a, size, cudaMemcpyHostToDevice); 
    printf("CUDA error (memcpy h_a -> d_a) = %s\n", cudaGetErrorString(Error));
}

void Device_To_Device(float **d_a, float **d_b, int N){
    // Size of data to send
    size_t size = N*sizeof(float);
    // Grab a error type
    cudaError_t Error;

    // Send A to B
    Error = cudaMemcpy(*d_b, *d_a, size, cudaMemcpyDeviceToDevice);
    printf("CUDA error (memcpy d_a -> d_b) = %s\n", cudaGetErrorString(Error));



void Host_To_Host(float **h_a, float **h_b, int N){
    // Size of data to send
    size_t size = N*sizeof(float);
void Device_To_Device(float **d_a, float **d_b, int N);void Device_To_Device(float **d_a, float **d_b, int N);void Device_To_Device(float **d_a, float **d_b, int N);    // Grab a error type
    cudaError_t Error;

    // Send A to the B
    Error = cudaMemcpy(*h_b, *h_a, size, cudaMemcpyHostToHost);
    printf("CUDA error (memcpy h_a -> h_b) = %s\n", cudaGetErrorString(Error));

}

void Get_From_Device(float **d_a, float **h_b, int N) {
    // Size of data to send
    size_t size = N*sizeof(float);
    // Grab a error type
    cudaError_t Error;
    // Send d_a to the host variable h_b
    Error = cudaMemcpy(*h_b, *d_a, size, cudaMemcpyDeviceToHost);
    printf("CUDA error (memcpy d_a -> h_b) = %s\n", cudaGetErrorString(Error));
}
