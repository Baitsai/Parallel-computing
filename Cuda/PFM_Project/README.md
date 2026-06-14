# Supersonic Forward-Facing Step PFM Solver

Folders:
- CPU: single-core C implementation
- GPU: CUDA implementation using one GPU device

Build and run:

```bash
cd CPU
make all
time ./solver 300 100 4.0
python plot_contours.py

cd ../GPU
make all
time ./solver 300 100 4.0
python plot_contours.py
```

The solver writes `results.txt` and snapshot files `results_t0.txt` to `results_t4.txt` when those times are reached. `plot_contours.py` reads `results.txt` and writes `density.png`.
