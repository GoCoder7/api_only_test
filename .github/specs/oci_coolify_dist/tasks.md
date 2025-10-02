# OCI에서 Coolify를 이용한 Rails API 서버 배포 가이드

> **목표**: Oracle Cloud Infrastructure(OCI) Ubuntu 인스턴스에 Coolify를 설치하고 Rails API 서버를 배포하여 실제 운영 환경을 구축한다.

## 📋 진행 상황

### ✅ 완료된 단계
- [x] **OCI 인스턴스 생성** - Ubuntu 24.04.2 LTS (ARM64, 24GB RAM)
- [x] **SSH 연결 설정** - 키 기반 인증으로 안전한 접근 가능
- [x] **기본 시스템 확인** - 시스템 리소스 및 기본 도구 확인 완료
- [x] **Docker 설치** - Docker 27.0.3 ARM64 버전 설치 완료
- [x] **Coolify 설치** - 4.0.0-beta.432 버전 설치 및 서비스 실행 확인
- [x] **필수 포트 개방** - 8000, 6001, 6002, 80, 443 포트 설정 완료

### 🔄 현재 진행 중
- [ ] **Coolify 대시보드 접근** - http://168.107.46.107:8000
- [ ] **Coolify 초기 설정** - 관리자 계정 생성 및 기본 설정

### ⏳ 대기 중인 단계
- [ ] **GitHub 연동** - Rails 프로젝트 저장소 연결
- [ ] **Rails 프로젝트 배포** - Docker 기반 배포 설정
- [ ] **데이터베이스 설정** - PostgreSQL 연결 및 마이그레이션

### ✅ OCI 인스턴스 요구사항
- [ ] **OCI Always Free Tier** 계정 생성 완료
- [ ] **Ubuntu 22.04 LTS** 인스턴스 생성 (4 Core, 24GB RAM)
- [ ] **150GB Block Volume** 연결 완료
- [ ] **SSH 키 쌍** 생성 및 인스턴스 접근 확인
- [ ] **방화벽/보안 그룹** 설정 (포트 22, 80, 443, 8000, 6001, 6002 열기)

### ✅ 로컬 개발 환경
- [ ] **SSH 클라이언트** 설치 (Terminal, PuTTY 등)
- [ ] **Git** 설치 및 GitHub 계정
- [ ] **코드 에디터** (VS Code, vim 등)

### ✅ 도메인 설정 (선택사항)
- [ ] **도메인 구매** 및 DNS A 레코드 설정
- [ ] **SSL 인증서** 자동 발급을 위한 도메인 연결

---

## 🌐 1단계: OCI Console에서 인스턴스 생성

### 1.1 OCI Console 접속 및 Compute Instance 생성
- [ ] **OCI Console 로그인**: https://cloud.oracle.com
- [ ] **Compute > Instances 메뉴 이동**
- [ ] **Create Instance 버튼 클릭**

### 1.2 인스턴스 기본 설정
- [ ] **Name**: `coolify-rails-server`
- [ ] **Compartment**: 기본 compartment 또는 새로 생성한 compartment
- [ ] **Availability Domain**: 사용 가능한 도메인 선택

### 1.3 이미지 및 Shape 설정
- [ ] **Image**: `Canonical Ubuntu 22.04` 선택
- [ ] **Shape**: 
  - Shape series: `Ampere` (ARM 기반)
  - Shape name: `VM.Standard.A1.Flex`
  - OCPUs: `4` (Always Free 한도)
  - Memory: `24 GB` (Always Free 한도)

### 1.4 네트워킹 설정
- [ ] **Primary network**: 
  - VCN: 기본 VCN 또는 새로 생성
  - Subnet: Public Subnet 선택
  - **Assign a public IPv4 address** 체크
- [ ] **NSG (Network Security Group)**: 필요시 생성하여 적용

### 1.5 SSH 키 설정
- [ ] **SSH keys**: 
  - **Generate a key pair for me** 또는
  - **Upload public key files (.pub)** - 기존 키 사용
  - 생성된 private key 다운로드 및 안전한 곳에 보관

