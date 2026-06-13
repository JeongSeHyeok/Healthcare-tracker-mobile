def build_recommendation(today_exercise=0, today_nutrition=0, steps=0, heart_rate=0, bmr=1500):
    messages = []
    if today_exercise < 200:
        messages.append('오늘 운동 칼로리가 낮습니다. 20~30분 빠르게 걷기 또는 러닝머신을 추천합니다.')
    else:
        messages.append('오늘 운동량이 좋습니다. 스트레칭으로 마무리하세요.')
    if today_nutrition > bmr + 500:
        messages.append('섭취 칼로리가 높은 편입니다. 다음 식사는 단백질과 채소 중심으로 조절하세요.')
    else:
        messages.append('섭취 칼로리가 안정적입니다. 수분 섭취를 유지하세요.')
    if steps < 7000:
        messages.append('걸음 수가 부족합니다. 목표 달성을 위해 산책을 추가해보세요.')
    if heart_rate > 140:
        messages.append('심박수가 높습니다. 무리한 운동보다 휴식을 권장합니다.')
    return messages
