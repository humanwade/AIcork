# 라즈베리파이 서버에서 백엔드 실행 + 여러 기기 테스트 가이드

## 1. 라즈베리파이에 옮길 것 (파일/폴더)

프로젝트 **루트**를 그대로 복사하는 것이 가장 단순합니다. 최소한 아래 구조는 유지해야 합니다.

```
wine_recommendation_app/   (또는 임의 이름)
├── backend/               ← 필수 (전체 폴더)
│   ├── api.py
│   ├── auth.py
│   ├── database.py
│   ├── discover.py
│   ├── email_utils.py
│   ├── wine_type.py
│   ├── requirements.txt
│   ├── .env               ← 복사 후 수정 (아래 2번 참고)
│   ├── recommendation/    (폴더 전체)
│   ├── data/              (migrations, schema 등)
│   └── ...
├── data/                  ← 필수 (DB + FAISS 인덱스)
│   ├── pairings.db
│   └── wine_faiss_index/  (recommend 기능 사용 시)
```

- **backend/**  
  - 그대로 통째로 복사 (코드, `.env`, `recommendation/`, `data/`(migrations 등) 모두).
- **data/**  
  - `pairings.db`, `wine_faiss_index/` 등 **현재 PC에서 쓰는 data 폴더 전체**를 복사.
- **경로 관계**  
  - 백엔드는 `PROJECT_ROOT = backend 폴더의 부모` 를 기준으로  
    `data/pairings.db`, `data/wine_faiss_index` 를 찾습니다.  
  - 따라서 **backend와 data가 같은 상위 폴더 아래**에 있어야 합니다 (위 트리처럼).

옮기는 방법 예:  
- USB, SCP, rsync, Git clone 등 편한 방법 사용.

---

## 2. 라즈베리파이에서 해야 할 설정

### 2.1 Python 환경

```bash
cd /path/to/wine_recommendation_app
python3 -m venv venv
source venv/bin/activate   # Linux
pip install -r backend/requirements.txt
```

### 2.2 환경 변수 (.env)

`backend/.env` 를 복사한 뒤, **라즈베리파이에서 쓰는 값**으로만 수정하면 됩니다.

- **API 서버 host/port**  
  - 백엔드 코드에는 host/port 설정이 없습니다.  
  - 아래 2.3처럼 `uvicorn` 실행 시 `--host 0.0.0.0 --port 8000` 으로 지정하면 됩니다.  
  - `.env`에 `HOST`/`PORT` 추가할 필요 없음.

- **그대로 두거나 확인할 것**
  - `GOOGLE_API_KEY`
  - `SMTP_HOST`, `SMTP_PORT`, `MAIL_USERNAME`, `MAIL_PASSWORD`, `MAIL_FROM`
  - (선택) `PAIRINGS_DB_PATH` — DB를 다른 경로에 두었다면 절대 경로로 지정.

예시 (DB 경로만 바꾸는 경우):

```env
# API 서버용 HOST/PORT는 uvicorn 실행 옵션으로 지정. 여기 없어도 됨.
GOOGLE_API_KEY=...
SMTP_HOST=smtp.gmail.com
SMTP_PORT=587
MAIL_USERNAME=...
MAIL_PASSWORD=...
MAIL_FROM=AIcork <...>

# DB를 다른 위치에 두었다면 예:
# PAIRINGS_DB_PATH=/home/pi/wine_data/pairings.db
```

### 2.3 서버 실행 (반드시 0.0.0.0)

다른 기기에서 접속하려면 **반드시** `--host 0.0.0.0` 로 실행해야 합니다.

```bash
cd /path/to/wine_recommendation_app
source venv/bin/activate
cd backend
uvicorn api:app --host 0.0.0.0 --port 8000
```

- `--host 0.0.0.0`: 같은 공유기(네트워크) 안의 모든 기기에서 접속 가능.
- `--port 8000`: 포트 번호 (바꿔도 되지만, Flutter 앱 baseUrl 포트와 맞춰야 함).

서버 주소는 **라즈베리파이 IP:8000** 이 됩니다.  
예: `http://192.168.0.10:8000`

### 2.4 방화벽 (필요 시)

라즈베리파이에서 방화벽을 쓰면 8000 포트를 열어줍니다.

```bash
sudo ufw allow 8000
sudo ufw reload
```

---

## 3. Flutter 앱(테스트 기기)에서 바꿀 것

여러 기기에서 같은 백엔드(라즈베리파이)를 바라보게 하려면 **기기마다 같은 baseUrl**을 쓰면 됩니다.

### 3.1 baseURL 한 곳만 수정

- **파일**: `lib/core/config/app_config.dart`
- **내용**: `10.0.2.2`(에뮬레이터용) → **라즈베리파이 IP**로 변경.

**변경 전:**

```dart
static const String baseUrl = 'http://10.0.2.2:8000';
```

**변경 후 (예: 라즈베리파이 IP가 192.168.0.10 일 때):**

```dart
static const String baseUrl = 'http://192.168.0.10:8000';
```

- 이 주소만 바꾸면, Dio를 쓰는 모든 API 호출(인증, 셀러, 추천, 디스커버, 스캔 등)이 라즈베리파이로 갑니다.
- **다른 파일에서 baseUrl/localhost/8000 을 하드코딩한 곳은 없습니다.** 이 한 군데만 수정하면 됩니다.

### 3.2 기기별로 추가로 할 일

- **Android 에뮬레이터 / iOS 시뮬레이터**  
  - `10.0.2.2` 대신 **PC에서 보이는 라즈베리파이 IP** (예: 192.168.0.10) 로 위처럼 수정 후, 앱에서 `http://192.168.0.10:8000` 으로 접속하도록 하면 됩니다.
- **실기기 (휴대폰/태블릿)**  
  - 같은 Wi‑Fi(공유기)에 연결된 상태에서, 위와 동일하게 baseUrl을 `http://<라즈베리파이IP>:8000` 로 맞추고 앱을 빌드해 설치하면 됩니다.

라즈베리파이 IP 확인 (라즈베리파이 터미널):

```bash
hostname -I
```

---

## 4. 정리: 꼭 바꿔야 하는 것만

| 구분 | 파일/위치 | 할 일 |
|------|-----------|--------|
| **라즈베리파이** | 파일 구조 | `backend/` + `data/`(pairings.db, wine_faiss_index) 옮기기, 구조 유지 |
| **라즈베리파이** | `backend/.env` | PC와 동일하게 두거나, DB 경로 등만 필요 시 수정 (API host/port는 uvicorn으로) |
| **라즈베리파이** | 서버 실행 | `uvicorn api:app --host 0.0.0.0 --port 8000` 로 실행 |
| **Flutter** | `lib/core/config/app_config.dart` | `baseUrl` 만 `http://<라즈베리파이IP>:8000` 로 변경 |

이렇게 하면 라즈베리파이에서 백엔드를 띄워 두고, 여러 기기에서 같은 baseUrl로 테스트할 수 있습니다.
