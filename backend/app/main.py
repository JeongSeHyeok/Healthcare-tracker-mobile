from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from .routes.auth import router as auth_router
from .routes.app import router as app_router

app = FastAPI(title='Healthcare Tracker API', description='운동/영양/목표/웨어러블 시뮬레이션 REST API', version='2.0.0')
app.add_middleware(CORSMiddleware, allow_origins=['*'], allow_credentials=True, allow_methods=['*'], allow_headers=['*'])
app.include_router(auth_router)
app.include_router(app_router)

@app.get('/')
def root():
    return {'message': 'Healthcare Tracker FastAPI 서버 정상 작동', 'docs': '/docs'}
