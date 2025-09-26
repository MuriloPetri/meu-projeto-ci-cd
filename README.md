# 🚀 Projeto CI/CD com FastAPI, Docker e ArgoCD

Este projeto demonstra a implementação de um pipeline completo de **CI/CD** (Integração Contínua e Entrega Contínua) para uma aplicação **FastAPI**. O processo utiliza **GitHub Actions** para automação, **Docker Hub** como registro de contêineres e **ArgoCD** para realizar o deploy contínuo em um cluster **Kubernetes** local, gerenciado pelo **Rancher Desktop**.

Nesta arquitetura, o repositório Git atua como a **fonte única da verdade** (*Single Source of Truth*), garantindo que todo o processo de deploy seja auditável, previsível e versionado.

---

## ☁️ Arquitetura e Tecnologias

A solução é composta pelas seguintes ferramentas:

-   **Orquestração de Containers:** Kubernetes (via Rancher Desktop)
-   **CI/CD e GitOps:** GitHub Actions e ArgoCD
-   **Container Registry:** Docker Hub
-   **Aplicação:** FastAPI (Exemplo "Hello World")
-   **Ambiente Local:** Rancher Desktop com Docker

---

## 🎯 Objetivo

O objetivo principal é automatizar o ciclo completo de desenvolvimento de uma aplicação FastAPI, desde o build até o deploy em produção. O pipeline realiza as seguintes ações:

1.  **Build e Push:** Constrói a imagem Docker da aplicação e a publica no Docker Hub a cada novo commit na branch `main`.
2.  **Atualização de Manifestos:** Atualiza automaticamente os arquivos de manifesto do Kubernetes com a nova tag da imagem Docker.
3.  **Deploy Automático:** O ArgoCD detecta a mudança no repositório de manifestos e sincroniza o estado do cluster, aplicando o deploy da nova versão da aplicação.

---

## 🛠️ Pré-requisitos

Antes de iniciar, certifique-se de que você possui os seguintes softwares instalados e configurados:

