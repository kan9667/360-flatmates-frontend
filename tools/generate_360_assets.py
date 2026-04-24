from __future__ import annotations

import json
import shutil
from dataclasses import dataclass
from datetime import datetime, timezone
from pathlib import Path
from typing import Dict, List, Tuple

from PIL import Image, ImageDraw, ImageFilter, ImageFont


ROOT = Path("/Users/sakshammittal/Documents/360ghar/github/360ghar/360-flatmates")
SOURCE_IMAGE = ROOT / "docs" / "ChatGPT Image Apr 23, 2026, 02_39_48 AM.png"
PRD_PATH = ROOT / "docs" / "prd.md"
DELIVERABLES = ROOT / "deliverables" / "360-flatmates-assets"
OVERRIDES = ROOT / "tmp" / "generated_overrides"
SR_MODEL = ROOT / "tmp" / "models" / "EDSR_x4.pb"

MASTER_SIZE = (1290, 2796)
REVIEW_SIZE = (430, 932)
WEBP_SIZE = (860, 1864)

PALETTE = {
    "brand.primary": "#5F46FF",
    "success": "#2CC556",
    "warning": "#FFBE00",
    "text.primary": "#0F172A",
    "text.secondary": "#64748B",
    "surface.background": "#F5F5F9",
    "surface.card": "#FFFFFF",
    "border.subtle": "#D9DDF2",
}

TYPOGRAPHY = {
    "heading.1": {"size": 28, "weight": "Bold"},
    "heading.2": {"size": 20, "weight": "SemiBold"},
    "heading.3": {"size": 16, "weight": "SemiBold"},
    "body.1": {"size": 14, "weight": "Regular"},
    "body.2": {"size": 12, "weight": "Regular"},
    "caption": {"size": 11, "weight": "Regular"},
}

ICON_NAMES = [
    "home",
    "search",
    "chat",
    "heart",
    "bell",
    "user",
    "location-pin",
    "filter",
    "calendar",
    "document",
    "wallet",
    "settings",
    "help",
    "logout",
    "back-arrow",
    "chevron-right",
    "plus",
    "upload",
    "bookmark",
    "check-circle",
    "radio",
    "more-horizontal",
]


@dataclass(frozen=True)
class ScreenSpec:
    number: int
    slug: str
    title: str
    classification: str
    strategy: str
    row: int
    col: int
    phone_box: Tuple[int, int, int, int]
    context_box: Tuple[int, int, int, int]
    prompt: str
    replacement_note: str


def clamp_box(box: Tuple[int, int, int, int], width: int, height: int) -> Tuple[int, int, int, int]:
    x1, y1, x2, y2 = box
    return (
        max(0, x1),
        max(0, y1),
        min(width, x2),
        min(height, y2),
    )


def centers() -> List[int]:
    return [297, 413, 529, 645, 761, 877, 993, 1109, 1225, 1341]


