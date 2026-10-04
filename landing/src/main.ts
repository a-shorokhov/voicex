import './style.css';
import { release } from './release';
import { trajectoryCenterline } from './trajectory-centerline';

const publicURL = (value: string): boolean => {
  try { return new URL(value).protocol === 'https:'; } catch { return false; }
};

if (release.available && publicURL(release.downloadURL) && publicURL(release.checksumURL)) {
  document.querySelectorAll<HTMLElement>('[data-release]').forEach((placeholder) => {
    const link = document.createElement('a');
    link.className = placeholder.className;
    link.href = release.downloadURL;
    link.textContent = `Скачать для macOS ↗`;
    placeholder.replaceWith(link);
  });
  document.querySelectorAll<HTMLElement>('[data-release-note]').forEach((element) => {
    element.replaceChildren(document.createTextNode(`Версия ${release.version} · `));
    const checksum = document.createElement('a');
    checksum.href = release.checksumURL;
    checksum.textContent = 'SHA-256';
    element.append(checksum);
  });
}

// Letters and the PNG share the same measured centerline and displacement map.
const demo = document.querySelector<HTMLElement>('[data-demo]');
if (demo) {
  const scene = demo.querySelector<HTMLElement>('.voice-scene')!;
  const recorder = scene.querySelector<HTMLElement>('.recorder')!;
  const noteWindow = scene.querySelector<HTMLElement>('.note-window')!;
  const trail = scene.querySelector<HTMLElement>('.magic-trajectory')!;
  const bend = scene.querySelector<SVGFEDisplacementMapElement>('[data-trail-bend]')!;
  const path = scene.querySelector<SVGPathElement>('[data-trail-path]')!;
  const letterLayer = scene.querySelector<HTMLElement>('[data-trajectory-letters]')!;
  const note = scene.querySelector<HTMLElement>('[data-demo-text]')!;
  const phrase = Array.from('Давай обсудим идею завтра.');
  path.setAttribute('d', trajectoryCenterline);
  const pathLength = path.getTotalLength();
  const letters = phrase.filter((character) => character !== ' ').map((character) => {
    const element = document.createElement('span');
    element.textContent = character;
    letterLayer.append(element);
    return element;
  });
  const travelTime = 1240;
  const leadIn = 800;
  let spacing = 84;
  let originX = 0;
  let originY = 0;
  let rotation = 0;
  let elapsed = 0;
  let previousCount = -1;
  const motion = globalThis.matchMedia('(prefers-reduced-motion: reduce)');
  let visible = true;
  let frame = 0;
  let trailWidth = 460;
  let phase = 0;
  let lastFrame = 0;

  const layoutTrail = (): void => {
    // Attach the luminous tip to the capsule's upper-right border.
    const startX = recorder.offsetLeft + recorder.offsetWidth - recorder.offsetHeight * .5;
    const startY = recorder.offsetTop;
    const sceneBounds = scene.getBoundingClientRect();
    const noteBounds = noteWindow.getBoundingClientRect();
    const endX = noteBounds.left - sceneBounds.left + noteBounds.width * .46;
    const endY = noteBounds.top - sceneBounds.top + noteBounds.height * .58;
    const dx = endX - startX;
    const dy = endY - startY;
    // Visible endpoints in the original 1896 × 830 PNG: (65, 640), (1830, 510).
    const width = Math.hypot(dx, dy) * 1896 / Math.hypot(1765, 130);
    trailWidth = width;
    rotation = Math.atan2(dy, dx) - Math.atan2(-130, 1765);
    originX = startX;
    originY = startY;
    spacing = Math.max(84, travelTime * (scene.clientWidth < 600 ? 15 : 24) / (pathLength * width / 1896));
    trail.style.left = `${startX}px`;
    trail.style.top = `${startY}px`;
    trail.style.setProperty('--trail-width', `${width}px`);
    trail.style.transform = `rotate(${rotation}rad)`;
  };
  const tick = (timestamp: number): void => {
    if (lastFrame) {
      const delta = timestamp - lastFrame;
      phase += delta / 6000 * Math.PI * 2;
      elapsed += delta;
    }
    lastFrame = timestamp;
    // ±10 CSS px in the middle; the map is exactly neutral at both tips.
    const displacement = Math.sin(phase) * 20 * 1896 / trailWidth;
    bend.setAttribute('scale', String(displacement));
    const flightEnd = leadIn + travelTime + (letters.length - 1) * spacing;
    const writeTime = phrase.length * 60;
    const eraseStart = flightEnd + writeTime + 3000;
    const cycleTime = eraseStart + phrase.length * 28 + 200;
    const time = elapsed % cycleTime;
    const count = time < flightEnd ? 0 : time < eraseStart
      ? Math.min(phrase.length, Math.floor((time - flightEnd) / 60) + 1)
      : Math.max(0, phrase.length - Math.floor((time - eraseStart) / 28));
    if (count !== previousCount) {
      note.textContent = phrase.slice(0, count).join('');
      previousCount = count;
    }
    demo.dataset.state = time < flightEnd ? 'flying' : time >= eraseStart
      ? 'erasing' : count < phrase.length ? 'writing' : 'ready';
    letters.forEach((letter, index) => {
      // Keep the phrase readable from left to right as it moves to the right.
      const progress = (time - leadIn - (letters.length - 1 - index) * spacing) / travelTime;
      if (progress < 0 || progress >= 1 || time >= flightEnd) {
        letter.style.opacity = '0';
        return;
      }
      const point = path.getPointAtLength(progress * pathLength);
      const u = point.x / 1896;
      const envelope = Math.max(0, Math.min(1, (u - .12) / .38, (.88 - u) / .38));
      // SVG samples source pixels at y + scale * (G - .5), so their visible
      // position shifts in the opposite direction. End zones remain neutral.
      const yOnWave = point.y - displacement * (127 / 255) * envelope;
      const x = (point.x - 65) * trailWidth / 1896;
      const y = (yOnWave - 640) * trailWidth / 1896;
      const screenX = originX + x * Math.cos(rotation) - y * Math.sin(rotation);
      const screenY = originY + x * Math.sin(rotation) + y * Math.cos(rotation);
      letter.style.transform = `translate3d(${screenX}px, ${screenY}px, 0) translate(-50%, -50%)`;
      letter.style.opacity = String(Math.min(1, progress * 15, (1 - progress) * 18));
    });
    frame = requestAnimationFrame(tick);
  };
  const synchronize = (): void => {
    cancelAnimationFrame(frame);
    lastFrame = 0;
    const paused = motion.matches || document.hidden || !visible;
    demo.classList.toggle('motion-paused', paused);
    if (motion.matches) {
      bend.setAttribute('scale', '0');
      note.textContent = phrase.join('');
      previousCount = -1;
      demo.dataset.state = 'ready';
      letters.forEach((letter) => { letter.style.opacity = '0'; });
    }
    if (!paused) frame = requestAnimationFrame(tick);
  };
  layoutTrail();
  new ResizeObserver(layoutTrail).observe(scene);
  new IntersectionObserver(([entry]) => {
    visible = entry.isIntersecting;
    synchronize();
  }, { threshold: .05 }).observe(demo);
  motion.addEventListener('change', synchronize);
  document.addEventListener('visibilitychange', synchronize);
  synchronize();
}

