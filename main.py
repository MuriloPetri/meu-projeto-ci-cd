from fastapi import FastAPI
app = FastAPI()
@app.get("/")
async def root():
    # Testando o novo token de acesso
    return {"message": "Hello Compass!" }
