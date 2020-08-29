# Default variables
sas_deployment_data="SAS_Viya_deployment_data.zip"
sas_mirrormanager_download_url="https://support.sas.com/installation/viya/35/sas-mirror-manager/lax/mirrormgr-linux.tgz"
sas_mirrorextensions_download_url="https://support.sas.com/installation/viya/35/sas-edge-extension/sas-edge-extension.tgz"
sas_software_repository="sas-espedge-125-aarch64_ubuntu_linux_16-apt"
qemu_file="/usr/bin/qemu-aarch64-static"
container_name="esp_gpu"
container_tag="6_2_jetson"
container_build="YES"
container_push="NO"
OTHER_ARGUMENTS=()

# User provided variables
for arg in "$@"
do
    case $arg in
        -sdd*|--sas_deployment_data*)
        sas_deployment_data="${arg#*=}"
        shift
        ;;
        -smmdu*|--sas_mirrormanager_download_url*)
        sas_mirrormanager_download_url="${arg#*=}"
        shift
        ;;
        -smedu*|--sas_mirrorextensions_download_url*)
        sas_mirrorextensions_download_url="${arg#*=}"
        shift
        ;;
        -ssr*|--sas_software_repository*)
        sas_software_repository="${arg#*=}"
        shift
        ;;
        -cn*|--container_name*)
        container_name="${arg#*=}"
        shift
        ;;
        -ct*|--container_tag*)
        container_tag="${arg#*=}"
        shift
        ;;
        -qf*|--qemu_file*)
        qemu_file="${arg#*=}"
        shift
        ;;
        -db*|--docker_build*)
        docker_build="${arg#*=}"
        shift
        ;;
        -dp*|--docker_push*)
        docker_push="${arg#*=}"
        shift
        ;;
        *)
        OTHER_ARGUMENTS+=("$1")
        shift # Remove generic argument from processing
        ;;
    esac
done

# Intro
printf '#%.0s' {1..100}; printf '\n';
printf '#%.0s' {1..100}; printf '\n';
printf '##### %-88s #####\n'
printf '##### %-88s #####\n' "SAS Event Stream Processing on Edge for NVIDIA Jetson TX2"
printf '##### %-88s #####\n' "Version 6.2"
printf '##### %-88s #####\n'
printf '#%.0s' {1..100}; printf '\n';
printf '##### %-88s #####\n' "Source: github.com/Mentos05/SAS_ESP_JETSON_GPU"
printf '#%.0s' {1..100}; printf '\n';
printf '#%.0s' {1..100}; printf '\n';
printf '##### %-88s #####\n' "Variables"
printf '##### %-88s #####\n'
printf '##### %-88s #####\n' "SAS Deployment Data:"
printf '##### %-88s #####\n' "$sas_deployment_data"
printf '##### %-88s #####\n'
printf '##### %-88s #####\n' "SAS Mirror Manager URL:"
printf '##### %-88s #####\n' "$sas_mirrormanager_download_url"
printf '##### %-88s #####\n'
printf '##### %-88s #####\n' "SAS Mirror Extensions URL:"
printf '##### %-88s #####\n' "$sas_mirrorextensions_download_url"
printf '##### %-88s #####\n'
printf '##### %-88s #####\n' "Qemu File:"
printf '##### %-88s #####\n' "$qemu_file"
printf '##### %-88s #####\n'
printf '##### %-88s #####\n' "Docker Container Name:"
printf '##### %-88s #####\n' "$container_name"
printf '##### %-88s #####\n'
printf '##### %-88s #####\n' "Docker Container Tag:"
printf '##### %-88s #####\n' "$container_tag"
printf '##### %-88s #####\n'
printf '#%.0s' {1..100}; printf '\n';
printf '#%.0s' {1..100}; printf '\n'; printf '\n';

while true; do
    read -p "Are these settings correct?" yn
    case $yn in
        [Yy]* ) break;;
        [Nn]* ) exit;;
        * ) echo "Please answer yes or no.";;
    esac
done

# Check SAS deployment data
echo "NOTE: Verifying SAS_Viya_deployment_data.zip"
if ls $sas_deployment_data 1> /dev/null 2>&1; then
    echo "NOTE: $sas_deployment_data found in $(pwd)"
else
    echo "$sas_deployment_data not found in $(pwd). Exiting."
    exit 1
fi

# Check SAS Event Stream Processing on Edge repository
echo "NOTE: Verifying SAS Event Stream Processing on Edge files"
if ! ls espedge_repos/$sas_software_repository/analytics/sas-* 1> /dev/null 2>&1; then
   echo "NOTE: SAS Event Stream Processing on Egde repository does not exist. Begin download."
   # Check SAS Mirror Manager
   if ls mirrormgr 1> /dev/null 2>&1; then
      echo "NOTE: SAS Mirror Manager exists."
   else
      echo "NOTE: Downloading SAS Mirror Manager."
      wget $sas_mirrormanager_download_url -O mirrormgr-linux.tgz && tar zxfv mirrormgr-linux.tgz && rm mirrormgr-linux.tgz
   fi
   # Check SAS Mirror Manager Extensions
   if ls edge_mirror.sh 1> /dev/null 2>&1; then
      echo "NOTE: SAS Mirror Manager Extension exists."
   else
      echo "NOTE: Downloading SAS Mirror Extensions for SAS Event Stream Processing for Edge Computing."
      wget $sas_mirrorextensions_download_url -O sas-edge-extension.tgz && tar zxfv sas-edge-extension.tgz && rm sas-edge-extension.tgz
   fi
   # Download SAS Event Stream Processing on Edge
   echo "NOTE: Downloading SAS Event Stream Processing on Edge files."
   bash edge_mirror.sh $sas_software_repository /
else
   echo "NOTE: SAS Event Stream Processing on Egde repository exists. Skipping Download"
fi

# Check OpenCV files
echo "NOTE: Verifying OpenCV files"
if ! ls opencv-aarch64-deb/opencv-aarch64-deb/* 1> /dev/null 2>&1; then
   echo "NOTE: Could not find OpenCV files. Getting submodules."
   git submodule init
   git submodule update
else
   echo "NOTE: OpenCV files found."
fi

# Install qemu for aarch emulation on X64
echo "NOTE: Verifying qemu installation"
if ! ls $qemu_file 1> /dev/null 2>&1; then
   echo "NOTE: Installing qemu for aarch emulation on X64"
   sudo apt-get update -y
   sudo apt-get install qemu binfmt-support qemu-user-static -y
else
   echo "NOTE: Qemu installation found. Copying qemu-aarch64-static to repository folder."
   cp $qemu_file .
fi 

# Building Docker container
if [ $container_build="YES" ]; then
   echo "NOTE: Building Docker container $container_name:$container_tag"
   docker build -t $container_name:$container_tag .
else
   echo "NOTE: Skipping docker build."
fi

# Pushing Docker container
if [ $container_push="YES" ]; then
   echo "NOTE: Pushing Docker container $container_name:$container_tag to repository."
   docker push $container_name:$container_tag
else
   echo "NOTE: Skipping docker push."
fi

echo "Finished."
exit


