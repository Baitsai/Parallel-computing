#include <stdio.h>
#include <math.h>
#include <stdlib.h>
#include "simulation.h"

void save_files(float *z) {
    	FILE *fptr;
    	fptr = fopen("results.csv", "w");
   
    	if (fptr == NULL) {
        	printf("Error opening file\n");
        	return;
	}

//    for (int step = 0; step < NO_STEPS; step++) {
//    	for(int ball = 0; ball < N_BALLS; ball++){
//    	    int curr = step*N_BALLS+ball;
//    	    fprintf(fptr, "%d\t%.6f\t%.6f\t%.2f\n", ball, x[curr], y[curr], step*DT);
//    	}
//    }
    
	fprintf(fptr, "t,Z\n");
	int count = 0;
	for (int step = 0; step < NO_STEPS; step++) {
		float t = step * DT;
		fprintf(fptr, "%f,%f\n", t, z[step]);
		if(z[step]>0)count++;
		
	}
	printf("count%d\n",count);
    // Close the file
    fclose(fptr);
}
