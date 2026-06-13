# Healthcare Tracker Mobile 개선판

## 반영 내용
- 로그인/회원가입 화면 제거: 앱 실행 시 바로 메인 기능 메뉴로 이동
- 뒤로가기 개선: 하위 기능 화면에서는 뒤로가기 시 메인으로 복귀, 메인에서는 종료 확인창 표시
- 개인정보 활용 동의 개선: 세부내용 확인 팝업 추가
- 운동 칼로리와 웨어러블 걸음 수 누적 합산 표시
- 날짜별 리포트: 최근 7일 그래프, 선택 날짜 표 조회
- AI 챗봇: OpenAI API Key 입력 시 ChatGPT API 호출, 키가 없으면 로컬 추천으로 동작
- 운동 선택 드롭다운: 러닝머신, 걷기, 실내 자전거, 줄넘기, 웨이트, 스쿼트, 푸시업, 요가, 직접입력 지원
- 운동 종류별로 시간/강도/세트/횟수/거리 입력 항목을 다르게 표시

## 실행
```bash
cd healthcare-tracker-mobile/mobile_app
flutter clean
flutter pub get
flutter run -d emulator-5554
```

## 갤럭시용 APK 빌드
```bash
flutter build apk --release --target-platform android-arm64
```

생성 파일:
`build/app/outputs/flutter-apk/app-release.apk`
