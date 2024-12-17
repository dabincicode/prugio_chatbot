# Base image
FROM python:3.11-slim

# Set the working directory
WORKDIR /app

# Install system dependencies (curl, unzip)
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl unzip && rm -rf /var/lib/apt/lists/*

# Install Python dependencies and gdown
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt gdown

# Check network connectivity (Optional)
RUN curl -s https://google.com > /dev/null && echo "Network OK" || echo "Network Error"

# PyTorch 설치 (CPU 버전)
RUN pip install --no-cache-dir torch==1.13.1+cpu -f https://download.pytorch.org/whl/cpu/torch_stable.html

# Download and unzip the e5 model
RUN gdown --id 142QD5BxEEzdDR8W374wNKOHuc5XTZmCC -O /tmp/e5_model.zip \
    && unzip /tmp/e5_model.zip -d /app/e5_model \
    && rm /tmp/e5_model.zip

# Copy the rest of the application
COPY . .

# Ensure appropriate permissions for .files and .chainlit directories
RUN mkdir -p /app/.files /app/.chainlit && \
    chmod -R 777 /app/.files /app/.chainlit

# Set environment variable to change the .files directory location
ENV FILES_DIRECTORY=/app/.files

# Expose the port on which the app runs
EXPOSE 8000

# Command to run the application
CMD ["chainlit", "run", "app.py"]
