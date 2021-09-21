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

sudo apt install -y \
  python3-pip
pip3 install cpgtools
```

Put workshop data on the VM.
This assumes the data has already been generated somehow and is simply available to download from a public source.

```bash
#####
# Download from CloudStor
#####
curl https://cloudstor.aarnet.edu.au/plus/s/HBCVy6IKjVTJYq7/download \
  > wgbs.tar
tar -C / -xf wgbs.tar && rm wgbs.tar
```

# Publishing Workshop Data to CloudStor

While creating/testing the workshop content, it is advantagous to push the workshop data to a publically accessible location.
We can then use this during VM instantiation by pulling that data to each new VM.
The easiest way to achieve this is to create a tar archive and push it to CloudStor:

```bash
cd /data
sudo tar -cf wgbs.tar wgbs

sudo apt install rclone

# Set this variable to the App password you generated in the above steps
USERNAME='my_cloudstor_username'
APP_PASSWORD='MY_CLOUDSTOR_APP_PASSWORD'

# Now create the rclone configuration
rclone config create \
  SAGC_CloudStor \
  webdav \
  url https://cloudstor.aarnet.edu.au/plus/remote.php/webdav/ \
  vendor owncloud \
  user "${USERNAME}" \
  pass "${APP_PASSWORD}" \
  --obscure

rclone copy wgbs.tar SAGC_CloudStor:Shared/workshops/
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

# Instantiating and Managing a Suite of VMs

If you have to instantiate and manage a suite of VMs for a hands-on session, doing things 1-by-1 can get very annoying and be error prone.
Instead, we will use an API for instansiating VM and performing actions on them.
Below, I should how this can achieved using simple for loops.
However, you need to be aware of any API rate limits which will slow you down and use some form of "backoff" (preferrably exponential) to slow/limit retry attempts.

## Instantiate VMs on Google Cloud Platform (GCP)

### Setup Google Cloud SDK

Source: https://cloud.google.com/sdk/docs/install#deb

```bash
echo "deb [signed-by=/usr/share/keyrings/cloud.google.gpg] https://packages.cloud.google.com/apt cloud-sdk main" | sudo tee -a /etc/apt/sources.list.d/google-cloud-sdk.list
sudo apt-get install apt-transport-https ca-certificates gnupg
curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key --keyring /usr/share/keyrings/cloud.google.gpg add -
sudo apt-get update && sudo apt-get install google-cloud-sdk

gcloud init
```

### Create Trainee VMs from an Existing Machine Image

The following code will:

 1. generate VM's called `wgbs-001` through to `wgbs-025`
 2. Pull the wgbs workshop data from a public CloudStore link
 3. Update the [workshop-sysadmin](https://github.com/sagc-bioinformatics/workshop-sysadmin) repo on the VM
 4. Create a single user account `sagc001` on the VM

It is worth noting, that after the VM's are instantiated, SSH access using passwords is NOT enabled.
Similarly, the user account is also locked.
Just prior to the start of the workshop, you would need to enable SSH login using passwords AND unlock the relevant user account(s) so trainees can log into the VMs.

```bash
machine_image_name='wgbs'
ZERO_PADDING_LENGTH=3
START=1
END=25

for i in $(seq --format "%0${ZERO_PADDING_LENGTH}g" ${START} ${END}); do
  echo "## Creating VM"
  # Try creating VM up to 5 times with 2 mins between retries
  #   We should exponentially backoff instead
  n=0
  until [ "$n" -ge 5 ]; do
    gcloud beta compute instances create "wgbs-${i}" --source-machine-image "${machine_image_name}" && break
    n=$((n+1))
    sleep 120
  done

  # Wait for VM to come up before trying to SSH into it
  echo "## Waiting for VM to come up"
  sleep 60

  # Pull the workshop data and extract it
  echo "## Pulling data"
  gcloud compute ssh wgbs-${i} -- 'sudo wget --continue -O /data/wgbs.tar https://cloudstor.aarnet.edu.au/plus/s/HBCVy6IKjVTJYq7/download && cd /data && sudo tar -xf /data/wgbs.tar && sudo rm -f /data/wgbs.tar'

  # Update the workshop-sysadmin repo code
  gcloud compute ssh root@wgbs-${i} -- 'cd /root/workshop-sysadmin && git pull && source /opt/miniconda3/etc/profile.d/conda.sh && mamba env update --name wgbs --file /root/workshop-sysadmin/wgbs.yaml'
  
  # Setup user accounts
  echo "## Creating Users"
  gcloud compute ssh wgbs-${i} -- 'sudo /root/workshop-sysadmin/trainusers.sh -a create -s 1 -e 1'

  # To help prevent exceeding API rate limit
  #   We should exponentially backoff instead
  echo "## sleeping"
  sleep 300
done
```

Once VM's are instantiated and user accounts created, extract that login information.
This info will need to be printed along with VM IP addresses for use in the workshop.

```bash
for i in $(seq --format "%0${ZERO_PADDING_LENGTH}g" ${START} ${END}); do
  gcloud compute ssh wgbs-${i} -- "sudo sed 's/^/'\$(hostname)'\t/' /root/userlist.txt"
done \
> wgbs_login.tsv
```

## Enable Trainee Access

Trainee's will NOT be able to access the VM until, SSH login with passwords is enabled and the relevant user accounts unlocked.
Do both actions:

```bash
for i in $(seq --format "%0${ZERO_PADDING_LENGTH}g" ${START} ${END}); do
  gcloud compute ssh wgbs-${i} -- 'sudo /root/workshop-sysadmin/trainusers.sh -a pwon && sudo /root/workshop-sysadmin/trainusers.sh -a unlock -s 1 -e 1'
done
```

## Disable Trainee Access

Following the workshop, you probably want to disable trainee access to the VMs.
Lock the relevant user account(s) and disable SSH logins using passwords:

```bash
for i in $(seq --format "%0${ZERO_PADDING_LENGTH}g" ${START} ${END}); do
  gcloud compute ssh wgbs-${i} -- 'sudo /root/workshop-sysadmin/trainusers.sh -a lock -s 1 -e 1 && sudo /root/workshop-sysadmin/trainusers.sh -a pwoff'
done
```

# TODO

The above loops for instantiating VMs is slow since there is an API rate limit which prevents more rapid creation of VMs with this approach.
Instead, we should aim to use instance templates and create a group of managed VMs: https://stackoverflow.com/a/51978768/1413849
 
```bash
gcloud compute instances bulk create \
  --name-pattern="wgbs-#" \
  --count=25
```
