# Estágio 1: Builder - Compilação e instalação de dependências
# Usamos a imagem Alpine solicitada, que é extremamente leve.
FROM python:3.13.5-alpine3.22 as builder

# Define o diretório de trabalho
WORKDIR /app

# Instala dependências de sistema necessárias para compilar alguns pacotes Python
# em ambiente Alpine. Elas não serão incluídas na imagem final.
RUN apk add --no-cache gcc musl-dev linux-headers

# Copia e instala as dependências Python primeiro para otimizar o cache do Docker
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copia o restante do código da aplicação
COPY . .

# ---

# Estágio 2: Final - Imagem de produção enxuta e segura
FROM python:3.13.5-alpine3.22

# Cria um usuário e grupo não-root para rodar a aplicação (boa prática de segurança)
RUN addgroup -S appgroup && adduser -S appuser -G appgroup

WORKDIR /app

# Adiciona os diretórios de executáveis do Python ao PATH
ENV PATH="/usr/local/bin:/usr/local/lib/python3.13/site-packages/bin:$PATH"

COPY --from=builder /usr/local/lib/python3.13/site-packages /usr/local/lib/python3.13/site-packages
COPY --from=builder /usr/local/bin /usr/local/bin
COPY --from=builder /app /app

# Define o usuário não-root como o proprietário dos arquivos e o usuário padrão
RUN chown -R appuser:appgroup /app
USER appuser

# Expõe a porta da aplicação
EXPOSE 8000

# Comando para iniciar o servidor em produção
CMD ["uvicorn", "app:app", "--host", "0.0.0.0", "--port", "8000", "--reload"]