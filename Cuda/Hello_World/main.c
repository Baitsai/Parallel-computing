#include <stdio.h>
#include "gpu.h"

int main() {
    printf("Meow meow meow\n");

    int no_blocks = 6;
    int threads_per_block = 4;

    launch_GPU_hello_world(no_blocks, threads_per_block);

    return 0;
}
