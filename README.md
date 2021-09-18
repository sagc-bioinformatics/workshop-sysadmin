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
cat >>/etc/skel/.bashrc <<'EOF'
# >>> conda initialize >>>
# !! Contents within this block are managed by 'conda init' !!
__conda_setup="$('/opt/miniconda3/bin/conda' 'shell.bash' 'hook' 2> /dev/null)"
if [ $? -eq 0 ]; then
    eval "$__conda_setup"
else
    if [ -f "/opt/miniconda3/etc/profile.d/conda.sh" ]; then
        . "/opt/miniconda3/etc/profile.d/conda.sh"
    else
        export PATH="/opt/miniconda3/bin:$PATH"
    fi
fi
unset __conda_setup
# <<< conda initialize <<<
EOF

#####
# Setup screenrc for new users
#####
cat >>/etc/skel/.screenrc <<'EOF'
startup_message off
caption string "%?%F%{= Bk}%? %C%A %D %d-%m-%Y %{= kB} %t%= %?%F%{= Bk}%:%{= wk}%? %n "
hardstatus alwayslastline
hardstatus string '%{= kG}[ %{G}%H %{g}][%= %{= kw}%?%-Lw%?%{r}(%{W}%n*%f%t%?(%u)%?%{r})%{w}%?%+Lw%?%?%= %{g}][%{R} %d/%m %{W}%c %{g}]'
altscreen on
# Let screen spawn its shell as the user's login shell. This will then also parse /etc/profile /etc/profile.d and ~/.profile
shell -$SHELL
EOF
```

## Install WGBS Software

```bash
#####
# Setup conda environment for all users
#####
mkdir -p /data/envs

cat >/data/envs/wgbs.yaml <<'EOF'
name: wgbs
channels:
  - bioconda
  - conda-forge
  - defaults
dependencies:
  - fastqc=0.11.9
  - multiqc=1.11
  - bismark=0.23.1
  - samtools=1.11
  - trim-galore=0.6.7
  - bedtools=2.30.0
  - MethylDackel=0.6.0
EOF

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
