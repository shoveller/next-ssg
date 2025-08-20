#!/bin/bash

# Next.js SSG 프로젝트 자동 설정 스크립트
# PROCESS.md의 모든 단계를 순차적으로 실행합니다

set -e  # 에러 발생 시 스크립트 종료

# 색상 정의
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# 진행률 및 상태 변수
TOTAL_STEPS=8
CURRENT_STEP=0
PROJECT_NAME=""

# 유틸리티 함수들
print_header() {
    clear
    echo -e "${PURPLE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${PURPLE}                         Next.js SSG 프로젝트 자동 설정 도구                        ${NC}"
    echo -e "${PURPLE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
}

print_progress() {
    local step=$1
    local description=$2
    local percentage=$(( (step * 100) / TOTAL_STEPS ))
    local bar_length=50
    local filled_length=$(( (percentage * bar_length) / 100 ))
    
    printf "\r${BLUE}진행률: [${NC}"
    for ((i=0; i<filled_length; i++)); do printf "█"; done
    for ((i=filled_length; i<bar_length; i++)); do printf "░"; done
    printf "${BLUE}] ${percentage}%% (${step}/${TOTAL_STEPS})${NC}\n"
    echo -e "${CYAN}현재 작업: ${description}${NC}"
    echo ""
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

ask_confirmation() {
    local message="$1"
    local default="${2:-y}"
    
    if [[ "$default" == "y" ]]; then
        prompt="${message} (Y/n): "
    else
        prompt="${message} (y/N): "
    fi
    
    while true; do
        echo -ne "${YELLOW}${prompt}${NC}"
        read -r answer
        
        # 기본값 처리
        if [[ -z "$answer" ]]; then
            answer="$default"
        fi
        
        case $(echo "$answer" | tr '[:upper:]' '[:lower:]') in
            y|yes|예|네 ) return 0;;
            n|no|아니오|아니요 ) return 1;;
            * ) echo -e "${RED}y 또는 n을 입력해주세요.${NC}";;
        esac
    done
}

run_command() {
    local cmd="$1"
    local success_msg="$2"
    local error_msg="$3"
    
    echo -e "${BLUE}실행 중: ${cmd}${NC}"
    
    if eval "$cmd"; then
        print_success "$success_msg"
        return 0
    else
        print_error "$error_msg"
        
        if ask_confirmation "이 단계를 건너뛰고 계속하시겠습니까?"; then
            print_warning "단계를 건너뛰었습니다."
            return 0
        else
            echo -e "${RED}설치를 중단합니다.${NC}"
            exit 1
        fi
    fi
}

check_prerequisites() {
    print_header
    echo -e "${CYAN}📋 사전 요구사항 확인 중...${NC}"
    echo ""
    
    # Node.js 확인
    if command -v node &> /dev/null; then
        local node_version=$(node --version)
        print_success "Node.js 발견: $node_version"
    else
        print_error "Node.js가 설치되지 않았습니다."
        echo -e "${YELLOW}Node.js 18+ 설치가 필요합니다: https://nodejs.org/${NC}"
        exit 1
    fi
    
    # pnpm 확인
    if command -v pnpm &> /dev/null; then
        local pnpm_version=$(pnpm --version)
        print_success "pnpm 발견: v$pnpm_version"
    else
        print_error "pnpm이 설치되지 않았습니다."
        if ask_confirmation "pnpm을 설치하시겠습니까?"; then
            run_command "npm install -g pnpm" "pnpm 설치 완료" "pnpm 설치 실패"
        else
            exit 1
        fi
    fi
    
    # Git 확인
    if command -v git &> /dev/null; then
        local git_version=$(git --version)
        print_success "Git 발견: $git_version"
    else
        print_warning "Git이 설치되지 않았습니다. Husky 설정에서 필요할 수 있습니다."
    fi
    
    echo ""
    print_success "사전 요구사항 확인 완료"
    echo ""
    
    if ask_confirmation "설치를 시작하시겠습니까?"; then
        return 0
    else
        echo -e "${YELLOW}설치를 취소했습니다.${NC}"
        exit 0
    fi
}

