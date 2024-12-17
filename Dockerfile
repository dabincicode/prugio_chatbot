# Base image
FROM python:3.11-slim

# Set the working directory
WORKDIR /app

# Install system dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl unzip && rm -rf /var/lib/apt/lists/*

# Install gdown for Google Drive file downloads
RUN pip install --no-cache-dir gdown

# Download and unzip the e5 model
RUN gdown --id 1PVOTD5_SgGxF-08cIS5sV_atxJoFWrRa -O /tmp/e5.zip \
    && unzip /tmp/e5.zip -d /app/ \
    && rm /tmp/e5.zip

# Set Hugging Face cache directory
ENV TRANSFORMERS_CACHE=/app/.cache/huggingface
RUN mkdir -p /app/.cache/huggingface && chmod -R 777 /app/.cache/huggingface

# Install Python dependencies
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# PyTorch 설치 (CPU 버전)
RUN pip install --no-cache-dir torch==1.13.1+cpu -f https://download.pytorch.org/whl/cpu/torch_stable.html

# Copy the rest of the application
COPY . .

# Ensure appropriate permissions for .files and .chainlit directories
RUN mkdir -p /app/.files /app/.chainlit && \
    chmod -R 777 /app/.files /app/.chainlit

# Set environment variable for file directory
ENV FILES_DIRECTORY=/app/.files

# Expose the port on which the app runs
EXPOSE 8000

# Command to run the application
CMD ["chainlit", "run", "app.py"]
