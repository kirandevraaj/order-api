# 1. Use an official lightweight Python image
FROM python:3.11-slim

# 2. Set environment variables to optimize Python execution in containers
ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PORT=5000

# 3. Create a dedicated non-root user and group for security compliance
RUN groupadd -r appgroup && useradd -r -g appgroup appuser

# 4. Set the working directory inside the container
WORKDIR /app

# 5. Copy dependencies file and install them
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# 6. Copy the application code and assign ownership to the non-root user
COPY app.py .
RUN chown -R appuser:appgroup /app

# 7. Switch from root to the unprivileged user
USER appuser

# 8. Document the port the container will listen on
EXPOSE 5000

# 9. Define the startup command to launch the microservice
CMD ["python", "app.py"]