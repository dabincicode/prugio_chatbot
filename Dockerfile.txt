# Base image
FROM python:3.11-slim

# Set the working directory
WORKDIR /app

# Copy requirements.txt first to leverage Docker cache
COPY requirements.txt .

# Install dependencies
RUN pip install --no-cache-dir -r requirements.txt

# Copy the rest of the application
COPY . .

# Ensure appropriate permissions
RUN mkdir -p /app/.files && chmod -R 755 /app

# Set environment variable to change the .files directory location
ENV FILES_DIRECTORY=/app/.files

# Expose the port on which the app runs
EXPOSE 8000

# Command to run the application
CMD ["chainlit", "run", "app.py"]
