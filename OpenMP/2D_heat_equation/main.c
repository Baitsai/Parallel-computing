
#include <stdio.h>
#include <stdlib.h>
#include <omp.h>

#define NX 100
#define NY 100
#define N (NX*NY)
#define ALPHA 1.0
#define L 1.0
#define H 0.5
#define DX (L/NX)
#define DY (H/NY)
#define DT 0.000005
#define CFL_X (DT*ALPHA / (DX*DX))
#define CFL_Y (DT*ALPHA / (DY*DY))
#define T_TARGET 1.0
#define NO_STEPS ((int)(T_TARGET / DT))
#define a 0.05
#define b 0.05

//2D memory code
int main(){
	//Print details of our sim
	printf("NX=%d, NY=%d, DT=%g, CFL_X=%g, CFL_Y=%g", NX, NY, DT, CFL_X, CFL_Y);

	float *T = (float*)malloc(sizeof(float)*N);
	float *Hole = (float*)malloc(sizeof(float)*N);
	float *Tnew = (float*)malloc(sizeof(float)*N);
	float *E = (float*)malloc(sizeof(float)*NO_STEPS);
	float *Time = (float*)malloc(sizeof(float)*NO_STEPS);

	//set the initial values
	for(int i=0; i<NX; i++){
    		for(int j=0; j<NY; j++){
        		int index = i*NY + j;
        		float X = (i + 0.5) * DX;
        		float Y = (j + 0.5) * DY;

        		T[index] = 0.0;
			Tnew[index]=0.0;

			//check for hole1
       			if (X > a && X < (a + 0.25) &&
            		    Y > b && Y < (b + 0.25)) {
           			Hole[index] = 1;
        		}
			//check for hole2
        		else if (X > (L - a - 0.25) && X < (L - a) &&
                		 Y > (H - b - 0.25) && Y < (H - b)) {
            			Hole[index] = 1;
        		}
			else
				Hole[index] = 0;
    		}
	}



	float time= 0.0;
        int step=0;
	#pragma omp parallel
	{
		while(time<T_TARGET){

			//Iterate through each cell and compute new T
			#pragma omp for
			for(int i=0; i<NX; i++){
				for(int j=0; j<NY; j++){
					float Left, Right, Top, Bottom;
					int index = i*NY+j;

					//Left
					if(i==0){
						Left=0.0;
					}else{
						if(Hole[index-NY]==0)
							Left=T[index-NY];
						else
							Left=T[index];
					}

					//Right
					if(i==(NX-1)){
						Right=1.0;
					}else{
						if(Hole[index+NY]==0)
							Right=T[index+NY];
						else
							Right=T[index];
					}

					//Bottom
                	                if(j==0){
        	                                Bottom=T[index];
	                                }else{
                                	        if (Hole[index-1] == 0)
							Bottom = T[index-1];
						else
							Bottom = T[index];
	                                }

					//Top
                        	        if(j==(NY-1)){
                	                        Top=T[index];
        	                        }else {
						if (Hole[index+1] == 0)
							Top = T[index+1];
						else
							Top = T[index];
					}

					if (Hole[index] == 0) {
						Tnew[index] = T[index]+CFL_X*(Left+Right-2.0*T[index])+CFL_Y*(Top+Bottom-2.0*T[index]);
					}
				}
			}


			//update T
			#pragma omp for
			for(int i=0; i<NX; i++){
        		       for(int j=0; j<NY; j++){
					int index = i*NY+j;
					T[index]=Tnew[index];
				}
			}//End t


			#pragma omp single
			{
				float totalE = 0.0;
				for (int i = 0; i < NX; i++) {
 					for (int j = 0; j < NY; j++) {
						int index = i * NY + j;
						totalE += T[index] * DX * DY;
					}
				}

				Time[step] = time;
				E[step] = totalE;

				//printf("\nStep: %d\n",step);
                                //printf("\nSimulating time %g\n",time);
                                step++;
				time +=DT;
			}


		}//End  cell
	}//End parallel
	printf("\nEnd Parallel.\n");

	FILE *pFile;
	pFile=fopen("result.txt","w");
	for(int i = 0; i<NX; i++){
		for(int j=0; j<NY; j++){
			float X = (i+0.5)*DX;
			float Y = (j+0.5)*DY;
			int index = i*NY+j;
			fprintf(pFile,"%g\t%g\t%g\t%g\n",X,Y,T[index],Hole[index]);

		}
	}
	fclose(pFile);

	printf("\nStep: %d\n",step);
	FILE *eFile = fopen("energy.txt", "w");
	for (int k = 0; k < step; k++) {
		fprintf(eFile, "%g\t%g\n", Time[k], E[k]);
	}
	fclose(eFile);

	free(T);
	free(Hole);
	free(Tnew);
	free(E);
	free(Time);

	return 0;
}
