from datetime import date
from fastapi import APIRouter, Depends, HTTPException
from ..deps import current_user
from ..schemas import ExerciseRequest, NutritionRequest, GoalRequest, GoalUpdateRequest, WearableRequest, PrivacyConsentRequest
from ..db.json_mongo import insert, find, update, delete, delete_by_user, now
from ..services.calorie import calculate_exercise_calories
from ..services.recommend import build_recommendation
from ..services.wearable import normalize_wearable_payload

router = APIRouter(prefix='/api', tags=['Healthcare Services'])

def today_str():
    return date.today().isoformat()

def _user_rows(collection, user_id):
    return find(collection, user_id=user_id)

def dashboard_payload(user):
    uid = user['id']; today = today_str()
    exercises = _user_rows('exercises', uid)
    nutrition = _user_rows('nutrition', uid)
    goals = _user_rows('goals', uid)
    wearable_logs = _user_rows('wearable_logs', uid)
    chart_map = {}
    for e in exercises:
        chart_map[e['exercise_date']] = chart_map.get(e['exercise_date'], 0) + int(e['calories'])
    chart = [{'date': k, 'calories': v} for k, v in sorted(chart_map.items())[-14:]]
    for g in goals:
        target = float(g.get('target_value') or 1)
        g['progress'] = round(float(g.get('current_value') or 0) / target * 100, 1)
    return {
        'exercises': sorted(exercises, key=lambda r: r.get('created_at',''), reverse=True)[:20],
        'nutrition': sorted(nutrition, key=lambda r: r.get('intake_time',''), reverse=True)[:20],
        'goals': goals,
        'wearable': sorted(wearable_logs, key=lambda r: r.get('logged_at',''), reverse=True)[0] if wearable_logs else None,
        'todayExercise': sum(int(e['calories']) for e in exercises if e['exercise_date'] == today),
        'todayNutrition': sum(int(n['calories']) for n in nutrition if str(n.get('intake_time','')).startswith(today)),
        'chart': chart
    }

@router.get('/dashboard')
def dashboard(user=Depends(current_user)):
    return dashboard_payload(user)

@router.post('/exercises')
def create_exercise(body: ExerciseRequest, user=Depends(current_user)):
    calories = calculate_exercise_calories(user.get('weight'), body.duration, body.speed, body.incline, user.get('bmr'), user.get('muscle_mass'))
    row = insert('exercises', {
        'user_id': user['id'], 'type': body.type, 'duration': body.duration,
        'speed': body.speed, 'incline': body.incline, 'calories': calories,
        'exercise_date': body.exerciseDate or today_str(), 'created_at': now()
    })
    return {'exerciseId': row['id'], 'calories': calories}

@router.get('/exercises')
def list_exercises(user=Depends(current_user)):
    return _user_rows('exercises', user['id'])

@router.delete('/exercises/{exercise_id}')
def delete_exercise(exercise_id: str, user=Depends(current_user)):
    if not delete('exercises', exercise_id, user['id']):
        raise HTTPException(404, '운동 기록을 찾을 수 없습니다.')
    return {'message': '운동 기록 삭제 완료'}

@router.post('/nutrition')
def create_nutrition(body: NutritionRequest, user=Depends(current_user)):
    row = insert('nutrition', {'user_id': user['id'], 'food_name': body.foodName, 'calories': body.calories, 'intake_time': now()})
    return {'nutritionId': row['id']}

@router.get('/nutrition')
def list_nutrition(user=Depends(current_user)):
    return _user_rows('nutrition', user['id'])

@router.delete('/nutrition/{nutrition_id}')
def delete_nutrition(nutrition_id: str, user=Depends(current_user)):
    if not delete('nutrition', nutrition_id, user['id']):
        raise HTTPException(404, '식단 기록을 찾을 수 없습니다.')
    return {'message': '식단 삭제 완료'}

@router.post('/goals')
def create_goal(body: GoalRequest, user=Depends(current_user)):
    row = insert('goals', {'user_id': user['id'], 'goal_type': body.goalType, 'target_value': body.targetValue, 'current_value': body.currentValue})
    return {'goalId': row['id']}

@router.put('/goals/{goal_id}')
def update_goal(goal_id: str, body: GoalUpdateRequest, user=Depends(current_user)):
    row = update('goals', goal_id, user['id'], {'current_value': body.currentValue})
    if not row:
        raise HTTPException(404, '목표를 찾을 수 없습니다.')
    return {'message': '목표 진행률 수정 완료'}

@router.post('/wearable/simulate')
def simulate_wearable(body: WearableRequest, user=Depends(current_user)):
    payload = normalize_wearable_payload(body.steps, body.heartRate)
    row = insert('wearable_logs', {'user_id': user['id'], **payload, 'logged_at': now()})
    return {'logId': row['id'], **payload}

@router.get('/recommendations')
def recommendations(user=Depends(current_user)):
    data = dashboard_payload(user)
    wearable = data.get('wearable') or {}
    return {'recommendations': build_recommendation(data['todayExercise'], data['todayNutrition'], wearable.get('steps',0), wearable.get('heart_rate',0), user.get('bmr',1500))}

@router.get('/notifications')
def notifications(user=Depends(current_user)):
    for g in _user_rows('goals', user['id']):
        if float(g.get('current_value') or 0) < float(g.get('target_value') or 0):
            insert('notifications', {'user_id': user['id'], 'message': f"{g.get('goal_type')} 목표가 아직 미달입니다. 현재 {g.get('current_value')}/{g.get('target_value')}", 'is_read': False, 'created_at': now()})
    return sorted(_user_rows('notifications', user['id']), key=lambda r: r.get('created_at',''), reverse=True)[:10]

@router.post('/privacy/consent')
def privacy_consent(body: PrivacyConsentRequest, user=Depends(current_user)):
    update('users', user['id'], None, {'privacy_consent': body.consent})
    return {'message': '개인정보 동의 상태가 저장되었습니다.'}

@router.get('/privacy/download')
def privacy_download(user=Depends(current_user)):
    uid = user['id']
    safe_user = {k:v for k,v in user.items() if k != 'password'}
    return { 'user': safe_user, 'exercises': _user_rows('exercises', uid), 'nutrition': _user_rows('nutrition', uid), 'goals': _user_rows('goals', uid), 'wearable': _user_rows('wearable_logs', uid) }

@router.delete('/privacy/delete')
def privacy_delete(user=Depends(current_user)):
    for collection in ['exercises','nutrition','goals','wearable_logs','notifications']:
        delete_by_user(collection, user['id'])
    return {'message': '사용자 건강 데이터가 삭제되었습니다.'}
