
from aether import Regridder, grids
from pathlib import Path
import xarray


def main():

    beg_year = 1993
    end_year = 2025

    src_dir: Path = Path("/fs/site8/eccc/mrd/rpnem/pwa001/hindcast/bc10_tc/")
    dst_dir: Path = Path("training-data/gdsps-hindcast/era5-grid")

    grid_file: Path = Path("training-data/gdsps-hindcast/PN_y1993.nc")
    wgt_file: Path = Path("training-data/gdsps-hindcast/wgt-ORCA12_to_ERA5.parquet")
    wgt_meta_file: Path = wgt_file.parent / f"{wgt_file.name}.meta.json  "

    dst = xarray.open_dataset(grid_file)

    # cleanup
    wgt_file.unlink(missing_ok=True)
    wgt_meta_file.unlink(missing_ok=True)

    print("Creating weights ...")

    for year in range(beg_year, end_year + 1):
        cur_inp_dir = src_dir / f"{year}"

        with xarray.open_mfdataset([f for f in cur_inp_dir.iterdir() if f.name.endswith(".nc")],
                                   data_vars="minimal", coords="minimal", parallel=True) as ds:

            ds = ds[["sossheig", ]]

            rg = Regridder(ds, dst, 
                           method="mixt", 
                           filename=wgt_file, 
                           reuse_weights=wgt_file.exists())
    
            print("Interpolating: ")
    
            print(f"input: {ds = }")
            out = rg(ds)
            out.to_zarr(dst_dir / f"SSH_y{year}.zarr")

            break
    
    


if __name__ == "__main__":
    main()

