# Parallel-computing

## Reference Problem

This project uses the two-dimensional supersonic forward-facing step problem as a reference test case. This problem is commonly associated with the strong-shock benchmark discussed by Woodward and Colella:

Woodward, P. and Colella, P. (1984). *The numerical simulation of two-dimensional fluid flow with strong shocks*. Journal of Computational Physics, 54(1), 115–173. DOI: 10.1016/0021-9991(84)90142-6.

Our implementation does not reproduce the exact numerical scheme from the paper. Instead, we use the same type of strong-shock forward-facing step flow as a benchmark problem and implement it using a Particle Flux Method with CPU and CUDA GPU versions.

## Problem Description

The simulation domain is a 2D channel with a solid step obstacle. The inflow is a high-speed Mach 3 flow from the left side.

Main physical settings:

Flow type: supersonic flow, Mach 3
Inflow velocity: (u, v) = (3.0, 0.0)
Density: rho = 1.4
Pressure: p = 1.0
Gas constants: R_GAS = 1.0, GAMMA = 1.4
Step location: SBL = 0.6
Step height: SBH = 0.2
Solid region: approximately x >= SBL and y <= SBH

Ghost cells are used to impose boundary conditions around the computational domain.

## Numerical Method

The code uses a Particle Flux Method. Each time step consists of the following operations:

Apply boundary conditions.
Compute the maximum particle velocity.
Compute the time step using the CFL condition:
dt = CFL * min(DX, DY) / max_v
Clear the new conservative variable arrays.
Move particles for one time step.
Reflect particles if they hit a wall or the solid step.
Deposit mass, momentum, and energy into the target cell.
Convert conservative variables back to primitive variables.

Each cell emits Nf particles. In the CUDA version, the main particle kernel flattens all particles into a 1D index, so each CUDA thread handles one particle.

## Build and Run
### GPU version

Compile:
make
./solver NX NY T_END

Example:./solver 300 300 2.0

### CPU version

Compile manually:
gcc -O3 solver.c -lm -o solver_cpu
./solver_cpu NX NY T_END

### Output Format

The output file results.txt contains one row per physical cell: x y rho u v p solid
The plotting script reads these columns, masks the solid cells, and saves the density contour as density.png.

## Visualization

Generate the density contour: python plot_contours.py

The output figure is:
<img width="2400" height="800" alt="density" src="https://github.com/user-attachments/assets/bbe13791-190f-4aba-94e6-d023d7f5ebaa" />

## Speedup Measurement

Run the same case using CPU and GPU, then compute: Speedup = CPU time / GPU time

Total cells = NX * NY
Speedup = CPU time / GPU time

<img width="514" height="319" alt="image" src="https://github.com/user-attachments/assets/5a7ed1c4-f1d3-474c-87c8-52f857ccde5e" />

