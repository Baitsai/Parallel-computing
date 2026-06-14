#include <stdio.h>
#include <omp.h>

int main(int argc, char *argv[]) {
    // Create an array a containing 8 elements
    const int N = 8;
    float a[N];
    int no_threads = 4;
    int index = 0;
    int tid;
    int i;
    float C = 0.5; // A constant we are multiplying across a

    // Initialise the value of a based on index
    for (i = 0; i < N; i++)
    {
        a[i] = i;
        printf("Original value of a[%d] = %g\n", i, a[i]);
    }

    // Set the number of OpenMP threads
    omp_set_num_threads(no_threads);

    // Create threads and do the computation in parallel
    // #pragma omp parallel private(index, tid,a)
    // 每個 thread 都有自己的 a(沒有初始化),這個a不是原a, thread對它做操作等於在用垃圾值計算
    // 正確應該是:所有 threads 都應該操作「同一個 a」
    #pragma omp parallel private(index, tid)
    {
        tid = omp_get_thread_num();
        index = tid*(N/no_threads); 
        for (int i = 0; i < N/no_threads; i++) {
            a[index+i] = C*a[index+i];
        }
    } // Destroy threads

    // Show the result after multiplication
    for (int i = 0; i < N; i++) {
        printf("Final value of a[%d] = %g\n", i, a[i]);
    }
    return 0;
}