### 1.6 Boot Volume 설정
- [ ] **Boot volume**: 
  - **Specify a custom boot volume size**: `100 GB`
  - **Use in-transit encryption**: 체크 (보안 강화)

### 1.7 Advanced Options (고급 옵션)
- [ ] **Cloud-init script** (선택사항):
  ```bash
  #!/bin/bash
  # 시스템 업데이트
  apt update && apt upgrade -y
  
  # 필수 도구 설치
  apt install -y curl wget git nano htop unzip
  
  # Docker 설치 준비
  curl -fsSL https://get.docker.com -o get-docker.sh
  ```

### 1.8 인스턴스 생성 완료
- [ ] **Create 버튼 클릭**
- [ ] **Provisioning 상태 확인** (보통 1-2분 소요)
- [ ] **Public IP 주소 확인 및 기록**
---

## 🔒 2단계: OCI 보안 설정

### 2.1 Security List 또는 NSG 규칙 추가
- [ ] **OCI Console > Networking > Virtual Cloud Networks**
- [ ] **해당 VCN > Security Lists** 또는 **Network Security Groups**
- [ ] **Ingress Rules 추가**:
  ```
  Port 22   (SSH)     - Source: 0.0.0.0/0 또는 특정 IP
  Port 80   (HTTP)    - Source: 0.0.0.0/0
  Port 443  (HTTPS)   - Source: 0.0.0.0/0  
  Port 8000 (Coolify Dashboard) - Source: 0.0.0.0/0 또는 특정 IP
  Port 6001 (Coolify Real-time) - Source: 0.0.0.0/0 또는 특정 IP
  Port 6002 (Coolify Terminal)  - Source: 0.0.0.0/0 또는 특정 IP
  ```

### 2.2 Block Volume 생성 및 연결
- [ ] **OCI Console > Storage > Block Volumes**
- [ ] **Create Block Volume**:
  - Name: `coolify-data-volume`
  - Size: `150 GB` (Always Free 한도)
  - Volume Performance: `Balanced`
- [ ] **생성된 볼륨을 인스턴스에 연결**:
  - Attach to Instance > 생성한 인스턴스 선택
  - Device path 확인 (예: `/dev/oracleoci/oraclevdb`)

---

## 🖥️ 3단계: SSH 접속 및 서버 초기 설정

### 3.1 SSH 접속
- [ ] **SSH Key 권한 설정** (로컬에서)
  ```bash
  chmod 600 ~/.ssh/oci_private_key
  ```

- [ ] **인스턴스 접속**
  ```bash
  ssh -i ~/.ssh/oci_private_key ubuntu@<OCI_PUBLIC_IP>
  ```

### 3.2 시스템 업데이트 및 기본 설정
- [ ] **시스템 업데이트**
  ```bash
  sudo apt update && sudo apt upgrade -y
  ```

- [ ] **필수 패키지 설치**
  ```bash
  sudo apt install -y curl wget git nano htop unzip ufw
  ```

### 3.3 Block Volume 마운트
- [ ] **연결된 볼륨 확인**
  ```bash
  lsblk
  # /dev/sdb 또는 /dev/oracleoci/oraclevdb 확인
  ```

- [ ] **파일시스템 생성 및 마운트**
  ```bash
  sudo mkfs.ext4 /dev/sdb  # 디바이스명에 맞게 수정
  sudo mkdir -p /data
  sudo mount /dev/sdb /data
  sudo chown -R ubuntu:ubuntu /data
  ```

- [ ] **자동 마운트 설정**
  ```bash
  echo '/dev/sdb /data ext4 defaults,nofail 0 2' | sudo tee -a /etc/fstab
  ```

### 3.4 방화벽 설정 (추가 보안)
- [ ] **UFW 방화벽 설정**
  ```bash
  sudo ufw allow 22/tcp      # SSH
  sudo ufw allow 80/tcp      # HTTP  
  sudo ufw allow 443/tcp     # HTTPS
  sudo ufw allow 8000/tcp    # Coolify
  sudo ufw allow 3000/tcp    # Rails (임시)
  sudo ufw --force enable
  ```

