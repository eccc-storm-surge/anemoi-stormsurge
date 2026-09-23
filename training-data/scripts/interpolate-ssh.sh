
out_dir=training-data/gdsps-hindcast/era5-grid

grid_def=training-data/gdsps-hindcast/PN_y1993.nc
mkdir -p ${out_dir}
wgt=w.parquet

for f in /fs/site8/eccc/mrd/rpnem/pwa001/hindcast/bc10_tc/1993/*.nc; do

	f_out=${out_dir}/$(basename $f) 
	if [ -e ${f_out} ]; then
		echo "Skipping ${f_out}, already done"
		continue
	fi

	reuse_opt="--reuse-weights"
	if [ ! -e ${wgt} ]; then
		reuse_opt=""
	fi
	pixi run aether-regrid $f --dst ${grid_def} -o ${out_dir}/$(basename $f) \
				  -m mixt --weights w.parquet ${reuse_opt}
	
	break
done
