import numpy as np
import matplotlib.pyplot as plt

data = np.loadtxt("results.txt")

x = data[:, 0]
y = data[:, 1]
rho = data[:, 2]
solid = data[:, 6].astype(int)

rho_plot = np.where(solid == 0, rho, np.nan)

x_unique = np.unique(x)
y_unique = np.unique(y)

NX = len(x_unique)
NY = len(y_unique)

X = x.reshape(NY, NX)
Y = y.reshape(NY, NX)
RHO = rho_plot.reshape(NY, NX)

plt.figure(figsize=(10, 4))
plt.pcolormesh(X, Y, RHO, shading="auto")
plt.colorbar(label="Density")

plt.xlabel("x")
plt.ylabel("y")
plt.title("Density Contour")
plt.axis("equal")
plt.tight_layout()

plt.savefig("density.png", dpi=300)
plt.show()
