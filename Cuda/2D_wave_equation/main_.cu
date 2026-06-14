#include <stdio.h>
#include <stdlib.h>

#define NX 1000
#define NY 1000
#define N (NX*NY)
#define L 10.0
#define H 10.0
#define DX (L/NX)
#define DY (H/NY)
#define C2 (1.4*287*300)   // Speed of sound squared
#define U 1.0
#define DT 0.00001
#define NO_STEPS 10000

float *Temp_old; // The old displacement
float *Temp; // displacement (pressure)
float *Temp_new; // new displacement (pressure)
float *d_Temp_old; // The old displacement
float *d_Temp; // displacement (pressure)
float *d_Temp_new; // new displacement (pressure)

void Allocate_Memory(){
    Temp = (float*)malloc(N*sizeof(float));
    Temp_new = (float*)malloc(N*sizeof(float));
    Temp_old = (float*)malloc(N*sizeof(float));

    cudaError_t Error0,Error1,Error2; 
   // Device memory
    Error0 = cudaMalloc((void**)&d_Temp, N*sizeof(float));
    Error1 = cudaMalloc((void**)&d_Temp_new, N*sizeof(float));
    Error2 = cudaMalloc((void**)&d_Temp_old, N*sizeof(float));
   // printf("CUDA error (d_Temp) = %s\n", cudaGetErrorString(Error0));
    //printf("CUDA error (d_Temp_new) = %s\n", cudaGetErrorString(Error1));
    //printf("CUDA error (d_Temp_old) = %s\n", cudaGetErrorString(Error2));
}

void Free_Memory() {
    free(Temp);
    free(Temp_new);
    free(Temp_old);
    cudaFree(d_Temp);
    cudaFree(d_Temp_new);
    cudaFree(d_Temp_old);
}

void Send_To_Device() {
    // Size of data to send
    size_t size = N*sizeof(float);
    // Grab a error type
    cudaError_t Error;
    // Send A to the GPU
    Error = cudaMemcpy(d_Temp, Temp, size, cudaMemcpyHostToDevice);
    //printf("CUDA error (memcpy h_a -> d_a) = %s\n", cudaGetErrorString(Error));
    Error = cudaMemcpy(d_Temp_new, Temp_new, size, cudaMemcpyHostToDevice);
    //printf("CUDA error (memcpy h_a -> d_a) = %s\n", cudaGetErrorString(Error));
    Error = cudaMemcpy(d_Temp_old, Temp_old, size, cudaMemcpyHostToDevice);
    //printf("CUDA error (memcpy h_a -> d_a) = %s\n", cudaGetErrorString(Error));
}

void Device_To_Device() {
    // Size of data to send
    size_t size = N*sizeof(float);
    // Grab a error type
    cudaError_t Error;
    // Copy cat data into dog on the GPU
    Error = cudaMemcpy(d_Temp_old, d_Temp, size, cudaMemcpyDeviceToDevice);
    //printf("CUDA error (memcpy d_Temp -> d_Temp_old) = %s\n", cudaGetErrorString(Error));
    Error = cudaMemcpy(d_Temp, d_Temp_new, size, cudaMemcpyDeviceToDevice);
    //printf("CUDA error (memcpy d_Temp_new -> d_Temp) = %s\n", cudaGetErrorString(Error));
}

void Get_From_Device() {
    // Size of data to send
    size_t size = N*sizeof(float);
    // Grab a error type
    cudaError_t Error;
    // Send d_a to the host variable h_a
    Error = cudaMemcpy(Temp_new, d_Temp_new, size, cudaMemcpyDeviceToHost);
    //printf("CUDA error (memcpy device -> host) = %s\n", cudaGetErrorString(Error));
    Error = cudaMemcpy(Temp, d_Temp, size, cudaMemcpyDeviceToHost);
    //printf("CUDA error (memcpy device -> host) = %s\n", cudaGetErrorString(Error));
    Error = cudaMemcpy(Temp_old, d_Temp_old, size, cudaMemcpyDeviceToHost);
    //printf("CUDA error (memcpy device -> host) = %s\n", cudaGetErrorString(Error));
}

