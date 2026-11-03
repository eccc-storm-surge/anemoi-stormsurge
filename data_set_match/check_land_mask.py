"""Check that SSH land NaNs are static and line up with the graph's connected (ocean) nodes.

Run inside your project env:
    pixi run python check_land_mask.py
"""
import numpy as np
import torch
from anemoi.datasets import open_dataset

BASE = "/home/osw001/data/ppp7/surge_anemoi_project/anemoi-stormsurge"
SSH_ZARR = f"{BASE}/training-data/combined_anemoi_zarr/SSH_1993-2025_anemoi.zarr"
GRAPH = f"{BASE}/graph/global_graph_ocean_mask.pt"

# A short window is enough; widen it if you want a stronger check.
START, END = "2011-01-01", "2011-02-01"
VAR = "sossheig"

# ---------------------------------------------------------------- dataset
ds = open_dataset(SSH_ZARR, start=START, end=END)
vi = ds.name_to_index[VAR]
x = np.asarray(ds[0 : len(ds)])[:, vi, 0, :]  # (time, grid)
print(f"samples={x.shape[0]}  grid points={x.shape[1]}")

nan = np.isnan(x)
frac_per_point = nan.mean(axis=0)

always_nan = frac_per_point == 1.0
never_nan = frac_per_point == 0.0
sometimes = ~always_nan & ~never_nan

print(f"\noverall NaN fraction : {nan.mean():.4f}")
print(f"always NaN (land)    : {always_nan.sum()}  ({always_nan.mean():.2%} of points)")
print(f"never NaN (ocean)    : {never_nan.sum()}")
print(f"sometimes NaN        : {sometimes.sum()}   <- should be 0 if land is static")

if np.isinf(x).any():
    print("WARNING: found inf values")

ocean = x[:, never_nan]
print(f"ocean SSH  min={ocean.min():.3f}  max={ocean.max():.3f}  "
      f"mean={ocean.mean():.3f}  std={ocean.std():.3f}")

# ---------------------------------------------------------------- graph
g = torch.load(GRAPH, weights_only=False)
sel = g["data"]["indices_connected_nodes"]
sel = sel.squeeze().cpu()
n_grid = x.shape[1]

if sel.dtype == torch.bool:
    connected = sel.numpy()
else:
    connected = np.zeros(n_grid, dtype=bool)
    connected[sel.numpy().astype(int)] = True

print(f"\ngraph 'data' nodes   : {len(connected)}  (dataset grid: {n_grid})")
if len(connected) != n_grid:
    print("MISMATCH: graph and dataset have different node counts, stop here.")
else:
    print(f"connected nodes      : {connected.sum()}")
    print(f"connected but land   : {(connected & always_nan).sum()}   <- ideally 0")
    print(f"ocean but unconnected: {(~connected & never_nan).sum()}   <- ocean points dropped by the mask")
    print(f"land and unconnected : {(~connected & always_nan).sum()}")