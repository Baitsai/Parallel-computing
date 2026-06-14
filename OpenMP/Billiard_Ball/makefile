CC = gcc
LIBS = -lm -fopenmp

all: main

main: main.c simulation.c file.c
	$(CC) main.c simulation.c file.c -o main $(LIBS)

clean:
	rm -f main results.csv
