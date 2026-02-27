<script lang="ts">
  import { onMount } from "svelte";

  const apiUrl = import.meta.env.PUBLIC_COUNTER_API_URL ?? "";
  const CACHE_KEY = "visitor-count";
  const REQUEST_TIMEOUT_MS = 1500;
  const RETRY_DELAY_MS = 150;

  let countText = "Visits --";
  let inFlightRequest: Promise<number | null> | null = null;

  const parseCount = (payload: unknown): number | null => {
    if (typeof payload !== "object" || payload === null || !("count" in payload)) {
      return null;
    }

    const count = Number((payload as { count: unknown }).count);
    return Number.isFinite(count) ? count : null;
  };

  const wait = (ms: number): Promise<void> => new Promise((resolve) => setTimeout(resolve, ms));

  const fetchCountOnce = async (): Promise<number | null> => {
    const controller = new AbortController();
    const timeout = setTimeout(() => controller.abort(), REQUEST_TIMEOUT_MS);
    try {
      const response = await fetch(apiUrl, { method: "GET", cache: "no-cache", signal: controller.signal });
      if (!response.ok) return null;
      return parseCount(await response.json());
    } finally {
      clearTimeout(timeout);
    }
  };

  const fetchCount = (): Promise<number | null> => {
    if (!inFlightRequest) {
      inFlightRequest = (async () => {
        try {
          const firstTry = await fetchCountOnce();
          if (firstTry !== null) return firstTry;

          await wait(RETRY_DELAY_MS);
          return await fetchCountOnce();
        } catch {
          return null;
        }
      })().finally(() => {
        inFlightRequest = null;
      });
    }
    return inFlightRequest;
  };

  const loadVisitorCounter = async (): Promise<void> => {
    if (!apiUrl) {
      countText = "Visits unavailable";
      return;
    }

    const cachedRaw = sessionStorage.getItem(CACHE_KEY);
    const cached = cachedRaw === null ? Number.NaN : Number(cachedRaw);
    const hasCached = Number.isFinite(cached);
    countText = hasCached ? `Visits: ${cached}` : "Visits ...";

    const value = await fetchCount();
    if (value !== null) {
      sessionStorage.setItem(CACHE_KEY, String(value));
      countText = `Visits: ${value}`;
      return;
    }

    if (!hasCached) countText = "Visits unavailable";
  };

  onMount(() => {
    void loadVisitorCounter();
  });
</script>

<span class="ui-text-muted text-sm tabular-nums" aria-live="polite">{countText}</span>
