<script lang="ts">
  import { onMount } from "svelte";

  const apiUrl = import.meta.env.PUBLIC_COUNTER_API_URL ?? "";

  let countText = "Visits --";

  const parseCount = (payload: unknown): number | null => {
    if (typeof payload !== "object" || payload === null || !("count" in payload)) {
      return null;
    }

    const count = Number((payload as { count: unknown }).count);
    return Number.isFinite(count) ? count : null;
  };

  const loadVisitorCounter = async (): Promise<void> => {
    if (!apiUrl) {
      countText = "Visits unavailable";
      return;
    }

    try {
      const response = await fetch(apiUrl, { method: "GET" });
      if (!response.ok) return;

      const payload: unknown = await response.json();
      const value = parseCount(payload);
      if (value === null) return;

      countText = `Visits: ${value}`;
    } catch {
    }
  };

  onMount(() => {
    void loadVisitorCounter();
  });
</script>

<span class="ui-text-faint text-xs tabular-nums" aria-live="polite">{countText}</span>
