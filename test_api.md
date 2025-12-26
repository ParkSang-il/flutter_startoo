# API 연결 테스트 가이드

## 1단계: 호스트에서 API 접근 테스트

Windows PowerShell에서 실행:

```powershell
# GET 요청 테스트
Invoke-WebRequest -Uri "http://localhost:8000" -Method GET

# POST 요청 테스트 (인증번호 발송)
$body = @{
    phone = "01011111111"
} | ConvertTo-Json

Invoke-WebRequest -Uri "http://localhost:8000/api/auth/phone/send" -Method POST -Body $body -ContentType "application/json"
```

또는 curl 사용:
```bash
curl http://localhost:8000
curl -X POST http://localhost:8000/api/auth/phone/send -H "Content-Type: application/json" -d "{\"phone\":\"01011111111\"}"
```

## 2단계: 에뮬레이터에서 접근 테스트

Android 에뮬레이터의 브라우저에서:
- `http://10.0.2.2:8000` 접근 시도

## 3단계: Flutter 앱 로그 확인

앱 실행 후 콘솔에서 다음 로그 확인:
- 요청 URL
- 에러 메시지
- 응답 상태 코드

