# SAS Event Stream Processing on Edge Docker Container with GPU acceleration (NVIDIA Jetson Version)

This repository provides build instructions to create your own SAS Event Stream Processing on Edge Docker Container with GPU acceleration.
Note that this repository is for NVIDIA Jetson, not x64 devices.

### Overview
SAS Event Stream Processing on Edge already offers the possibility to be installed as a Docker container. So, why does this repository exist?
Looking at the official [documentation](https://go.documentation.sas.com/?docsetId=dplyesp0phy0lax&docsetTarget=p1rcii2jo7dt9yn1qr1upedc0y3w.htm&docsetVersion=6.2&locale=en) you will notice that the Docker image does not support GPU acceleration.

However GPU acceleration is needed or at least recommended if you want to work with deep learning.
For this reason I decided to share my work of creating GPU accelerated for SAS Event Stream Processing.

Please note:
This repository is privately owned by me. Don't expect any official support for the work provided here.

### Requirements
* Valid SAS Event Stream Processing license file (tested with SAS Event Stream Processing 6.2)
* x64 machine running Ubuntu (tested with Ubuntu 18.04)
* NVIDIA Jetson device (tested with NVIDIA Jetson TX2)
* NVIDIA Jetpack (tested with Jetpack 4.3)
* [NVIDIA Container Runtime on Jetson](https://github.com/NVIDIA/nvidia-docker/wiki/NVIDIA-Container-Runtime-on-Jetson)

### Container Setup on X64 machine
1. Pull this repository<br>
```
git clone https://github.com/Mentos05/SAS_ESP_JETSON_GPU.git
cd SAS_ESP_JETSON_GPU
```
2. Copy your deployment data file into the repository folder (usually named: SAS_Viya_deployment_data.zip)
```
cp /path/to/your/deplyomentdata.zip .
```
3. Run buildContainer.sh. The script will download all required files and build the container.
```
bash buildContainer.sh
```

The buildContainer.sh script accepts the following variables:

| Variable | Description | Default |
| ------ | ------ | ------ |
| sas_deployment_data | Name of your SAS deployment data file | SAS_Viya_deployment_data.zip |
| sas_mirrormanager_download_url | URL for SAS Mirror Manager | https://support.sas.com/installation/viya/35/sas-mirror-manager/lax/mirrormgr-linux.tgz |
| sas_mirrorextensions_download_url | URL for SAS Mirror Manager Extension | https://support.sas.com/installation/viya/35/sas-edge-extension/sas-edge-extension.tgz |
| sas_software_repository | Name of the SAS software repository | sas-espedge-125-aarch64_ubuntu_linux_16-apt |
| qemu_file | Path of your Qemu binary | /usr/bin/qemu-aarch64-static |
| container_name | Docker container name | esp_gpu |
| container_tag | Docker container tag | 6_2_jetson |

### Run Container
Simply use docker run and attach your gpus:
```
docker run -it --net=host --gpus all esp:gpu
```
In many cases you want to extend your run call with additional variables to configure the container.

| Variable | Description | Default |
| ------ | ------ | ------ |
| ESP_PORT | ESP -port option | 9900 |
| ESP_PUBSUB_PORT | ESP -pubsub option | 31416 |
| ESP_LOGLEVEL | ESP -loglevel option | error |
| ESP_MAS_THREADS | MAS Threads | 1 |
| MAS_PYLOG_LEVEL | MAS logging level | ERROR |
| MAS_PYLOG_FILE | MAS logfile location | /opt/maspylog.txt |
| JUPYTERLAB_PORT | JupyterLab port | 8080 |
| JUPYTERLAB_NBDIR | JupyterLab notebook directory | /data/notebooks/ |

Example: `docker run -it --net=host -e ESP_PORT 12345 --gpus all esp:gpu` will run the ESP server on port 12345.

You should see something like this:<br>
![cv](images/running_container.png "cv")

### Access Jupyter Lab
Open one of the following URLs in your browser:
* JupyterLab: http://localhost:8080

### Whats next?
Connect to your container, e.g. via [SAS ESPPy](https://github.com/sassoftware/python-esppy).<br>
Your container is running on port 9900 by default.
```
import esppy
esp = esppy.ESP(hostname='http://localhost:9900')
```

### Jupyter Lab (Python Environment)
Some of the Python packages installed are:<br>

| Package | Description |
| ------ | ------ |
| SAS SWAT | [SAS SWAT](https://github.com/sassoftware/python-swat) |
| SAS DLPy | [SAS DLPy](https://github.com/sassoftware/python-dlpy) | 
| SAS ESPPy | [SAS ESPPy](https://github.com/sassoftware/python-esppy) |
| OpenCV | [OpenCV](https://github.com/opencv/opencv) |
| OpenPose | [OpenPose](https://github.com/CMU-Perceptual-Computing-Lab/openpose) |

For a full list, please look at the python_sas.yml file in /jupyterlab_environments folder.
When building your own container, you can add your own environment.yml files into /jupyterlab_environments folder to have customized Python environments.

### Share ressources with your container
If you want to share ressources with your container, e.g. a webcam, you can do so by adapting your docker run command.<br>
To share devices, e.g. your webcam, use:
```
docker run --device=/dev/video0:/dev/video0 --net=host esp:gpu
```
To share a folder, e.g. with additional data like models, projects, etc. use:
```
docker run -v folder-on-host:folder-on-container --net=host esp:gpu
```

Example: For my needs I usually start my container with the following command to share my local notebooks, my webcam, host networking interface and to allow GUI applications (e.g. Opencv).<br>
```
docker run -it --privileged=true --net=host --ipc=host \
           -v /home/michael/Development/github.com/:/data/notebooks \
           --device=/dev/video0:/dev/video0 \
           --gpus all -e DISPLAY=$DISPLAY \
           -v /tmp/.X11-unix:/tmp/.X11-unix -v /var/run/dbus:/var/run/dbus \
           esp:gpu
```

### Run GUI applications inside your Docker container
I am using OpenCV very often to display the scored images from ESP. To allow OpenCV to access your hosts display you'll have to allow access to your X server.
To do this simply type `xhost +` on your host system.
Additionally you'll have to provide some information to your container by adding the following statements to your run-command:<br>
```
-e DISPLAY=$DISPLAY
-v /tmp/.X11-unix:/tmp/.X11-unix
```

### Verify/Monitor GPU Usage
While you should notice a significant performance improvement while training/scoring your deep learning models you can also monitor GPU usage by using:
```
watch -n 1 nvidia-smi
```
nvidia-smi should show a esp process.
![nvidia-smi monitoring](images/nvidia-smi.png "nvidia-smi monitoring")<br>
Make sure you run this command on your host, not inside the container.

### Private Repository
Please Note: This is my private repository and not an official SAS repository.<br>
If you are looking for official SAS repositories, please go to:
* [SAS Software Repository](https://github.com/sassoftware/)
* [SAS Scripting Wrapper for Analytics Transfer (SWAT)](https://github.com/sassoftware/python-swat)
* [SAS Viya Deep Learning API for Python](https://github.com/sassoftware/python-dlpy)
* [SAS Event Stream Processing Python Interface](https://github.com/sassoftware/python-esppy)

### Contact
If you like to discuss how deep learning can be applied to your problems, you're of course free to contact me.<br>

| Channel | Adress |
| ------ | ------ |
| Email Work | michael.gorkow@sas.com |
| Email Private | michaelgorkow@gmail.com |
| LinkedIn | [LinkedIn Profile](https://www.linkedin.com/in/michael-gorkow-08353678/) |
| Twitter | [Twitter Profile](https://twitter.com/GorkowMichael) |
