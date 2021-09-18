# Template VM Setup

SSH to the VM and grab this git repository:

```bash
ssh -J hpc.sahmri.com 34.116.110.196

git clone https://github.com/sagc-bioinformatics/workshop-sysadmin.git
```

## Install Generic Software

```bash
sudo apt update
sudo apt dist-upgrade -y

sudo apt install -y \
  python3 \
  tree \
  bmon \
  htop \
  screen

sudo apt install \
  python3-pip

sudo su -

#####
# Change timezone
#####
dpkg-reconfigure tzdata

#####
# Setup conda
#####
conda_prefix='/opt/miniconda3'
wget https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh

# Install to /opt/miniconda3
bash ./Miniconda3-latest-Linux-x86_64.sh \
  -b \
  -p "${conda_prefix}"
source "${conda_prefix}/etc/profile.d/conda.sh"

#####
# Add conda initialisation to /etc/skel/.bashrc
#####
cat .bashrc >>/etc/skel/.bashrc

#####
# Setup screenrc for new users
#####
cat .screenrc >>/etc/skel/.screenrc
```

## Install WGBS Software

```bash
#####
# Setup conda environment for all users
#####
mkdir -p /data/envs

cp wgbs.yaml /data/envs/wgbs.yaml

# Install environments
conda install mamba -n base -c conda-forge -y
mamba env create -f /data/envs/wgbs.yaml
# If need to update the environment
#mamba env update --name agrigenomics --file /data/envs/wgbs.yaml
pip3 install cpgtools
```

## Download Data Set

```bash
#####
# Download from CloudStor
#####
curl https://cloudstor.aarnet.edu.au/plus/s/XXXXXXXXXXXXXXX/download \
  > wgbs.tar
tar -C / -xf wgbs.tar && rm wgbs.tar
```

# Generate Data Set

```bash
conda activate wgbs
mkdir -p /data/wgbs/

# Do stuff and put the data in /data/wgbs/
```

## Package Data Set

Package the data set and upload to CloudStor

```bash
tar -c -f wgbs.tar /data/wgbs

# cleanup
#rm -f *.fastq.gz *.tsv
```
