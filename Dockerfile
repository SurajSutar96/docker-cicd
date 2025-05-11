# Use official Python image
FROM python:3.11-slim

# Set working directory
WORKDIR /docker_entry

# Copy files
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY main.py .

# Expose port
EXPOSE 8000

# Run the app with uvicorn
CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000"]
