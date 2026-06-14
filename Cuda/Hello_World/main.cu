#include <stdio.h>
#include <cuda_runtime.h>

void CPU_hello_world(){
	printf("CPU\n");
}

__global__ void GPU_hello_world(){
	int tid = threadIdx.x;
	int global_tid = blockIdx.x*blockDim.x + tid;
	printf("GPU Meow from thread %d (%d)\n",tid, global_tid);


}

int main(){
	printf("Meow meow meow\n");
	int no_blocks =6;
	int threads_per_block=4;
	GPU_hello_world<<<no_blocks,threads_per_block>>>();
	cudaDeviceSynchronize();
	return 0;
}
