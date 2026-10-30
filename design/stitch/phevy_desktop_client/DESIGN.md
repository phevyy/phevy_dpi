---
name: Phevy Desktop Client
colors:
  surface: '#0f131c'
  surface-dim: '#0f131c'
  surface-bright: '#353942'
  surface-container-lowest: '#0a0e16'
  surface-container-low: '#181c24'
  surface-container: '#1c2028'
  surface-container-high: '#262a33'
  surface-container-highest: '#31353e'
  on-surface: '#dfe2ee'
  on-surface-variant: '#cbc3d7'
  inverse-surface: '#dfe2ee'
  inverse-on-surface: '#2c3039'
  outline: '#958ea0'
  outline-variant: '#494454'
  surface-tint: '#d0bcff'
  primary: '#d0bcff'
  on-primary: '#3c0091'
  primary-container: '#a078ff'
  on-primary-container: '#340080'
  inverse-primary: '#6d3bd7'
  secondary: '#4cd7f6'
  on-secondary: '#003640'
  secondary-container: '#03b5d3'
  on-secondary-container: '#00424e'
  tertiary: '#4edea3'
  on-tertiary: '#003824'
  tertiary-container: '#00a572'
  on-tertiary-container: '#00311f'
  error: '#ffb4ab'
  on-error: '#690005'
  error-container: '#93000a'
  on-error-container: '#ffdad6'
  primary-fixed: '#e9ddff'
  primary-fixed-dim: '#d0bcff'
  on-primary-fixed: '#23005c'
  on-primary-fixed-variant: '#5516be'
  secondary-fixed: '#acedff'
  secondary-fixed-dim: '#4cd7f6'
  on-secondary-fixed: '#001f26'
  on-secondary-fixed-variant: '#004e5c'
  tertiary-fixed: '#6ffbbe'
  tertiary-fixed-dim: '#4edea3'
  on-tertiary-fixed: '#002113'
  on-tertiary-fixed-variant: '#005236'
  background: '#0f131c'
  on-background: '#dfe2ee'
  surface-variant: '#31353e'
typography:
  headline-lg:
    fontFamily: Inter
    fontSize: 22px
    fontWeight: '700'
    lineHeight: 28px
    letterSpacing: -0.02em
  headline-md:
    fontFamily: Inter
    fontSize: 18px
    fontWeight: '600'
    lineHeight: 24px
    letterSpacing: -0.015em
  headline-sm:
    fontFamily: Inter
    fontSize: 15px
    fontWeight: '600'
    lineHeight: 20px
    letterSpacing: -0.01em
  body-md:
    fontFamily: Inter
    fontSize: 13px
    fontWeight: '400'
    lineHeight: 18px
    letterSpacing: 0em
  body-sm:
    fontFamily: Inter
    fontSize: 12px
    fontWeight: '400'
    lineHeight: 16px
    letterSpacing: 0em
  label-md:
    fontFamily: Inter
    fontSize: 11px
    fontWeight: '600'
    lineHeight: 14px
    letterSpacing: 0.04em
  label-sm:
    fontFamily: Inter
    fontSize: 10px
    fontWeight: '500'
    lineHeight: 12px
    letterSpacing: 0.02em
  data-mono:
    fontFamily: JetBrains Mono
    fontSize: 12px
    fontWeight: '500'
    lineHeight: 16px
    letterSpacing: -0.01em
  data-mono-xs:
    fontFamily: JetBrains Mono
    fontSize: 10px
    fontWeight: '400'
    lineHeight: 12px
    letterSpacing: 0em
rounded:
  sm: 0.25rem
  DEFAULT: 0.5rem
  md: 0.75rem
  lg: 1rem
  xl: 1.5rem
  full: 9999px
spacing:
  gutter: 0.5rem
  margin: 0.75rem
  space-xs: 0.25rem
  space-sm: 0.5rem
  space-md: 0.75rem
  space-lg: 1rem
  space-xl: 1.5rem
---

## Brand & Style

This design system defines an ultra-compact, high-performance desktop utility application built specifically for modern Windows environments. It bridges technical network utility precision with the sleek, polished ergonomics of consumer cyber-tools.

### Design Movement & Aesthetic
- **Cyber-Tactile Glass & Precision Surfaces:** A fusion of modern Windows Fluent-inspired utility layering and dark cyber-surfaces. It utilizes deep slate foundations, luminous edge highlights, and focused neon accents.
- **Form Factor Constraint:** Designed for a compact vertical viewport (~400×680px), demanding relentless space efficiency, high visual density, and immediate glanceability.
- **Emotional Response:** Inspires absolute operational trust, high-speed responsiveness, stealth, and tactile satisfaction during connection state toggling.
- **Localization Context:** Primary microcopy and telemetry strings are structured in concise Turkish (`Bağlandı`, `Bağlantıyı Kes`, `Gecikme`, `Protokol`, `Ayrık Tünelleme`).

## Colors

The palette establishes high-contrast readability against multi-tiered dark slate canvases, punctuated by luminous neon vectors.

### Surface Architecture
- **Canvas Base:** `#0B0F17` (Deep Near-Black Slate) — Root window backdrop.
- **Surface Layer 1:** `#111827` (Card & Panel Base) — Primary structural blocks.
- **Surface Layer 2:** `#1E293B` (Interactive/Elevated Containers) — Inputs, list tiles, and secondary buttons.
- **Surface Border Stroke:** `rgba(255, 255, 255, 0.08)` to `rgba(139, 92, 246, 0.25)` on active state.

