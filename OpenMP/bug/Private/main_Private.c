#include <stdio.h>
#include <stdlib.h>
#include <omp.h>

int main(){
	int i;
	#pragma omp parallel private(i) 
	{
		int A[] = {0,1,2,3};
		
		for(i =0;i<4;i++){
			printf("A[%d]=%d\n",i,A[i]);

		}

	}

	return 0;

}