def make_screen_specs() -> List[ScreenSpec]:
    top_y = (248, 266, 346, 526)
    bottom_y = (556, 582, 346, 824)
    phone_w = 98
    context_w = 112

    screen_meta = [
        ("splash", "Splash", "Keep", "faithful", "Faithfully recreate the splash screen as a standalone mobile UI screen. Keep the 360 Flatmates wordmark, illustration-led composition, indigo progress line, and the line 'Find. Connect. Live Together.' Preserve the bright, airy white background and minimal onboarding feel.", ""),
        ("onboarding", "Onboarding", "Keep", "faithful", "Faithfully recreate the onboarding screen as a standalone mobile UI screen. Keep the centered flatmate illustration, short headline, supporting copy, progress dots, 'Skip', and primary indigo button. Preserve the same composition and visual tone from the board.", ""),
        ("choose-role", "Choose Role", "Adapt", "hybrid", "Recreate the choose role screen in the same visual style and layout, but change the content to the PRD's three-card role selection: 'Room Poster', 'Co-Hunter', and 'Open to Both'. Keep the rounded cards, soft shadows, outline icons, and indigo primary CTA.", "Adapt two-card concept to three PRD modes."),
        ("basic-information", "Basic Information", "Adapt", "hybrid", "Recreate the location/basic information step in the same style, but turn it into a PRD-aligned basic information form with fields for First name, Age, Profession, City, and Preferred locality. Keep the single primary CTA and soft form styling.", "Reframe location picker into PRD basic information form."),
        ("home-discover", "Home / Discover", "Adapt", "hybrid", "Recreate the Home / Discover screen in the board's exact visual language, but rewrite content for a flatmate-first home feed: sections 'Picked for You', 'New in Bangalore', and 'Moving Soon', with compatibility-oriented listing cards and subtle chips.", "Keep home layout; rewrite sections and cards."),
        ("search-filters", "Search & Filters", "Adapt", "hybrid", "Recreate the search and filters screen with the same structure, but rewrite filters around vibe, timeline, verification, and locality for flatmate discovery. Preserve the search bar, soft section dividers, chips, and bottom CTA.", "Keep filter layout; use PRD-compatible filters."),
        ("flat-details", "Flat Details", "Adapt", "hybrid", "Recreate the details screen with the same premium property-card composition, but rewrite the content as a hybrid person-plus-property profile: compatibility score, flatmates, rent split, amenities, move-in date, and action buttons.", "Keep layout; convert to hybrid compatibility detail view."),
        ("chat", "Chat", "Keep", "faithful", "Faithfully recreate the chat screen as a standalone mobile UI screen. Keep the avatar header, alternating message bubbles, indigo outgoing bubbles, light incoming bubbles, and bottom message field.", ""),
        ("likes-chat", "Likes & Chat", "Replace", "replace", "Generate a polished mobile UI screen in the exact 360 Flatmates style titled 'Likes & Chat'. Show segmented tabs 'Likes' and 'Chats', a grid of blurred profile cards with Match buttons, then a chat list below or in the alternate tab state. Active bottom nav tab: Likes & Chat. Use Poppins, indigo #5F46FF, light background, white cards, thin outline icons.", "Replace bookings flow with PRD Likes & Chat tab."),
        ("schedule-visit", "Schedule Visit", "Replace", "replace", "Generate a mobile UI screen in the exact 360 Flatmates style titled 'Schedule Visit'. Show sections Date, Time, Add a note, with rounded selectors, time chips, a note field, and a primary button 'Send Visit Request'. Include subtle reference to in-chat visit coordination. Use Poppins, indigo #5F46FF, white cards, light background, restrained shadows.", "Replace move-in checklist with PRD visit scheduling flow."),
        ("add-listing", "Add Listing", "Adapt", "hybrid", "Recreate the add listing screen in the same style, but ensure the form reflects Room Poster listing fields such as locality, rent, room type, furnishing, and flat details. Preserve the clean one-screen form layout and indigo primary CTA.", "Keep form layout; align fields to PRD listing builder."),
        ("photos", "Photos", "Keep", "faithful", "Faithfully recreate the photos upload screen as a standalone mobile UI screen. Keep the section title, helper copy, image thumbnails, add-more prompt, progress dots, and indigo primary button.", ""),
        ("preferences", "Preferences", "Adapt", "hybrid", "Recreate the preferences screen in the same style, but rewrite it around lifestyle and compatibility: food habits, smoking, sleep schedule, work style, guests policy, pets, budget, and move-in timeline. Preserve the stacked preference controls and primary CTA.", "Replace rental-filter semantics with lifestyle quiz semantics."),
        ("review-publish", "Review & Publish", "Adapt", "hybrid", "Recreate the review screen in the same style, but change it to a review-and-submit state with moderation messaging. Show listing preview, quick facts, and an indigo CTA such as 'Publish Listing', plus note that the listing will go under review.", "Keep review layout; add moderation messaging."),
        ("profile", "Profile", "Keep", "faithful", "Faithfully recreate the profile screen as a standalone mobile UI screen. Keep the circular avatar, user name, bio summary, list-based navigation items, and clean white-card layout.", ""),
        ("listing-under-review", "Listing Under Review", "Replace", "replace", "Generate a mobile UI screen in the exact 360 Flatmates style titled 'Listing Under Review'. Show an indigo status chip 'Under Review', support copy 'We'll review your listing within 24 hours', a 'What happens next' section, a small listing preview card, and CTAs 'Go to Home Feed' and 'View Listing'.", "Replace payments screen with PRD under-review state."),
        ("notifications", "Notifications", "Adapt", "hybrid", "Recreate the notifications screen in the same style, but focus the items on chat messages, listing approval updates, edit requests, and visit confirmations. Preserve the stacked notification-card pattern.", "Keep notification layout; use PRD notification content."),
        ("help-safety", "Help & Safety", "Adapt", "hybrid", "Recreate the help and support screen in the same style, but retitle and refocus it as 'Help & Safety' with FAQ, report a user, payments and refunds removed, privacy/account help, and contact support. Preserve the searchable support layout.", "Keep support layout; focus on safety and privacy."),
        ("settings", "Settings", "Keep", "faithful", "Faithfully recreate the settings screen as a standalone mobile UI screen. Keep the sectioned list layout, chevrons, and dense settings rows in the board's original visual language.", ""),
        ("post-manage-property", "Post & Manage Property", "Replace", "replace", "Generate a mobile UI screen in the exact 360 Flatmates style titled 'Post & Manage Property'. Show a primary 'New Listing' CTA, an 'Active Listings' section with rounded listing cards, status badges like Live or Under Review, metrics such as Match Count and Profile Views, and quick actions Edit, Pause, Renew, Boost, View Stats, and Share. Active bottom nav tab: Post / Manage Property.", "Replace drawer with room-poster manage property screen."),
    ]

    specs: List[ScreenSpec] = []
    x_positions = centers()
    for idx in range(1, 21):
        row = 1 if idx <= 10 else 2
        col = idx if row == 1 else idx - 10
        center_x = x_positions[col - 1]
        y_cfg = top_y if row == 1 else bottom_y
        ctx_top, phone_top, ctx_h, phone_bottom = y_cfg
        phone_bottom_extra = 0
        phone_top_extra = 0
        if idx == 7:
            phone_top_extra = -10
            phone_bottom_extra = 14
        if idx == 8:
            phone_bottom_extra = 12
        if idx == 10:
            phone_bottom_extra = 14
        if idx == 15:
            phone_top_extra = -8
        if idx == 20:
            phone_bottom_extra = 16

        phone_box = clamp_box(
            (
                int(center_x - phone_w / 2),
                phone_top + phone_top_extra,
                int(center_x + phone_w / 2),
                phone_bottom + phone_bottom_extra,
            ),
            1536,
            1024,
        )
        context_box = clamp_box(
            (
                int(center_x - context_w / 2),
                ctx_top,
                int(center_x + context_w / 2),
                phone_bottom + phone_bottom_extra,
            ),
            1536,
            1024,
        )

        slug, title, classification, strategy, prompt, replacement_note = screen_meta[idx - 1]
        specs.append(
            ScreenSpec(
                number=idx,
                slug=slug,
                title=title,
                classification=classification,
                strategy=strategy,
                row=row,
                col=col,
                phone_box=phone_box,
                context_box=context_box,
                prompt=prompt,
                replacement_note=replacement_note,
            )
        )

    return specs


