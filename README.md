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

Crie um repositório Git para a aplicação (`hello-app`) e adicione o arquivo `main.py`:

```python
from fastapi import FastAPI

app = FastAPI()

@app.get("/")
async def root():
    return {"message": "Hello World"}
```