get_project_info() {
    print_header
    echo -e "${CYAN}📝 프로젝트 정보 입력${NC}"
    echo ""
    
    while [[ -z "$PROJECT_NAME" ]]; do
        echo -ne "${YELLOW}프로젝트 이름을 입력하세요: ${NC}"
        read -r PROJECT_NAME
        
        if [[ -z "$PROJECT_NAME" ]]; then
            print_error "프로젝트 이름을 입력해주세요."
        elif [[ -d "$PROJECT_NAME" ]]; then
            print_error "이미 존재하는 디렉토리입니다: $PROJECT_NAME"
            PROJECT_NAME=""
        fi
    done
    
    echo ""
    print_info "프로젝트 이름: $PROJECT_NAME"
    print_info "생성 위치: $(pwd)/$PROJECT_NAME"
    echo ""
    
    if ask_confirmation "이 설정으로 프로젝트를 생성하시겠습니까?"; then
        return 0
    else
        get_project_info
    fi
}

# 단계별 함수들
step1_create_nextjs() {
    CURRENT_STEP=1
    print_header
    print_progress $CURRENT_STEP "Next.js 프로젝트 생성"
    
    local create_cmd="pnpm create next-app@latest \"$PROJECT_NAME\" --typescript --eslint --no-tailwind --app --src-dir --import-alias \"@/*\" --no-git"
    
    echo -e "${BLUE}다음 옵션으로 Next.js 프로젝트를 생성합니다:${NC}"
    echo "- TypeScript: 활성화"
    echo "- ESLint: 활성화" 
    echo "- Tailwind CSS: 비활성화 (대신 SASS 사용)"
    echo "- App Router: 활성화"
    echo "- src/ 디렉토리: 활성화"
    echo "- Import alias: @/*"
    echo ""
    
    run_command "$create_cmd" \
        "Next.js 프로젝트 생성 완료" \
        "Next.js 프로젝트 생성 실패"
    
    # SASS 설치
    echo ""
    echo -e "${BLUE}SASS를 설치하고 설정합니다.${NC}"
    run_command "pnpm i -D sass" \
        "SASS 설치 완료" \
        "SASS 설치 실패"
    
    # 프로젝트 디렉토리로 이동
    cd "$PROJECT_NAME"
    
    print_success "프로젝트 디렉토리로 이동: $(pwd)"
    echo ""
    
    if ask_confirmation "다음 단계로 진행하시겠습니까?"; then
        return 0
    else
        echo -e "${YELLOW}설치를 일시정지합니다.${NC}"
        exit 0
    fi
}

step2_setup_nextconfig() {
    CURRENT_STEP=2
    print_header
    print_progress $CURRENT_STEP "Next.js 설정 파일 구성"
    
    echo -e "${BLUE}SSG 모드와 이미지 최적화 설정을 구성합니다.${NC}"
    echo ""
    
    # next.config.ts 파일 생성
    cat > next.config.ts << 'EOF'
import type { NextConfig } from 'next'

const nextConfig: NextConfig = {
    output: 'export', // ssg 모드로 빌드한다
    images: {
        unoptimized: true // cdn 레벨의 이미지 최적화를 사용하지 않는다
    }
}

export default nextConfig
EOF

    print_success "next.config.ts 파일 생성 완료"
    echo ""
    
    if ask_confirmation "다음 단계로 진행하시겠습니까?"; then
        return 0
    fi
}

step3_setup_typescript() {
    CURRENT_STEP=3
    print_header
    print_progress $CURRENT_STEP "TypeScript 설정 최적화"
    
    echo -e "${BLUE}TypeScript 설정을 최적화합니다.${NC}"
    echo ""
    
    # tsconfig.base.json 생성
    cat > tsconfig.base.json << 'EOF'
{
  "compilerOptions": {
    /* 컴파일 성능 최적화 */
    "skipLibCheck": true,
    "incremental": true,
    "tsBuildInfoFile": "./node_modules/.cache/tsc/tsbuildinfo",

    /* 출력 제어 */
    "noEmit": true,

    /* 엄격한 타입 검사 */
    "strict": true,
    "noUnusedLocals": true,
    "noUnusedParameters": true,
    "noFallthroughCasesInSwitch": true,
    "noUncheckedSideEffectImports": true,

    /* 구문 분석 최적화 */
    "erasableSyntaxOnly": true
  }
}
EOF

    # tsconfig.json 업데이트
    cat > tsconfig.json << 'EOF'
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
EOF

    # package.json에 타입체크 스크립트 추가
    npm pkg set scripts.type:check="tsc"
    
    print_success "TypeScript 설정 완료"
    print_info "tsconfig.base.json: 성능 최적화 설정"
    print_info "tsconfig.json: Next.js 프로젝트 설정"
    print_info "package.json: type:check 스크립트 추가"
    echo ""
    
    if ask_confirmation "다음 단계로 진행하시겠습니까?"; then
        return 0
    fi
}

