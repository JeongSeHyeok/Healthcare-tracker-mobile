from fastapi import Depends, HTTPException
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from .core.security import decode_token
from .db.json_mongo import one

bearer = HTTPBearer()

def current_user(credentials: HTTPAuthorizationCredentials = Depends(bearer)):
    payload = decode_token(credentials.credentials)
    if not payload:
        raise HTTPException(status_code=401, detail='유효하지 않은 토큰입니다.')
    user = one('users', id=payload['sub'])
    if not user:
        raise HTTPException(status_code=401, detail='사용자를 찾을 수 없습니다.')
    return user
