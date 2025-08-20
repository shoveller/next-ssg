# 사용 설명
- 최신 next.js를 ssg에 최적화해서 인스톨하는 쉘 스크립트입니다.    
- 레시피는 `PROCESS.md`에 적어 두었습니다.  

# 셀프호스팅을 할 때 참고할 수 있는 문서
- `LOCAL_CACHE.md` 에 vercel 의 캐시를 로컬에서 확인하는 방법을 적어 두었습니다.     
- `NEXT_FETCH.md` 에 서버에서 fetch 할때 캐시하는 방법을 적어 두었습니다.  
- `IMAGE_PROCESS.md` 에 이미지 최적화 기능을 셀프 호스팅 서버에서 사용하는 방법을  적어 두었습니다.  

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