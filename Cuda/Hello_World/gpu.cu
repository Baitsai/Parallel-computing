#include <stdio.h>
#include <cuda_runtime.h>
#include "gpu.h"

void CPU_hello_world() {
    printf("CPU\n");
}

__global__ void GPU_hello_world() {
    int tid = threadIdx.x;
    int global_tid = blockIdx.x * blockDim.x + tid;

    printf("GPU cpp from thread %d (%d)\n", tid, global_tid);
}

void launch_GPU_hello_world(int no_blocks, int threads_per_block) {
    GPU_hello_world<<<no_blocks, threads_per_block>>>();
    cudaDeviceSynchronize();
}
