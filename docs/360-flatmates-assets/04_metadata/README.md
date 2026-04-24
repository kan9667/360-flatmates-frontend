# 360 Flatmates Asset Package

This package contains source crops, brand basics, prompt specs, manifests, and standalone screen images derived from the composite board in `docs/ChatGPT Image Apr 23, 2026, 02_39_48 AM.png`.

## Source of truth
- Visual source: the composite board image
- Product-content source for adapted/replaced screens: `docs/prd.md`

## Build process
- Run `python3 tools/generate_360_assets.py`
- Optional image-model overrides can be placed in `tmp/generated_overrides/` using `{nn}_{slug}.png` naming before re-running the script.

## Deliverables
- `01_brand/` for the minimal brand basics pack
- `02_screens/` for per-screen source crops and final outputs
- `03_exports/` for flattened export copies
- `04_metadata/` for manifests, prompts, lineage, and QA notes

## Current implementation note
- If a screen has no override in `tmp/generated_overrides/`, its final image is the upscaled source phone crop baseline.
- Replacement and adaptation intent is fully documented in prompt files and inventory metadata.
