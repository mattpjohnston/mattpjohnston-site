<script lang="ts">
  import { onDestroy, onMount } from "svelte";

  const LERP_FACTOR = 0.16;

  let glowEl: HTMLDivElement | null = null;
  let reduceMotionQuery: MediaQueryList | undefined;
  let coarsePointerQuery: MediaQueryList | undefined;
  let currentX = 0;
  let currentY = 0;
  let targetX = 0;
  let targetY = 0;
  let frameId: number | null = null;
  let pointerTrackingEnabled = false;

  const setGlowPosition = (x: number, y: number) => {
    if (!glowEl) {
      return;
    }

    glowEl.style.setProperty("--mouse-x", `${Math.round(x)}px`);
    glowEl.style.setProperty("--mouse-y", `${Math.round(y)}px`);
  };

  const setStaticGlow = () => {
    targetX = window.innerWidth / 2;
    targetY = Math.min(window.innerHeight * 0.18, 220);
    currentX = targetX;
    currentY = targetY;
    setGlowPosition(currentX, currentY);
  };

  const stopAnimation = () => {
    if (frameId !== null) {
      cancelAnimationFrame(frameId);
      frameId = null;
    }
  };

  const animate = () => {
    currentX += (targetX - currentX) * LERP_FACTOR;
    currentY += (targetY - currentY) * LERP_FACTOR;
    setGlowPosition(currentX, currentY);

    const hasMotion = Math.abs(targetX - currentX) > 0.2 || Math.abs(targetY - currentY) > 0.2;
    if (hasMotion) {
      frameId = requestAnimationFrame(animate);
      return;
    }

    frameId = null;
  };

  const startAnimation = () => {
    if (frameId === null) {
      frameId = requestAnimationFrame(animate);
    }
  };

  const handlePointerMove = (event: PointerEvent) => {
    targetX = event.clientX;
    targetY = event.clientY;
    startAnimation();
  };

  const enablePointerTracking = () => {
    if (pointerTrackingEnabled) {
      return;
    }

    window.addEventListener("pointermove", handlePointerMove, { passive: true });
    pointerTrackingEnabled = true;
  };

  const disablePointerTracking = () => {
    if (!pointerTrackingEnabled) {
      return;
    }

    window.removeEventListener("pointermove", handlePointerMove);
    pointerTrackingEnabled = false;
  };

  const prefersReducedMotion = () => reduceMotionQuery?.matches ?? false;
  const hasCoarsePointer = () => coarsePointerQuery?.matches ?? false;

  const syncInteractionMode = () => {
    if (prefersReducedMotion() || hasCoarsePointer()) {
      disablePointerTracking();
      stopAnimation();
      setStaticGlow();
      return;
    }

    enablePointerTracking();
  };

  const bindMediaChange = (
    query: MediaQueryList,
    handler: (event: MediaQueryListEvent) => void,
  ) => {
    query.addEventListener("change", handler);
  };

  const unbindMediaChange = (
    query: MediaQueryList,
    handler: (event: MediaQueryListEvent) => void,
  ) => {
    query.removeEventListener("change", handler);
  };

  let handleMediaChange: ((event: MediaQueryListEvent) => void) | undefined;
  let handleResize: (() => void) | undefined;

  onMount(() => {
    if (!glowEl) {
      return;
    }

    reduceMotionQuery = window.matchMedia("(prefers-reduced-motion: reduce)");
    coarsePointerQuery = window.matchMedia("(pointer: coarse)");

    setStaticGlow();

    handleMediaChange = () => {
      syncInteractionMode();
    };
    bindMediaChange(reduceMotionQuery, handleMediaChange);
    bindMediaChange(coarsePointerQuery, handleMediaChange);

    handleResize = () => {
      if (prefersReducedMotion() || hasCoarsePointer()) {
        setStaticGlow();
      }
    };
    window.addEventListener("resize", handleResize, { passive: true });

    syncInteractionMode();
  });

  onDestroy(() => {
    stopAnimation();
    disablePointerTracking();

    if (reduceMotionQuery && handleMediaChange) {
      unbindMediaChange(reduceMotionQuery, handleMediaChange);
    }
    if (coarsePointerQuery && handleMediaChange) {
      unbindMediaChange(coarsePointerQuery, handleMediaChange);
    }
    if (handleResize) {
      window.removeEventListener("resize", handleResize);
    }
  });
</script>

<div bind:this={glowEl} class="glow-follow" aria-hidden="true"></div>

<style>
  .glow-follow {
    position: absolute;
    inset: 0;
    pointer-events: none;
    background:
      radial-gradient(
        21rem 21rem at var(--mouse-x, 50%) var(--mouse-y, 18%),
        rgba(99, 102, 241, 0.107),
        rgba(56, 189, 248, 0.048) 36%,
        rgba(2, 10, 34, 0) 70%
      );
  }
</style>
