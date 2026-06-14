#include<stdio.h>
#include<stdlib.h>

int main(){
	float*A;
	int sum=0;
	A = malloc(10000000*sizeof(float));
	for(int i = 0;i<10000000; i++){
		A[i]=(float)i;
		sum+=A[i];
	}
	printf("sum=%d",sum);
	free(A);
	return 0;

	
}