step4_setup_prettier() {
    CURRENT_STEP=4
    print_header
    print_progress $CURRENT_STEP "Prettier 설정"
    
    echo -e "${BLUE}Prettier와 관련 플러그인을 설치합니다.${NC}"
    echo ""
    
    # Prettier 및 플러그인 설치
    run_command "pnpm i -D prettier @ianvs/prettier-plugin-sort-imports prettier-plugin-css-order prettier-plugin-classnames" \
        "Prettier 및 플러그인 설치 완료" \
        "Prettier 설치 실패"
    
    # prettier.config.mjs 생성
    cat > prettier.config.mjs << 'EOF'
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
EOF

    # package.json에 prettier 스크립트 추가
    npm pkg set scripts.prettier="prettier --write \"**/*.{ts,tsx,cjs,mjs,json,html,css,js,jsx}\" --cache --config prettier.config.mjs"
    
    print_success "Prettier 설정 완료"
    print_info "Import 정렬, CSS 정렬, 클래스명 정렬 플러그인 포함"
    echo ""
    
    if ask_confirmation "다음 단계로 진행하시겠습니까?"; then
        return 0
    fi
}

step5_setup_eslint() {
    CURRENT_STEP=5
    print_header
    print_progress $CURRENT_STEP "ESLint 고급 설정"
    
    echo -e "${BLUE}ESLint 플러그인들을 설치합니다.${NC}"
    echo ""
    
    # 필수 플러그인 설치
    run_command "pnpm i -D eslint-plugin-react-hooks @next/eslint-plugin-next eslint-plugin-functional eslint-plugin-unused-imports typescript-eslint" \
        "ESLint 플러그인 설치 완료" \
        "ESLint 플러그인 설치 실패"
    
    # eslint.config.mjs 생성
    cat > eslint.config.mjs << 'EOF'
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
EOF

    # package.json에 eslint 스크립트 추가
    npm pkg set scripts.eslint="eslint --fix --ignore-pattern .gitignore --cache --cache-location ./node_modules/.cache/eslint ."
    
    print_success "ESLint 설정 완료"
    print_info "함수형 프로그래밍 룰 적용"
    print_info "미사용 imports 자동 삭제"
    print_info "커스텀 TypeScript 룰 적용"
    echo ""
    
    if ask_confirmation "다음 단계로 진행하시겠습니까?"; then
        return 0
    fi
}

step6_setup_husky() {
    CURRENT_STEP=6
    print_header
    print_progress $CURRENT_STEP "Husky 및 Pre-commit 훅 설정"
    
    echo -e "${BLUE}Husky와 npm-run-all을 설치합니다.${NC}"
    echo ""
    
    # Husky 및 npm-run-all 설치
    run_command "pnpm i -D husky npm-run-all" \
        "Husky 설치 완료" \
        "Husky 설치 실패"
    
    # Husky 초기화
    run_command "pnpm husky init" \
        "Husky 초기화 완료" \
        "Husky 초기화 실패"
    
    # package.json에 format 스크립트 추가
    npm pkg set scripts.format="run-s type:check prettier eslint"
    
    # pre-commit 훅 설정
    echo "pnpm format" > .husky/pre-commit
    
    print_success "Husky 설정 완료"
    print_info "Pre-commit 훅: 타입체크 → Prettier → ESLint 순서로 실행"
    echo ""
    
    if ask_confirmation "다음 단계로 진행하시겠습니까?"; then
        return 0
    fi
}

