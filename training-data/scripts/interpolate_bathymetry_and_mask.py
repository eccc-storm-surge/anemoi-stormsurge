
from pathlib import Path
import xarray
from aether import Regridder


def main():

    ds_btmy = xarray.open_dataset(
        "/home/sssm001/constants/cmde/surge/gesps/bathy70.nc")

    ds_ssh_era5 = xarray.open_dataset(
        "training-data/gdsps-hindcast/era5-grid/netcdf/SSH_y1993.nc"
    )

    ds_grd = xarray.open_dataset(
        "/home/olh001/Python/anemoi-stormsurge/training-data/gdsps-hindcast/PN_y1993.nc")

    # ds_grd = ds_grd.isel(latitude=slice(None, None, -1))

    print(f"Input dst grid shapes: {ds_grd.longitude.shape = }; {ds_grd.latitude.shape = }")

    print(ds_grd.latitude[0], ds_grd.latitude[-1])

    rg = Regridder(ds_btmy, ds_grd, method="mixt")

    out = rg(ds_btmy[["Bathymetry"]])

    print(f"Output dst grid shapes: {out['lon'].shape = }; {out['lat'].shape = }")


    ssh_field = ds_ssh_era5["sossheig"].isel(time_counter=0)
    ssh_field.attrs["units"] = "-"
    out["tmask"] = ~ssh_field.isnull().squeeze()

    out.to_netcdf(
        "training-data/gdsps-hindcast/era5-grid/bathymetry_and_mask_era5_grid.nc")


if __name__ == "__main__":
    main()