// The three-step illustration runs independently of the hero's visibility.
const how = document.querySelector<HTMLElement>('.how-section');
if (how) {
  const steps = Array.from(how.querySelectorAll<HTMLElement>('[data-step]'));
  const motion = globalThis.matchMedia('(prefers-reduced-motion: reduce)');
  let visible = false;
  let frame = 0;
  let elapsed = 0;
  let lastFrame = 0;
  const tick = (timestamp: number): void => {
    if (lastFrame) elapsed += timestamp - lastFrame;
    lastFrame = timestamp;
    const active = Math.floor(elapsed / 2200) % steps.length;
    steps.forEach((step, index) => step.classList.toggle('is-active', index === active));
    frame = requestAnimationFrame(tick);
  };
  const synchronize = (): void => {
    cancelAnimationFrame(frame);
    lastFrame = 0;
    const paused = motion.matches || document.hidden || !visible;
    how.classList.toggle('motion-paused', paused);
    if (motion.matches) steps.forEach((step) => step.classList.remove('is-active'));
    if (!paused) frame = requestAnimationFrame(tick);
  };
  new IntersectionObserver(([entry]) => {
    visible = entry.isIntersecting;
    synchronize();
  }, { threshold: .05 }).observe(how);
  motion.addEventListener('change', synchronize);
  document.addEventListener('visibilitychange', synchronize);
  synchronize();
}
