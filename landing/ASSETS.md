# Voicex — визуальные ассеты

Выбрано направление «Зелёный сад». Иллюстрации созданы встроенным Image Gen и сконвертированы в WebP без изменения композиции. Все буквы, текст, заметки и элементы управления сделаны в HTML/CSS/TypeScript; текст в изображениях не используется.

- `public/assets/hero.webp`: зелёная стеклянная лента, 1536 × 1024.
- `public/assets/process.webp`: панорамная лента, 2172 × 724.
- `public/assets/privacy.webp`: концептуальная иллюстрация Apple Silicon, 1536 × 1024. Яблочко и M возвращены по прямому запросу пользователя.
- `public/assets/white-magic-trajectory.png`: предоставленный пользователем прозрачный PNG, 1896 × 830. Скопирован без изменения пикселей из `output/imagegen/landing-letter-flow/white-magic-trajectory-asset.png`; инструкция — `white-magic-trajectory-asset.md`. Белый ореол и искры находятся в PNG, движение середины добавлено через SVG-фильтр, концы неподвижны.
- `public/assets/trajectory-displacement.svg`: кодовая карта смещения середины траектории с нейтральными краями.
- `public/favicon.svg`: небольшая кодовая иконка листьев Voicex. Знак сайта — листья, Apple используется только в иллюстрации совместимой платформы.

## Промпты Image Gen

### hero

```text
Create a brand-new wide 3:2 cinematic background illustration for the HERO of the website shown in the reference. Use the reference ONLY for art direction: pale sage/ivory tones, translucent green sea-glass acoustic ribbon, warm yellow rim refraction, subtle botanical shadows, high-end 3D render. This output is ONLY the background scene, NOT a website screenshot. On a softly reflective ivory tabletop a broad elegant green glass ribbon curls upward from lower middle into the right half, its largest sweeping curl in the upper right. The LEFT 48% must be quiet pale ivory-sage negative space for real HTML headline. Gentle diffuse morning sunlight and beautiful shadows. A little botanical depth behind the ribbon on the far right. Keep detailed glass but restrained contrast. No UI, no panels, no note, no chips, no microphones, no wave bars, no logos, no letters, absolutely NO TEXT or pseudo-letterforms anywhere. The letters, recorder and note will be added as sharp HTML by the developer. Ultra polished, crisp high-resolution materials, immersive composition.
```

### process

```text
Create a brand-new panoramic 3:1 decorative lower-section illustration for the website shown in the reference. Use reference ONLY for pale sage sea-glass art direction. Output is a TEXTLESS background scene, NOT a website. One flowing low green glass ribbon undulates gently from left to right along an ivory reflective tabletop; low folds at the left third, translucent crest at center, relaxed wider fold at right. Upper half has clean cream negative space for real HTML content. Refined sunlit translucent pale olive glass, lemon edge highlights, delicate reflections, a few blurred leaf shadows, original sculptural forms, calm premium 3D product aesthetic. No user interface, no badges, no notes, no devices, no controls, no letters, no digits, NO TEXT or pseudo-glyphs at all. Developer will overlay actual controls and clear text.
```

### privacy

```text
Create a brand-new 3:2 product-art illustration for the privacy section of the website shown in the reference, using it ONLY as an art-direction reference. Beautiful translucent pale green glass computational tile, subtly raised central deep-evergreen square with a small simple embossed abstract leaf symbol (not any existing corporate logo), lying at an elegant angle within curling sea-glass ribbon. Scene occupies right 65%, LEFT 35% fades into calm pale cream negative space. Close-up macro-like luxurious physically realistic studio render, softly lit cream background, yellow rim highlights and soft botanical shadows, tangible etched circuitry details WITHOUT ANY letters, logos or digits. A visual metaphor for local processing, not an actual branded hardware render. NO Apple logo, NO M1, NO text, NO pseudo-text, no website or interface, no labels, no shields or claim badges. Match the chosen sage green website precisely.
```

### Обновление privacy

```text
Edit this image with one precise change only: replace the embossed two-leaf symbol at the center of the dark green chip with a crisp silver Apple bitten-apple logo and a single clean silver capital M next to it, as a conceptual Apple Silicon chip illustration. Keep the logo small and centered on the chip in perspective. Keep EVERYTHING else exactly unchanged: translucent casing, circuitry, ribbon, color palette, lighting, camera, composition, cream negative space at left. No additional text. This is a conceptual illustration for a local macOS dictation app landing page.
```