---

## 🐳 4단계: Docker 설치

### 4.1 Docker 설치
- [ ] **Docker 공식 설치 스크립트 사용**
  ```bash
  curl -fsSL https://get.docker.com -o get-docker.sh
  sudo sh get-docker.sh
  ```

- [ ] **Docker 사용자 권한 추가**
  ```bash
  sudo usermod -aG docker ubuntu
  newgrp docker  # 또는 재로그인
  ```

- [ ] **Docker 설치 확인**
  ```bash
  docker --version
  docker run hello-world
  ```

---

## 🚀 5단계: Coolify 설치

### 5.1 SSH 설정 (Coolify 요구사항)
- [ ] **SSH 설정 파일 수정**
  ```bash
  sudo nano /etc/ssh/sshd_config
  ```

- [ ] **다음 설정 확인/추가**:
  ```bash
  PermitRootLogin prohibit-password
  PubkeyAuthentication yes
  ```

- [ ] **SSH 서비스 재시작**
  ```bash
  sudo systemctl restart ssh
  ```

### 5.2 Coolify 설치
- [ ] **Coolify 자동 설치 스크립트 실행**
  ```bash
  curl -fsSL https://cdn.coollabs.io/coolify/install.sh | bash
  ```

- [ ] **설치 완료 대기** (5-10분 소요)
- [ ] **Coolify 서비스 상태 확인**
  ```bash
  docker ps
  # coolify 관련 컨테이너들이 실행 중인지 확인
  ```

### 5.3 Coolify 접속 확인
- [ ] **웹 브라우저에서 접속**: `http://<OCI_PUBLIC_IP>:8000`
- [ ] **초기 관리자 계정 생성** (첫 접속시)
- [ ] **로그인 성공 확인**

---

## � 6단계: Rails 프로젝트 준비

### 6.1 로컬에서 프로젝트 준비
- [ ] **`.env.example` 파일 생성** (로컬 프로젝트에서)
  ```bash
  # 프로젝트 루트에서
  touch .env.example
  ```

- [ ] **`.env.example` 내용 작성**
  ```env
  # Rails 환경 설정
  RAILS_ENV=production
  RAILS_MASTER_KEY=your_32_character_master_key_here
  RAILS_LOG_TO_STDOUT=true
  
  # 데이터베이스 설정  
  POSTGRES_USER=rails_app
  POSTGRES_PASSWORD=secure_password_here
  POSTGRES_DB=api_only_production
  DATABASE_URL=postgres://rails_app:secure_password_here@db:5432/api_only_production
  
  # 추가 설정
  RAILS_SERVE_STATIC_FILES=true
  RAILS_LOG_LEVEL=info
  PORT=3000
  ```

### 6.2 개발용 코드 정리
- [ ] **GroupsController에서 디버그 로깅 제거**
  ```ruby
  # app/controllers/groups_controller.rb에서 디버그 출력 코드 제거
  # divider, puts 관련 코드들 삭제
  ```

### 6.3 Health Check 엔드포인트 추가
- [ ] **Health Check 컨트롤러 생성** (로컬에서)
  ```bash
  rails generate controller Health check --no-test-framework
  ```

- [ ] **라우트 추가**
  ```ruby
  # config/routes.rb
  Rails.application.routes.draw do
    get "health", to: "health#check"
    resources :groups
  end
  ```

- [ ] **Health Check 구현**
  ```ruby
  # app/controllers/health_controller.rb
  class HealthController < ApplicationController
    def check
      render json: { 
        status: 'OK', 
        timestamp: Time.current,
        version: '1.0.0',
        environment: Rails.env
      }
    end
  end
  ```