void Init() {
    // Set the air stationary everywhere
    for (int i = 0; i < N; i++) {
        Temp_old[i] = 0.0;
        Temp[i] = 0.0;
	Temp_new[i] = 0.0;
    }
}

void Save_Results() {
    FILE *pFile;
    pFile = fopen("results.txt", "w");
    for (int i = 0; i < N; i++) {
        int xcell = (int)i/NY;
        int ycell = i - xcell*NY;
        float cx = (xcell+0.5)*DX;
        float cy = (ycell+0.5)*DY;
        fprintf(pFile, "%g\t%g\t%g\n", cx, cy, Temp_new[i]);
    }
    fclose(pFile);
}

float Compute_Sound_Source(float x, float y, float time) {
    // See if this location has a source
    float freq = 1000.0;
    if ((x > 0.45*L) & (x < 0.55*L) & (y > 0.2*H) & (y < 0.25*H)) {
	return 1.0*sin(freq*time);
    } else {
        return 0.0;
    }
}

__device__ float Compute_Sound_GPU(float x, float y, float time){
    float freq = 1000.0;
    if ((x > 0.45*L) & (x < 0.55*L) & (y > 0.2*H) & (y < 0.25*H)) {
        return 1.0*sin(freq*time);
    } else {
         return 0.0;
    }
}

__global__ void GPU_Solve(int step, float *d_Temp,float *d_Temp_old,float *d_Temp_new){
	
        //int index = blockDim.x * blockIdx.x + threadIdx.x;
	//__shared__ float temp[16][16];
        int xcell = blockDim.x * blockIdx.x + threadIdx.x;
        int ycell = blockDim.y * blockIdx.y + threadIdx.y;
        int index = xcell*NY + ycell;
        
        // Move cell i's temperature into shared memory
       // if ((xcell < NX) && (ycell < NY)) temp[threadIdx.x][threadIdx.y] = d_Temp[index];
        //__syncthreads();

	if((xcell < NX) && (ycell < NY)){ 
                int i = xcell; //(int)index/NY;
                int j = ycell; //index-(i*NY);

                // Compute cell location
                float cx = (i+0.5)*DX;
                float cy = (j+0.5)*DY;
                float TC = d_Temp[index];
                float TL, TR, FL, FR;
                float BC = Compute_Sound_GPU(cx, cy, step*DT);

                if (BC > 0) {
                    // We manually set the value based on BC
                    d_Temp_new[index] = BC;
                } else {

                    // This is free air; we need to solve the wave equation

                    // Set TL
                    if (i == 0) {
                        TL = 0.0;
                    } else {
                       TL = d_Temp[index-NY];
		       /*if (threadIdx.x == 0) {
                	    TL = d_Temp[index-NY];
            		} else {
                	    TL = temp[threadIdx.x-1][threadIdx.y];         
            		}*/
                    }

                    // Set TR
                    if (i == (NX-1)) {
                        TR = 0.0;
                    } else {
                        TR = d_Temp[index+NY];
            		/*if (threadIdx.x == 15) {
                	    // We hit the edge of our region - we need to pull it from global
                	    TR = d_Temp[index+NY];
            		} else {
                            // We can pull this value from 2D shared memory
                	    TR = temp[threadIdx.x+1][threadIdx.y];
            		}*/
                    }

                    // Left Flux
                    FL =  C2*(TC - TL)/DX;
                    // Right Flux
                    FR =  C2*(TR - TC)/DX;

                    // Wave equation - update new values using X flux values
                    d_Temp_new[index] = 2.0*d_Temp[index]-d_Temp_old[index]+(DT*DT/DX)*(FR-FL);

                    // Set TL
                    if (j == 0) {
                        TL = 0.0;
                    } else {
                        TL = d_Temp[index-1];
                    }

                    // Set TR, force 0
                    if (j == (NY-1)) {
                        TR = 0.0;
                    } else {
                        TR = d_Temp[index+1];
                    }

                    // Left Flux
                    FL = C2*(TC - TL)/DY;
                    // Right Flux
                    FR = C2*(TR - TC)/DY;

                    // Update Wave equation for Y flux values
                    d_Temp_new[index] += (DT*DT/DY)*(FR-FL);
                }
	}
}

