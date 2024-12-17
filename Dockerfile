# Base image
FROM python:3.11-slim

# Set the working directory
WORKDIR /app

# Copy requirements.txt first to leverage Docker cache
COPY requirements.txt .

# Install dependencies
RUN pip install --no-cache-dir -r requirements.txt

# PyTorch 설치 (CUDA 11.7 버전 예시)
RUN pip install torch==1.13.1+cu117 -f https://download.pytorch.org/whl/cu117/torch_stable.html

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