### 6.4 Git 커밋 및 푸시
- [ ] **변경사항 커밋**
  ```bash
  git add .
  git commit -m "feat: prepare for OCI Coolify deployment
  
  - Add .env.example for production configuration
  - Clean up debug logging in GroupsController  
  - Add health check endpoint for monitoring
  - Update configurations for cloud deployment"
  ```

- [ ] **GitHub에 푸시**
  ```bash
  git push origin main
  ```

---

## 🌐 7단계: Coolify에서 프로젝트 배포

### 7.1 Coolify 대시보드 접속
- [ ] **브라우저에서 Coolify 접속**: `http://<OCI_PUBLIC_IP>:8000`
- [ ] **로그인** (초기 설정한 관리자 계정)

### 7.2 새 프로젝트 생성
- [ ] **+ New Project** 클릭
- [ ] **프로젝트 정보 입력**:
  - Name: `rails-api-server`
  - Description: `Rails API server for production deployment`

### 7.3 서버 설정 (localhost)
- [ ] **Servers 탭 > localhost 확인**
- [ ] **localhost 서버가 정상 연결되어 있는지 확인**
- [ ] 필요시 SSH 키 설정 업데이트

### 7.4 GitHub 연동 및 애플리케이션 생성
- [ ] **+ New Resource** 클릭
- [ ] **Public Repository** 선택
- [ ] **Repository 정보 입력**:
  - Git Repository URL: `https://github.com/GoCoder7/api_only_test.git`
  - Branch: `main`
  - Build Pack: `Docker`

### 7.5 배포 설정
- [ ] **Docker Compose 설정**:
  - Docker Compose Location: `./compose.yml` (루트에 있는 파일)
  - Build Command: 기본값 사용
  - Start Command: 기본값 사용

### 7.6 환경변수 설정
- [ ] **Environment Variables 탭에서 추가**:
  ```env
  RAILS_ENV=production
  RAILS_MASTER_KEY=<실제_마스터_키_값>
  POSTGRES_USER=rails_app
  POSTGRES_PASSWORD=<안전한_비밀번호>
  POSTGRES_DB=api_only_production
  DATABASE_URL=postgres://rails_app:<비밀번호>@db:5432/api_only_production
  RAILS_LOG_TO_STDOUT=true
  RAILS_SERVE_STATIC_FILES=true
  RAILS_LOG_LEVEL=info
  ```

### 7.7 도메인 설정 (선택사항)
- [ ] **Domains 탭에서 도메인 추가** (도메인이 있는 경우)
- [ ] **SSL 인증서 자동 발급 설정**

---

## 🚀 8단계: 첫 배포 실행

### 8.1 배포 시작
- [ ] **Deploy 버튼 클릭**
- [ ] **Build 로그 실시간 모니터링**:
  - Docker 이미지 빌드 진행상황 확인
  - PostgreSQL 컨테이너 시작 확인  
  - Rails 애플리케이션 시작 확인
  - 에러 메시지 확인 및 트러블슈팅

### 8.2 배포 상태 확인
- [ ] **Services 탭에서 상태 체크**:
  - `db` 서비스: `Healthy` 상태 확인
  - `web` 서비스: `Running` 상태 확인
- [ ] **Logs 탭에서 로그 확인**:
  - Rails 서버 정상 시작 로그 확인
  - 데이터베이스 연결 상태 확인

### 8.3 데이터베이스 초기화
- [ ] **Coolify Terminal 또는 SSH를 통해 마이그레이션 실행**
  ```bash
  # Coolify Terminal에서 또는
  docker exec -it <container_name> rails db:create db:migrate db:seed
  
  # 또는 SSH에서
  docker-compose exec web rails db:create db:migrate db:seed
  ```

---

## 🧪 9단계: API 테스트 및 검증

### 9.1 기본 연결 테스트
- [ ] **Health Check 엔드포인트 테스트**
  ```bash
  curl http://<OCI_PUBLIC_IP>:3000/health
  # 예상 응답: {"status":"OK","timestamp":"...","version":"1.0.0","environment":"production"}
  ```

