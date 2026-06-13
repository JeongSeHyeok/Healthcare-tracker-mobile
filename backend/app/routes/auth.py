from fastapi import APIRouter, HTTPException, Depends
from ..schemas import RegisterRequest, LoginRequest
from ..db.json_mongo import insert, one, update, now
from ..core.security import hash_password, verify_password, create_token
from ..deps import current_user

router = APIRouter(prefix='/api/auth', tags=['Auth Service'])

@router.post('/register')
def register(body: RegisterRequest):
    if one('users', email=body.email):
        raise HTTPException(status_code=409, detail='이미 가입된 이메일입니다.')
    user = insert('users', {
        'email': body.email,
        'password': hash_password(body.password),
        'name': body.name,
        'age': body.age,
        'height': body.height,
        'weight': body.weight,
        'bmr': body.bmr,
        'muscle_mass': body.muscleMass,
        'privacy_consent': False,
        'created_at': now()
    })
    return {'message': '회원가입 완료', 'userId': user['id']}

@router.post('/login')
def login(body: LoginRequest):
    user = one('users', email=body.email)
    if not user or not verify_password(body.password, user['password']):
        raise HTTPException(status_code=401, detail='이메일 또는 비밀번호가 올바르지 않습니다.')
    token = create_token(user['id'], user['email'])
    return {'token': token, 'user': public_user(user)}

@router.get('/me')
def me(user=Depends(current_user)):
    return public_user(user)

def public_user(user):
    return {
        'id': user['id'], 'email': user['email'], 'name': user.get('name'),
        'age': user.get('age'), 'height': user.get('height'), 'weight': user.get('weight'),
        'bmr': user.get('bmr'), 'muscleMass': user.get('muscle_mass'),
        'privacyConsent': user.get('privacy_consent', False)
    }
