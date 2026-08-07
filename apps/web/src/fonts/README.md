# Fonts

Self-hosted production faces, all licensed under the SIL Open Font License
Version 1.1 (see OFL.txt in this directory).

- `newsreader-latin.woff2`: Newsreader (Production Type), variable
  wght 400–600 + opsz 6–72, Latin/Latin-Ext subset.
  Copyright 2020 The Newsreader Project Authors.
  Source: https://github.com/google/fonts/tree/main/ofl/newsreader
- `instrument-sans-latin.woff2`: Instrument Sans (Rodrigo Fuenzalida,
  Latinotype), variable wght 400–600 (width axis pinned to 100),
  Latin/Latin-Ext subset.
  Copyright 2022 The Instrument Sans Project Authors.
  Source: https://github.com/google/fonts/tree/main/ofl/instrumentsans

Subset with fonttools (`pyftsubset`). Rebuild from the sources above if more
glyphs or weights are needed.

Same subsets as mattpjohnston.com. They're in `src/` rather than `public/` so
the build puts a hash in the filename. Monaspace Neon comes from Fontsource.
