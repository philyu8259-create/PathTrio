#!/usr/bin/env python3
from __future__ import annotations

from dataclasses import dataclass
from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter, ImageFont


ROOT = Path(__file__).resolve().parents[1]
RAW_ROOT = ROOT / "artifacts" / "app_store_raw"
OUT_ROOT = ROOT / "artifacts" / "app_store_previews"

FONT_CN = "/System/Library/Fonts/Hiragino Sans GB.ttc"
FONT_CN_BOLD = "/System/Library/Fonts/STHeiti Medium.ttc"
FONT_EN = "/System/Library/Fonts/Supplemental/Arial.ttf"
FONT_EN_BOLD = "/System/Library/Fonts/Supplemental/Arial Bold.ttf"
FONT_FALLBACK = "/System/Library/Fonts/Helvetica.ttc"

INK = (22, 34, 48, 255)
MUTED = (91, 106, 123, 255)
BLUE = (12, 126, 234, 255)
TEAL = (0, 166, 148, 255)
ORANGE = (252, 126, 38, 255)


@dataclass(frozen=True)
class Scene:
    slug: str
    raw_name: str
    title_cn: str
    subtitle_cn: str
    title_en: str
    subtitle_en: str
    accent: tuple[int, int, int, int]


SCENES: tuple[Scene, ...] = (
    Scene(
        "01_track",
        "01_home",
        "走路 跑步 骑行\n一键记录",
        "路线、距离、配速和时间清楚呈现",
        "Track Walks,\nRuns & Rides",
        "Routes, distance, pace, and time in one clean view",
        BLUE,
    ),
    Scene(
        "02_route",
        "04_active",
        "GPS 路线轨迹\n实时记录",
        "户外运动路径自动保存，回看更直观",
        "GPS Routes\nMade Clear",
        "Save outdoor paths and review every workout later",
        TEAL,
    ),
    Scene(
        "03_history",
        "02_history",
        "按天 按月\n整理历史",
        "按运动类型查看记录、统计和趋势",
        "Daily & Monthly\nHistory",
        "Browse workouts by type, date, and long-term progress",
        (58, 118, 226, 255),
    ),
    Scene(
        "04_pro",
        "03_settings",
        "Pro 解锁更多\n专业功能",
        "导出数据、健康同步、地图样式和 Apple Watch 支持",
        "Unlock Pro\nWhen You Need More",
        "Export data, map styles, Health sync, and Apple Watch support",
        ORANGE,
    ),
)


def load_font(locale: str, size: int, bold: bool) -> ImageFont.FreeTypeFont:
    paths = [FONT_CN_BOLD if bold else FONT_CN] if locale == "cn" else [FONT_EN_BOLD if bold else FONT_EN]
    paths.append(FONT_FALLBACK)
    for path in paths:
        try:
            return ImageFont.truetype(path, size)
        except OSError:
            continue
    return ImageFont.load_default()


def text_width(font: ImageFont.FreeTypeFont, text: str) -> int:
    box = font.getbbox(text)
    return box[2] - box[0]


def wrap_text(text: str, font: ImageFont.FreeTypeFont, max_width: int, locale: str) -> list[str]:
    source_lines = text.split("\n")
    lines: list[str] = []
    for source in source_lines:
        if text_width(font, source) <= max_width:
            lines.append(source)
            continue
        units = list(source) if locale == "cn" else source.split()
        sep = "" if locale == "cn" else " "
        current: list[str] = []
        for unit in units:
            candidate = sep.join(current + [unit]) if current else unit
            if text_width(font, candidate) <= max_width:
                current.append(unit)
            else:
                if current:
                    lines.append(sep.join(current))
                current = [unit]
        if current:
            lines.append(sep.join(current))
    return lines


def rounded_mask(size: tuple[int, int], radius: int) -> Image.Image:
    mask = Image.new("L", size, 0)
    ImageDraw.Draw(mask).rounded_rectangle((0, 0, size[0], size[1]), radius=radius, fill=255)
    return mask


