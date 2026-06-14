#include <stdlib.h>

float Calc_T_CPU(float *vx, float *x, float left, float right, int N,float R){

	int count = 0;
	float sum_vx=0.0;
	
	for(int i = 0; i<N; i++){
		if (x[i] >= left && x[i] <= right) {
			sum_vx += vx[i];
			count++;
		}
	}

	if(count==0) return -1;

	float mean_vx = (float)sum_vx/count;
	float var_vx = 0.0;

        for(int i = 0; i<N; i++){
       	        if (x[i] >= left && x[i] <= right) {
               	        float v =  (vx[i]-mean_vx)*(vx[i]-mean_vx);
			var_vx = var_vx+v;
               	}
       	}

	float T = (float)var_vx/(R*count); 

	return T;
}
