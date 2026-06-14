#include <stdio.h>
#include <stdlib.h>

#define NX 1000
#define NY 1000
#define N (NX*NY)
#define L 10.0
#define H 10.0
#define DX (L/NX)
#define DY (H/NY)
#define C2 (1.4*287*300)   // Speed of sound squared
#define U 1.0
#define DT 0.00001
#define NO_STEPS 10000

float *Temp_old; // The old displacement
float *Temp; // displacement (pressure)
float *Temp_new; // new displacement (pressure)

void Allocate_Memory() {
    Temp = (float*)malloc(N*sizeof(float));
    Temp_new = (float*)malloc(N*sizeof(float));
    Temp_old = (float*)malloc(N*sizeof(float));
}

void Free_Memory() {
    free(Temp);
    free(Temp_new);
    free(Temp_old);
}

void Init() {
    // Set the air stationary everywhere
    for (int i = 0; i < N; i++) {
        Temp_old[i] = 0.0;
        Temp[i] = 0.0;
    }
}

void Save_Results() {
    FILE *pFile;
    pFile = fopen("results.txt", "w");
    for (int i = 0; i < N; i++) {
        int xcell = (int)i/NY;
        int ycell = i - xcell*NY;
        float cx = (xcell+0.5)*DX;
        float cy = (ycell+0.5)*DY;
        fprintf(pFile, "%g\t%g\t%g\n", cx, cy, Temp[i]);
    }
    fclose(pFile);
}


float Compute_Sound_Source(float x, float y, float time) {
    // See if this location has a source
    float freq = 1000.0;
    if ((x > 0.45*L) & (x < 0.55*L) & (y > 0.2*H) & (y < 0.25*H)) {
	return 1.0*sin(freq*time);
    } else {
        return 0.0;
    }
}


void Solve() {

    // Take time steps
    for (int step = 0; step < NO_STEPS; step++) {

        // Compute the new T value in each cell
        for (int i = 0; i < NX; i++) {
            for (int j = 0; j < NY; j++) { 
                int index = j + i*NY;

                // Compute cell location
                float cx = (i+0.5)*DX;
                float cy = (j+0.5)*DY;

                float TC = Temp[index];
                float TL, TR, FL, FR;

                // Compute the source
                float BC = Compute_Sound_Source(cx,cy, step*DT);

                if (BC > 0) {
                    // We manually set the value based on BC
                    Temp_new[index] = BC;
                } else {

                    // This is free air; we need to solve the wave equation

                    // Set TL
                    if (i == 0) {
                        TL = 0.0;
                    } else {
                        TL = Temp[index-NY];
                    }
                    // Set TR
                    if (i == (NX-1)) {
                        TR = 0.0;
                    } else {
                        TR = Temp[index+NY];
                    }

                    // Left Flux
                    FL =  C2*(TC - TL)/DX;
                    // Right Flux
                    FR =  C2*(TR - TC)/DX;

                    // Wave equation - update new values using X flux values
                    Temp_new[index] = 2.0*Temp[index] - Temp_old[index] + (DT*DT/DX)*(FR-FL);

                    // Set TL
                    if (j == 0) {
                        TL = 0.0;
                    } else {
                        TL = Temp[index-1];
                    }
                    // Set TR, force 0
                    if (j == (NY-1)) {
                        TR = 0.0;
                    } else {
                        TR = Temp[index+1];
                    }
                    // Left Flux
                    FL = C2*(TC - TL)/DY;
                    // Right Flux
                    FR = C2*(TR - TC)/DY;
                    // Update Wave equation for Y flux values
                    Temp_new[index] += (DT*DT/DY)*(FR-FL);
                }
            }
        }

        // Now update the temperature
        for (int i = 0; i < N; i++) {
            Temp_old[i] = Temp[i];
            Temp[i] = Temp_new[i];
        }
    }
}

int main() {
    Allocate_Memory();
    Init();
    Solve();
    Save_Results();
    Free_Memory();
}