def background(size: tuple[int, int], accent: tuple[int, int, int, int]) -> Image.Image:
    width, height = size
    canvas = Image.new("RGBA", size, (241, 249, 248, 255))
    px = canvas.load()
    for y in range(height):
        t = y / max(height - 1, 1)
        for x in range(width):
            s = x / max(width - 1, 1)
            r = int(244 - 10 * t + 4 * s)
            g = int(251 - 7 * t)
            b = int(250 - 20 * t + 8 * s)
            px[x, y] = (r, g, b, 255)

    glow = Image.new("RGBA", size, (0, 0, 0, 0))
    draw = ImageDraw.Draw(glow, "RGBA")
    blobs = [
        ((int(width * 0.12), int(height * 0.12)), int(width * 0.30), (*accent[:3], 56)),
        ((int(width * 0.92), int(height * 0.18)), int(width * 0.25), (116, 187, 255, 48)),
        ((int(width * 0.50), int(height * 0.70)), int(width * 0.36), (255, 255, 255, 90)),
        ((int(width * 0.18), int(height * 0.82)), int(width * 0.23), (181, 235, 224, 46)),
    ]
    for (cx, cy), radius, color in blobs:
        draw.ellipse((cx - radius, cy - radius, cx + radius, cy + radius), fill=color)
    glow = glow.filter(ImageFilter.GaussianBlur(radius=int(width * 0.055)))
    canvas.alpha_composite(glow)

    grid = Image.new("RGBA", size, (0, 0, 0, 0))
    grid_draw = ImageDraw.Draw(grid)
    step = max(width // 14, 80)
    for x in range(0, width, step):
        grid_draw.line((x, 0, x, height), fill=(255, 255, 255, 24), width=1)
    for y in range(0, height, step):
        grid_draw.line((0, y, width, y), fill=(255, 255, 255, 18), width=1)
    canvas.alpha_composite(grid)
    return canvas


def paste_shadow(base: Image.Image, box: tuple[int, int, int, int], radius: int, alpha: int) -> None:
    x, y, w, h = box
    layer = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    ImageDraw.Draw(layer).rounded_rectangle((0, 0, w, h), radius=radius, fill=(20, 49, 84, alpha))
    shadow = Image.new("RGBA", base.size, (0, 0, 0, 0))
    shadow.alpha_composite(layer, (x, y))
    shadow = shadow.filter(ImageFilter.GaussianBlur(radius=max(24, w // 30)))
    base.alpha_composite(shadow)


def draw_title(canvas: Image.Image, scene: Scene, locale: str, is_ipad: bool) -> int:
    draw = ImageDraw.Draw(canvas)
    width, height = canvas.size
    title = scene.title_cn if locale == "cn" else scene.title_en
    subtitle = scene.subtitle_cn if locale == "cn" else scene.subtitle_en

    title_size = 106 if is_ipad else 78
    subtitle_size = 43 if is_ipad else 34
    title_font = load_font(locale, title_size, True)
    subtitle_font = load_font(locale, subtitle_size, False)
    max_width = int(width * (0.78 if is_ipad else 0.84))

    y = int(height * (0.045 if is_ipad else 0.055))
    for line in wrap_text(title, title_font, max_width, locale):
        line_width = text_width(title_font, line)
        draw.text(((width - line_width) / 2, y), line, font=title_font, fill=INK)
        y += int(title_size * 1.02)

    y += int(height * 0.012)
    for line in wrap_text(subtitle, subtitle_font, max_width, locale):
        line_width = text_width(subtitle_font, line)
        draw.text(((width - line_width) / 2, y), line, font=subtitle_font, fill=MUTED)
        y += int(subtitle_size * 1.24)

    return y + int(height * (0.025 if is_ipad else 0.030))


def draw_device(canvas: Image.Image, screenshot: Image.Image, top_y: int, is_ipad: bool) -> None:
    width, height = canvas.size
    if is_ipad:
        frame_w = int(width * 0.82)
        frame_h = int(height * 0.69)
        radius = int(frame_w * 0.045)
        bezel = max(16, int(frame_w * 0.018))
    else:
        frame_w = int(width * 0.82)
        frame_h = int(height * 0.75)
        radius = int(frame_w * 0.115)
        bezel = max(18, int(frame_w * 0.020))

    x = (width - frame_w) // 2
    y = min(top_y, height - frame_h - int(height * 0.050))
    paste_shadow(canvas, (x, y + int(height * 0.010), frame_w, frame_h), radius, 76)

    frame = Image.new("RGBA", (frame_w, frame_h), (0, 0, 0, 0))
    frame_draw = ImageDraw.Draw(frame, "RGBA")
    frame_draw.rounded_rectangle((0, 0, frame_w, frame_h), radius=radius, fill=(16, 20, 28, 255))
    frame_draw.rounded_rectangle(
        (4, 4, frame_w - 4, frame_h - 4),
        radius=radius,
        outline=(255, 255, 255, 42),
        width=max(2, bezel // 5),
    )

    screen_w = frame_w - bezel * 2
    screen_h = frame_h - bezel * 2
    screen = screenshot.resize((screen_w, screen_h), Image.Resampling.LANCZOS).convert("RGBA")
    screen_mask = rounded_mask((screen_w, screen_h), max(22, radius - bezel))
    frame.paste(screen, (bezel, bezel), screen_mask)

    canvas.alpha_composite(frame, (x, y))


def build_one(raw_dir: Path, out_dir: Path, scene: Scene, locale: str) -> None:
    raw = Image.open(raw_dir / f"{scene.raw_name}.png").convert("RGBA")
    is_ipad = raw.width >= 1800
    canvas = background(raw.size, scene.accent)
    top_y = draw_title(canvas, scene, locale, is_ipad)
    draw_device(canvas, raw, top_y, is_ipad)
    out_dir.mkdir(parents=True, exist_ok=True)
    canvas.convert("RGB").save(out_dir / f"{scene.slug}.png", quality=100)


def main() -> None:
    sets = [
        ("phone_cn", "cn"),
        ("phone_en", "en"),
        ("ipad_cn", "cn"),
        ("ipad_en", "en"),
    ]
    for folder, locale in sets:
        raw_dir = RAW_ROOT / folder
        out_dir = OUT_ROOT / folder
        for scene in SCENES:
            build_one(raw_dir, out_dir, scene, locale)
            print(f"built {out_dir / (scene.slug + '.png')}")


if __name__ == "__main__":
    main()
