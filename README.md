# 행운의 십계명 카드 (Lucky Ten Commandments)

매일매일 새로운 지혜와 영감을 제공하는 다국어 지원 Flutter 앱입니다.

## 📱 앱 소개

행운의 십계명 카드는 사용자가 매일 하나의 카드를 뽑아 인생의 지혜와 실천 과제를 받을 수 있는 앱입니다. 각 카드에는 실천 제목, 스토리, 그리고 자기 성찰을 위한 질문이 포함되어 있습니다.

## ✨ 주요 기능

### 🎯 카드 시스템
- **랜덤 카드 뽑기**: 매일 새로운 십계명 카드를 랜덤으로 제공
- **다국어 지원**: 한국어, 영어, 일본어, 중국어, 스페인어 지원
- **오늘의 실천**: 실천 제목, 스토리, 성찰 질문으로 구성

### ✍️ 메모 시스템
- **개인 메모**: 카드 내용에 대한 개인적인 생각과 실천 기록
- **메모 저장**: 날짜별로 메모를 저장하고 관리
- **메모 조회**: 과거 작성한 메모들을 모아보기

### 📊 사용자 통계
- **연속 접속일**: 매일 꾸준히 접속한 일수 추적
- **전체 접속 횟수**: 총 앱 사용 횟수 기록
- **사용 통계**: 개인 사용 패턴 분석

### 🔔 알림 시스템
- **매일 알림**: 설정한 시간에 십계명 확인 알림
- **리마인더 설정**: 개인 맞춤 시간 설정 가능

### 🌐 커뮤니티 기능
- **커뮤니티 메모**: 다른 사용자들과 경험 공유 (선택적)

## 🛠️ 기술 스택

- **Framework**: Flutter (Dart)
- **Database**: Supabase
- **상태 관리**: SharedPreferences
- **로깅**: Logger
- **환경 설정**: flutter_dotenv
- **다국어 지원**: 커스텀 JSON 기반 로케일라이제이션

## 🌍 지원 언어

- 🇰🇷 한국어 (Korean)
- 🇺🇸 영어 (English)
- 🇯🇵 일본어 (Japanese)
- 🇨🇳 중국어 (Chinese)
- 🇪🇸 스페인어 (Spanish)

## 🚀 시작하기

### 필요 조건

- Flutter SDK (3.0.0 이상)
- Dart SDK (3.7.2 이상)
- Android Studio / VS Code
- Supabase 계정 및 프로젝트

### 설치 및 실행

1. **저장소 클론**
   ```bash
   git clone <repository-url>
   cd Apple_Multi_lucky_ten_commandments
   ```

2. **의존성 설치**
   ```bash
   flutter pub get
   ```

3. **환경 설정**
   - 프로젝트 루트에 `.env` 파일 생성
   ```env
   SUPABASE_URL=your_supabase_url
   SUPABASE_ANON_KEY=your_supabase_anon_key
   ```

4. **앱 실행**
   ```bash
   flutter run
   ```

### 빌드하기

**Android APK 빌드**
```bash
flutter build apk --release
```

**iOS 빌드**
```bash
flutter build ios --release
```

**Web 빌드**
```bash
flutter build web
```

## 📋 데이터베이스 구조

### multilang_cards 테이블
- `id`: 카드 고유 번호
- `title_[언어코드]`: 각 언어별 제목
- `story_[언어코드]`: 각 언어별 스토리
- `q1_[언어코드]`, `q2_[언어코드]`: 각 언어별 질문

## 🎨 앱 아이콘

앱 아이콘은 `assets/images/app_icon.png`에서 관리되며, 다양한 플랫폼에 맞게 자동 생성됩니다.

## 📄 라이센스

이 프로젝트는 개인 프로젝트로 제작되었습니다.

## 🤝 기여하기

버그 리포트나 기능 제안은 언제든지 환영합니다!

## 📞 문의

프로젝트에 대한 문의사항이 있으시면 이슈를 통해 연락해 주세요.

---

**매일 새로운 지혜와 함께하는 행운의 십계명 카드를 경험해보세요! 🍀**