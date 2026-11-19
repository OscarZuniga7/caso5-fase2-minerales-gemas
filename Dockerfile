FROM python:3.12-slim
ENV PYTHONUNBUFFERED=1 PYTHONDONTWRITEBYTECODE=1
WORKDIR /app
COPY requirements.txt /app/requirements.txt
RUN pip install --no-cache-dir -r requirements.txt
COPY src /app/src
COPY scripts /app/scripts
COPY sql /app/sql
COPY app.py /app/app.py
EXPOSE 8501
CMD ["sh", "-c", "python scripts/provisionar_usuarios.py && exec streamlit run app.py --server.address=0.0.0.0 --server.port=8501 --server.headless=true"]