### 9.2 Groups API 테스트
- [ ] **GET /groups (목록 조회)**
  ```bash
  curl -X GET http://<OCI_PUBLIC_IP>:3000/groups \
    -H "Content-Type: application/json"
  ```

- [ ] **POST /groups (새 그룹 생성)**
  ```bash
  curl -X POST http://<OCI_PUBLIC_IP>:3000/groups \
    -H "Content-Type: application/json" \
    -d '{"group": {"name": "Test Group from OCI"}}'
  ```

- [ ] **GET /groups/1 (특정 그룹 조회)**
  ```bash
  curl -X GET http://<OCI_PUBLIC_IP>:3000/groups/1 \
    -H "Content-Type: application/json"
  ```

### 9.3 브라우저 테스트
- [ ] **브라우저에서 API 엔드포인트 직접 접속**
  - `http://<OCI_PUBLIC_IP>:3000/health`
  - `http://<OCI_PUBLIC_IP>:3000/groups`

### 9.4 성능 및 부하 테스트 (선택사항)
- [ ] **간단한 부하 테스트**
  ```bash
  # Apache Bench를 사용한 기본 테스트
  ab -n 100 -c 10 http://<OCI_PUBLIC_IP>:3000/health
  ```

---

## 📊 10단계: 모니터링 및 운영 관리

### 10.1 OCI 모니터링
- [ ] **OCI Console > Observability > Monitoring**
- [ ] **인스턴스 메트릭 확인**:
  - CPU 사용률
  - 메모리 사용률  
  - 네트워크 트래픽
  - 디스크 I/O

### 10.2 Coolify 모니터링
- [ ] **Coolify 대시보드에서 리소스 사용량 모니터링**
- [ ] **컨테이너 상태 주기적 확인**
- [ ] **로그 모니터링**:
  ```bash
  # SSH로 서버 접속 후
  docker-compose logs -f web  # Rails 애플리케이션 로그
  docker-compose logs -f db   # PostgreSQL 로그
  ```

### 10.3 알림 설정 (선택사항)
- [ ] **OCI Notifications 서비스 설정**
- [ ] **CPU/메모리 임계값 알림 구성**
- [ ] **애플리케이션 상태 체크 스크립트 작성**

---

## 🔄 11단계: CI/CD 및 업데이트 테스트

### 11.1 코드 변경 및 자동 배포 테스트
- [ ] **로컬에서 간단한 변경사항 추가**
  ```ruby
  # app/controllers/health_controller.rb 수정
  def check
    render json: { 
      status: 'OK', 
      timestamp: Time.current,
      version: '1.0.1',  # 버전 업데이트
      environment: Rails.env,
      server: 'OCI Production'
    }
  end
  ```

- [ ] **Git 커밋 및 푸시**
  ```bash
  git add .
  git commit -m "feat: update health check with server info"
  git push origin main
  ```

### 11.2 자동 재배포 확인
- [ ] **Coolify에서 자동 빌드 트리거 확인**
- [ ] **배포 완료까지 모니터링**
- [ ] **새 버전 API 테스트**
  ```bash
  curl http://<OCI_PUBLIC_IP>:3000/health
  # server: 'OCI Production' 필드가 추가되었는지 확인
  ```

---

## 🛡️ 12단계: 보안 및 최적화

### 12.1 보안 설정 강화
- [ ] **불필요한 포트 차단**
  ```bash
  # SSH에서 Rails 직접 접근 포트 차단 (Coolify 프록시 사용)
  sudo ufw delete allow 3000/tcp
  ```

- [ ] **SSL/TLS 설정** (도메인이 있는 경우)
  - Coolify에서 Let's Encrypt 자동 인증서 발급
  - HTTPS 리다이렉션 설정

### 12.2 성능 최적화
- [ ] **데이터베이스 인덱스 최적화**
- [ ] **Rails 로그 레벨 조정**
- [ ] **메모리 사용량 모니터링 및 조절**

