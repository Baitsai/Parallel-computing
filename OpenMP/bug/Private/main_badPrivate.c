#include <stdio.h>
#include <stdlib.h>
#include <omp.h>

int main(){
	int A[] ={0,1,2,3};
	#pragma omp parallel private(A)
	{
		// bad, local A is never set by thread
		for(int  i =0;i<4;i++){
			printf("A[%d]=%d\n",i,A[i]);

		}

	}
	// original A value
	for (int i=0;i<4;i++){
		printf("A[%d]=%d\n",i,A[i]);
	}

	return 0;

}

