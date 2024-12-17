# Base image
FROM python:3.11-slim

# Set the working directory
WORKDIR /app

# Copy requirements.txt first to leverage Docker cache
COPY requirements.txt .

# Install dependencies
RUN pip install --no-cache-dir -r requirements.txt

RUN apt-get update && apt-get install -y curl
RUN curl -s https://google.com > /dev/null && echo "Network OK" || echo "Network Error"

# PyTorch 설치 (CPU 버전)
RUN pip install torch==1.13.1+cpu -f https://download.pytorch.org/whl/cpu/torch_stable.html

# 필요한 패키지 설치 (curl, unzip 추가)
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl unzip && rm -rf /var/lib/apt/lists/*

# 모델 다운로드 및 압축 해제
RUN curl -L -o /tmp/e5_model.zip "https://drive.google.com/uc?id=142QD5BxEEzdDR8W374wNKOHuc5XTZmCC" \
    && unzip /tmp/e5_model.zip -d /app/e5_model \
    && rm /tmp/e5_model.zip

# Copy the rest of the application
COPY . .

# Ensure appropriate permissions for .files and .chainlit directories
RUN mkdir -p /app/.files /app/.chainlit && \
    chmod -R 777 /app/.files /app/.chainlit && \
    chown -R root:root /app

# Set environment variable to change the .files directory location
ENV FILES_DIRECTORY=/app/.files

# Expose the port on which the app runs
EXPOSE 8000

# Explicitly set the user to root to avoid permission issues
USER root

# Command to run the application
CMD ["chainlit", "run", "app.py"]
