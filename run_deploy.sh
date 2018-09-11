#!/bin/bash
# Sourcing to get travis_wait
source ~/.travis/job_stages

# Exiting if we are not building master or dev, or if we are in a pull request
if [[ "$TRAVIS_BRANCH" != "master" && "$TRAVIS_BRANCH" != "dev" ]]; then exit; fi
if [ "$TRAVIS_PULL_REQUEST" != "false" ]; then exit; fi

# Setting variables
export COMMIT_ID=${TRAVIS_COMMIT:0:7}
echo "export BRANCH=${COMMIT_ID}" > /home/travis/build_args

# Installing Google Cloud
export CLOUD_SDK_REPO="cloud-sdk-$(lsb_release -c -s)"
echo "deb http://packages.cloud.google.com/apt $CLOUD_SDK_REPO main" | sudo tee -a /etc/apt/sources.list.d/google-cloud-sdk.list
curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add -
sudo apt-get update && sudo apt-get install google-cloud-sdk
## wget $GSUTIL_TOKEN
## chmod 600 gsutil_token.json
## gcloud auth activate-service-account travis-gcs@ppaquette-backup-perso.iam.gserviceaccount.com --key-file=gsutil_token.json

# Installing Singularity
export VERSION=2.6.0
sudo apt-get install -y build-essential squashfs-tools libarchive-dev
wget -nv https://github.com/singularityware/singularity/releases/download/$VERSION/singularity-$VERSION.tar.gz
tar -xzf singularity-$VERSION.tar.gz
cd singularity-$VERSION
./configure --prefix=/usr/local > /dev/null
make --quiet > /dev/null
sudo make --quiet install > /dev/null
cd ${TRAVIS_BUILD_DIR}

# Building singularity container
export EXPORT_FOLDER="${TRAVIS_BUILD_DIR}/build/"
export IMG_NAME="${TRAVIS_BUILD_DIR}/build/container_$(TZ='America/Montreal' date +"%Y%m%d_%H%M%S")_${TRAVIS_BRANCH}_${COMMIT_ID}.img"
mkdir -p $EXPORT_FOLDER

travis_wait 60 sudo singularity build $IMG_NAME ${TRAVIS_BUILD_DIR}/Singularity
if [ $? -ne 0 ]; then
    echo "Return code was not zero. The build command failed. Aborting."
    exit 1
fi

# Uploading
# You can use gsutil cp here
ls -lhA $EXPORT_FOLDER
## cd ${TRAVIS_BUILD_DIR}
## sudo rm -f /etc/boto.cfg
## gsutil cp -R ${TRAVIS_BUILD_DIR}/build/* gs://ppaquette-singularity/
