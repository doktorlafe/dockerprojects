FROM python:3.11-slim
WORKDIR /app
COPY requirements.txt .
RUN pip install -r requirements.txt
COPY manage.py .
CMD ["python", "manage.py", "runserver", "0.0.0.0:8000"]
