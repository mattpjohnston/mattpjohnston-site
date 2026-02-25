/// <reference types="astro/client" />

interface ImportMetaEnv {
  readonly PUBLIC_COUNTER_API_URL?: string;
}

interface ImportMeta {
  readonly env: ImportMetaEnv;
}
