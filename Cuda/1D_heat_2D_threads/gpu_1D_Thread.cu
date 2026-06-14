#include <stdio.h>
#include <stdlib.h>
#include "gpu.h"
// Device Functions

__global__ void GPU_Vector_Times_Constant(float *a, float *b, float C, int N) {
    int i = blockDim.x * blockIdx.x + threadIdx.x;
    if (i < N) {
        //b[i] = C*a[i];
        float left, right;
	if(i==0){
	    left = 0.0;
	}
	else{
	    left = a[i-1];
	}

        if(i==(N-1)){
            right = 1.0;
        }
        else{
            right = a[i+ 1];
        }
	b[i] = a[i] + C*(left+right-2*a[i]);
        printf("a[%d] = %g, b[%d] = %g\n",i,a[i],i,b[i]);
    }
}

// Host Functions

void Allocate_Memory(float **h_a, float **h_b, float **d_a, float **d_b, int N) {
    size_t size = N*sizeof(float);
    cudaError_t Error,Error1;
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
    printf("Copying d_b to d_a\n");
    size_t size = N*sizeof(float);
    // Grab a error type
    cudaError_t Error;

    // Send A to B
    Error = cudaMemcpy(*d_a, *d_b, size, cudaMemcpyDeviceToDevice);
    printf("CUDA error (memcpy d_b -> d_a) = %s\n", cudaGetErrorString(Error));
}

void Get_From_Device(float **h_a, float **d_a,int N) {
    // Size of data to send
    size_t size = N*sizeof(float);
    // Grab a error type
    cudaError_t Error;
    // Send d_a to the host variable h_b
    Error = cudaMemcpy(*h_a, *d_a, size, cudaMemcpyDeviceToHost);
    printf("CUDA error (memcpy d_a -> h_a) = %s\n", cudaGetErrorString(Error));
}

void Vector_Times_Constant(float *d_a, float *d_b, float C, int N) {
    int threadsPerBlock = 4;
    int blocksPerGrid = 6; //(N + threadsPerBlock - 1) / threadsPerBlock;
    GPU_Vector_Times_Constant<<<blocksPerGrid, threadsPerBlock>>>(d_a,d_b,  C, N);
    cudaDeviceSynchronize();
}