step7_setup_storybook() {
    CURRENT_STEP=7
    print_header
    print_progress $CURRENT_STEP "Storybook 설치"
    
    if ask_confirmation "Storybook을 설치하시겠습니까?"; then
        echo -e "${BLUE}Storybook을 설치합니다...${NC}"
        echo ""
        
        run_command "pnpm create storybook@latest" \
            "Storybook 설치 완료" \
            "Storybook 설치 실패"
        
        print_success "Storybook 설치 완료"
        print_warning "설치 후 수동으로 다음 작업을 진행해주세요:"
        echo "  1. onboarding 패키지 삭제"
        echo "  2. 모바일 뷰포트 설정 추가"
        echo "  3. 불필요한 스토리 파일 정리"
        echo ""
    else
        print_warning "Storybook 설치를 건너뛰었습니다."
        echo ""
    fi
    
    if ask_confirmation "다음 단계로 진행하시겠습니까?"; then
        return 0
    fi
}

step8_advanced_features() {
    CURRENT_STEP=8
    print_header
    print_progress $CURRENT_STEP "고급 기능 설정"
    
    # CSS 타입 정의 파일 생성
    mkdir -p src/types
    cat > src/types/css.d.ts << 'EOF'
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
EOF

    print_success "CSS 타입 정의 파일 생성 완료"
    echo ""
    
    # Nanum Square 폰트 설정
    if ask_confirmation "Nanum Square 폰트 설정을 구성하시겠습니까?"; then
        mkdir -p public/fonts
        mkdir -p src/app
        
        # GitHub에서 폰트 다운로드
        echo -e "${BLUE}GitHub에서 Nanum Square 폰트를 다운로드합니다...${NC}"
        
        # 임시 디렉토리 생성 및 폰트 다운로드
        temp_dir=$(mktemp -d)
        
        run_command "curl -L -o \"$temp_dir/nanumSquare.zip\" https://github.com/moonspam/NanumSquare/archive/refs/heads/master.zip" \
            "폰트 압축 파일 다운로드 완료" \
            "폰트 다운로드 실패"
        
        # 압축 해제 및 폰트 파일 복사
        if command -v unzip &> /dev/null; then
            current_dir=$(pwd)
            
            run_command "cd \"$temp_dir\" && unzip -q nanumSquare.zip" \
                "압축 해제 완료" \
                "압축 해제 실패"
            
            # 프로젝트 루트로 돌아가기
            cd "$current_dir"
            
            # .woff2 파일들을 public/fonts로 복사 (절대 경로 사용)
            if [[ -d "$temp_dir/NanumSquare-master" ]]; then
                # public/fonts 디렉토리가 확실히 존재하는지 확인
                mkdir -p "$current_dir/public/fonts"
                run_command "find \"$temp_dir/NanumSquare-master\" -name \"*.woff2\" -exec cp {} \"$current_dir/public/fonts/\" \;" \
                    "폰트 파일 복사 완료" \
                    "폰트 파일 복사 실패"
            fi
        else
            print_warning "unzip 명령어가 없습니다. 수동으로 폰트를 다운로드해주세요."
        fi
        
        # 임시 디렉토리 정리
        rm -rf "$temp_dir"
        
        # 폰트 정의 파일 생성
        mkdir -p "$current_dir/src/app"
        cat > "$current_dir/src/app/fonts.ts" << 'EOF'
// app/fonts.ts (폰트 정의 파일)

import localFont from 'next/font/local'

export const nanumSquare = localFont({
  src: [
    {
      path: '../../public/fonts/NanumSquareL.woff2',
      weight: '300',
      style: 'normal',
    },
    {
      path: '../../public/fonts/NanumSquareR.woff2',
      weight: '400',
      style: 'normal',
    },
    {
      path: '../../public/fonts/NanumSquareB.woff2',
      weight: '700',
      style: 'normal',
    },
    {
      path: '../../public/fonts/NanumSquareEB.woff2',
      weight: '800',
      style: 'normal'
    }
  ],
  variable: '--font-nanum-square',
  display: 'swap',
  fallback: ['system-ui', 'sans-serif'],
})
EOF

        # layout.tsx 자동 수정
        if [[ -f "$current_dir/src/app/layout.tsx" ]]; then
            echo -e "${BLUE}layout.tsx에 폰트를 자동으로 적용합니다...${NC}"
            
            # 기존 layout.tsx 백업
            cp "$current_dir/src/app/layout.tsx" "$current_dir/src/app/layout.tsx.backup"
            
            # layout.tsx 수정
            cat > "$current_dir/src/app/layout.tsx" << 'EOF'
import type { Metadata } from "next"
import { nanumSquare } from './fonts'
import "./globals.css"

export const metadata: Metadata = {
  title: "Create Next App",
  description: "Generated by create next app",
}

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode
}>) {
  return (
    <html lang="ko" className={nanumSquare.variable}>
      <body className={nanumSquare.className}>
        {children}
      </body>
    </html>
  )
}
EOF
            
            print_success "layout.tsx에 Nanum Square 폰트 적용 완료"
        else
            print_warning "layout.tsx 파일을 찾을 수 없습니다. 수동으로 폰트를 적용해주세요."
        fi
        
        print_success "Nanum Square 폰트 설정 완료"
        print_info "다운로드된 폰트 파일들을 public/fonts/ 디렉토리에서 확인하세요"
        echo ""
    fi
    
    # Sentry 설정
    if ask_confirmation "Sentry 에러 추적을 설정하시겠습니까?"; then
        run_command "pnpx @sentry/wizard@latest -i nextjs" \
            "Sentry 설정 완료" \
            "Sentry 설정 실패"
        
        print_warning "SSG 모드에서는 클라이언트 사이드 Sentry만 필요합니다."
        echo ""
    fi
    
    # API 클라이언트 설정
    if ask_confirmation "API 클라이언트(ky + swagger-typescript-api)를 설정하시겠습니까?"; then
        run_command "pnpm i ky" \
            "ky 설치 완료" \
            "ky 설치 실패"
        
        # API 생성 스크립트 추가
        npm pkg set scripts.api="pnpx swagger-typescript-api generate --path https://raw.githubusercontent.com/PokeAPI/pokeapi/refs/heads/master/openapi.yml -o ./src/api"
        
        mkdir -p src/api
        cat > src/api/client.ts << 'EOF'
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
EOF

        print_success "API 클라이언트 설정 완료"
        print_info "pnpm api 명령으로 API 클라이언트 생성 가능"
        echo ""
    fi
    
    print_success "고급 기능 설정 완료"
}