def mkdirs() -> Dict[str, Path]:
    paths = {
        "root": DELIVERABLES,
        "source_composite": DELIVERABLES / "00_source" / "composite",
        "source_references": DELIVERABLES / "00_source" / "references",
        "brand_logos": DELIVERABLES / "01_brand" / "logos",
        "brand_colors": DELIVERABLES / "01_brand" / "colors",
        "brand_typography": DELIVERABLES / "01_brand" / "typography",
        "brand_icons": DELIVERABLES / "01_brand" / "icons",
        "brand_components": DELIVERABLES / "01_brand" / "components",
        "brand_references": DELIVERABLES / "01_brand" / "references",
        "screens": DELIVERABLES / "02_screens",
        "exports_png": DELIVERABLES / "03_exports" / "png",
        "exports_webp": DELIVERABLES / "03_exports" / "webp",
        "manifest": DELIVERABLES / "04_metadata" / "manifest",
        "prompts": DELIVERABLES / "04_metadata" / "prompts",
        "reviews": DELIVERABLES / "04_metadata" / "reviews",
        "lineage": DELIVERABLES / "04_metadata" / "lineage",
    }
    for path in paths.values():
        path.mkdir(parents=True, exist_ok=True)
    return paths


def font(size: int, bold: bool = False) -> ImageFont.FreeTypeFont | ImageFont.ImageFont:
    candidates = [
        "/System/Library/Fonts/Supplemental/Arial Unicode.ttf",
        "/System/Library/Fonts/Supplemental/Arial.ttf",
        "/System/Library/Fonts/SFNS.ttf",
    ]
    for candidate in candidates:
        if Path(candidate).exists():
            try:
                return ImageFont.truetype(candidate, size=size)
            except OSError:
                continue
    return ImageFont.load_default()


def draw_wrapped_text(draw: ImageDraw.ImageDraw, xy: Tuple[int, int], text: str, max_width: int, fill: str, font_obj) -> int:
    words = text.split()
    lines = []
    current = []
    for word in words:
        test = " ".join(current + [word]).strip()
        if draw.textlength(test, font=font_obj) <= max_width or not current:
            current.append(word)
        else:
            lines.append(" ".join(current))
            current = [word]
    if current:
        lines.append(" ".join(current))
    x, y = xy
    line_h = int(font_obj.size * 1.35) if hasattr(font_obj, "size") else 18
    for line in lines:
        draw.text((x, y), line, fill=fill, font=font_obj)
        y += line_h
    return y


def make_logo_svg(wordmark_path: Path, mark_path: Path) -> None:
    wordmark = f"""<svg xmlns="http://www.w3.org/2000/svg" width="640" height="300" viewBox="0 0 640 300" fill="none">
  <rect width="640" height="300" fill="white"/>
  <path d="M80 86C80 48.4446 110.445 18 148 18H191C225.242 18 253 45.7583 253 80C253 114.242 225.242 142 191 142H148V190H206" stroke="#0F172A" stroke-width="28" stroke-linecap="round" stroke-linejoin="round"/>
  <path d="M297 68C297 40.3858 319.386 18 347 18H395C441.944 18 480 56.0558 480 103V190" stroke="#0F172A" stroke-width="28" stroke-linecap="round" stroke-linejoin="round"/>
  <circle cx="404" cy="103" r="64" stroke="#5F46FF" stroke-width="28"/>
  <path d="M450 34C473 48 488 74 488 103" stroke="#5F46FF" stroke-width="28" stroke-linecap="round"/>
  <path d="M438 41L489 44L473 88" stroke="#5F46FF" stroke-width="18" stroke-linecap="round" stroke-linejoin="round"/>
  <text x="80" y="248" fill="#5F46FF" font-family="Arial, sans-serif" font-size="56" font-weight="700" letter-spacing="8">FLATMATES</text>
</svg>
"""
    mark = """<svg xmlns="http://www.w3.org/2000/svg" width="320" height="220" viewBox="0 0 320 220" fill="none">
  <rect width="320" height="220" fill="white"/>
  <path d="M20 68C20 40.3858 42.3858 18 70 18H118C164.944 18 203 56.0558 203 103V190" stroke="#0F172A" stroke-width="24" stroke-linecap="round" stroke-linejoin="round"/>
  <circle cx="127" cy="103" r="64" stroke="#5F46FF" stroke-width="24"/>
  <path d="M173 34C196 48 211 74 211 103" stroke="#5F46FF" stroke-width="24" stroke-linecap="round"/>
  <path d="M161 41L212 44L196 88" stroke="#5F46FF" stroke-width="16" stroke-linecap="round" stroke-linejoin="round"/>
</svg>
"""
    wordmark_path.write_text(wordmark)
    mark_path.write_text(mark)


