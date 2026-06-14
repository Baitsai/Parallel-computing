#include <stdio.h>
#include <stdlib.h>
//#include "gpu.h"

// Device Functions
__device__ float Compute_Heat_Flux(float T_LEFT, float T_RIGHT, float ALPHA_LEFT, float ALPHA_RIGHT, float DX){
    float effective_alpha = 2.0/((1.0/ ALPHA_LEFT)+(1.0/ ALPHA_RIGHT));
    float heat_flux = effective_alpha*(T_RIGHT-T_LEFT)/DX;
    return heat_flux;
}

__global__ void GPU_Compute_New_Temperature(float *a, float *b, float *c, 
					    float DX, float DY, float DT, int N, int NX, int NY) {
    // b is Tnew
    // a is T
    //int i = blockDim.x * blockIdx.x + threadIdx.x;
    int i = threadIdx.y * blockDim.x + threadIdx.x + ( blockDim.x * blockDim.y) * blockIdx.x  ;

     if (i < N) {
        float top, bottom, left, right, middle;
        float topF, bottomF, leftF, rightF;
        float topA, bottomA, leftA, rightA, middleA;
	int y_cell = (int)i/NX;
        int x_cell = i - y_cell*NX;
	middle = a[i];
	middleA = c[i];

	if (y_cell == 0) {
		bottom = a[i];//0.0;
		bottomA = c[i];
	} else {
		bottom = a[i-NX];
		bottomA = c[i-NX];
	}
	if (y_cell == NY-1) {
		top = 0.0;
		topA = 0.0;
	} else {
		top = a[i+NX];
		topA = c[i+NX];
	}
        if (x_cell == 0) {
                left = 300.0;//0.0;
		leftA = c[i];
        } else {
                left = a[i-1];
		leftA = c[i-1];
        }
        if (x_cell == NX-1) {
                right = 400.0;//1.0;
		rightA = c[i];
        } else {
                right = a[i+1];
		rightA = c[i+1];
        }

	float CFL_X =  DT / DX ;
        float CFL_Y =  DT / DY ;
	leftF = Compute_Heat_Flux(left, middle, leftA, middleA, DX);
	rightF = Compute_Heat_Flux(middle, right, middleA, rightA, DX);
        bottomF = Compute_Heat_Flux(bottom, middle, bottomA, middleA, DX);
	bottomF = Compute_Heat_Flux(bottom, middle, topA, middleA, DX);
        b[i] = a[i] + CFL_X*(left + right - 2.0*a[i]) + CFL_Y*(bottom + top - 2.0*a[i]);
	//printf("a[%d] FL= %g, b[%d] = %g\n", i, a[i], i, b[i]);
    }
}

// Host Functions

void Allocate_Memory(float **h_a, float **h_b, float **d_a, float **d_b, float **h_c, float **d_c,int N) {
    size_t size = N*sizeof(float);
    cudaError_t Error;
    // Host memory
    *h_a = (float*)malloc(size); 
    *h_b = (float*)malloc(size); 
    *h_c = (float*)malloc(size);
    // Device memory
    Error = cudaMalloc((void**)d_a, size); 
    printf("CUDA error (malloc d_a) = %s\n", cudaGetErrorString(Error));
    Error = cudaMalloc((void**)d_b, size);
    printf("CUDA error (malloc d_b) = %s\n", cudaGetErrorString(Error));
    Error = cudaMalloc((void**)d_c, size);
    printf("CUDA error (malloc d_c) = %s\n", cudaGetErrorString(Error));
}

void Free_Memory(float **h_a, float **h_b, float **d_a, float **d_b, float **h_c, float **d_c) {
    if (*h_a) free(*h_a);
    if (*h_b) free(*h_b);
    if (*d_a) cudaFree(*d_a);
    if (*d_b) cudaFree(*d_b);
    if (*h_c) cudaFree(*h_c);
    if (*d_c) cudaFree(*d_c);
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

void Device_To_Device(float **d_dog, float **d_cat, int N) {
    // Size of data to send
    size_t size = N*sizeof(float);
    // Grab a error type
    cudaError_t Error;
    // Copy cat data into dog on the GPU
    Error = cudaMemcpy(*d_dog, *d_cat, size, cudaMemcpyDeviceToDevice);
    printf("CUDA error (memcpy cat -> dog) = %s\n", cudaGetErrorString(Error));
}

void Get_From_Device(float **d_a, float **h_a, int N) {
    // Size of data to send
    size_t size = N*sizeof(float);
    // Grab a error type
    cudaError_t Error;
    // Send d_a to the host variable h_a
    Error = cudaMemcpy(*h_a, *d_a, size, cudaMemcpyDeviceToHost);
    printf("CUDA error (memcpy device -> host) = %s\n", cudaGetErrorString(Error));
}

//void Compute_New_Temperature(float *d_a, float *d_b, float CFL_X, float CFL_Y, int N, int NX, int NY) {
    ////int threadsPerBlock = 128;
    ////int blocksPerGrid = (N + threadsPerBlock - 1) / threadsPerBlock;
    ////GPU_Compute_New_Temperature<<<blocksPerGrid, threadsPerBlock>>>(d_a, d_b, CFL_X, CFL_Y, N, NX, NY);
    //dim3 threadsPerBlock(16,16,1);
    //dim3 blocksPerGrid(blocksPerGrid,1);
void Vector_Times_Constant(float *d_a, float *d_b, float *d_c, float DX, float DY, float DT, int N, int NX, int NY){
    int threadsPerBlock = 16*16;
    int blocksPerGrid =  (N + threadsPerBlock - 1) / threadsPerBlock;
    GPU_Compute_New_Temperature<<<blocksPerGrid, threadsPerBlock>>>(d_a, d_b, d_c, DX, DY, DT, N, NX, NY);
}
