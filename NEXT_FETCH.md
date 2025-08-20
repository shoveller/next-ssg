# next.js 의 비표준 캐시 기능들
- next.js의 `fetch`를 서버에서 실행하면 웹 표준 fetch API를 확장한 여러 특수 옵션들을 사용할 수 있게 된다.
- fetch 요청을 next.js 런타임이 인터셉트하는 방식으로 동작한다.  
- 그래서 반드시 `next build` 후애 `next start` 를 실행해야 동작한다.  

## 캐싱 관련 옵션

### cache 옵션

```javascript
// 기본값: 'force-cache' (영구 캐싱)
fetch('/api/data', { cache: 'force-cache' })

// 캐시 없이 항상 새로 요청
fetch('/api/data', { cache: 'no-store' })

// 기본 브라우저 캐싱 동작
fetch('/api/data', { cache: 'default' })

// 캐시가 있으면 사용, 없으면 새로 요청
fetch('/api/data', { cache: 'force-cache' })
```

### next.revalidate 옵션

```javascript
// 60초마다 재검증
fetch('/api/data', { 
  next: { revalidate: 60 } 
})

// 재검증 안함 (영구 캐싱)
fetch('/api/data', { 
  next: { revalidate: false } 
})

// 매 요청마다 재검증
fetch('/api/data', { 
  next: { revalidate: 0 } 
})
```

## 태그 기반 재검증

### next.tags 옵션

```javascript
// 태그로 캐시 그룹화
fetch('/api/posts', {
  next: { tags: ['posts', 'blog'] }
})

// 다른 곳에서 태그로 재검증
import { revalidateTag } from 'next/cache'
revalidateTag('posts') // posts 태그가 있는 모든 캐시 무효화
```

## App Router에서의 특수 동작

### Server Components에서

```javascript
// 빌드 시점에 캐싱 (Static Generation)
async function getData() {
  const res = await fetch('/api/data', {
    cache: 'force-cache'
  })
  return res.json()
}

// 매 요청마다 새로 가져오기 (Dynamic Rendering)
async function getData() {
  const res = await fetch('/api/data', {
    cache: 'no-store'
  })
  return res.json()
}
```

### Route Handlers에서

```javascript
// app/api/data/route.js
export async function GET() {
  const data = await fetch('/external-api', {
    next: { revalidate: 3600 } // 1시간마다 재검증
  })
  return Response.json(await data.json())
}
```

## 데이터 변형 감지

### next.revalidate + ISR

```javascript
// Incremental Static Regeneration
fetch('/api/products', {
  next: { 
    revalidate: 300, // 5분
    tags: ['products']
  }
})

// 특정 이벤트에서 수동 재검증
import { revalidatePath } from 'next/cache'
revalidatePath('/products') // 해당 페이지 재검증
```

## 실제 사용 예시

### 블로그 포스트 캐싱

```javascript
// 포스트 목록 - 30분마다 업데이트
async function getPosts() {
  const res = await fetch('/api/posts', {
    next: { 
      revalidate: 1800,
      tags: ['posts']
    }
  })
  return res.json()
}

// 개별 포스트 - 영구 캐싱 (빌드 시점)
async function getPost(id) {
  const res = await fetch(`/api/posts/${id}`, {
    cache: 'force-cache',
    next: { tags: [`post-${id}`] }
  })
  return res.json()
}
```

### 사용자 데이터 - 캐시 없음

```javascript
async function getUserData() {
  const res = await fetch('/api/user', {
    cache: 'no-store', // 항상 최신 데이터
    headers: {
      'Authorization': `Bearer ${token}`
    }
  })
  return res.json()
}
```

### 상품 데이터 - 조건부 캐싱

```javascript
async function getProducts(userId) {
  const cacheOption = userId 
    ? { cache: 'no-store' } // 로그인 시 개인화 데이터
    : { next: { revalidate: 600 } } // 비로그인 시 10분 캐싱
    
  const res = await fetch('/api/products', cacheOption)
  return res.json()
}
```