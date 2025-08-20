# 프로세스
- 이 스크립트는 아래의 프로세스를 순차 구현한다.

## 1. next.js 인스톨
- [create-next-app](https://nextjs.org/docs/app/api-reference/cli/create-next-app) 패키지를 사용해서 인스톨한다.
    - typescript, eslint 사용으로 설정한다
    - 가능하다면 tailwindcss 사용을 설정한다.
```sh
pnpm create next-app@latest
```

- 아니라면 최소한 sass 를 설치해서 css module 정도는 사용하도록 한다.
  https://nextjs.org/docs/app/guides/sass

## 2. output 옵션, images.unoptimized 을 설정
- `output: 'export'`: ssg 모드로 빌드한다.
- `images.unoptimized: true`: cdn 레벨의 이미지 최적화를 사용하지 않는다.
```ts
// next.config.ts
import type { NextConfig } from 'next'

const nextConfig: NextConfig = {
    output: 'export', // ssg 모드로 빌드한다
    images: {
        unoptimized: true // cdn 레벨의 이미지 최적화를 사용하지 않는다
    }
}

export default nextConfig
```

## 3. tsconfig , prettier, eslint, husky 설정
### 1. `tsconfig.base.json` + `tsconfig.json`
    - `tsc` 는 컴파일러의 기능과 타입 체커의 기능을 모두 가지고 있다.
    - `tsc` 는 컴파일 속도가 느리다. 2025년 현 시점에서의 최신 레시피는 tsc 를 타입 체커로만 사용하는 것이다.
    - 타입스크립트 최신판에서는 tsc 를 go 언어로 다시 만든다고 하니 그때는 tsc 만으로 컴파일과 타입 체크를 동시에 할지도 모르겠다.

- 아래의 `tsconfig.base.json` 을 프로젝트 루트에 배치하고 사용하면 보일러플레이트 코드를 최소화할 수 있다.
```json
{
  "compilerOptions": {
    /* 컴파일 성능 최적화 */
    "skipLibCheck": true, // 라이브러리 타입 정의 파일 검사 건너뛰기 (빌드 속도 향상)
    "incremental": true, // 증분 컴파일 활성화 (이전 빌드 정보 재사용)
    "tsBuildInfoFile": "./node_modules/.cache/tsc/tsbuildinfo", // 증분 컴파일 정보 저장 위치

    /* 출력 제어 */
    "noEmit": true, // JavaScript 파일 생성하지 않음 (타입 검사만 수행)

    /* 엄격한 타입 검사 */
    "strict": true, // 모든 엄격한 타입 검사 옵션 활성화
    "noUnusedLocals": true, // 사용하지 않는 지역 변수 에러 처리
    "noUnusedParameters": true, // 사용하지 않는 함수 매개변수 에러 처리
    "noFallthroughCasesInSwitch": true, // switch문에서 break 누락 시 에러 처리
    "noUncheckedSideEffectImports": true, // 부작용이 있는 import 구문의 타입 검사 강화

    /* 구문 분석 최적화 */
    "erasableSyntaxOnly": true // TypeScript 고유 구문만 제거하고 JavaScript 호환성 유지
  }
}
```

- `tsconfig.json` 은 이렇게 업데이트 한다.
```json
{
  "extends": "./tsconfig.base.json",
  "compilerOptions": {
    "target": "ES2017",
    "lib": ["dom", "dom.iterable", "esnext"],
    "allowJs": true,
    "esModuleInterop": true,
    "module": "esnext",
    "moduleResolution": "bundler",
    "resolveJsonModule": true,
    "isolatedModules": true,
    "jsx": "preserve",
    "plugins": [
      {
        "name": "next"
      }
    ],
    "paths": {
      "@/*": ["./src/*"]
    },
    "types": ["node"]
  },
  "include": ["next-env.d.ts", "**/*.ts", "**/*.tsx", ".next/types/**/*.ts"],
  "exclude": ["node_modules"]
}
```

- 타입 체크용 npm 스크립트를 `package.json` 에 추가한다.
```json
{
	"type:check": "tsc"
}
```

### 2. prettier
#### 1. 프로젝트의 상태 확인
- 포매터로 prettier 최신 버전을 사용한다.
- 프로젝트 루트의 `package.json` 에 [prettier](https://www.npmjs.com/package/prettier) 가 설치되어 있는지 확인하고 없다면 development dependecy로 설치한다.
```sh
pnpm i -D prettier
```

- 아래의 `prettier.config.mjs` 가 기본 설정이다. 없다면 추가한다.
    - prettier 설정에는 한글 주석을 추가한다.
    - 타입 정의를 jsdoc 으로 추가한다.
```javascript
/** @type {import('prettier').Config} */
const config = {
  endOfLine: "lf",
  semi: false,
  singleQuote: true,
  tabWidth: 2,
  trailingComma: "none"
}

export default config;
```

#### 2. 추가 플러그인 설치
- 아래의 최신 플러그인을 development dependecy 로 설치한다.
    - [@ianvs/prettier-plugin-sort-imports](https://www.npmjs.com/package/@ianvs/prettier-plugin-sort-imports)
    -  [prettier-plugin-css-order](https://www.npmjs.com/package/prettier-plugin-css-order)
    - [prettier-plugin-classnames](https://www.npmjs.com/package/prettier-plugin-classnames)
```sh
pnpm i -D @ianvs/prettier-plugin-sort-imports prettier-plugin-css-order prettier-plugin-classnames
```

- 아래의`prettier.config.mjs` 를 수동으로 추가한다.
```javascript
/** @type {import('prettier').Config} */
const config = {
	endOfLine: "lf",
	semi: false,
	singleQuote: true,
	tabWidth: 2,
	trailingComma: "none",
	// import sort[s]
	plugins: [
		'@ianvs/prettier-plugin-sort-imports',
		'prettier-plugin-css-order',
		'prettier-plugin-classnames'
	],
	importOrder: [
		'^react',
		'^next',
		'^react-router',
		'',
		'<BUILTIN_MODULES>',
		'<THIRD_PARTY_MODULES>',
		'',
		'.css$',
		'.scss$',
		'^[.]'
	],
	importOrderParserPlugins: ['typescript', 'jsx', 'decorators-legacy']
	// import sort[e]
}

export default config;
```

#### 3. npm script 추가
- `package.json` 에 아래의 npm script 를 추가한다.
- `pnpm prettier` 명령어를 실행해서 정상적으로 동작하는지 확인한다.
```json
{
	"prettier": "prettier --write \"**/*.{ts,tsx,cjs,mjs,json,html,css,js,jsx}\" --cache --config prettier.config.mjs"
}
```

### 3. eslint
- typescript + eslint 는 [typescript-eslint](https://typescript-eslint.io/) 라는 패키지와 함께 사용해야 정상적으로 동작한다.
    - 아래의 코어 레시피는 직/간접적으로 [typescript-eslint](https://typescript-eslint.io/) 를 설치한 상태로 진행한다.

- 프로젝트를 스케폴드할때 설치하면 최신 레시피가 설치된다.
    - 기본으로 설치되는 플러그인 목록은 [이곳](https://nextjs.org/docs/app/api-reference/config/eslint#eslint-plugin)에 있다.
    - 레거시 룰을 flatconfig 에 맞춰 다시 만들지 않고 `FlatCompat` 이라는 컨버터를 사용해서 재활용하는 것이 특징이다.
- 테스트 결과 peer dependency가 누락되는 경우가 있다. 버전에 따라 이런 에러가 발생할 수 있으므로 아래 패키지들을 추가로 설치한다.
```sh
pnpm i -D eslint-plugin-react-hooks @next/eslint-plugin-next
```

```js
// eslint.config.mjs
import { dirname } from "path";
import { fileURLToPath } from "url";
import { FlatCompat } from "@eslint/eslintrc";

const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);

const compat = new FlatCompat({
  baseDirectory: __dirname,
});

const eslintConfig = [
  ...compat.extends("next/core-web-vitals", "next/typescript"),
];

export default eslintConfig;
```

#### eslint 용 npm script 추가
- eslint 를 실행하면 자동으로 수정하도록 한다.
    - 캐시 위치를 `node_modules` 아래로 옮기고, `.gitignore` 에 적은 내용을 eslint 에서 무시하도록 한다.
    - 이 커맨드를 수시로 실행해서 동작을 확인하자.
```json
{
	"eslint": "eslint --fix --ignore-pattern .gitignore --cache --cache-location ./node_modules/.cache/eslint ."
}
```

#### 함수형 코딩 룰 추가
- 부수효과를 최소화하기 위해 [eslint-plugin-functional](https://github.com/eslint-functional/eslint-plugin-functional) 플러그인을 사용한다.
```sh
pnpm i eslint-plugin-functional -D
```
- [공식 문서에는 typescript 사용시  tseslint 와 함께 사용하라고 되어 있지만](https://github.com/eslint-functional/eslint-plugin-functional/blob/main/GETTING_STARTED.md), 이미 코어에 적용이 되어 있으니 생략한다
```js
import functional from 'eslint-plugin-functional'

const functionalStyles = {
  plugins: {
    functional
  },
  rules: {
    // 변수 선언 관련
    'functional/no-let': 'error', // let, var 대신 const 사용
    'no-var': 'error', // var 금지
    'prefer-const': 'error', // const 선호
    // 루프 금지
    'functional/no-loop-statements': 'error', // 모든 루프문 금지
    // 데이터 불변성
    'functional/immutable-data': 'warn', // 배열/객체 변이 메서드 경고
    // 파라미터 관련
    'no-param-reassign': ['error', { props: true }] // 파라미터 재할당 금지
  }
}
```

#### 사용하지 않는 import와 변수를 삭제하는 코딩 룰 추가
- [eslint-plugin-unused-imports](https://github.com/sweepline/eslint-plugin-unused-imports) 를 사용하면 eslint 가 사용하지 않는 import 문과 변수를 삭제한다.
    - 작지만 품질 향상에 굉장히 큰 영항을 미친다.
```sh
pnpm i eslint-plugin-unused-imports -D
```

```js
import unusedImports from 'eslint-plugin-unused-imports'

const unUsedImportsStyles = {
  plugins: {
    'unused-imports': unusedImports,
  },
  rules: {
    'no-unused-vars': 'off',
    'unused-imports/no-unused-imports': 'error',
    'unused-imports/no-unused-vars': [
      'error',
      {
        vars: 'all',
        varsIgnorePattern: '^_',
        args: 'after-used',
        argsIgnorePattern: '^_'
      }
    ],
  }
}
```

#### 커스텀 스타일 추가
- 다른 플러그인에는 없는 개인적인 타입스크립트 설정이 섞인 세팅이다.
- typescript-eslint 를 플러그인으로 사용해야 동작한다.
```sh
pnpm i typescript-eslint -D
```

```js
import tseslint from 'typescript-eslint'

const customCodeStyles = {
  plugins: {
    '@typescript-eslint': tseslint.plugin
  },
  rules: {
    'max-depth': ['error', 2],
    'padding-line-between-statements': [
      'error',
      { blankLine: 'always', prev: '*', next: 'return' },
      { blankLine: 'always', prev: '*', next: 'if' },
      { blankLine: 'always', prev: 'function', next: '*' },
      { blankLine: 'always', prev: '*', next: 'function' }
    ],
    'no-restricted-syntax': [
      'error',
      {
        selector: 'TSInterfaceDeclaration',
        message: 'Interface 대신 type 을 사용하세요.'
      },
      {
        selector: 'ConditionalExpression',
        message: '삼항 연산자 대신 if 를 사용하세요.'
      }
    ],
    'no-shadow': 'off', // 기본 ESLint 규칙은 비활성화
    '@typescript-eslint/no-shadow': [
      'error',
      {
        builtinGlobals: true,
        hoist: 'all',
        allow: [] // 예외를 허용하고 싶은 변수 이름들
      }
    ]
  }
}
```

#### ignore pattern 추가
- 린팅에서 제외할 파일은 계속 늘어날 것이기 때문에 이렇게 추상화를 하면 좋다.
```js
const ignorePatterns = {
  name: 'ignore-patterns',
  // 목적파일을 저장하는 디렉토리를 추가
  ignores: ['**/*.d.ts', '**/*.d.mts', '**/*.d.cts', '.next']
}
```

#### 최종 `eslint.config.mjs`
```js
import { dirname } from 'path'
import { fileURLToPath } from 'url'
import { FlatCompat } from '@eslint/eslintrc'
import functional from 'eslint-plugin-functional'
import unusedImports from 'eslint-plugin-unused-imports'
import tseslint from 'typescript-eslint'

// eslint-disable-next-line @typescript-eslint/no-shadow
const __filename = fileURLToPath(import.meta.url)
// eslint-disable-next-line @typescript-eslint/no-shadow
const __dirname = dirname(__filename)

const compat = new FlatCompat({
  baseDirectory: __dirname
})

const functionalStyles = {
  plugins: {
    functional
  },
  rules: {
    // 변수 선언 관련
    'functional/no-let': 'error', // let, var 대신 const 사용
    'no-var': 'error', // var 금지
    'prefer-const': 'error', // const 선호
    // 루프 금지
    'functional/no-loop-statements': 'error', // 모든 루프문 금지
    // 데이터 불변성
    'functional/immutable-data': 'warn', // 배열/객체 변이 메서드 경고
    // 파라미터 관련
    'no-param-reassign': ['error', { props: true }] // 파라미터 재할당 금지
  }
}

const unUsedImportsStyles = {
  plugins: {
    'unused-imports': unusedImports
  },
  rules: {
    'no-unused-vars': 'off',
    'unused-imports/no-unused-imports': 'error',
    'unused-imports/no-unused-vars': [
      'error',
      {
        vars: 'all',
        varsIgnorePattern: '^_',
        args: 'after-used',
        argsIgnorePattern: '^_'
      }
    ]
  }
}

const customCodeStyles = {
  plugins: {
    '@typescript-eslint': tseslint.plugin
  },
  rules: {
    'max-depth': ['error', 2],
    'padding-line-between-statements': [
      'error',
      { blankLine: 'always', prev: '*', next: 'return' },
      { blankLine: 'always', prev: '*', next: 'if' },
      { blankLine: 'always', prev: 'function', next: '*' },
      { blankLine: 'always', prev: '*', next: 'function' }
    ],
    'no-restricted-syntax': [
      'error',
      {
        selector: 'TSInterfaceDeclaration',
        message: 'Interface 대신 type 을 사용하세요.'
      },
      {
        selector: 'ConditionalExpression',
        message: '삼항 연산자 대신 if 를 사용하세요.'
      }
    ],
    'no-shadow': 'off', // 기본 ESLint 규칙은 비활성화
    '@typescript-eslint/no-shadow': [
      'error',
      {
        builtinGlobals: true,
        hoist: 'all',
        allow: [] // 예외를 허용하고 싶은 변수 이름들
      }
    ]
  }
}

const ignorePatterns = {
  name: 'ignore-patterns',
  // 목적파일을 저장하는 디렉토리를 추가
  ignores: ['**/*.d.ts', '**/*.d.mts', '**/*.d.cts', '.next']
}

const eslintConfig = [
  ...compat.extends('next/core-web-vitals', 'next/typescript'),
  functionalStyles,
  unUsedImportsStyles,
  customCodeStyles,
  ignorePatterns
]

export default eslintConfig
```

### 4. husky
#### 허스키 설치
- [husky 공식문서](https://typicode.github.io/husky/get-started.html)를 참고해서 pnpm 을 사용해 설치한다.
```sh
pnpm i husky -D
```

- [husky 공식문서](https://typicode.github.io/husky/get-started.html)를 참고해서 초기화한다.
```sh
pnpm husky init
```

#### husky 와 eslint , prettier , typescript 통합
- 프로젝트에 `eslint` , `prettier` , `typescript` 가 모두 설치되어 있는지 확인한다.
- `package.json` 에 각각을 실행하는 명령어가 있는지 확인하고, 없다면 추가한다.
    - `eslint` : eslint 명령어에실행에 커스텀 옵션을 추가해서 실행한다.
    - `prettier` : prettier 명령어에실행에 커스텀 옵션을 추가해서 실행한다.
    - `type:check` : 타입스크립트의 타입 체크 명령에 커스텀 옵션을 추가해서 실행한다.
```diff
"eslint": "eslint --fix --ignore-pattern .gitignore --cache --cache-location ./node_modules/.cache/eslint .",
"prettier": "prettier --write \"**/*.{ts,tsx,cjs,mjs,json,html,css,js,jsx}\" --cache --config prettier.config.mjs",
"type:check": "tsc",
```

- 위 명령어를 한번에 실행하기 위해 [npm-run-all]() 패키지를 설치한다.
```sh
pnpm i npm-run-all -D
```

- `package.json` 에 위 명령어를 한번에 실행하는 명령어를 추가한다.
```diff
"format": "run-s type:check prettier eslint"
```

- `.husky/pre-commit` 의 내용을 아래의 코드로 바꾼다.
```sh
pnpm format
```

## 4. 스토리북 설치
- 별다른 제어가 없어도 오피셜 플러그인을 사용해서 스무스하게 통합된다.
- 서버 컴포넌트도 클라이언트 컴포넌트도 별다른 설정 없이 통합이 된다.
    - 역시 유저가 많으니 문제 해결이 빠르고 지원 범위가 넒다.
```sh
pnpm create storybook@latest
```
- 설치 후에 아래의 추가 작업을 한다.
    1. onboarding 패키지 삭제
    2. 모바일 레이아웃 추가
        1. [뷰포트 설정](https://storybook.js.org/docs/essentials/viewport)
    3. 불필요한 스토리 디렉토리 전체 삭제

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

## 8. swagger api 클라이언트 통합
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
