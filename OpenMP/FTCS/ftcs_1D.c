#include <stdio.h>
#include <stdlib.h>
#include <omp.h>
#define DEBUG 1
#define N 1000
#define ALPHA 1.0
#define L 1.0
#define DX(L/N)
#define DT(0.25*DX*DX/ALPHA)
#define NO_STEPS 2000
#define NP 20

int main(){
	float *T,*Tnew;
	T = (float*)malloc(N*sizeof(float));
	Tnew = (float*)malloc(N*sizeof(float));
	omp_set_num_threads(NP); //cant write 4? why?

	#pragma omp parallel
	{
	int tid = omp_get_thread_num();
	for (int i=tid; i<N;i+NP){
		if(i<0.5*N){
			T[i]=1.0;
		}
		else{
			T[i]=0.0;
		}
	}
	}// parallel end

	#pragma omp parallel
	{
	int tid = omp_get_thread_num();
        for (int step=0; step<NO_STEPS;step++){
		 
                for (int i=tid; i<N; i+=NP){
			printf("Computing new T in cell %d\n",i);
			float Left, Right;
			//left
			if(i==0){ 
                        	Left=1.0;
               		 }else{ 
                        	Left=T[i-1];
                	 }

			//right
			if(i==(N-1)){ 
                                Right=0.0;
                         }else{ 
                                Right=T[i+1];
                         }
			Tnew[i]=T[i]+0.25*(Left + Right -2.0*T[i]);
			printf("Tnew in cell=%g\n",Tnew[i]);
		} 
		#pragma omp barrier

		for (int i=tid; i<N; i+NP){
			T[i] =Tnew[i];
		}//loop over cells

	}

	}// End of time stepping
	
	FILE *pFile;
	if(DEBUG)printf("Saving results\n");
	pFile = fopen("result.txt","w");
	for(int i=0;i<N;i++){
		float X = DX*(i+1);
		fprintf(pFile,"%g\t%g\n",X,T[i]);
	}
	fclose(pFile);

	free(T);
	free(Tnew);

}
