# 🚀 Projeto CI/CD com FastAPI, Docker e ArgoCD

Este projeto demonstra a implementação de um pipeline completo de **CI/CD** para uma aplicação **FastAPI**, utilizando **GitHub Actions**, **Docker Hub** e **ArgoCD** para deploy automático em um cluster **Kubernetes local** gerenciado pelo **Rancher Desktop**.

O Git atua como a **fonte única da verdade**, garantindo que o deploy seja auditável, previsível e versionado.

---

## ☁️ Arquitetura e Tecnologias

- 🖥️ **Orquestração de Containers:** Kubernetes (via Rancher Desktop)  
- ⚙️ **CI/CD e GitOps:** GitHub Actions + ArgoCD  
- 🐳 **Container Registry:** Docker Hub  
- 🛠️ **Aplicação:** FastAPI (Hello World)  
- 💻 **Ambiente Local:** Rancher Desktop com Docker  

---

## 🛠️ Pré-requisitos

Antes de iniciar, verifique se você tem os seguintes softwares instalados e configurados:

- Rancher Desktop com Kubernetes habilitado  
- `kubectl` configurado e funcional (`kubectl get nodes`)  
- Git instalado localmente  
- Conta no GitHub  
- Conta no Docker Hub (com token de acesso)  
- Python 3 e Docker instalados  
- ArgoCD instalado no cluster local  

---

## 🎯 Objetivo

Automatizar o ciclo completo de desenvolvimento, build, deploy e execução de uma aplicação FastAPI. O pipeline deve:

1. Buildar e publicar a imagem Docker no Docker Hub  
2. Atualizar os manifests do Kubernetes  
3. Fazer deploy automático no cluster via ArgoCD  

---

## 📝 Passo a Passo

### 1. Criar a aplicação FastAPI

Crie um repositório Git para a aplicação (`meu-projeto-ci-cd`) e adicione o arquivo `main.py`:

```python
from fastapi import FastAPI

app = FastAPI()
```
Crie também o Dockerfile
```bash
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
```
### 2. Criar Workflow do Github Actions
Criar o workflow do GitHub Actions

No repositório projeto-ci-cd, crie o arquivo .github/workflows/ci-cd.yaml deve ficar assim:
<img width="806" height="255" alt="Image" src="https://github.com/user-attachments/assets/3e7e9336-d8b5-44bd-99c5-19ecf3efe86e" />

dentro de ci-cd.yaml:

```bash
name: CI/CD Pipeline 

on:
  push:
    branches: [ main ]

jobs:
  build-and-push:
    runs-on: ubuntu-latest
    steps:
    - name: Checkout code
      uses: actions/checkout@v3

    - name: Set up Docker Buildx
      uses: docker/setup-buildx-action@v2

    - name: Login to Docker Hub
      uses: docker/login-action@v2
      with:
        username: ${{ secrets.DOCKER_USERNAME }}
        password: ${{ secrets.DOCKER_PASSWORD }}

    - name: Build and push Docker image
      id: docker_build
      uses: docker/build-push-action@v4
      with:
        context: .
        file: ./Dockerfile
        push: true
        tags: ${{ secrets.DOCKER_USERNAME }}/hello-app:${{ github.sha }}

    # Configura a chave SSH antes do checkout do repo de manifests
    - name: Setup SSH key
      run: |
        mkdir -p ~/.ssh
        echo "${{ secrets.SSH_PRIVATE_KEY }}" > ~/.ssh/id_ed25519
        chmod 600 ~/.ssh/id_ed25519
        ssh-keyscan github.com >> ~/.ssh/known_hosts
      shell: bash

    # Checkout do repositório de manifests usando SSH
    - name: Clone manifests repository
      uses: actions/checkout@v3
      with:
        repository: MuriloPetri/meu-projeto-manifests
        path: ./manifests
        persist-credentials: false

    # ✅ Força o remote para SSH DENTRO da pasta manifests
    - name: Set git remote to SSH
      run: |
        cd ./manifests
        git remote set-url origin git@github.com:MuriloPetri/meu-projeto-manifests.git

    - name: Update image tag in Kubernetes manifest
      run: |
        sed -i 's|image:.*|image: ${{ secrets.DOCKER_USERNAME }}/hello-app:${{ github.sha }}|g' ./manifests/deployment.yaml

    - name: Commit and push changes
      run: |
        cd ./manifests
        git config --global user.name 'github-actions[bot]'
        git config --global user.email 'github-actions[bot]@users.noreply.github.com'
        git add deployment.yaml
        git commit -m "Update image tag to ${{ github.sha }}"
        git push origin main
      env:
        GIT_SSH_COMMAND: "ssh -i ~/.ssh/id_ed25519 -o StrictHostKeyChecking=no"
```

Adicione os segredos no GitHub:
```
**DOCKER_USERNAME**

**DOCKER_PASSWORD**

**SSH_PRIVATE_KEY** (para acessar o repositório de manifests)
```

<img width="1893" height="947" alt="Image" src="https://github.com/user-attachments/assets/84668f5d-034a-4fb4-9d36-05b877fe26da" />

## 📃3. Criar o repositorio Manifests
Crie um repositório separado (meu-projeto-manifests) contendo:

deployment.yaml

service.yaml

No deployment.yaml:
```bash
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
          image: seu-usuario-docker/hello-app:latest
          ports:
            - containerPort: 80
```
No service:
```bash
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
```

### 4. Instalar e Configurar o ArgoCD
```bash
kubectl create namespace argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
```

Acesse a interface do Argo com:
```bash
kubectl port-forward svc/argocd-server -n argocd 8080:443
```

e acesse a pagina local da porta 80:
```bash
https://localhost:8080/
```

## ⚙️ 5. Criando a Aplicação no ArgoCD

Com a interface do ArgoCD aberta em `https://localhost:8080/`, siga os passos para registrar sua nova aplicação:

1.  Clique no botão **+ NEW APP** no canto superior esquerdo.
2.  Preencha os campos principais na seção **GENERAL**:
    -   **Application Name:** `hello-app`
    -   **Project:** `default`
    -   **Sync Policy:** `Automatic` (Opcional, mas recomendado para GitOps)

3.  Na seção **SOURCE**, configure o repositório de manifestos:
    -   **Repository URL:** A URL **SSH** do seu repositório de manifestos (ex: `git@github.com:seu-usuario/meu-projeto-manifests.git`).
    -   **Path:** `.` (um ponto, para indicar a raiz do repositório).

4.  Finalmente, na seção **DESTINATION**, defina onde a aplicação será implantada:
    -   **Cluster:** `https://kubernetes.default.svc`
    -   **Namespace:** `default`

5.  Clique em **CREATE** no topo da página.

Após a criação, o ArgoCD começará o processo de sincronização. Aguarde até que o status da aplicação mude para **Healthy** ✅ e **Synced** ✅.

## 🧪 6. Testar a Aplicação Local

Para validar que a última versão da sua aplicação está rodando corretamente no cluster, vamos criar um túnel de comunicação seguro entre sua máquina e o serviço no Kubernetes.

**1. Crie o Port-Forward**

Execute o comando abaixo no seu terminal. Ele irá redirecionar todo o tráfego da porta `8081` da sua máquina local para a porta `80`.

```bash
kubectl port-forward svc/*NOME DO SEU CLUSTER* -n default 8081:80
e acesse a porta 81:
```bash
http://localhost:8081/
```
<img width="337" height="129" alt="Image" src="https://github.com/user-attachments/assets/542c3a69-ca73-496c-8ec0-a7011b7996cf" />
