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
  const motion = globalThis.matchMedia('(prefers-reduced-motion: reduce)');
  let visible = true;

  const layoutTrail = (): void => {
    const startX = recorder.offsetLeft + recorder.offsetWidth * .65;
    const startY = recorder.offsetTop + 12;
    const sceneBounds = scene.getBoundingClientRect();
    const noteBounds = noteWindow.getBoundingClientRect();
    const endX = noteBounds.left - sceneBounds.left + noteBounds.width * .6;
    const endY = noteBounds.top - sceneBounds.top + noteBounds.height * .5;
    const dx = endX - startX;
    const dy = endY - startY;
    // Visible endpoints in the original 1896 × 830 PNG: (65, 640), (1830, 510).
    const width = Math.hypot(dx, dy) * 1896 / Math.hypot(1765, 130);
    const rotation = Math.atan2(dy, dx) - Math.atan2(-130, 1765);
    trail.style.left = `${startX}px`;
    trail.style.top = `${startY}px`;
    trail.style.setProperty('--trail-width', `${width}px`);
    trail.style.transform = `rotate(${rotation}rad)`;
  };
  const synchronize = (): void => {
    document.documentElement.classList.toggle('motion-paused', motion.matches || document.hidden || !visible);
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
