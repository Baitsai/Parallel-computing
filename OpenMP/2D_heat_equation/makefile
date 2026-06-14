CC = gcc
LIBS = -lm -fopenmp

all: main

main: main.c 
	$(CC) main.c -o main $(LIBS)
clean:
	rm -f main result.txt energy.txt
