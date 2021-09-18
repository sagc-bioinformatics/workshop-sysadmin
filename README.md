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

sudo su -
git clone https://github.com/sagc-bioinformatics/workshop-sysadmin.git
cd workshop-sysadmin
```

## Install Generic Software

We'll install some really useful tools and configuration options:

```bash
apt update
apt dist-upgrade -y

apt install -y \
  python3 \
  tree \
  bmon \
  htop \
  screen

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

# Managing User Accounts on Instantiated VMs

The image generated from the template VM doesn't have any active user accounts.
We don't want an image containing default username and passwords since every VM would have the same login details and these will likely get leaked into the public domain at some point.
This would be a security risk!

Instead, we have a script (`trainusers.sh`) capable of of managing user accounts which must be used after VM instantiation to:

 1. Create user accounts
 2. Enable password logins via SSH
 3. Enable user accounts

Similarly, this script can be used at the end of the workshop to:

 1. Disable user accounts
 2. Disable password logins via SSH
 3. Delete user accounts

The `trainusers.sh` help:

```bash
$ ./trainusers.sh -h
USAGE: trainusers.sh [-h] -a <action> [-u <user_prefix>] [-s <start>] [-e <end>] [-z <zero_padding>] [-l <length_of_password>] [[-p <pwgen_arg>] ...]

User/password creation/management.
  where:
    -h Show this help text
    -a Action to perform (create|chpass|lock|unlock|pwon|pwoff|delete)
      create: create users with passwords
      chpass: change the user's passwords
      lock:   lock user's passwords
      unlock: unlock user's passwords
      pwon:   allow password authentication in SSH
      pwoff:  disable password authentication in SSH
      delete: delete user accounts
    -u Username prefix (default: sagc)
    -s Username suffix start number (default: 1)
    -e Username suffix end number (default: 10)
    -z Zero-pad username suffix number to this length (default:3)
    -l Password length (default: 12)
    -p Arguments to pass to pwgen (default: --ambiguous --symbols --numerals --capitalize)
```

## Create User Accounts

```bash
# Simple form
#   Creates 10 user accounts (sagc001 to sagc010)
#   Passwords of 12 characters in length
sudo ./trainusers.sh \
  -a create

# Complex form
#   Create a single user account called "sagc_043" with a password of length 23 characters
sudo ./trainusers.sh \
  -a create \
  -u sagc_ \
  -s 43 \
  -e 43 \
  -l 23
```

The username and passwords combinations are stored in the file `/root/userlist.txt`.
For example:

```bash
$ cat /root/userlist.txt 
sagc_043:ea4athaX<ohrHi7HiThee)n
```

## Disallow User Logins

Once user accounts are created, we want to ensure that no one can use those accounts until we say so.
This is achived by:

```bash
# Preventing ANY SSH logins using passwords, only SSH keys allowed
sudo ./trainusers.sh \
  -a pwoff

# Lock user accounts
#   Make sure to supply the same -u -s -e arguments as
#   used for creation, otherwise some user accounts will not be locked
sudo ./trainusers.sh \
  -a lock
```

## Allow User Logins

```bash
# Allow SSH logins using passwords
sudo ./trainusers.sh \
  -a pwon

# Unlock a specific user's account so only they are able to login
#   We'll unlock sagc001 by specifying -s and -e
sudo ./trainusers.sh \
  -a unlock \
  -s 1 \
  -e 1

# Unlock all user accounts that were created
sudo ./trainusers.sh \
  -a unlock
```

## Deleting User Accounts

Deleting user accounts will also delete their home directory/files.
This is particularly useful if you want to reuse/recycle the VM for another day/workshop:

```bash
# Delete users sagc003 to sagc005
sudo ./trainusers.sh \
  -a delete \
  -s 3 \
  -e 5

# Delete all default user accounts
sudo ./trainusers.sh \
  -a delete
```
