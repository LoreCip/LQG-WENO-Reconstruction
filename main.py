import numpy as np

from tqdm import tqdm

h = 1e-2
nx = int(2 / h + 5)
xs = np.linspace(-1, 1, nx)
# xs = np.array([np.NaN if (i == 0) or (i == 1) or (i == nx - 2) or (i == nx - 1) 
#                 else (i-2)*h - 1 for i in range(nx)])

# Phys
u_prev = 0.5 + np.sin(np.pi * xs)

dt = 1e-3
N_it = 500

r = 2

sol = np.zeros((len(u_prev), 3))
sol[:, 0] = u_prev.copy()

for i in tqdm(range(N_it)):
    ### Fortran u_next = TDV_RK(r, u_prev, xs, h, dt)
    u_prev = u_next.copy()

    if (i+1)*dt == 0.318:
       sol[:, 1] = u_next.copy()
        
sol[:, 2] = u_next.copy()