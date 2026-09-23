
from aether import Regridder, Grid
from pathlib import Path
import xarray
import shutil
import typing
import fasteners


"""
Locking mechanism is in place to allow multiple jobs doing interpolation
"""


def intrp_chunk(flist, wgt_file, dst_grid, 
                f_out: Path, ignore_var_list=(),
                field_name="sossheig", 
                time_dim_name="time_counter"):

    if f_out.exists():
        print(f"Removing pre-existing {f_out}")
        shutil.rmtree(f_out)


    wgt_file_lock = fasteners.InterProcessLock(wgt_file.parent / f"{wgt_file.name}.lock")

    with wgt_file_lock:
        tmp_wgt_file: Path = wgt_file.parent / f"{wgt_file.name}.tmp"
        if not wgt_file.exists():
            with xarray.open_dataset(flist[0]) as ds:
                print("Creating weights ...")
                ds = ds.reset_coords(ignore_var_list)
                ds = ds[[field_name, ]].isel({time_dim_name: 0})
                rg = Regridder(ds, dst_grid, 
                            method="mixt", 
                            filename=tmp_wgt_file, 
                            reuse_weights=False)
                _ = rg(ds)

                print(f"Weights created successfully in {wgt_file}")

            if wgt_file.exists():
                raise FileExistsError(
                    f"Weight file appeared before final rename: {wgt_file}"
                )

            tmp_wgt_file.rename(wgt_file)

    for i_file, f_inp in enumerate(flist):
            

        with xarray.open_dataset(f_inp) as ds:

            if i_file == 0:
                print(f"Interpolating files in {f_inp.parent}")

            ds = ds.reset_coords(ignore_var_list)
            ds = ds[[field_name, ]]
            print("Creating regridder")
            rg_apply = Regridder(ds, dst_grid, 
                        method="mixt", 
                        filename=wgt_file, 
                        reuse_weights=True)
    
            print("Interpolating: ")
    
            print(f"input: {ds = }")
            out: xarray.Dataset = typing.cast(xarray.Dataset, rg_apply(ds))
            
            print(f"Saving outputs {i_file + 1}/{len(flist)}: {f_inp} to {f_out}")

            
            if f_out.exists():
                save_kwargs = dict(mode="a-", append_dim=time_dim_name)
            else:
                save_kwargs = dict(mode="w")

            out.to_zarr(f_out, **save_kwargs)


    
def main():

    beg_year = 1993
    end_year = 2025
    field_name = "sossheig"
    time_dim_name = "time_counter"

    src_dir: Path = Path("/fs/site8/eccc/mrd/rpnem/pwa001/hindcast/bc10_tc/")
    dst_dir: Path = Path("training-data/gdsps-hindcast/era5-grid")

    grid_file: Path = Path("training-data/gdsps-hindcast/PN_y1993.nc")
    wgt_file: Path = Path("training-data/gdsps-hindcast/wgt-ORCA12_to_ERA5.parquet")
    wgt_meta_file: Path = wgt_file.parent / f"{wgt_file.name}.meta.json"

    with xarray.open_dataset(grid_file) as ds:
        dst_grid = Grid.from_dataset(ds)

    

    ignore_var_list = [
        "time_counter_bounds", "time_instant_bounds"
    ]

    for year in range(beg_year, end_year + 1):
        cur_inp_dir = src_dir / f"{year}"

        cur_lock_file = dst_dir / f"{year}.lock"
        lock = fasteners.InterProcessLock(cur_lock_file)

        status_file = dst_dir / f"interpolation_{year}.done"

        flist = sorted([f for f in cur_inp_dir.iterdir() if f.name.endswith(".nc")])

        f_out = dst_dir / f"SSH_y{year}.zarr"
        f_out_nc = dst_dir / "netcdf" / f"SSH_y{year}.nc"

        f_out.parent.mkdir(exist_ok=True)
        f_out_nc.parent.mkdir(exist_ok=True)

        

        if not status_file.exists():

            acquired = lock.acquire(blocking=False)
            if acquired:
                try:
                    intrp_chunk(flist, wgt_file, 
                                dst_grid=dst_grid, 
                                f_out=f_out,
                                ignore_var_list=ignore_var_list,
                                field_name=field_name,
                                time_dim_name=time_dim_name)

                    
                    print(f"zarr to nc conversion: {f_out} to {f_out_nc}")
                    xarray.open_zarr(f_out).to_netcdf(f_out_nc)

                    status_file.parent.mkdir(exist_ok=True, parents=True)
                    status_file.touch(exist_ok=True)
                finally:
                    lock.release()
            
        else:
            print(f"{status_file} exists, nothing to do for {year}, skipping")
       


if __name__ == "__main__":
    main()

