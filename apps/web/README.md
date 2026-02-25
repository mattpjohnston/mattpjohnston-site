# mattpjohnston-site (apps/web)

Personal portfolio site built with Astro, Tailwind CSS, and Svelte.

## Stack

- Astro 5
- Tailwind CSS 4
- Svelte 5 island in Astro (`GlowFollow`)

## Content

- Blog posts live in `src/blog`
- Project entries live in `src/projects`
- Collection schema is defined in `src/content.config.ts`

## Development

From this directory (`apps/web`):

```bash
npm install
npm run dev
```

- `npm run dev` start local dev server
- `npm run build` production build
- `npm run preview` preview built output
- `npx astro check` run Astro + TypeScript diagnostics
