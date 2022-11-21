# icenet-pipeline

Pipelining tools for operational execution of the IceNet model

## Overview

The structure of this repository is to provide CLI commands that allow you to
 run the icenet model end-to-end, allowing you to make daily sea ice 
 predictions.

## Get the repositories 

```bash
git clone git@github.com:icenet-ai/icenet-pipeline.git green
git clone git@github.com:icenet-ai/icenet.git icenet.green
ln -s green pipeline
ln -s icenet.green icenet
```

## Creating the environment

In spite of using the latest conda, the following may not work due to ongoing 
issues with the solver not failing / logging clearly. [1]

### Using conda

Conda can be used to manage system dependencies for HPC usage, we've tested on
the BAS and JASMIN (NERC) HPCs. Obviously your dependencies for conda will 
change based on what is in your system, so please treat this as illustrative:

```bash
cd pipeline
conda env create -n icenet -f environment.yml
conda activate icenet

# Environment specifics
# BAS HPC just continue
# For JASMIN you'll be missing some things
module load jaspy/3.8
conda install -c conda-forge geos proj

### Additional linkage instructions for GPU usage
mkdir -p $CONDA_PREFIX/etc/conda/activate.d
echo 'export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:$CONDA_PREFIX/lib/' > $CONDA_PREFIX/etc/conda/activate.d/env_vars.sh
chmod +x $CONDA_PREFIX/etc/conda/activate.d/env_vars.sh
. $CONDA_PREFIX/etc/conda/activate.d/env_vars.sh
```

### IceNet installation

Then install IceNet into your environment as applicable. If using conda 
obviously enable the environment first. We are not publishing to PyPI yet, at
time of last update. Using `-e` is optional, based on whether you want to be
able to hack at the source!

```bash
cd ../icenet   # or wherever you've cloned icenet
pip install -e . 
```

### Linking data folders

The system is set up to process data in certain directories. With each pipeline
installation you can share the source data if you like, so use symlinks for
`data` if applicable, and intermediate folders `processed` and 
`network_datasets` you might want to store on alternate storage as applicable.
The following kind of illustrates this:

```bash
# An example from deployment on JASMIN, linking big folders to group storage
ln -s /gws/nopw/j04/icenet/data
mkdir /gws/nopw/j04/icenet/network_datasets
mkdir /gws/nopw/j04/icenet/processed
ln -s /gws/nopw/j04/icenet/network_datasets
ln -s /gws/nopw/j04/icenet/processed
```

## Example run of the pipeline

### A note on HPCs

The pipeline is often run on __SLURM__. Previously the SBATCH headers for 
submission were included, but to avoid issues with portability these have now 
been removed and the instructions now exemplify running against this type of 
HPC with the setup passed on the command line rather than in hardcoded headers.

If you're not using SLURM, just run the commands without sbatch. To use an 
alternative just amend sbatch to whatever you need. 

### Configuration

This pipeline revolves around the ENVS file to provide the necessary 
configuration items. This can easily be derived from the `ENVS.example` file 
to a new file, then symbolically linked. Comments are available in 
`ENVS.example` to assist you with the editing process. 

```commandline
cp ENVS.example ENVS.myconfig
ln -sf ENVS.myconfig ENVS
# Edit ENVS.myconfig to customise parameters for the pipeline
```

These variables will then be picked up during the runs via the ENVS symlink.

### Running the pipeline 

_[This is a very high level overview, for a more detailed run-through please 
review the icenet-notebooks repository.][2]_

#### One off: preparing SIC masks

As an additional dataset, IceNet relies on some masks being pre-prepared, so you
only have to do this on first run against the data store. 

```bash
conda activate icenet
icenet_data_masks north
icenet_data_masks south
```

#### Running training and prediction commands 

```bash
source ENVS

./run_data.sh north
./run_train_ensemble.sh \
    -b 2 -e 20 -f $FILTER_FACTOR -p $PREP_SCRIPT -q 2 \
    train_loader train_loader the_model

./loader_test_dates.sh forecast_loader >forecast_dates.csv
./run_predict_ensemble.sh -f `cat FILTER_FACTOR | tr -d '\n'` -p bashpc.sh \
    the_model forecast a_forecast forecast_dates.csv
```

## Implementing and changing environments

The point of having a repository like this is to facilitate easy integration 
with workflow managers, as well as allow multiple pipelines to easily be 
co-located in the filesystem. To achieve this have a location that contains 
your environments and sources, for example: 

```commandline
cd hpc/icenet
ls -d1 *
blue
data
green
icenet2.blue        # Sources for blue for editable install
icenet2.green       # Sources for green for editable install
pipeline
scratch
test
# pipeline -> green
```

Change the location of the pipeline from green to blue

```commandline
TARGET=blue

ln -sfn $TARGET pipeline

# If using a branch, go into icenet.blue and pull / checkout as required, e.g.
cd icenet.blue
git pull
git checkout my-feature-branch
cd ..

# Next update the conda environment, which will be specific to your local disk
ln -sfn $HOME/hpc/miniconda3/envs/icenet-$TARGET $HOME/hpc/miniconda3/envs/icenet
cd pipeline
git pull

# Update the environment
conda env update -n icenet -f environment.yml
conda activate icenet
pip install --upgrade -r requirements-pip.txt
pip install -e ../icenet.$TARGET
```

## Credits

*Please see LICENSE for usage information*

Tom Andersson - Lead research
James Byrne - Research Software Engineer
Scott Hosking - PI

[1]: https://github.com/conda/conda/issues?q=is%3Aissue+is%3Aopen+solving
[2]: https://github.com/icenet-ai/icenet-notebooks/