#ifndef SIMULATION_H
#define SIMULATION_H

#define N_BALLS 20000
#define DT 0.00005
#define NO_STEPS (40.0/DT)

float randn();
int inside_target(float x, float y);
int inside_table(float x, float y);


#endif
