COMPILER := gcc
OPT_FLAGS := -lm -fopenmp
all: compile
	${COMPILER} main.o -o main ${OPT_FLAGS}
compile:
	${COMPILER} main.c -c ${OPT_FLAGS}
clean:
	rm main.exe main.o
