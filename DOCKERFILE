# 1. Escolhe a imagem base do Python
FROM python:3.11-slim

# 2. Define o diretório de trabalho dentro do container
WORKDIR /app

# 3. Instala as dependências necessárias
RUN pip install fastapi uvicorn

# 4. Copia o código da aplicação para dentro do container
COPY main.py .

# 5. Expõe a porta que o FastAPI vai rodar
EXPOSE 80

# 6. Comando para rodar a aplicação
CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "80"]