### 12.3 백업 전략
- [ ] **OCI Block Volume 스냅샷 자동화 설정**
- [ ] **PostgreSQL 자동 백업 스크립트 작성**
- [ ] **애플리케이션 코드 백업 (Git 외부 백업)**

---

## 🎯 성공 기준

### ✅ 필수 달성 목표
- [ ] OCI Ubuntu 인스턴스 성공적 생성 및 설정 완료
- [ ] Coolify 정상 설치 및 웹 인터페이스 접근 성공
- [ ] Rails API 프로젝트 성공적 배포
- [ ] 모든 API 엔드포인트 정상 작동 확인 (외부 IP로 접근)
- [ ] 데이터베이스 연결 및 CRUD 작업 정상
- [ ] CI/CD 파이프라인 (Git push → 자동 재배포) 작동 확인

### 📊 운영 목표
- [ ] **가용성**: 99% 이상 업타임 달성
- [ ] **성능**: Health check 응답시간 < 200ms
- [ ] **보안**: HTTPS 적용 및 불필요한 포트 차단
- [ ] **모니터링**: 리소스 사용률 지속적 관찰

### 🚀 추가 개선 목표
- [ ] 도메인 연결 및 SSL 인증서 자동 발급
- [ ] 로드 밸런싱 (향후 다중 인스턴스)
- [ ] 자동 백업 시스템 구축
- [ ] 로그 중앙화 및 알림 시스템

---

## 🔧 트러블슈팅 가이드

### 일반적인 문제들
- **포트 접근 불가**: OCI Security List 및 UFW 방화벽 규칙 확인
- **Docker 권한 오류**: `usermod -aG docker ubuntu` 및 재로그인
- **메모리 부족**: OCI 인스턴스 리소스 사용률 모니터링
- **SSL 인증서 실패**: 도메인 DNS 설정 및 방화벽 443 포트 확인

### 유용한 명령어들
```bash
# 시스템 리소스 확인
htop
df -h
free -h

# Docker 상태 확인
docker ps -a
docker-compose logs -f

# 네트워크 연결 테스트
curl -I http://localhost:8000
netstat -tlnp | grep :8000
```

---

## � 참고 자료

### 공식 문서
- [Oracle Cloud Infrastructure 문서](https://docs.oracle.com/en-us/iaas/)
- [Coolify 공식 문서](https://coolify.io/docs)
- [Docker Compose 문서](https://docs.docker.com/compose/)
- [Rails 운영 가이드](https://guides.rubyonrails.org/configuring.html)

### 커뮤니티 리소스
- [OCI Always Free 가이드](https://www.oracle.com/cloud/free/)
- [Coolify Discord 커뮤니티](https://discord.gg/coolify)
- [Rails 배포 Best Practices](https://guides.rubyonrails.org/getting_started.html)

---

## � 체크리스트 요약

### 인프라 구축 (1-5단계)
- [ ] OCI 인스턴스 생성 및 Block Volume 연결
- [ ] 보안 그룹 및 네트워크 설정
- [ ] SSH 접속 및 시스템 초기 설정
- [ ] Docker 설치 및 설정
- [ ] Coolify 설치 및 웹 인터페이스 확인

### 애플리케이션 배포 (6-9단계)  
- [ ] Rails 프로젝트 준비 및 GitHub 푸시
- [ ] Coolify에서 프로젝트 생성 및 환경 설정
- [ ] 첫 배포 실행 및 상태 확인
- [ ] API 엔드포인트 테스트 및 검증 완료

### 운영 및 관리 (10-12단계)
- [ ] 모니터링 시스템 설정
- [ ] CI/CD 파이프라인 테스트
- [ ] 보안 강화 및 성능 최적화
- [ ] 백업 전략 수립

---

> **🎉 완료 후**: 이 가이드를 완료하면 OCI에서 실제 운영 가능한 Rails API 서버를 Coolify로 관리하는 완전한 시스템을 갖게 됩니다. 확장 가능하고 안정적인 클라우드 네이티브 애플리케이션의 기초가 완성됩니다!