def render_swatch_sheet(path: Path) -> None:
    img = Image.new("RGB", (1400, 900), PALETTE["surface.background"])
    draw = ImageDraw.Draw(img)
    title_font = font(40, True)
    body_font = font(24)
    draw.text((60, 50), "360 Flatmates Palette", fill=PALETTE["text.primary"], font=title_font)
    x, y = 60, 150
    for idx, (token, hex_color) in enumerate(PALETTE.items()):
        draw.rounded_rectangle((x, y, x + 220, y + 140), radius=24, fill=hex_color, outline=PALETTE["border.subtle"], width=2)
        draw.text((x, y + 160), token, fill=PALETTE["text.primary"], font=body_font)
        draw.text((x, y + 195), hex_color, fill=PALETTE["text.secondary"], font=body_font)
        x += 300
        if (idx + 1) % 4 == 0:
            x = 60
            y += 280
    img.save(path)


def render_typography_specimen(path_png: Path) -> None:
    img = Image.new("RGB", (1600, 1100), "white")
    draw = ImageDraw.Draw(img)
    draw.text((60, 50), "360 Flatmates Typography", fill=PALETTE["text.primary"], font=font(44, True))
    y = 150
    sample = "Poppins style hierarchy"
    for token, spec in TYPOGRAPHY.items():
        size = spec["size"] * 3
        draw.text((60, y), f"{token}  {spec['size']}px / {spec['weight']}", fill=PALETTE["text.secondary"], font=font(24))
        draw.text((60, y + 42), sample, fill=PALETTE["text.primary"], font=font(size, "Bold" in spec["weight"]))
        y += max(120, size + 70)
    img.save(path_png)


def icon_svg(name: str) -> str:
    stroke = PALETTE["brand.primary"]
    common = f'stroke="{stroke}" stroke-width="2.4" stroke-linecap="round" stroke-linejoin="round" fill="none"'
    body = {
        "home": f'<path {common} d="M5 11.5 12 5l7 6.5V19H5z"/><path {common} d="M10 19v-5h4v5"/>',
        "search": f'<circle {common} cx="10" cy="10" r="5.5"/><path {common} d="M14.5 14.5 19 19"/>',
        "chat": f'<path {common} d="M5 6h14v10H9l-4 3z"/>',
        "heart": f'<path {common} d="M12 19s-6-3.7-8-7.7C2.4 8 4.3 5 7.5 5c1.8 0 3.1.9 4.5 2.4C13.4 5.9 14.7 5 16.5 5 19.7 5 21.6 8 20 11.3 18 15.3 12 19 12 19z"/>',
        "bell": f'<path {common} d="M7 9a5 5 0 0 1 10 0v4l2 3H5l2-3z"/><path {common} d="M10 19a2 2 0 0 0 4 0"/>',
        "user": f'<circle {common} cx="12" cy="8" r="3.5"/><path {common} d="M5 19a7 7 0 0 1 14 0"/>',
        "location-pin": f'<path {common} d="M12 20s6-5.8 6-10a6 6 0 1 0-12 0c0 4.2 6 10 6 10z"/><circle {common} cx="12" cy="10" r="2"/>',
        "filter": f'<path {common} d="M4 6h16M7 12h10M10 18h4"/>',
        "calendar": f'<rect {common} x="4" y="6" width="16" height="14" rx="2"/><path {common} d="M8 4v4M16 4v4M4 10h16"/>',
        "document": f'<path {common} d="M7 3h7l5 5v13H7z"/><path {common} d="M14 3v5h5M10 13h6M10 17h6"/>',
        "wallet": f'<rect {common} x="4" y="7" width="16" height="11" rx="2"/><path {common} d="M15 12h5v3h-5z"/>',
        "settings": f'<circle {common} cx="12" cy="12" r="3"/><path {common} d="M12 4v2M12 18v2M4 12h2M18 12h2M6.3 6.3l1.4 1.4M16.3 16.3l1.4 1.4M17.7 6.3l-1.4 1.4M7.7 16.3l-1.4 1.4"/>',
        "help": f'<circle {common} cx="12" cy="12" r="9"/><path {common} d="M9.5 9.5a2.5 2.5 0 1 1 4.2 1.8c-.9.8-1.7 1.4-1.7 2.7"/><circle cx="12" cy="17" r="1" fill="{stroke}"/>',
        "logout": f'<path {common} d="M9 5H5v14h4"/><path {common} d="M13 8l4 4-4 4"/><path {common} d="M8 12h9"/>',
        "back-arrow": f'<path {common} d="M15 5 8 12l7 7"/><path {common} d="M8 12h10"/>',
        "chevron-right": f'<path {common} d="M9 5l7 7-7 7"/>',
        "plus": f'<path {common} d="M12 5v14M5 12h14"/>',
        "upload": f'<path {common} d="M12 16V6"/><path {common} d="m8 10 4-4 4 4"/><path {common} d="M5 19h14"/>',
        "bookmark": f'<path {common} d="M7 4h10v16l-5-3-5 3z"/>',
        "check-circle": f'<circle {common} cx="12" cy="12" r="8"/><path {common} d="m8.5 12.5 2.4 2.4 4.8-5.2"/>',
        "radio": f'<circle {common} cx="12" cy="12" r="7"/><circle cx="12" cy="12" r="3" fill="{stroke}"/>',
        "more-horizontal": f'<circle cx="7" cy="12" r="1.5" fill="{stroke}"/><circle cx="12" cy="12" r="1.5" fill="{stroke}"/><circle cx="17" cy="12" r="1.5" fill="{stroke}"/>',
    }[name]
    return f'<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24">{body}</svg>'


