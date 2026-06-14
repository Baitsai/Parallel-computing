#include <stdio.h>
#include <math.h>
#include "Calc_T_CPU.h"
#define N 100000
#define R 287.0
#define T 300.0
#define Tx 3000.0
#define Right 0.6
#define Left 0.4

void Allocate_Memory(float **h_a, float **d_a, int n);
void Free_Memory(float **h_a, float **d_a);

float randn(){
        float two_PI = 2.0*M_PI;
        float u1 = rand()/(float)RAND_MAX;
        float u2 = rand()/(float)RAND_MAX;
        float z1 = sqrt(-2.0*log(u1))*cos(two_PI*u2);
        //printf("randn is done");
        return z1;

}

int main() {

	float *x_cpu;
	float *vx_cpu;
	float *x_gpu;
	float *vx_gpu;

	Allocate_Memory(&x_cpu, &vx_cpu, &x_gpu, &vx_gpu, N);

	for (int i = 0; i < N; i++) {
		if(x_cpu[i] >= Left && x_cpu[i] <= Right){
			x_cpu[i] = ((float)rand()/RAND_MAX);
			vx_cpu[i] = randn()*sqrtf(R*Tx);
		}
		else{
			x_cpu[i] = ((float)rand()/RAND_MAX);
			vx_cpu[i] = randn()*sqrtf(R*T);
		}
	}

	float ans = Calc_T_CPU(vx_cpu,x_cpu,Left,Right,N,R);
	printf("L=%g, R=%g, The answer  =  %g\n",Left,Right, ans);


	// Free memoryvx_cpu[i] = randn()*sqrtf(R*T);
	printf("T of cell = %g",ans);

	Free_Memory(&x_cpu, &vx_cpu, &x_gpu, &vx_gpu);

	return 0;
}
