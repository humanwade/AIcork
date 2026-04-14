FROM python:3.11-slim

ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1

# 도커 컨테이너 내부의 작업 공간 이름 (그대로 두셔도 됩니다)
WORKDIR /app

# 1. 라이브러리 설치 (캐시 활용을 위해 requirements.txt만 먼저 복사)
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# 2. 데이터 복사 (backend 폴더와 같은 위치에 data가 있다면)
# 만약 빌드 시 에러나면 이 줄만 주석처리(#) 하세요.
COPY ../data /app/data

# 3. 소스 코드 복사 
# backend 폴더의 모든 파일(api.py 등)을 컨테이너의 /app 폴더로 복사합니다.
COPY . /app

# 4. 실행 위치 설정 및 포트 개방
EXPOSE 8000

# api.py가 /app 바로 아래에 있으므로 아래와 같이 실행합니다.
CMD ["uvicorn", "api:app", "--host", "0.0.0.0", "--port", "8000"]