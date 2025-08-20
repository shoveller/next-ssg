# nextjs의 이미지 최적화 셀프호스팅

기본적으로 Next.js는 `squoosh`라는 라이브러리를 사용하여 이미지를 처리하지만, 프로덕션 환경의 셀프호스팅에서는 더 고성능인 `sharp` 라이브러리를 설치하여 사용하는 것이 좋다.   
`sharp`가 프로젝트에 설치되어 있으면 Next.js가 이를 자동으로 감지하여 이미지 최적화에 사용한다.
이 문서에서는 `sharp` 라이브러리를 설치하고, `standalone` 출력 모드를 사용하여 최적화된 Docker 이미지를 빌드하는 전체 과정을 안내한다.

---

### 1단계: `sharp` 라이브러리 설치

먼저, 이미지 처리를 위해 `sharp` 라이브러리를 프로젝트의 의존성으로 추가한다.  

```bash
npm install sharp
# 또는
yarn add sharp
# 또는
pnpm add sharp
```

---

### 2단계: `next.config.js` 설정

Docker 이미지를 최소한의 크기로 빌드하고 배포를 용이하게 하기 위해 `next.config.js` 파일에 `output: 'standalone'` 옵션을 추가한다.  
이 설정은 빌드 시 `.next/standalone` 폴더에 필요한 파일만 모아준다.  

**`next.config.js`**
```javascript
/** @type {import('next').NextConfig} */
const nextConfig = {
  // ... 다른 설정들
  output: 'standalone',
};

module.exports = nextConfig;
```

---

### 3단계: 최적화된 `Dockerfile` 작성

프로덕션 배포를 위한 효율적인 멀티-스테이지(multi-stage) `Dockerfile`을 작성한다.   
이 Dockerfile은 의존성 설치, 애플리케이션 빌드, 그리고 최종 실행 단계를 분리하여 이미지 크기를 최소화하고 빌드 캐시를 효율적으로 사용한다.  

**`Dockerfile`**
```dockerfile
# 1. 기본 이미지 설정 (Base Image)
# - - - - - - - - - - - - - - - - - - - - - - -
FROM node:18-alpine AS base

# 2. 의존성 설치 단계 (Dependencies)
# - - - - - - - - - - - - - - - - - - - - - - -
FROM base AS deps
WORKDIR /app

# package.json과 lock 파일을 먼저 복사하여 캐시 활용
COPY package.json yarn.lock* package-lock.json* pnpm-lock.yaml* ./
RUN \
  if [ -f yarn.lock ]; then yarn install --frozen-lockfile; \
  elif [ -f package-lock.json ]; then npm ci; \
  elif [ -f pnpm-lock.yaml ]; then corepack enable && pnpm i --frozen-lockfile; \
  else echo "Lockfile not found." && exit 1; \
  fi

# 3. 빌드 단계 (Builder)
# - - - - - - - - - - - - - - - - - - - - - - -
FROM base AS builder
WORKDIR /app
COPY --from=deps /app/node_modules ./node_modules
COPY . .

# Next.js가 sharp를 감지할 수 있도록 환경 변수 설정
ENV NEXT_SHARP_PATH=/app/node_modules/sharp

# pnpm 활성화 및 애플리케이션 빌드
RUN corepack enable && pnpm build

# 4. 최종 실행 단계 (Runner)
# - - - - - - - - - - - - - - - - - - - - - - -
FROM base AS runner
WORKDIR /app

# 프로덕션 환경 설정
ENV NODE_ENV=production
# Next.js가 sharp를 감지할 수 있도록 환경 변수 설정
ENV NEXT_SHARP_PATH=/app/node_modules/sharp

# nextjs 사용자 생성 (보안을 위해 non-root 사용자 사용)
RUN addgroup -g 1001 -S nodejs
RUN adduser -S nextjs -u 1001

# standalone 모드에서 생성된 파일들을 복사
COPY --from=builder /app/public ./public
COPY --from=builder --chown=nextjs:nodejs /app/.next/standalone ./
COPY --from=builder --chown=nextjs:nodejs /app/.next/static ./.next/static

# sharp 모듈이 standalone 출력에 포함되지 않을 수 있으므로 명시적으로 복사
# (Next.js 버전에 따라 필요 없을 수도 있지만, 안정성을 위해 추가)
COPY --from=builder /app/node_modules/sharp ./node_modules/sharp

# nextjs 사용자로 실행
USER nextjs

# 서버 실행 (기본 포트 3000)
CMD ["node", "server.js"]
```

---

### 4단계: Docker 이미지 빌드 및 실행

작성한 `Dockerfile`을 사용하여 이미지를 빌드하고 컨테이너를 실행한다.

```bash
# 1. Docker 이미지 빌드
docker build -t my-next-app .

# 2. Docker 컨테이너 실행
# -p 3000:3000: 호스트의 3000번 포트를 컨테이너의 3000번 포트와 매핑
docker run -p 3000:3000 my-next-app
```

이제 브라우저에서 `http://localhost:3000`으로 접속하면, `next/image`로 렌더링된 이미지들이 `sharp`를 통해 최적화되어 제공되는 것을 확인할 수 있다.

---

### 요약

1.  **`sharp` 설치**: 고성능 이미지 최적화를 위해 `sharp`를 프로젝트에 추가한다.
2.  **`output: 'standalone'` 설정**: `next.config.js`에 이 옵션을 추가하여 Docker에 최적화된 빌드 결과물을 생성한다.
3.  **멀티-스테이지 `Dockerfile` 작성**: 효율적인 캐싱과 최소한의 이미지 크기를 위해 빌드 단계를 분리한다.
4.  **빌드 및 실행**: `docker build`와 `docker run` 명령어로 애플리케이션을 실행한다.

위 단계를 따르면 셀프호스팅 환경에서도 Next.js의 이미지 최적화 기능을 완벽하게 활용할 수 있다.