void Solve(){
    //Create timers
    cudaEvent_t start;
    cudaEvent_t stop;
    float elapsedTime;
    //start timer
    cudaEventCreate(&start);
    cudaEventCreate(&stop);
    cudaEventRecord(start, 0);

    //int threadsPerBlock = 64;
    //int blocksPerGrid = (N + threadsPerBlock - 1) / threadsPerBlock;
    int no_threads_x = 16;   // No. threads in the X direction
    int no_threads_y = 16;   // No. threads in the Y direction
    // Compute the number of blocks required in each direction
    int no_blocks_x = (int)((NX + no_threads_x - 1)/no_threads_x);
    int no_blocks_y = (int)((NY + no_threads_y - 1)/no_threads_y);
    dim3 threads(no_threads_x, no_threads_y, 1); // 2D Threads in each block (ignore Z for now)
    dim3 grid(no_blocks_x, no_blocks_y,1);

    // Take time steps
    for (int step = 0; step < NO_STEPS; step++) {
 	GPU_Solve<<<grid,threads>>>(step,d_Temp,d_Temp_old,d_Temp_new);
        cudaError_t err = cudaGetLastError();
        if (err != cudaSuccess) {
            printf("Kernel launch error at step %d: %s\n", step, cudaGetErrorString(err));
            break;
        }
        cudaDeviceSynchronize();
        Device_To_Device();
    }
    cudaEventRecord(stop, 0);
    cudaEventSynchronize(stop);
    cudaEventElapsedTime(&elapsedTime, start, stop);
    printf("Total GPU solve time = %f ms\n", elapsedTime);

    cudaEventDestroy(start);
    cudaEventDestroy(stop);
}

void CPU_Solve() { 
    // Take time steps
    for (int step = 0; step < NO_STEPS; step++) {
        // Compute the new T value in each cell
        for (int i = 0; i < NX; i++) {
            for (int j = 0; j < NY; j++) { 
                int index = j + i*NY;

                // Compute cell location
                float cx = (i+0.5)*DX;
                float cy = (j+0.5)*DY;

                float TC = Temp[index];
                float TL, TR, FL, FR;

                // Compute the source
                float BC = Compute_Sound_Source(cx,cy, step*DT);

                if (BC > 0) {
                    // We manually set the value based on BC
                    Temp_new[index] = BC;
                } else {

                    // This is free air; we need to solve the wave equation

                    // Set TL
                    if (i == 0) {
                        TL = 0.0;
                    } else {
                        TL = Temp[index-NY];
                    }
                    // Set TR
                    if (i == (NX-1)) {
                        TR = 0.0;
                    } else {
                        TR = Temp[index+NY];
                    }

                    // Left Flux
                    FL =  C2*(TC - TL)/DX;
                    // Right Flux
                    FR =  C2*(TR - TC)/DX;

                    // Wave equation - update new values using X flux values
                    Temp_new[index] = 2.0*Temp[index] - Temp_old[index] + (DT*DT/DX)*(FR-FL);

                    // Set TL
                    if (j == 0) {
                        TL = 0.0;
                    } else {
                        TL = Temp[index-1];
                    }
                    // Set TR, force 0
                    if (j == (NY-1)) {
                        TR = 0.0;
                    } else {
                        TR = Temp[index+1];
                    }
                    // Left Flux
                    FL = C2*(TC - TL)/DY;
                    // Right Flux
                    FR = C2*(TR - TC)/DY;
                    // Update Wave equation for Y flux values
                    Temp_new[index] += (DT*DT/DY)*(FR-FL);
                }
            }
        }

        // Now update the temperature
        for (int i = 0; i < N; i++) {
            Temp_old[i] = Temp[i];
            Temp[i] = Temp_new[i];
        }
    }
}

int main() {
    Allocate_Memory();
    Init();
    Send_To_Device();
    Solve();
    Get_From_Device();
    Save_Results();
    Free_Memory();
    return 0;
}
