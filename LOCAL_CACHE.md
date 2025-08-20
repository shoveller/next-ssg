- next.js 의 [self-hosting](https://nextjs.org/docs/app/guides/self-hosting)문서에는 셀프호스팅과 관련한 지침이 아주 자세히 나와있다.
- [configuring-caching](https://nextjs.org/docs/app/guides/self-hosting#configuring-caching) 항목에는 데이터 캐시를 만드는 지침이 적혀 있다.
    - 아래의 예제 코드는 Map 객체에 캐시를 저장한다.
    - 이 기능에 redis 등의 캐시 시스템을 통합하면 셀프호스팅 환경에서도 ISR과 확장된 fetch 시스템을 이용할 수 있다.
        - 내부의 동작을 확인할 수 있게 로그를 많이 더한 상태다.
        - 반드시 클래스를 반환해야 한다.
```js
// cache-handler.js
// 애플리케이션 인스턴스 내에서 공유될 인메모리 캐시 저장소
const cacheStore = new Map();
// 태그와 캐시 키를 매핑하여 revalidateTag를 구현하기 위한 저장소
const tagsCache = new Map();

console.log('✅ In-Memory Cache Handler Initialized');

class CacheHandler {
    constructor(options) {
        console.log('Cache Handler initialized with options:', options);
    }

    async get(key) {
        console.log(`[Cache Handler] GET: ${key}`);
        const entry = cacheStore.get(key);

        if (!entry) {
            console.log(`[Cache Handler] MISS`);
            return null;
        }

        // 캐시 만료 시간 확인 (ISR의 revalidate 시간)
        const isStale = Date.now() > entry.lastModified + entry.revalidate * 1000;
        if (isStale) {
            console.log(`[Cache Handler] STALE: Expired`);
            // 만료된 캐시는 삭제
            cacheStore.delete(key);
            return null;
        }

        console.log(`[Cache Handler] HIT`, entry);
        return entry;
    }

    async set(key, data, ctx) {
        console.log(`[Cache Handler] SET: ${key}`);
        // Next.js가 제공하는 데이터 구조를 그대로 저장
        cacheStore.set(key, {
            value: data,
            lastModified: Date.now(),
            tags: ctx.tags,
            revalidate: ctx.revalidate,
        });

        // 태그와 캐시 키 매핑
        if (ctx.tags) {
            for (const tag of ctx.tags) {
                if (!tagsCache.has(tag)) {
                    tagsCache.set(tag, new Set());
                }
                tagsCache.get(tag).add(key);
            }
        }
    }

    async revalidateTag(tag) {
        console.log(`[Cache Handler] REVALIDATE TAG: ${tag}`);
        const keysToInvalidate = tagsCache.get(tag);

        if (keysToInvalidate) {
            for (const key of keysToInvalidate) {
                console.log(`  - Deleting key: ${key}`);
                cacheStore.delete(key);
            }
            tagsCache.delete(tag);
        }
    }
}

module.exports = CacheHandler;
```

- 그리고 `next.config.ts` 에 추가한다.
    - 이때 반드시 목적파일(js)의 경로를 넘겨야 한다.
```ts
// next.config.ts
import type {NextConfig} from "next";

const nextConfig: NextConfig = {
    cacheHandler: require.resolve('./cache-handler.js'),
    cacheMaxMemorySize: 0, // in-memory 캐시 비활성화
};
```

- 실행하면 캐시 동작을 눈으로 볼 수 있다.
```sh
NEXT_PRIVATE_DEBUG_CACHE=1 pnpm start
```