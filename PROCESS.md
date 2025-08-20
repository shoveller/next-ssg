# 프로세스
- 이 cli 는 아래의 순서를 구현한다.

## 1. 스케폴딩
- [create-next-app](https://nextjs.org/docs/app/api-reference/cli/create-next-app) 패키지를 사용헤서 인스톨한다.
    - typescript, eslint 사용으로 설정한다
    - 가능하다면 tailwindcss 사용을 설정한다.
```sh
pnpm create next-app@latest
```

- 아니라면 최소한 sass 를 설치해서 css module 정도는 사용하도록 한다.
  https://nextjs.org/docs/app/guides/sass

## 2. output 옵션을 설정
- 이 설정이 `next export` 명령을 대신한다.
```ts
// next.config.ts
import type { NextConfig } from 'next'

const nextConfig: NextConfig = {
    output: 'export'
}

export default nextConfig
```

## 3. tsconfig , prettier, eslint, husky 설정
1. `tsconfig.json`
    - [[메타 프레임워크의 tsconfig 설정 정리(2025년 8월 4일)]]
2. prettier
    - [[메타 프레임워크의 prettier 설정 정리(2025년 8월 4일)]]
3. eslint
    - [[메타 프레임워크의 eslint 설정 정리(2025년 8월 4일)]]
4. husky
    - [[싱글 레파지토리용 husky 설정 정리(2025년 8월 4일)]]

## 4. 스토리북 설치
- 별다른 제어가 없어도 오피셜 플러그인을 사용해서 스무스하게 통합된다.
    - react router v7이 아직도 서드파티에 의존하는 것에 비하면큰 차이가 있다.
- 서버 컴포넌트도 클라이언트 컴포넌트도 별다른 설정 없이 통합이 된다.
    - 역시 유저가 많을수록 문제 해결이 빠르고 지원 범위가 넒다.
```sh
pnpm create storybook@latest
```
- 설치 후에 아래의 추가 작업을 한다.
    1. onboarding 패키지 삭제
    2. 모바일 레이아웃 추가
        1. [뷰포트 설정](https://storybook.js.org/docs/essentials/viewport)
    3. 불필요한 스토리 삭제

## 5. 폰트 설치
- [Nanum Square 를 다운로드](https://github.com/moonspam/NanumSquare) 해서 `public/fonts` 디렉토리에 추가한다.
- Nanum Square는 Google Fonts가 제공하지 않는다. 따라서 `next/font/google` 을 사용할 수 없고, `next/font/local` 을 사용해야 한다.
```ts
// app/fonts.ts (폰트 정의 파일)

import localFont from 'next/font/local'

export const nanumSquare = localFont({
  src: [
    {
      path: '../public/fonts/NanumSquare-Light.woff2',
      weight: '300',
      style: 'normal',
    },
    {
      path: '../public/fonts/NanumSquare-Regular.woff2',
      weight: '400',
      style: 'normal',
    },
    {
      path: '../public/fonts/NanumSquare-Bold.woff2',
      weight: '700',
      style: 'normal',
    },
  ],
  variable: '--font-nanum-square',
  display: 'swap',
  fallback: ['system-ui', 'sans-serif'],
})
```

- 루트 레이아웃애 적용한다.
```typescript
// app/layout.tsx
import { nanumSquare } from './fonts'

export default function RootLayout({
  children,
}: {
  children: React.ReactNode
}) {
  return (
    <html lang="ko" className={nanumSquare.variable}>
      <body className={nanumSquare.className}>
        {children}
      </body>
    </html>
  )
}
```

## 6. 추가 타입 정의
- 타입스크립트를 위한 타입 정의는 추가해야 한다.
  `src/types/css.d.ts`
```ts
// src/types/css.d.ts
declare module '*.css' {
  const styles: { [key: string]: string };
  export default styles;
}

declare module '*.scss' {
  const styles: { [key: string]: string };
  export default styles;
}

declare module '*.sass' {
  const styles: { [key: string]: string };
  export default styles;
}

declare module '*.less' {
  const styles: { [key: string]: string };
  export default styles;
}

declare module '*/globals.css' {
  const styles: any;
  export default styles;
}
```

## 7. 센트리 통합
- 센트리 위자드를 실행하면 vercel 인프라를 간접적으로 이해하게된다.
    - vercel 인프라에 최적화된 로깅 시스템을 스케폴드하기 때문이다.
```sh
 pnpx @sentry/wizard@latest -i nextjs
```

- 위자드를 실행하면 센트리 초기화 모듈을 총 4개 만든다.
    - `src/instrumentation.ts` : 런타임에 따라 센트리 초기화
        - `sentry.edge.config.ts` : 엣지 런타임에서 센트리 초기화
        - `sentry.server.config.ts` : vercel functions 에서 센트리 초기화
    - `src/instrumentation-client.ts` : 클라이언트 사이드 센트리 초기화
- ssg 상황에서는 `src/@instrumentation-client.ts` 만 사용하면 된다.
```ts
import {withSentryConfig} from '@sentry/nextjs';

export default withSentryConfig({
    output: 'export' // SSG (Static Site Generation) 모드로 정적 파일 생성
}, {
    // Sentry webpack 플러그인 설정 옵션들
    // 자세한 옵션: https://www.npmjs.com/package/@sentry/webpack-plugin#options
    org: "illuwa-soft",
    project: "javascript",
    // Sentry SDK 내부 로거를 번들에서 제거하여 크기 최적화
    disableLogger: true,
    // 소스맵 관련 설정
    sourcemaps: {
        // 소스맵 업로드 활성화 (에러 추적을 위해 필요)
        disable: false,
        // 업로드할 파일 지정
        assets: ["**/*.js", "**/*.js.map"],
        // node_modules는 제외
        ignore: ["**/node_modules/**"],
        // 업로드 후 소스맵 파일 삭제 (보안을 위해 권장)
        deleteSourcemapsAfterUpload: true,
    },
});
```

## 9. swagger api 클라이언트 통합
- fetch 구현에 기반한  [ky](https://github.com/sindresorhus/ky) 와 [acacode/swagger-typescript-api](https://github.com/acacode/swagger-typescript-api) 를 사용해서 api 계층을 만든다
    - 사실 둘 중에 하나만 사용해도 캐시가 동작하지만, [ky](https://github.com/sindresorhus/ky) 를 사용해야 명시적으로 인터셉터를 사용할 수 있다.
```sh
pnpm i ky	
```

- 아래의 npm script 는 [acacode/swagger-typescript-api](https://github.com/acacode/swagger-typescript-api) 로  [pokeapi swagger](https://raw.githubusercontent.com/oapicf/pokeapi-clients/refs/heads/main/specification/pokeapi.yml) 를 클라이언트로 만든다.
```json
{
  "scripts": {
     "api": "pnpx swagger-typescript-api generate --path https://raw.githubusercontent.com/PokeAPI/pokeapi/refs/heads/master/openapi.yml -o ./src/api"
   }
}
```

- ky 와 swagger sdk 는 아래와 같이 통합한다.
```ts
import { Api } from "@/api/Api";
import ky from "ky";

const customFetch = ky.create({
  hooks: {
    beforeRequest: [(req) => {
      console.log(`req 인터셉트`);
    }],
    afterResponse: [(req, options, res) => {
      console.log('res 인터셉트')
      return res
    }],
  },
})

export const api = new Api({
  customFetch
})
```
