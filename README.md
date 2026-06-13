# Healthcare Tracker Mobile - Menu UI Version

모바일 화면에서 한 번에 모든 기능이 길게 표시되지 않도록, 메인 화면을 아이콘 메뉴형 UI로 수정한 버전입니다.

## 실행 방법

```bash
cd mobile_app
flutter clean
flutter pub get
flutter run -d emulator-5554
```

## APK 생성

```bash
cd mobile_app
flutter build apk --release
```

APK 위치:

```text
mobile_app/build/app/outputs/flutter-apk/app-release.apk
```

## 변경 내용

- 메인 화면을 기능별 아이콘 버튼 메뉴로 변경
- 운동 기록, 식단 관리, 목표 설정, 웨어러블, 리포트, AI 추천, 알림, 개인정보 화면 분리
- 각 기능에 맞는 Material 아이콘 적용
- 저장 기능은 SharedPreferences 기반으로 유지
- 그래프 Y축 숫자 겹침 수정
