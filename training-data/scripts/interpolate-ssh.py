
from aether import Regridder, grids, Grid
from pathlib import Path
import xarray



    
def main():

    beg_year = 1993
    end_year = 2025
    field_name = "sossheig"
    time_dim_name = "time_counter"

    src_dir: Path = Path("/fs/site8/eccc/mrd/rpnem/pwa001/hindcast/bc10_tc/")
    dst_dir: Path = Path("training-data/gdsps-hindcast/era5-grid")

    grid_file: Path = Path("training-data/gdsps-hindcast/PN_y1993.nc")
    wgt_file: Path = Path("training-data/gdsps-hindcast/wgt-ORCA12_to_ERA5.parquet")
    wgt_meta_file: Path = wgt_file.parent / f"{wgt_file.name}.meta.json  "

    with xarray.open_dataset(grid_file) as ds:
        dst_grid = Grid.from_dataset(ds)

    # cleanup
    wgt_file.unlink(missing_ok=True)
    wgt_meta_file.unlink(missing_ok=True)

    ignore_var_list = [
        "time_counter_bounds", "time_instant_bounds"
    ]

    

    for year in range(beg_year, end_year + 1):
        cur_inp_dir = src_dir / f"{year}"

        flist = [f for f in cur_inp_dir.iterdir() if f.name.endswith(".nc")]

        if not wgt_file.exists():
            with xarray.open_dataset(flist[0]) as ds:
                print("Creating weights ...")
                ds = ds.reset_coords(ignore_var_list)
                ds = ds[[field_name, ]].isel({time_dim_name: 0})
                print(ds)
                rg = Regridder(ds, dst_grid, 
                            method="mixt", 
                            filename=wgt_file, 
                            reuse_weights=False)
                _ = rg(ds)
                print(f"Weights created successfully in {wgt_file}")                
            

        with xarray.open_mfdataset(flist,
                                   data_vars="minimal", 
                                   coords="minimal") as ds:

            print(f"Interpolating files in {flist[0].parent}")
            ds = ds.reset_coords(ignore_var_list)
            ds = ds[[field_name, ]]
            print("Creating regridder")
            rg_apply = Regridder(ds, dst_grid, 
                           method="mixt", 
                           filename=wgt_file, 
                           reuse_weights=True)
    
            print("Interpolating: ")
    
            print(f"input: {ds = }")
            out = rg_apply(ds)
            out.to_zarr(dst_dir / f"SSH_y{year}.zarr")

            break
    
   


if __name__ == "__main__":
    main()

