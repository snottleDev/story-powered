# Bridge Scene — Asset Specification

Base canvas: 1080×1920 (portrait). Comic panel interior: 1000×1750.
All assets PNG with transparency where noted. Deliver at 1× resolution.

## Background Layers

| Asset | Dimensions | Description |
|-------|-----------|-------------|
| `sky_bg.png` | 1000×1200 | Sky with horizon line. Painterly style, single version — tinted via color modulate to shift from dawn blue-grey through midday neutral to golden hour warm. |
| `landscape_mid.png` | 1000×400 | Silhouetted distant hills/earth along horizon. Transparent top edge, solid at bottom. Dark natural tones. Parallax 0.3. |
| `construction_fg.png` | 1000×500 | Construction crew silhouettes: workers, crane, earth-moving equipment. Mid-ground depth. Transparent edges. Parallax 0.6. |

## Bridge Sections

| Asset | Dimensions | Description |
|-------|-----------|-------------|
| `bridge_ghost_full.png` | 1000×300 | Faint planned bridge outline spanning the horizon — blueprint/architectural drawing feel. |
| `bridge_section_1_ghost.png` | 210×130 | Section 1 outline — left span. Light, semi-transparent. |
| `bridge_section_2_ghost.png` | 210×130 | Section 2 outline — left-center span. |
| `bridge_section_3_ghost.png` | 210×130 | Section 3 outline — right-center span. |
| `bridge_section_4_ghost.png` | 210×130 | Section 4 outline — right span. |
| `bridge_section_1_built.png` | 210×130 | Section 1 solid — illustrated/painted bridge segment. |
| `bridge_section_2_built.png` | 210×130 | Section 2 solid. |
| `bridge_section_3_built.png` | 210×130 | Section 3 solid. |
| `bridge_section_4_built.png` | 210×130 | Section 4 solid. |

## Fence

| Asset | Dimensions | Description |
|-------|-----------|-------------|
| `fence.png` | 1000×200 | Chain-link or wooden fence running horizontally. Transparent top portion so bridge is visible through gaps. Parallax 1.0. |

## Characters

| Asset | Dimensions | Description |
|-------|-----------|-------------|
| `father_standing.png` | 300×800 | Father silhouette — head and shoulders prominent, facing the bridge. Dark figure. Only the top ~70px visible initially; full body revealed by camera pan. |
| `daughter_standing.png` | 200×700 | Daughter silhouette — smaller figure beside father, also facing the bridge. Fully hidden at start, fades in during stage 2 pan. |
| `family_kneeling.png` | 500×600 | Father kneeling with arm around daughter, both looking toward the completed bridge. Emotional reveal pose. Replaces standing silhouettes at stage 4 completion. |

## Speech Bubble

| Asset | Dimensions | Description |
|-------|-----------|-------------|
| `bubble_tail_left.png` | 60×40 | Speech bubble tail pointing down-left (toward father). White with slight shadow. |
| `bubble_tail_right.png` | 60×40 | Speech bubble tail pointing down-right (toward daughter). White with slight shadow. |

## Style Notes

- Illustration style: warm, slightly textured, hand-drawn/painterly feel
- Color palette shifts from cool dawn to golden warm across the 5 daylight stages
- Characters are silhouettes (no facial detail) — emotion conveyed through posture
- Bridge should feel like infrastructure being built — concrete, steel, arches
- The fence grounds the viewer's perspective: we're watching from behind it
- All transparency should use soft/feathered edges, not hard cutoffs
