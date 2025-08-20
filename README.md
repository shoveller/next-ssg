# 설명
- 최신 next.js를 ssg에 최적화해서 인스톨하는 쉘 스크립트입니다.  
- 자세한 레시피는 `PROCESS.md`를 참조하세요.

---

# 사용법
## 다운로드
```shell
curl https://github.com/shoveller/next-ssg/raw/main/install.sh
```

## 실행권한 부여
```shell
chmod +x install.sh
```

## 설치
```shell
./install.sh
```

---

# 주의사항
⚠️ 스토리북 설치 후 수동으로 다음 작업을 진행해주세요:
1. onboarding 패키지 삭제
2. 모바일 뷰포트 설정 추가
3. `src/stories` 아래의 불필요한 스토리 파일 정리

⚠️ 센트리 설치 후 수동으로 다음 파일을 삭제해주세요.
- sentry.edge.config.ts
- sentry.server.config.ts
- src/instrumentation.ts