### Accents & Status Indicators
- **Primary Accent:** `#8B5CF6` (Electric Violet) and `#A78BFA` (Hover/Illumination) — Core actions, active switches, and brand focal points.
- **Secondary Telemetry Accent:** `#06B6D4` (Electric Cyan) — Bandwidth spikes, download counters, and encryption badges.
- **Operational Status:**
  - **Connected / Secure:** `#10B981` (Emerald) with soft radiant bloom.
  - **Warning / Handshake:** `#F59E0B` (Amber).
  - **Disconnected / Critical:** `#F43F5E` (Rose Red).
- **Text & Content Tiers:**
  - Primary: `#F9FAFB`
  - Secondary / Metric Labels: `#94A3B8`
  - Disabled / Muted: `#475569`

## Typography

Typography prioritizes legibility inside tight coordinate matrices.

- **Primary Interface (Inter):** Clean grotesque shapes tuned for screen rasterization at 11–13px. Headline tracking is tightly pulled (`-0.01em` to `-0.02em`) to maintain a native desktop application character.
- **Telemetry & Technical Specs (JetBrains Mono):** Monospaced glyphs are mandated for dynamic values (IP addresses, ping metrics `24 ms`, throughput `14.2 MB/s`, and port assignments) to avoid tabular jitter during real-time streaming updates.
- **Casing Rules:** Structural tags, sub-metrics, and status labels use uppercase transforms with explicit positive letter spacing (`0.04em`).

## Layout & Spacing

The layout is optimized for an ultra-compact fixed desktop window footprint (380–420px width, 640–720px height).

### Layout Rules
- **Container Architecture:** Single-column stacked layout with a fixed custom title bar (32px height), a central operational hero area, scrollable server/metrics drawer, and a pinned bottom navigation dock.
- **Horizontal Margins:** Fixed `0.75rem` (12px) margin from outer window borders keeps touch and mouse targets comfortably separated from window resize zones.
- **Rhythm:** Dense 4px-based spacing unit scale (`space-xs` through `space-xl`). Every block enforces predictable vertical flow to eliminate unexpected scrollbar appearance on native default heights.

## Elevation & Depth

Visual depth is achieved through surface tone gradations, luminous colored halos, and precise semi-transparent borders rather than heavy opaque drop shadows.

- **Window Shell:** Contained by a crisp `1px solid rgba(255, 255, 255, 0.08)` perimeter border.
- **Inactive Modules:** Cast no ambient shadow; rendered in `#111827` with subtle interior contrast.
- **Active Interactive Glows:**
  - **Connected State:** Dual ambient glow using `box-shadow: 0 0 24px rgba(16, 185, 129, 0.25), 0 0 4px rgba(16, 185, 129, 0.6)`.
  - **Primary Action (Connect Trigger):** Violet illumination `box-shadow: 0 4px 20px rgba(139, 92, 246, 0.35)`.
- **Modals & Flyouts:** Surface `#1E293B` elevated with `0 16px 32px rgba(0, 0, 0, 0.65)` and `backdrop-filter: blur(12px)`.

## Shapes

The design uses balanced, compact corner radii suited for a desktop tool:

- **Window Edge:** Matches native Windows rounded corner geometry (8px).
- **Cards & Primary Modules:** `0.5rem` (8px) for clean grouping without wasting perimeter screen estate.
- **Pills & Status Rings:** Dedicated circular tokens (`9999px`) reserved strictly for connection toggles, protocol tags, and indicator dots.
- **Inputs & Action Buttons:** `0.5rem` (8px).

## Components

### Title Bar (Windows Client Native Feel)
- Height: 32px. Integrated background matching `#0B0F17`.
- Left: Client brand mark (14px) and muted label ("phevy client").
- Right: Windows system controls (Minimize, Maximize/Restore, Close). Close control shifts to `#F43F5E` on hover with crisp 10px vector glyphs.

### Connect Hero Switch
- Central circular or rounded rectangular action module.
- Inactive: Slate ring `#1E293B` with muted text (`"BAĞLANILMADI"`).
- Connecting: Pulsing border transitioning from Violet (`#8B5CF6`) to Cyan (`#06B6D4`).
- Active: Vivid Emerald halo (`#10B981`), display copy reads `"GÜVENLİ BAĞLANTI"`.

### Server / Node Selector Card
- Compact interactive row (height 44px).
- Leading: Country flag glyph with latency ping tag in `JetBrains Mono` (`"28 ms"` in green).
- Middle: Node title (`"Frankfurt, Almanya"`).
- Trailing: Protocol badge (`"WireGuard"`, Cyan tint) and chevron.

### Buttons & Inputs
- **Primary Button:** `#8B5CF6` background, white text, bold weight, with subtle violet inner-top edge border (`1px solid rgba(255, 255, 255, 0.2)`).
- **Ghost Action:** Background transparent, border `1px solid rgba(255, 255, 255, 0.1)`, hover `#1E293B`.
- **Search & Config Inputs:** Background `#111827`, height 36px, typography `body-sm`, placeholder `#475569`, focused ring `1px solid #8B5CF6`.

### Telemetry Stat Grid
- Two-column compact cards presenting `"İndirme"` (Down) and `"Yükleme"` (Up) metrics.
- Uses `JetBrains Mono` for live numerical feedback, with sub-pixel sparklines tinted in Cyan (`#06B6D4`).