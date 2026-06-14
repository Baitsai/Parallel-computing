#include <stdio.h>
#include <stdlib.h>
#include <math.h>
#include <time.h>

float randn(){
        float two_PI = 2.0*M_PI;
        float u1 = rand()/(float)RAND_MAX;
        float u2 = rand()/(float)RAND_MAX;
        float z1 = sqrt(-2.0*log(u1))*cos(two_PI*u2);
        //printf("randn is done");
	return z1;

}

int inside_table(float x, float y){
    if (x >= 0.0 && x <= 2.0 && y >= 2.0 && y <= 3.0) return 1;
    if (x >= 1.5 && x <= 2.0 && y >= 1.0 && y <= 2.0) return 1;
    if (x >= 1.5 && x <= 3.5 && y >= 0.0 && y <= 1.0) return 1;
    return 0;
}

int inside_target(float x, float y){
    if (x >= 3.0 && x <= 3.5 && y >= 0.0 && y <= 1.0)return 1;
    return 0;
}



