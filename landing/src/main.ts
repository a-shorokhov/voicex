import './style.css';
import { release } from './release';

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

// The supplied transparent trail is decorative; the note stays readable and static.
const demo = document.querySelector<HTMLElement>('[data-demo]');
if (demo) {
  const scene = demo.querySelector<HTMLElement>('.voice-scene')!;
  const recorder = scene.querySelector<HTMLElement>('.recorder')!;
  const noteWindow = scene.querySelector<HTMLElement>('.note-window')!;
  const trail = scene.querySelector<HTMLElement>('.magic-trajectory')!;
  const bend = scene.querySelector<SVGFEDisplacementMapElement>('[data-trail-bend]')!;
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
    const endX = noteBounds.left - sceneBounds.left + noteBounds.width * .6;
    const endY = noteBounds.top - sceneBounds.top + noteBounds.height * .5;
    const dx = endX - startX;
    const dy = endY - startY;
    // Visible endpoints in the original 1896 × 830 PNG: (65, 640), (1830, 510).
    const width = Math.hypot(dx, dy) * 1896 / Math.hypot(1765, 130);
    trailWidth = width;
    const rotation = Math.atan2(dy, dx) - Math.atan2(-130, 1765);
    trail.style.left = `${startX}px`;
    trail.style.top = `${startY}px`;
    trail.style.setProperty('--trail-width', `${width}px`);
    trail.style.transform = `rotate(${rotation}rad)`;
  };
  const tick = (timestamp: number): void => {
    if (lastFrame) phase += (timestamp - lastFrame) / 6000 * Math.PI * 2;
    lastFrame = timestamp;
    // ±10 CSS px in the middle; the map is exactly neutral at both tips.
    bend.setAttribute('scale', String(Math.sin(phase) * 20 * 1896 / trailWidth));
    frame = requestAnimationFrame(tick);
  };
  const synchronize = (): void => {
    cancelAnimationFrame(frame);
    lastFrame = 0;
    const paused = motion.matches || document.hidden || !visible;
    document.documentElement.classList.toggle('motion-paused', paused);
    if (motion.matches) bend.setAttribute('scale', '0');
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
