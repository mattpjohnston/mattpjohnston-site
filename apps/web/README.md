# mattpjohnston-site (apps/web)

Personal site built with Astro and Tailwind CSS.

## Stack

- Astro 5
- Tailwind CSS 4
- No framework. The only JavaScript is the visitor counter in
  `src/components/VisitorCounter.astro`.

## Design

Newsreader for text, Instrument Sans for headings and nav, Monaspace Neon for
code. The first two are subset woff2 files in `src/fonts/` rather than
`public/` so the build puts a hash in the filename.

Colours are custom properties in `src/styles/global.css`, with a
`prefers-color-scheme` block for dark mode.

## Content

- Blog posts live in `src/blog`
- Project entries live in `src/projects`
- Collection schema is defined in `src/content.config.ts`
- `Writing` appears in the navigation automatically once a post exists

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
