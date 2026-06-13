# 추천 역할 분담 3인 기준

## 팀원 A — 프론트엔드 & UI/UX 담당
### 맡을 기능
- Flutter 앱 화면 제작
- 로그인/회원가입 UI
- 운동 기록 화면
- 식단 입력 화면
- 목표 설정 화면
- 그래프/대시보드 화면
- 알림 UI

### 주요 기술
- Flutter
- Provider/Riverpod
- Chart 라이브러리(fl_chart 등)
- REST API 연동(Dio/http)

### 세부 산출물
- 화면 설계
- 공통 위젯
- API 연결 코드
- 앱 내비게이션 구조

## 팀원 B — 백엔드/API/DB 담당
### 맡을 기능
- FastAPI 서버 구축
- JWT 로그인 인증
- REST API 작성
- DB 설계 및 CRUD
- 사용자/운동/목표 기능 API
- 알림 기능 기본 구조

### 담당 서비스
- Auth Service
- User Service
- Exercise Service
- Goal Service
- Notification Service

### 주요 기술
- Python/FastAPI
- JWT 인증
- Swagger(API 문서)
- MongoDB Mock DB 구조

### 세부 산출물
- API 명세
- DB ERD
- 인증/인가
- 로그 처리
- 서버 배포 준비

## 팀원 C — AI 추천 / 데이터 분석 / 웨어러블 연동 담당
### 맡을 기능
- 칼로리 계산 알고리즘
- AI 추천 기능
- 웨어러블 연동 시뮬레이션
- MongoDB 데이터 처리
- 리포트/분석 기능

### 담당 서비스
- Nutrition Service
- AI Recommend Service
- Wearable API Adapter
- Report Service

### 핵심 구현 포인트
- 경사 기반 칼로리 계산
- 기초대사량 + 골격근량 기반 연산 알고리즘
- 걸음 수/심박수 mock wearable data 처리
- 운동/섭취/목표 달성률 리포트

### 주요 기술
- Python/FastAPI
- MongoDB Mock Data
- Pandas 선택 가능
- 간단 추천 알고리즘
- Wearable Mock Data
