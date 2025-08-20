# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a workspace for creating an `install.sh` script that automates the Next.js SSG project scaffolding process following the procedures outlined in `PROCESS.md`. The project implements a sequential installation script that sets up a complete Next.js development environment with TypeScript, ESLint, Prettier, Storybook, and other essential tools.

## Package Manager

- **Always use pnpm** as the package manager for this project
- Commands should use `pnpm` instead of npm or yarn

## Core Setup Process

The `install.sh` script implements a systematic setup process documented in PROCESS.md that sequentially configures:

1. **Scaffolding**: Create Next.js app with TypeScript, ESLint, and TailwindCSS
   ```sh
   pnpm create next-app@latest
   ```

2. **Static Export Configuration**: Configure Next.js for SSG in `next.config.ts`:
   ```ts
   const nextConfig: NextConfig = {
       output: 'export'
   }
   ```

3. **Development Tools Setup**:
   - **TypeScript Configuration**: Use `tsc` as type checker only (not for compilation)
     - Base `tsconfig.base.json` with performance optimizations (`skipLibCheck`, `incremental`, `noEmit`)
     - Strict type checking enabled (`strict: true`, `noUnusedLocals`, `noUnusedParameters`)
   - Configure prettier, eslint, and husky following meta-framework patterns
   - References external documentation for specific configurations

4. **Storybook Integration**:
   ```sh
   pnpm create storybook@latest
   ```
   - Includes mobile viewport configuration
   - Remove onboarding packages after installation

5. **Font Integration**: 
   - Uses Nanum Square fonts (not available via Google Fonts)
   - Requires `next/font/local` with manual font file placement in `public/fonts`
   - Font definition in `app/fonts.ts` and application in root layout

6. **Type Definitions**:
   - CSS module types in `src/types/css.d.ts` for TypeScript support

7. **Sentry Integration**:
   ```sh
   pnpx @sentry/wizard@latest -i nextjs
   ```
   - For SSG, primarily uses client-side instrumentation
   - Configured with source map upload and optimization settings

8. **API Client Generation**:
   - Uses `ky` for fetch implementation and `swagger-typescript-api` for client generation
   - Example API script: 
     ```json
     "api": "pnpx swagger-typescript-api generate --path https://raw.githubusercontent.com/PokeAPI/pokeapi/refs/heads/master/openapi.yml -o ./src/api"
     ```
   - Includes interceptor patterns for request/response handling

## Architecture Principles

- **Static Site Generation**: All builds target static export
- **TypeScript First**: Full TypeScript integration across all tools
- **Component-Driven**: Storybook integration for component development
- **API-First**: Swagger-generated clients with custom fetch interceptors
- **Error Tracking**: Integrated Sentry for production monitoring
- **Font Optimization**: Local font loading with proper fallbacks

## Install Script Development

When developing the `install.sh` script:
- **Use pnpm exclusively** for all package installations and commands
- **Sequential execution** following the PROCESS.md order (Next.js → TypeScript config → Prettier → ESLint → Husky → Storybook → Fonts → Sentry → API)
- **Detailed ESLint configuration** including functional programming rules, unused imports cleanup, and custom code style enforcement
- **Comprehensive Prettier setup** with import sorting and CSS ordering plugins
- **Husky integration** with pre-commit hooks for code formatting and type checking
- **Error handling** for each installation step
- **Verification steps** to ensure each tool is properly configured

## Key Configuration Details

The install script creates:
- **`tsconfig.base.json` + `tsconfig.json`** - Optimized TypeScript configuration with build performance improvements
- **`prettier.config.mjs`** - Prettier configuration with import sorting, CSS ordering, and classname formatting plugins  
- **`eslint.config.mjs`** - Comprehensive ESLint setup with functional programming rules, unused imports cleanup, and custom TypeScript rules
- **`.husky/pre-commit`** - Git hooks for automated formatting and type checking
- **Storybook configuration** - Component development environment with mobile viewports
- **Font integration** - Nanum Square fonts with proper fallback configuration
- **Sentry configuration** - Client-side error tracking for SSG builds
- **API client setup** - ky + swagger-typescript-api integration with interceptors

## Final Project Structure

The script generates:
- `next.config.ts` with SSG export configuration
- `tsconfig.base.json` + `tsconfig.json` for optimized TypeScript
- `prettier.config.mjs` with plugins
- `eslint.config.mjs` with comprehensive rule set
- `.husky/pre-commit` hooks
- `app/fonts.ts` for font definitions
- `src/types/css.d.ts` for CSS module types
- `src/api/` directory for generated API clients
- Storybook configuration with custom viewports