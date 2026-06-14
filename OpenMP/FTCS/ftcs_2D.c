
#include <stdio.h>
#include <stdlib.h>
#include <omp.h>

#define NX 5
#define NY 5
#define N (NX*NY)
#define ALPHA 1.0
#define CFL 0.25
#define L 1.0
#define H 1.0
#define DX (L/NX)
#define DY (H/NY)
#define DT (CFL*DX*DX/ALPHA)
#define T_TARGET 1.0

//2D memory code
int main(){
	//Print details of our sim
	printf("NX=%d, NY=%d, DT=%g", NX, NY, DT);

	float *T = (float*)malloc(sizeof(float)*N);
	float *Tnew = (float*)malloc(sizeof(float)*N);
	char *CPU = (char*)malloc(sizeof(char)*N);

	//set the initial values of T
	for(int i=0; i<NX; i++){
		for(int j=0; j<NY; j++){
			int index = i*NY+j;
			printf("\nSetting T[%d]=0.0",index);
			T[index]=0.0;
		}
	}
	#pragma omp parallel
	 {
	float time= 0.0;
	while(time<T_TARGET){
		//Iterate through time untill our target time
		printf("Simulating time %g\n",time);
		time +=DT;

		#pragma omp for
		//Iterate through each cell and compute new T
		for(int i=0; i<NX; i++){
			for(int j=0; j<NY; j++){
				float Left,Right,Top,Bottom;
				int index = i*NY+j;
				//Left
				if(i==0){
					Left=0.0;
				}else{
					Left=T[index-NY];
				}

				//Right
				if(i==(NX-1)){
					Right=1.0;
				}else{
					Right=T[index+NY];
				}

				//Bottom
                                if(j==0){
                                        Bottom=0.0;
                                }else{ 
                                        Bottom=T[index-1];
                                }

				//Top
                                if(j==(NY-1)){
                                        Top=0.0;
                                }else{ 
                                        Top=T[index+1];
                                }

				Tnew[index] = T[index]+CFL*(Left+Right+Top+Bottom-4.0*T[index]);

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


	}//End  cell

	}//End parallel

	FILE *pFile;
	pFile=fopen("result.txt","w");
	for(int i = 0; i<NX; i++){
		for(int j=0; j<NY; j++){
			float X = (i+0.5)*DX;
			float Y = (j+0.5)*DY;
			int index = i*NY+j;
			fprintf(pFile,"%g\t%g\t%g\n",X,Y,T[index]);
			
		}
	}
	fclose(pFile);
	free(T);                        
	free(Tnew);
	free(CPU);
	return 0;
}
