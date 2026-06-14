#include <stdio.h>
#include <stdlib.h>
#include <time.h>
#include "simulation.h"
#include "file.h"
#include <omp.h>

int main(){
	double start, end;
	double cpu_time_used,parallel_time;
	srand(time(NULL));
	float *vx = malloc(N_BALLS * sizeof(float));
	float *vy = malloc(N_BALLS * sizeof(float));
	float *x = malloc(N_BALLS * sizeof(float));	
	float *y = malloc(N_BALLS * sizeof(float));
	float *z = malloc(NO_STEPS  * sizeof(float));
	
	for(int i = 0; i < N_BALLS; i++) {
		x[i] = 0.5 * ((float)rand() / RAND_MAX);
		y[i] = 2 + (float)rand() / RAND_MAX;
		vx[i] = randn();
		vy[i] = randn();
		//printf("%.6f\n",y[i]);
		//printf("%.6f\t%.6f\n",vx[i],vy[i]);
		//printf("%.6f\n",vy[i]);
	}
	
	start = omp_get_wtime();
	omp_set_num_threads(4);
	int nthreads = 4;
	int *target_local = malloc(nthreads * sizeof(int));

	# pragma omp parallel
	{
	int tid = omp_get_thread_num();
	for(int step=0; step<NO_STEPS; step++){
		target_local[tid] = 0;
		#pragma omp for
		for(int b = 0; b < N_BALLS; b++){
			float x_new = x[b] + vx[b] * DT;
			float y_new = y[b] + vy[b] * DT;

			if (inside_table(x_new, y_new)) {
			    x[b] = x_new;
			    y[b] = y_new;
			}
			else {
			    /* 撞到上外框 y = 3 */
			    if (y_new > 3.0 && x_new >= 0.0 && x_new <= 2.0) {
			        y_new = 6.0 - y_new;
			        vy[b] = -vy[b];
			    }
			    /* 撞到下外框 y = 0 */
			    else if (y_new < 0.0 && x_new >= 1.5 && x_new <= 3.5) {
			        y_new = -y_new;
			        vy[b] = -vy[b];
			    }
			    /* 撞到左上塊底邊 y = 2 */
			    else if (y[b] >= 2.0 && y_new < 2.0 && x_new >= 0.0 && x_new <= 1.5) {
			        y_new = 4.0 - y_new;
			        vy[b] = -vy[b];
			    }
			    /* 撞到右下塊上邊 y = 1 */
			    else if (y[b] <= 1.0 && y_new > 1.0 && x_new >= 2.0 && x_new <= 3.5) {
			        y_new = 2.0 - y_new;
			        vy[b] = -vy[b];
			    }
			    /* 撞到左邊界 x = 0 */
			    else if (x_new < 0.0 && y_new >= 2.0 && y_new <= 3.0) {
			        x_new = -x_new;
			        vx[b] = -vx[b];
			    }
			    /* 撞到上面右邊界 x = 2 */
			    else if (x[b] <= 2.0 && x_new > 2.0 && y_new >= 2.0 && y_new <= 3.0) {
			        x_new = 4.0 - x_new;
			        vx[b] = -vx[b];
			    }
			    /* 撞到中間左牆 x = 1.5 */
			    else if (x[b]>= 1.5 && x_new < 1.5 && y_new >= 1.0 && y_new <= 2.0) {
			        x_new = 3.0 - x_new;
			        vx[b] = -vx[b];
			    }
			    /* 撞到中間右牆 x = 2 */
			    else if (x[b] <= 2.0 && x_new > 2.0 && y_new >= 1.0 && y_new <= 2.0) {
			        x_new = 4.0 - x_new;
			        vx[b] = -vx[b];
			    }
			    /* 撞到下面左牆 x = 1.5 */
			    else if (x[b] >= 1.5 && x_new < 1.5 && y_new >= 0.0 && y_new <= 1.0) {
			        x_new = 3.0 - x_new;
			        vx[b] = -vx[b];
			    }
			    /* 撞到右外框 x = 3.5 */
			    else if (x_new > 3.5 && y_new >= 0.0 && y_new <= 1.0) {
			        x_new = 7.0 - x_new;
			        vx[b] = -vx[b];
			    }
			    else {
			        vx[b] = -vx[b];
			        vy[b] = -vy[b];
			    }

			    x[b] = x_new;
			    y[b] = y_new;
			}
			if (inside_target(x[b], y[b])){
				target_local[tid]++;
			}
		}
		#pragma omp barrier
		#pragma omp master
		{
			int target = 0;
            		for (int t = 0; t < nthreads; t++) {
                		target += target_local[t];
            		}
			z[step]=(float)target / (float)N_BALLS;
        	}
		#pragma omp barrier
	}
	}
	 
	end = omp_get_wtime();
	save_files(z);
	cpu_time_used = ((double) (end - start));
	printf("Total Time = %f\n", cpu_time_used);

	free(x);
	free(y);
	free(vx);
	free(vy);
	free(z);
	free(target_local);
}

