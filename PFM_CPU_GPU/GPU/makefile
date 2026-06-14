NVCC=nvcc
NVCCFLAGS=-O3 -arch=sm_120

all: solver

solver: solver.cu
	$(NVCC) $(NVCCFLAGS) solver.cu -o solver

clean:
	rm -f solver results.txt density.png