def write_icons(icons_dir: Path) -> None:
    for name in ICON_NAMES:
        svg_path = icons_dir / f"360f_icon_{name}_24_outline.svg"
        svg_path.write_text(icon_svg(name))


def render_component_basics(path: Path) -> None:
    img = Image.new("RGB", (1400, 1000), PALETTE["surface.background"])
    draw = ImageDraw.Draw(img)
    draw.text((60, 50), "360 Flatmates Component Basics", fill=PALETTE["text.primary"], font=font(42, True))
    # Primary button
    draw.rounded_rectangle((80, 180, 560, 260), radius=26, fill=PALETTE["brand.primary"])
    draw.text((245, 204), "Primary Button", fill="white", font=font(28, True))
    # Secondary button
    draw.rounded_rectangle((80, 300, 560, 380), radius=26, fill="white", outline=PALETTE["brand.primary"], width=3)
    draw.text((225, 324), "Secondary Button", fill=PALETTE["brand.primary"], font=font(28))
    # Search field
    draw.rounded_rectangle((80, 440, 700, 520), radius=24, fill="white", outline=PALETTE["border.subtle"], width=2)
    draw.text((120, 463), "Search field", fill=PALETTE["text.secondary"], font=font(26))
    # Chips
    chip_x = 80
    for label in ["Nearby", "1 BHK", "Furnished"]:
        w = int(draw.textlength(label, font=font(24))) + 60
        draw.rounded_rectangle((chip_x, 590, chip_x + w, 650), radius=30, fill="white", outline=PALETTE["border.subtle"], width=2)
        draw.text((chip_x + 30, 607), label, fill=PALETTE["brand.primary"], font=font(24))
        chip_x += w + 20
    # Bottom nav
    draw.rounded_rectangle((80, 730, 660, 850), radius=48, fill="white", outline=PALETTE["border.subtle"], width=2)
    labels = ["Home", "Search", "Add", "Chat", "Profile"]
    for i, label in enumerate(labels):
        cx = 145 + i * 116
        color = PALETTE["brand.primary"] if i == 0 else PALETTE["text.secondary"]
        draw.ellipse((cx - 12, 760, cx + 12, 784), outline=color, width=3)
        draw.text((cx - 28, 803), label, fill=color, font=font(18))
    # Card shell
    draw.rounded_rectangle((780, 190, 1240, 540), radius=28, fill="white", outline=PALETTE["border.subtle"], width=2)
    draw.rectangle((820, 230, 1200, 400), fill="#EAE6FF")
    draw.text((820, 430), "Standard Card Shell", fill=PALETTE["text.primary"], font=font(30, True))
    draw.text((820, 475), "Rounded, white, subtle border, soft hierarchy", fill=PALETTE["text.secondary"], font=font(22))
    # List row
    y = 620
    for label in ["Edit Profile", "Privacy & Security", "Notification Settings"]:
        draw.rounded_rectangle((780, y, 1240, y + 86), radius=18, fill="white", outline=PALETTE["border.subtle"], width=2)
        draw.text((820, y + 26), label, fill=PALETTE["text.primary"], font=font(24))
        draw.text((1200, y + 26), ">", fill=PALETTE["text.secondary"], font=font(24))
        y += 104
    img.save(path)