-   [Rancher Desktop](https://rancherdesktop.io/) com Kubernetes habilitado.
-   `kubectl` configurado e com acesso ao cluster (verifique com `kubectl get nodes`).
-   [Git](https://git-scm.com/) instalado localmente.
-   Uma conta no [GitHub](https://github.com/).
-   Uma conta no [Docker Hub](https://hub.docker.com/) (com um token de acesso criado).
-   Python 3 e Docker instalados na sua máquina local.
-   ArgoCD instalado no cluster Kubernetes.

---

## 📝 Passo a Passo Detalhado

### 1. Criando a Aplicação FastAPI

Primeiro, crie um repositório no GitHub para o código da aplicação (ex: `meu-projeto-ci-cd`).

**1.1. Código da Aplicação**

Crie o arquivo `main.py` com o seguinte conteúdo:

```python
from fastapi import FastAPI

app = FastAPI()

@app.get("/")
async def root():
    return {"message": "Hello World"}
```
1.2. Dockerfile

Em seguida, crie o Dockerfile na raiz do projeto para containerizar a aplicação:

Dockerfile

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
2. Configurando o Workflow do GitHub Actions
Crie um segundo repositório no GitHub que servirá para armazenar os manifestos do Kubernetes (ex: meu-projeto-manifests).

No repositório da aplicação (meu-projeto-ci-cd), crie o arquivo .github/workflows/ci-cd.yaml para definir o pipeline de CI/CD:

YAML

name: CI/CD Pipeline

on:
  push:
    branches: [ main ]

jobs:
  build-and-push:
    runs-on: ubuntu-latest
    steps:
    - name: Checkout do código da aplicação
      uses: actions/checkout@v3

    - name: Configurar Docker Buildx
      uses: docker/setup-buildx-action@v2

    - name: Login no Docker Hub
      uses: docker/login-action@v2
      with:
        username: ${{ secrets.DOCKER_USERNAME }}
        password: ${{ secrets.DOCKER_PASSWORD }}

    - name: Build e Push da imagem Docker
      id: docker_build
      uses: docker/build-push-action@v4
      with:
        context: .
        file: ./Dockerfile
        push: true
        tags: ${{ secrets.DOCKER_USERNAME }}/hello-app:${{ github.sha }}

    - name: Configurar chave SSH para o repositório de manifestos
      run: |
        mkdir -p ~/.ssh
        echo "${{ secrets.SSH_PRIVATE_KEY }}" > ~/.ssh/id_ed25519
        chmod 600 ~/.ssh/id_ed25519
        ssh-keyscan github.com >> ~/.ssh/known_hosts
      shell: bash

    - name: Clonar o repositório de manifestos
      uses: actions/checkout@v3
      with:
        repository: SEU_USUARIO/meu-projeto-manifests # ⚠️ TROCAR AQUI
        path: ./manifests
        ssh-key: ${{ secrets.SSH_PRIVATE_KEY }}

    - name: Atualizar a tag da imagem no manifesto Kubernetes
      run: |
        sed -i 's|image:.*|image: ${{ secrets.DOCKER_USERNAME }}/hello-app:${{ github.sha }}|g' ./manifests/deployment.yaml

    - name: Commit e Push das alterações no repositório de manifestos
      run: |
        cd ./manifests
        git config --global user.name 'github-actions[bot]'
        git config --global user.email 'github-actions[bot]@users.noreply.github.com'
        git add deployment.yaml
        git commit -m "Update image tag to ${{ github.sha }}"
        git push origin main

        
Adicione os seguintes secrets nas configurações do repositório da aplicação:

DOCKER_USERNAME: Seu nome de usuário do Docker Hub.

DOCKER_PASSWORD: Seu token de acesso do Docker Hub.

SSH_PRIVATE_KEY: A chave SSH privada (sem senha) que tem permissão de escrita no repositório meu-projeto-manifests.

3. Criando o Repositório de Manifestos Kubernetes
No repositório meu-projeto-manifests, crie os seguintes arquivos:

3.1. deployment.yaml

YAML

apiVersion: apps/v1
kind: Deployment
metadata:
  name: hello-app
spec:
  replicas: 1
  selector:
    matchLabels:
      app: hello-app
  template:
    metadata:
      labels:
        app: hello-app
    spec:
      containers:
        - name: hello-app
          image: seu-usuario-docker/hello-app:latest # ⚠️ Esta linha será atualizada pelo GitHub Actions
          ports:
            - containerPort: 80
3.2. service.yaml

YAML

apiVersion: v1
kind: Service
metadata:
  name: hello-app
spec:
  selector:
    app: hello-app
  ports:
    - protocol: TCP
      port: 80
      targetPort: 80
  type: ClusterIP
4. Instalando e Configurando o ArgoCD
Execute os seguintes comandos para instalar o ArgoCD no seu cluster local:

Bash

# Criar o namespace para o ArgoCD
kubectl create namespace argocd

# Aplicar os manifestos de instalação
kubectl apply -n argocd -f [https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml](https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml)
Para acessar a interface do ArgoCD, obtenha a senha inicial e exponha a porta do serviço:

Bash

# Obter a senha (em base64) e decodificá-la
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d

# Expor a porta do servidor do ArgoCD
kubectl port-forward svc/argocd-server -n argocd 8080:443
Acesse a interface em https://localhost:8080/. O usuário é admin e a senha é a que você obteve no passo anterior.

5. Criando a Aplicação no ArgoCD
Na interface do ArgoCD, siga os passos:

Clique em NEW APP.

Preencha as informações:

Application Name: hello-app

Project: default

Repository URL: A URL SSH do seu repositório de manifestos (ex: git@github.com:SEU_USUARIO/meu-projeto-manifests.git).

Path: .

Cluster: https://kubernetes.default.svc (cluster local)

Namespace: default

Clique em CREATE.

Após a criação, o ArgoCD irá clonar o repositório de manifestos e aplicar os recursos no seu cluster. Aguarde o status ficar Healthy e Synced.

6. Testando a Aplicação
Para validar o deploy, exponha a porta do Service da sua aplicação:

Bash

kubectl port-forward svc/hello-app -n default 8081:80
Agora, acesse http://localhost:8081/ no seu navegador. Você deverá ver a mensagem: {"message":"Hello World"}.