# 메인 함수
main() {
    # 트랩 설정 - 스크립트 중단 시 정리
    trap 'echo -e "\n${RED}설치가 중단되었습니다.${NC}"; exit 1' INT TERM
    
    check_prerequisites
    get_project_info
    step1_create_nextjs
    step2_setup_nextconfig
    step3_setup_typescript
    step4_setup_prettier
    step5_setup_eslint
    step6_setup_husky
    step7_setup_storybook
    step8_advanced_features
    
    # 최종 성공 메시지
    print_header
    echo -e "${GREEN}🎉 Next.js SSG 프로젝트 설정이 완료되었습니다!${NC}"
    echo ""
    echo -e "${CYAN}📋 설정 완료 항목:${NC}"
    echo "✅ Next.js 프로젝트 (TypeScript, ESLint, SASS)"
    echo "✅ SSG 모드 설정 (output: export)"
    echo "✅ 이미지 최적화 비활성화"
    echo "✅ TypeScript 성능 최적화"
    echo "✅ Prettier + Import/CSS 정렬"
    echo "✅ ESLint + 함수형 프로그래밍 룰"
    echo "✅ Husky Pre-commit 훅"
    echo "✅ CSS 타입 정의"
    echo ""
    echo -e "${CYAN}🚀 프로젝트 시작하기:${NC}"
    echo "  cd $PROJECT_NAME"
    echo "  pnpm dev"
    echo ""
    echo -e "${CYAN}💡 유용한 명령어:${NC}"
    echo "  pnpm type:check  - 타입 검사"
    echo "  pnpm prettier    - 코드 포맷팅"
    echo "  pnpm eslint      - 린트 검사 및 수정"
    echo "  pnpm format      - 타입체크 + 포맷팅 + 린트 일괄 실행"
    echo "  pnpm build       - SSG 빌드"
    echo ""
    echo -e "${PURPLE}Happy coding! 🎊${NC}"
}

# 스크립트 실행
main "$@"