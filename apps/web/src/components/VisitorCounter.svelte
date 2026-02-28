<script lang="ts">
  import { onMount } from "svelte";

  const API_URL = import.meta.env.PUBLIC_COUNTER_API_URL ?? "";
  const CACHE_KEY = "visitor-count";
  const TIMEOUT_MS = 10_000;
  const MAX_RETRIES = 3;

  let countText = "Visits --";

  function sleep(ms: number) {
    return new Promise<void>((resolve) => setTimeout(resolve, ms));
  }

  function getCachedCount(): number | null {
    const raw = sessionStorage.getItem(CACHE_KEY);
    if (raw === null) return null;
    const n = Number(raw);
    return Number.isFinite(n) ? n : null;
  }

  async function fetchCount(): Promise<number | null> {
    const controller = new AbortController();
    const timer = setTimeout(() => controller.abort(), TIMEOUT_MS);

    try {
      const res = await fetch(API_URL, { signal: controller.signal });
      if (!res.ok) return null;

      const data = await res.json();
      const count = Number(data?.count);
      return Number.isFinite(count) ? count : null;
    } catch {
      return null;
    } finally {
      clearTimeout(timer);
    }
  }

  async function fetchCountWithRetries(): Promise<number | null> {
    for (let attempt = 0; attempt <= MAX_RETRIES; attempt++) {
      if (attempt > 0) await sleep(1_000 * 2 ** (attempt - 1));

      const count = await fetchCount();
      if (count !== null) return count;
    }

    return null;
  }

  onMount(async () => {
    if (!API_URL) {
      countText = "Visits unavailable";
      return;
    }

    const cached = getCachedCount();
    if (cached !== null) countText = `Visits: ${cached}`;

    const count = await fetchCountWithRetries();
    if (count !== null) {
      sessionStorage.setItem(CACHE_KEY, String(count));
      countText = `Visits: ${count}`;
    } else if (cached === null) {
      countText = "Visits unavailable";
    }
  });
</script>

<span class="ui-text-muted text-sm tabular-nums" aria-live="polite">{countText}</span>
