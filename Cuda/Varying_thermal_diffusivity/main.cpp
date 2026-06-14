// Simple 1D Heat Transfer code
// a = Temperature, b = New temperature
// but..there is a bug here.
#include <stdio.h>
#include "gpu.h"

#define ALPHA_STEEL 15e-6
#define ALPHA_SILVER 173e-6

int main(int argc, char *argv[]) {
    float *h_a, *h_b, *h_c;  
    float *d_a, *d_b, *d_c;
    int N = 8000;
    int NX = 100;
    int NY = 40;
    float L = 1.0;
    float H = 0.4;
    float DX = L/NX;
    float DY = H/NY;
    float DT = 0.001;
    //float ALPHA = 1.0;
    int i,j;
    float CFL_STEEL, CFL_SILVER ;

    //float CFL_X = DT * ALPHA / (DX * DX);
    //float CFL_Y = DT * ALPHA / (DY * DY);
    //printf("CFL_X = %g\n", CFL_X);
    //printf("CFL_Y = %g\n", CFL_Y);
    CFL_STEEL = DT*ALPHA_STEEL/(DX * DX);
    printf("CFL_STEEL = %g\n", CFL_STEEL); 
    CFL_SILVER = DT*ALPHA_SILVER/(DX * DX);
    printf("CFL_SILVER = %g\n", CFL_SILVER);

    // Allocate memory on both device and host
    Allocate_Memory(&h_a, &h_b, &d_a, &d_b,  &h_c, &d_c, N);

    // Initialise h_a, but not h_b
    for(i = 0; i < NX; i++)
       for (j = 0; j < NY; j++) {
            int index = NY*i + j;
            float cx = (i+0.5)*DX;
	    float cy = (j+0.5)*DY; 
            h_a[index] = 300.0;
            h_c[index] = ALPHA_STEEL;
            if((cx>0.05)&&(cx<0.95)&&(cy>0.15)&&(cy<0.25)) h_c[index] = ALPHA_SILVER;
        }

    // Take h_a and store it on the device in d_a
    Send_To_Device(&h_a, &d_a, N);

    for (int step = 0; step < 1000; step++) {
    	// Perform a computation - multiply d_a by a constant (2)
	Vector_Times_Constant(d_a, d_b, d_c, DX, DY, DT, N, NX, NY);
    	//Compute_New_Temperature(d_a, d_b, d_c, DX, DY, DT, N, NX, NY);
   	// This function copies
    	Device_To_Device(&d_a, &d_b, N);
    }

    // Copy d_a from the device into h_b on the host
    Get_From_Device(&d_b, &h_b, N);

    // Check the values of h_b; should be the same as h_a
    for (i = 0; i < N; i++) {
        printf("Value of h_b[%d] = %g\n", i, h_b[i]);
    }

    FILE *pFile = fopen("result.txt", "w");

    for (int j = 0; j < NY; j++) {

    	for (int i = 0; i < NX; i++) {
        	int index = j * NX + i;
        	fprintf(pFile,"%d %d %.6f\n",i,j, h_b[index]);
    	}
    }

    fclose(pFile);

    // Free memory
    Free_Memory(&h_a, &h_b, &d_a, &d_b);

    return 0;
}
