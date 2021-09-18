Setting up VMs for use in a training workshop is achieved by:

 1. Create a "template VM" containing the workshop software and data
 2. Image the template VM
 3. Instantiate a "test VM" from the image
   1. Set up test user
   2. Test workshop content
 5. Instantiate multiple workshop VMs from the image
   1. Setup workshop users

# Create Template VM

Create a vanilla Ubuntu VM in the cloud (e.g. AWS, GCP, etc).
SSH into it and clone this repository:

```bash
ssh -J hpc.sahmri.com 34.116.110.196

git clone https://github.com/sagc-bioinformatics/workshop-sysadmin.git
```

## Install Generic Software

We'll install some really useful tools and configuration options:

```bash
sudo apt update
sudo apt dist-upgrade -y

sudo apt install -y \
  python3 \
  tree \
  bmon \
  htop \
  screen

sudo su -

#####
# Change timezone
#####
dpkg-reconfigure tzdata

#####
# Setup conda
#####
wget https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh

# Install to /opt/miniconda3
bash ./Miniconda3-latest-Linux-x86_64.sh \
  -b \
  -p /opt/miniconda3
source /opt/miniconda3/etc/profile.d/conda.sh

#####
# Add conda initialisation for new users
#####
cat .bashrc >>/etc/skel/.bashrc

#####
# Setup screenrc for new users
#####
cat .screenrc >>/etc/skel/.screenrc
```

## Workshop Specific Setup

### WGBS Workshop

Software:

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

sudo apt install \
  python3-pip
pip3 install cpgtools
```

Put workshop data on the VM.
This assumes the data has already been generated somehow and is simply available to download from a public source.

```bash
#####
# Download from CloudStor
#####
curl https://cloudstor.aarnet.edu.au/plus/s/XXXXXXXXXXXXXXX/download \
  > wgbs.tar
tar -C / -xf wgbs.tar && rm wgbs.tar
```
