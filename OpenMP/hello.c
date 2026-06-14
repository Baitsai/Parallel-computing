#include <stdio.h>
#include <omp.h>

int main(int argc, char *argv[]) {
    
    int no_threads = 2;

    omp_set_num_threads(no_threads);
    // Create threads
    #pragma omp parallel
    {
        int tid = omp_get_thread_num();
        printf("Hello again from thread %d\n", tid);
    } // Destroy threads
    return 0;
}
