# 로그인 기능 구현 가이드

## 개요
Flutter 앱에 로그인 관련 화면과 API 연동 기능이 구현되었습니다.

## 구현된 기능

### 1. 화면
- **휴대폰 번호 입력 화면** (`lib/screens/auth/phone_input_screen.dart`)
  - 전화번호 입력 및 자동 포맷팅 (010-1234-5678)
  - 인증번호 발송 요청
  
- **인증번호 입력 화면** (`lib/screens/auth/verification_code_screen.dart`)
  - 6자리 인증번호 입력 (각 자리별 개별 입력 필드)
  - 3분 타이머 및 재전송 기능
  - 인증 완료 후 자동으로 로그인 또는 회원가입 플로우로 이동

- **회원 타입 선택 화면** (`lib/screens/auth/user_type_selection_screen.dart`)
  - 일반 회원 / 사업자 선택
  - 신규 가입 시에만 표시

- **회원가입 화면** (`lib/screens/auth/register_screen.dart`)
  - 닉네임 입력 (선택)
  - 회원가입 완료

### 2. API 서비스
- 인증번호 발송 (`/auth/phone/send`)
- 인증번호 재전송 (`/auth/phone/resend`)
- 인증번호 검증 (`/auth/phone/verify`)
- 로그인 (`/auth/login`)
- 회원가입 (`/auth/register`)
- 로그아웃 (`/auth/logout`)

### 3. 상태 관리
- `AuthProvider`: 인증 상태 관리 (Provider 패턴 사용)
- JWT 토큰 자동 저장 및 관리 (`flutter_secure_storage`)

## 설정 방법

### 1. 패키지 설치
터미널에서 다음 명령어를 실행하세요:
```bash
flutter pub get
```

### 2. API URL 설정
`lib/config/api_config.dart` 파일을 열어서 실제 API 서버 URL로 변경하세요:

```dart
static const String baseUrl = 'http://your-api-url.com/api';
```

예시:
- 로컬 개발: `'http://localhost:8000/api'`
- 프로덕션: `'https://api.starttoo.com/api'`

### 3. Android 네트워크 보안 설정
Android에서 HTTP를 사용하는 경우, `android/app/src/main/AndroidManifest.xml`에 다음을 추가하세요:

```xml
<application
    android:usesCleartextTraffic="true"
    ...>
```

## 사용 방법

### 앱 실행
```bash
flutter run
```

### 로그인 플로우
1. 앱 실행 시 자동으로 휴대폰 번호 입력 화면이 표시됩니다
2. 휴대폰 번호 입력 후 "인증번호 받기" 버튼 클릭
3. 인증번호 입력 화면에서 6자리 인증번호 입력
4. 기존 사용자: 자동 로그인 후 홈 화면으로 이동
5. 신규 사용자: 회원 타입 선택 → 회원가입 정보 입력 → 홈 화면으로 이동

## 프로젝트 구조

```
lib/
├── config/
│   └── api_config.dart          # API 설정
├── models/
│   ├── api_response.dart         # API 응답 모델
│   └── auth_response.dart        # 인증 응답 모델
├── providers/
│   └── auth_provider.dart        # 인증 상태 관리
├── screens/
│   ├── auth/
│   │   ├── phone_input_screen.dart
│   │   ├── verification_code_screen.dart
│   │   ├── user_type_selection_screen.dart
│   │   └── register_screen.dart
│   └── home_screen.dart          # 홈 화면
├── services/
│   └── auth_service.dart         # 인증 API 서비스
└── utils/
    ├── api_client.dart           # HTTP 클라이언트 (Dio)
    └── phone_formatter.dart      # 전화번호 포맷팅 유틸리티
```

## 주요 기능 설명

### JWT 토큰 자동 관리
- 로그인 성공 시 자동으로 토큰 저장
- API 요청 시 자동으로 Authorization 헤더에 토큰 추가
- 401 에러 시 자동으로 토큰 리프레시 시도
- 로그아웃 시 토큰 삭제

### 전화번호 포맷팅
- 입력 시 자동으로 `010-1234-5678` 형식으로 포맷팅
- 숫자만 추출하여 API에 전송

### 인증번호 입력 UX
- 6개의 개별 입력 필드로 구성
- 자동 포커스 이동 (입력 시 다음 필드로, 삭제 시 이전 필드로)
- 6자리 모두 입력 시 자동으로 검증 요청

## API 응답 형식

API는 다음 형식으로 응답해야 합니다:

### 성공 응답
```json
{
  "success": true,
  "message": "성공 메시지",
  "data": {
    "access_token": "jwt_token",
    "refresh_token": "refresh_token",
    "user": {
      "id": 1,
      "nickname": "사용자명",
      "phone": "01012345678",
      "user_type": 1
    },
    "is_existing_user": true,
    "verification_token": "verification_token"
  }
}
```

### 실패 응답
```json
{
  "success": false,
  "message": "에러 메시지"
}
```

## 주의사항

1. **API URL 설정**: 반드시 `lib/config/api_config.dart`에서 실제 API URL로 변경하세요
2. **HTTPS 사용 권장**: 프로덕션 환경에서는 HTTPS를 사용하세요
3. **에러 처리**: API 응답 구조가 다를 경우 `lib/services/auth_service.dart`를 수정하세요
4. **토큰 리프레시**: `/auth/refresh` API의 요청 형식이 다를 경우 `lib/utils/api_client.dart`의 `_refreshToken` 메서드를 수정하세요

## 다음 단계

- [ ] 사업자 추가 정보 입력 화면 구현
- [ ] 프로필 수정 화면 구현
- [ ] 자동 로그인 기능 개선 (토큰으로 사용자 정보 가져오기)
- [ ] 에러 처리 개선
- [ ] 로딩 상태 UI 개선