def render_reference_sheet(source: Image.Image, path: Path, title: str, crops: List[Tuple[int, int, int, int]]) -> None:
    canvas = Image.new("RGB", (1400, 900), "white")
    draw = ImageDraw.Draw(canvas)
    draw.text((50, 40), title, fill=PALETTE["text.primary"], font=font(42, True))
    x, y = 50, 130
    max_h = 0
    for idx, box in enumerate(crops):
        crop = source.crop(box)
        crop.thumbnail((260, 620))
        canvas.paste(crop, (x, y))
        draw.rounded_rectangle((x, y, x + crop.width, y + crop.height), radius=16, outline=PALETTE["border.subtle"], width=2)
        x += 300
        max_h = max(max_h, crop.height)
        if (idx + 1) % 4 == 0:
            x = 50
            y += max_h + 70
            max_h = 0
    canvas.save(path)


def save_json(path: Path, data) -> None:
    path.write_text(json.dumps(data, indent=2, ensure_ascii=True) + "\n")


def upscale_crop_with_sr(phone_crop: Image.Image) -> Image.Image:
    try:
        import cv2
        import numpy as np
    except Exception:
        return phone_crop.resize(MASTER_SIZE, Image.Resampling.LANCZOS)

    if not SR_MODEL.exists():
        return phone_crop.resize(MASTER_SIZE, Image.Resampling.LANCZOS)

    sr = cv2.dnn_superres.DnnSuperResImpl_create()
    sr.readModel(str(SR_MODEL))
    sr.setModel("edsr", 4)
    arr = cv2.cvtColor(np.array(phone_crop.convert("RGB")), cv2.COLOR_RGB2BGR)
    upscaled = sr.upsample(arr)
    upscaled = cv2.cvtColor(upscaled, cv2.COLOR_BGR2RGB)
    upscaled_img = Image.fromarray(upscaled)
    # Preserve the existing screen design while reducing blur. Use a light sharpen pass
    # after super-resolution, then scale to the master export size.
    upscaled_img = upscaled_img.resize(MASTER_SIZE, Image.Resampling.LANCZOS)
    return upscaled_img.filter(ImageFilter.UnsharpMask(radius=1.6, percent=180, threshold=2))


