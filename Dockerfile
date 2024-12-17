# Base image
FROM python:3.11-slim

# Set the working directory
WORKDIR /app

# Install system dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl unzip && rm -rf /var/lib/apt/lists/*

# Download and unzip the e5 model
RUN curl -L "https://drive.google.com/uc?export=download&id=1PVOTD5_SgGxF-08cIS5sV_atxJoFWrRa" -o /tmp/e5.zip \
    && unzip /tmp/e5.zip -d /app/ \
    && rm /tmp/e5.zip

# Install Python dependencies
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# PyTorch 설치 (CPU 버전)
RUN pip install torch==1.13.1+cpu -f https://download.pytorch.org/whl/cpu/torch_stable.html

# Copy the rest of the application
COPY . .

# Expose the port on which the app runs
EXPOSE 8000

# Command to run the application
CMD ["chainlit", "run", "app.py"]
