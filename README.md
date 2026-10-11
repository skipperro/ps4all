# ue-docker-nvidia
Run **Windows Unreal Engine** apps inside a **Linux** Docker container with full **NVIDIA GPU** acceleration — and stream them in your **web browser** via Selkies-GStreamer.

> [!CAUTION]
> This is just a proof of concept and work in progress piece of code. It works on my machine and with my application.
>
> Your milage may vary. **Run at your own risk** ⚠️

![Lyra running in browser from docker container](images/ue5-lyra-linux.jpg)
UE 5 Lyra running in browser from docker container


## ✨ Features
- Supports **DirectX 11 and 12** applications with output to Vulkan.
- Based on **nvidia-egl** Linux image with KDE desktop.
- **Selkies-Gstreamer** for remote access **via web-browser** with Pixelstreaming-like performance.
- **Wineprefix** with VC++ libraries, fonts, codecs and ann NVIDIA components.
- **MangoHud** included.

## ✅ System requirements
- NVIDIA GPU with drivers **535.xx** or newer.
- Linux Kernel **5.x** or newer.
- Internet connection.

## 🔧 Instructions
### Install docker
Installation script is available at https://get.docker.com/
```
curl -fsSL https://get.docker.com -o install-docker.sh
sudo sh install-docker.sh
```
### Install nvidia-container-toolkit
Instructions are available at https://docs.nvidia.com/datacenter/cloud-native/container-toolkit/latest/install-guide.html
```
curl -fsSL https://nvidia.github.io/libnvidia-container/gpgkey | sudo gpg --dearmor -o /usr/share/keyrings/nvidia-container-toolkit-keyring.gpg \
  && curl -s -L https://nvidia.github.io/libnvidia-container/stable/deb/nvidia-container-toolkit.list | \
    sed 's#deb https://#deb [signed-by=/usr/share/keyrings/nvidia-container-toolkit-keyring.gpg] https://#g' | \
    sudo tee /etc/apt/sources.list.d/nvidia-container-toolkit.list
```
```
sudo apt-get install -y nvidia-container-toolkit
sudo nvidia-ctk runtime configure --runtime=docker
sudo systemctl restart docker
```
### Clone this repository
```
git clone https://github.com/Skipperro/ue-docker-nvidia.git
cd ue-docker-nvidia
```
### Build image

```
sudo sh build.sh
```

### Copy your application to app directory
Copy the whole UE application to the `app` directory. **No zip files** - It must be extracted.

The included script will find the proper executable automatically, as long as there is just one .exe file in `Project/Binaries/Win64` directory.

You can even have spaces in project name, but for now only one app can be present in the app directory.

### Create wineprefix
> [!NOTE]
> Because building wineprefix to run Unreal Engine applications requires GUI (to display popups from various setup.exe files), it's impossible to do it as part of the image building. 
> 
> To work around this issue you can use create_wineprefix.sh script to create it on your GUI-capable Linux workstation or **just skip this step** and wineprefix will be created during the first run of your application. It will take a few minutes.

## 🚀 Usage
### Run the application
```
sudo sh run.sh [optional parameters to pass to UE application]
```

### Check if it's running using Selkies-Gstreamer
Just visit http://localhost:8080/

Replace `localhost` with IP if you are testing from different device.

While running use **Shift+F12** to bring up MangoHud with performance statistics.