def build_assets() -> None:
    paths = mkdirs()
    source = Image.open(SOURCE_IMAGE).convert("RGB")
    specs = make_screen_specs()
    generated_at = datetime.now(timezone.utc).isoformat()

    shutil.copy2(SOURCE_IMAGE, paths["source_composite"] / SOURCE_IMAGE.name)
    shutil.copy2(PRD_PATH, paths["source_references"] / PRD_PATH.name)

    # Source panel references
    ref_regions = {
        "logo_reference.png": (0, 0, 250, 210),
        "design_system_reference.png": (0, 200, 235, 845),
        "key_features_reference.png": (280, 0, 712, 184),
        "journey_reference.png": (726, 0, 1270, 184),
        "user_roles_reference.png": (1276, 0, 1536, 184),
    }
    for name, box in ref_regions.items():
        source.crop(box).save(paths["source_references"] / name)

    # Brand basics
    wordmark_svg = paths["brand_logos"] / "360f_logo_wordmark_primary_rgb.svg"
    mark_svg = paths["brand_logos"] / "360f_logo_mark_360_primary_rgb.svg"
    make_logo_svg(wordmark_svg, mark_svg)

    render_swatch_sheet(paths["brand_colors"] / "360f_palette_swatches.png")
    save_json(paths["brand_colors"] / "360f_palette_tokens.json", PALETTE)
    render_typography_specimen(paths["brand_typography"] / "360f_typography_specimen.png")
    save_json(paths["brand_typography"] / "360f_typography_tokens.json", TYPOGRAPHY)
    write_icons(paths["brand_icons"])
    render_component_basics(paths["brand_components"] / "360f_component_basics.png")
    save_json(
        paths["brand_components"] / "360f_component_tokens.json",
        {
            "primary_button": {"radius": 26, "fill": PALETTE["brand.primary"], "text": "#FFFFFF"},
            "secondary_button": {"radius": 26, "fill": "#FFFFFF", "stroke": PALETTE["brand.primary"]},
            "search_field": {"radius": 24, "fill": "#FFFFFF", "stroke": PALETTE["border.subtle"]},
            "filter_chip": {"radius": 30, "fill": "#FFFFFF", "stroke": PALETTE["border.subtle"]},
            "bottom_nav": {"radius": 48, "fill": "#FFFFFF", "stroke": PALETTE["border.subtle"]},
            "card_shell": {"radius": 28, "fill": "#FFFFFF", "stroke": PALETTE["border.subtle"]},
            "list_row": {"radius": 18, "fill": "#FFFFFF", "stroke": PALETTE["border.subtle"]},
        },
    )

    render_reference_sheet(
        source,
        paths["brand_references"] / "360f_avatar_style_ref.png",
        "Avatar Style Reference",
        [(1283, 47, 1530, 174), (714, 580, 823, 825), (1326, 581, 1499, 823), (1041, 266, 1164, 529)],
    )
    render_reference_sheet(
        source,
        paths["brand_references"] / "360f_illustration_style_ref.png",
        "Illustration Style Reference",
        [(20, 0, 250, 210), (247, 266, 347, 527), (361, 266, 462, 527)],
    )

    model_logo_override = OVERRIDES / "logo_wordmark.png"
    model_logo_export = None
    if model_logo_override.exists():
        model_logo_export = paths["brand_logos"] / "360f_logo_wordmark_primary_rgb_model.png"
        shutil.copy2(model_logo_override, model_logo_export)

    inventories = []
    source_map = {}
    asset_manifest = {"generated_at": generated_at, "assets": []}

    for spec in specs:
        screen_dir = paths["screens"] / f"{spec.number:02d}_{spec.slug}"
        screen_dir.mkdir(parents=True, exist_ok=True)

        context_path = screen_dir / f"360f_{spec.number:02d}_{spec.slug}_context-crop_{spec.context_box[2]-spec.context_box[0]}x{spec.context_box[3]-spec.context_box[1]}_reference.png"
        phone_path = screen_dir / f"360f_{spec.number:02d}_{spec.slug}_phone-crop_{spec.phone_box[2]-spec.phone_box[0]}x{spec.phone_box[3]-spec.phone_box[1]}_reference.png"
        final_path = screen_dir / f"360f_{spec.number:02d}_{spec.slug}_primary_{MASTER_SIZE[0]}x{MASTER_SIZE[1]}_final.png"
        review_path = screen_dir / f"360f_{spec.number:02d}_{spec.slug}_primary_{REVIEW_SIZE[0]}x{REVIEW_SIZE[1]}_review.png"
        webp_path = screen_dir / f"360f_{spec.number:02d}_{spec.slug}_primary_{WEBP_SIZE[0]}x{WEBP_SIZE[1]}_review.webp"
        lineage_path = paths["lineage"] / f"360f_{spec.number:02d}_{spec.slug}_lineage.json"
        prompt_path = paths["prompts"] / f"360f_{spec.number:02d}_{spec.slug}_primary_prompt.md"

        context_crop = source.crop(spec.context_box)
        phone_crop = source.crop(spec.phone_box)
        context_crop.save(context_path)
        phone_crop.save(phone_path)

        override_path = OVERRIDES / f"{spec.number:02d}_{spec.slug}.png"
        if override_path.exists():
            final_img = Image.open(override_path).convert("RGB")
            render_method = "image-model-override"
            source_asset = str(override_path.relative_to(ROOT))
        else:
            final_img = upscale_crop_with_sr(phone_crop)
            render_method = "source-crop-superres-upscale"
            source_asset = str(phone_path.relative_to(ROOT))

        final_img.save(final_path)
        final_img.resize(REVIEW_SIZE, Image.Resampling.LANCZOS).save(review_path)
        final_img.resize(WEBP_SIZE, Image.Resampling.LANCZOS).save(webp_path, format="WEBP", quality=92)
        shutil.copy2(final_path, paths["exports_png"] / final_path.name)
        shutil.copy2(webp_path, paths["exports_webp"] / webp_path.name)

        prompt_text = "\n".join(
            [
                f"# 360 Flatmates Screen {spec.number:02d}: {spec.title}",
                "",
                f"Classification: `{spec.classification}`",
                f"Strategy: `{spec.strategy}`",
                "",
                "Use case: ui-mockup",
                "Asset type: mobile app screen",
                f"Primary request: {spec.prompt}",
                "Style/medium: polished mobile app UI mockup",
                "Color palette: primary indigo #5F46FF, dark navy #0F172A, white cards, subtle borders, light neutral background",
                "Typography: Poppins-style hierarchy with airy spacing and thin rounded outline icons",
                "Constraints: portrait mobile screen only; no watermark; keep white/light UI, rounded geometry, restrained shadows",
                "Avoid: dark mode, clutter, heavy gradients, skeuomorphic textures, mismatched icon weights, oversaturated colors",
            ]
        )
        prompt_path.write_text(prompt_text + "\n")

        lineage = {
            "screen_id": f"{spec.number:02d}_{spec.slug}",
            "generated_at": generated_at,
            "render_method": render_method,
            "source_asset": source_asset,
            "classification": spec.classification,
            "strategy": spec.strategy,
            "prompt_file": str(prompt_path.relative_to(ROOT)),
            "source_phone_crop": str(phone_path.relative_to(ROOT)),
            "source_context_crop": str(context_path.relative_to(ROOT)),
        }
        save_json(lineage_path, lineage)

        inventories.append(
            {
                "number": spec.number,
                "slug": spec.slug,
                "title": spec.title,
                "classification": spec.classification,
                "strategy": spec.strategy,
                "row": spec.row,
                "column": spec.col,
                "source_context_box": list(spec.context_box),
                "source_phone_box": list(spec.phone_box),
                "prompt_file": str(prompt_path.relative_to(ROOT)),
                "final_png": str(final_path.relative_to(ROOT)),
                "review_png": str(review_path.relative_to(ROOT)),
                "review_webp": str(webp_path.relative_to(ROOT)),
                "replacement_note": spec.replacement_note,
            }
        )

        source_map[f"{spec.number:02d}_{spec.slug}"] = {
            "context_box": list(spec.context_box),
            "phone_box": list(spec.phone_box),
            "source_image": str(SOURCE_IMAGE.relative_to(ROOT)),
        }

        for asset_path, kind in [
            (context_path, "source-context-crop"),
            (phone_path, "source-phone-crop"),
            (final_path, "final-screen"),
            (review_path, "review-screen"),
            (webp_path, "review-screen-webp"),
            (prompt_path, "prompt"),
            (lineage_path, "lineage"),
        ]:
            asset_manifest["assets"].append(
                {
                    "id": asset_path.stem,
                    "kind": kind,
                    "path": str(asset_path.relative_to(ROOT)),
                }
            )

    brand_inventory = {
        "logos": [
            str((paths["brand_logos"] / "360f_logo_wordmark_primary_rgb.svg").relative_to(ROOT)),
            str((paths["brand_logos"] / "360f_logo_mark_360_primary_rgb.svg").relative_to(ROOT)),
        ],
        "colors": [str((paths["brand_colors"] / "360f_palette_tokens.json").relative_to(ROOT)), str((paths["brand_colors"] / "360f_palette_swatches.png").relative_to(ROOT))],
        "typography": [str((paths["brand_typography"] / "360f_typography_tokens.json").relative_to(ROOT)), str((paths["brand_typography"] / "360f_typography_specimen.png").relative_to(ROOT))],
        "icons": [str((paths["brand_icons"] / f"360f_icon_{name}_24_outline.svg").relative_to(ROOT)) for name in ICON_NAMES],
        "components": [
            str((paths["brand_components"] / "360f_component_basics.png").relative_to(ROOT)),
            str((paths["brand_components"] / "360f_component_tokens.json").relative_to(ROOT)),
        ],
        "references": [
            str((paths["brand_references"] / "360f_avatar_style_ref.png").relative_to(ROOT)),
            str((paths["brand_references"] / "360f_illustration_style_ref.png").relative_to(ROOT)),
        ],
    }
    if model_logo_export is not None:
        brand_inventory["logos"].append(str(model_logo_export.relative_to(ROOT)))

    save_json(paths["manifest"] / "screen-inventory.json", inventories)
    save_json(paths["manifest"] / "brand-inventory.json", brand_inventory)
    save_json(paths["manifest"] / "asset-manifest.json", asset_manifest)
    save_json(paths["lineage"] / "source-map.json", source_map)

    if model_logo_export is not None:
        asset_manifest["assets"].append(
            {
                "id": model_logo_export.stem,
                "kind": "brand-logo-model-png",
                "path": str(model_logo_export.relative_to(ROOT)),
            }
        )
        save_json(paths["manifest"] / "asset-manifest.json", asset_manifest)

    readme = "\n".join(
        [
            "# 360 Flatmates Asset Package",
            "",
            "This package contains source crops, brand basics, prompt specs, manifests, and standalone screen images derived from the composite board in `docs/ChatGPT Image Apr 23, 2026, 02_39_48 AM.png`.",
            "",
            "## Source of truth",
            "- Visual source: the composite board image",
            "- Product-content source for adapted/replaced screens: `docs/prd.md`",
            "",
            "## Build process",
            "- Run `python3 tools/generate_360_assets.py`",
            "- Optional image-model overrides can be placed in `tmp/generated_overrides/` using `{nn}_{slug}.png` naming before re-running the script.",
            "",
            "## Deliverables",
            "- `01_brand/` for the minimal brand basics pack",
            "- `02_screens/` for per-screen source crops and final outputs",
            "- `03_exports/` for flattened export copies",
            "- `04_metadata/` for manifests, prompts, lineage, and QA notes",
            "",
            "## Current implementation note",
            "- If a screen has no override in `tmp/generated_overrides/`, its final image is the upscaled source phone crop baseline.",
            "- Replacement and adaptation intent is fully documented in prompt files and inventory metadata.",
        ]
    )
    (DELIVERABLES / "04_metadata" / "README.md").write_text(readme + "\n")

    qa = "\n".join(
        [
            "# QA Checklist",
            "",
            "- [ ] 20 screen folders exist",
            "- [ ] Each screen folder contains context crop, phone crop, final PNG, review PNG, review WEBP",
            "- [ ] Prompt and lineage files exist for all 20 screens",
            "- [ ] Brand basics files exist and are minimal in scope",
            "- [ ] Replacement screens map to PRD concepts",
            "- [ ] Color and type tokens match the board's inferred design system",
        ]
    )
    (paths["reviews"] / "qa-checklist.md").write_text(qa + "\n")
    (paths["reviews"] / "decision-log.md").write_text(
        "Generated from the hybrid plan. Source-crop baselines are used where no image-model override exists.\n"
    )
    (paths["reviews"] / "review-index.md").write_text(
        "\n".join([f"- {spec.number:02d} {spec.title}: {spec.classification} / {spec.strategy}" for spec in specs]) + "\n"
    )


if __name__ == "__main__":
    build_assets()
