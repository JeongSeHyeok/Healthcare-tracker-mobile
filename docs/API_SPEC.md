# API 명세 요약

| 구분 | Method | URL | 설명 |
|---|---:|---|---|
| Auth | POST | `/api/auth/register` | 회원가입 |
| Auth | POST | `/api/auth/login` | 로그인/JWT 발급 |
| Auth | GET | `/api/auth/me` | 내 정보 조회 |
| Dashboard | GET | `/api/dashboard` | 운동/영양/목표/웨어러블 요약 |
| Exercise | POST | `/api/exercises` | 운동 기록 + 칼로리 계산 |
| Exercise | GET | `/api/exercises` | 운동 기록 조회 |
| Exercise | DELETE | `/api/exercises/{id}` | 운동 기록 삭제 |
| Nutrition | POST | `/api/nutrition` | 식단 입력 |
| Nutrition | GET | `/api/nutrition` | 식단 조회 |
| Nutrition | DELETE | `/api/nutrition/{id}` | 식단 삭제 |
| Goal | POST | `/api/goals` | 목표 생성 |
| Goal | PUT | `/api/goals/{id}` | 목표 진행률 수정 |
| Wearable | POST | `/api/wearable/simulate` | 웨어러블 데이터 시뮬레이션 |
| AI | GET | `/api/recommendations` | AI 추천 메시지 |
| Notification | GET | `/api/notifications` | 알림 목록 |
| Privacy | POST | `/api/privacy/consent` | 개인정보 동의/철회 |
| Privacy | GET | `/api/privacy/download` | 내 데이터 다운로드 |
| Privacy | DELETE | `/api/privacy/delete` | 건강 데이터 삭제 |

Swagger 문서: `http://localhost:5000/docs`
