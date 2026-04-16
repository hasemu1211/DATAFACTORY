V\&V 아키텍트 관점에서 현재 귀하의 호스트 OS(Ubuntu 22.04) 상태에 맞춘 최적화 세팅 가이드를 제공합니다 1\.  
가장 중요한 아키텍처 원칙은 **호스트 OS에 무거운 CUDA Toolkit을 직접 설치하지 않는 것**입니다. 124GB의 극단적인 스토리지 제약을 극복하기 위해, 호스트에는 그래픽 드라이버와 Docker, 그리고 NVIDIA Container Toolkit만 설치하고 모든 실행 환경(CUDA 포함)은 컨테이너 내부로 격리해야 합니다 1, 2\.  
아래의 명령어를 터미널(Ctrl+Alt+T)에 순차적으로 입력하여 시스템 아키텍처를 구성하십시오.  
**1\. Docker 엔진 설치 및 사용자 권한 설정**ROS 2 및 Isaac Sim 컨테이너 운용 시 볼륨 마운트 권한 충돌을 방지하기 위해 사용자를 docker 그룹에 추가해야 합니다 2\.  
\# 오래된 패키지 삭제 및 필수 패키지 설치  
sudo apt-get update  
sudo apt-get install \-y ca-certificates curl gnupg lsb-release

\# Docker 공식 GPG 키 추가  
sudo mkdir \-p /etc/apt/keyrings  
curl \-fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg \--dearmor \-o /etc/apt/keyrings/docker.gpg

\# 저장소 설정 및 도커 설치  
echo "deb \[arch=$(dpkg \--print-architecture) signed-by=/etc/apt/keyrings/docker.gpg\] https://download.docker.com/linux/ubuntu $(lsb\_release \-cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list \> /dev/null  
sudo apt-get update  
sudo apt-get install \-y docker-ce docker-ce-cli containerd.io docker-compose-plugin

\# sudo 없이 docker를 사용하기 위한 권한 부여 (매우 중요)  
sudo usermod \-aG docker $USER  
**2\. NVIDIA Container Toolkit 설치 및 런타임 구성**컨테이너 내부에서 호스트의 RTX 3050 GPU 리소스에 직접 접근하기 위한 필수 세팅입니다 1, 2\.  
\# NVIDIA 패키지 저장소 설정  
curl \-fsSL https://nvidia.github.io/libnvidia-container/gpgkey | sudo gpg \--dearmor \-o /usr/share/keyrings/nvidia-container-toolkit-keyring.gpg  
curl \-s \-L https://nvidia.github.io/libnvidia-container/stable/deb/nvidia-container-toolkit.list | \\  
  sed 's\#deb https://\#deb \[signed-by=/usr/share/keyrings/nvidia-container-toolkit-keyring.gpg\] https://\#g' | \\  
  sudo tee /etc/apt/sources.list.d/nvidia-container-toolkit.list

\# Toolkit 설치  
sudo apt-get update  
sudo apt-get install \-y nvidia-container-toolkit

\# Docker 런타임 구성 및 데몬 재시작  
sudo nvidia-ctk runtime configure \--runtime=docker  
sudo systemctl restart docker  
**3\. 도커 데몬 스토리지 및 로그 통제 (Disk Full 방지)**컨테이너 로그가 124GB 스토리지를 무한정 잠식하는 것을 수학적으로 차단해야 합니다 1\.  
sudo nano /etc/docker/daemon.json  
파일을 열고 기존 내용에 병합하거나 아래 내용을 붙여넣습니다.  
{  
  "log-driver": "json-file",  
  "log-opts": {  
    "max-size": "10m",  
    "max-file": "3"  
  },  
  "storage-driver": "overlay2"  
}  
저장(Ctrl+O, Enter) 후 종료(Ctrl+X)하고 도커를 재시작합니다.  
sudo systemctl daemon-reload  
sudo systemctl restart docker  
**4\. Isaac Sim 캐시 및 도커 레이어 자동 프루닝 (Storage Management)**Isaac Sim은 구동 시 엄청난 양의 캐시 데이터를 생성하여 지속적인 관리가 필요합니다 3, 4\. 이를 통제하기 위한 셸 스크립트를 작성합니다.  
nano \~/clean\_storage.sh  
아래 스크립트를 붙여넣습니다.  
\#\!/bin/bash  
echo "Starting V\&V Storage Pruning Process..."  
docker system prune \-a \-f \--volumes  
rm \-rf \~/.cache/ov/kit/\*  
rm \-rf \~/.cache/ov/ComputeCache/\*  
rm \-rf \~/.nvidia-omniverse/logs/\*  
echo "Storage Pruning Complete."  
df \-h /  
저장 후 실행 권한을 부여합니다.  
chmod \+x \~/clean\_storage.sh  
**5\. 컨테이너 실행 시 필수 V\&V 아키텍처 파라미터**추후 docker run 구문을 작성할 때 다음의 제약 조건 파라미터들을 반드시 포함해야 합니다.

* **네트워크 동기화:** \--network host 옵션을 통해 ROS 2 DDS 멀티캐스트 통신 지연을 최소화하고 호스트 네트워크를 공유합니다 4, 5\.  
* **공유 메모리(IPC):** \--ipc=host (또는 docker-compose의 경우 ipc: "shareable")를 설정하여 컨테이너 간 대용량 데이터 전송 시 복사 오버헤드를 제거합니다 6, 7\.  
* **GPU 및 GUI 권한:** NVIDIA\_DRIVER\_CAPABILITIES=compute,graphics,utility 환경 변수 주입과 xhost local:docker 명령을 통해 렌더링 및 컴퓨팅 권한을 확보합니다 8, 9\.

모든 명령어 입력이 완료되면 **시스템을 완전히 재부팅(또는 로그아웃 후 재로그인)하셔야 부여된 Docker 권한이 정상적으로 적용**됩니다 2\. 재부팅이 완료되면 즉시 ROS 2와 Isaac Sim 간의 파이프라인(Pillar A) 구축을 위한 컨테이너 실행 논의를 이어가겠습니다.  
