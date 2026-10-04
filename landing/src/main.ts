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

const demo = document.querySelector<HTMLElement>('[data-demo]');
if (demo) {
  const trigger = demo.querySelector<HTMLButtonElement>('[data-demo-trigger]')!;
  const label = demo.querySelector<HTMLElement>('[data-demo-label]')!;
  const note = demo.querySelector<HTMLElement>('[data-demo-text]')!;
  const status = demo.querySelector<HTMLElement>('[data-demo-status]')!;
  const pause = demo.querySelector<HTMLButtonElement>('[data-motion-toggle]')!;
  const steps = document.querySelectorAll<HTMLElement>('[data-step]');
  const phrase = 'Давай обсудим идею завтра.';
  const motion = window.matchMedia('(prefers-reduced-motion: reduce)');
  let timers: ReturnType<typeof setTimeout>[] = [];
  let session = 0;
  let paused = motion.matches;

  const schedule = (callback: () => void, delay: number, id: number): void => {
    timers.push(setTimeout(() => { if (id === session) callback(); }, delay));
  };
  const clear = (): void => {
    session += 1;
    timers.forEach(clearTimeout);
    timers = [];
  };
  const state = (value: string, message: string, activeStep: string): void => {
    demo.dataset.state = value;
    status.textContent = message;
    steps.forEach((step) => step.classList.toggle('is-active', step.dataset.step === activeStep));
  };
  const finish = (): void => {
    note.textContent = phrase;
    trigger.disabled = false;
    trigger.setAttribute('aria-label', 'Повторить демонстрацию диктовки');
    label.textContent = 'Ещё раз';
    state('ready', 'Текст готов. Это демонстрация — микрофон не используется.', '3');
  };
  const setPaused = (value: boolean): void => {
    paused = value;
    document.documentElement.classList.toggle('motion-paused', paused);
    pause.setAttribute('aria-pressed', String(paused));
    pause.setAttribute('aria-label', paused ? 'Включить анимацию' : 'Приостановить анимацию');
    pause.querySelector('span')!.textContent = paused ? 'Включить движение' : 'Пауза анимации';
    if (paused) { clear(); finish(); }
  };

  trigger.hidden = false;
  pause.hidden = false;
  setPaused(paused);
  trigger.addEventListener('click', () => {
    clear();
    const id = session;
    if (paused) { finish(); return; }
    trigger.disabled = true;
    label.textContent = 'Запись';
    note.textContent = '';
    state('recording', 'Демонстрация: запись голоса.', '1');
    schedule(() => {
      label.textContent = 'Распознавание';
      state('processing', 'Запись остановлена. Распознавание на Mac.', '2');
    }, 2600, id);
    schedule(() => {
      state('typing', 'Распознавание завершено. Появляется текст.', '3');
      Array.from(phrase).forEach((_, i) => schedule(() => {
        note.textContent = Array.from(phrase).slice(0, i + 1).join('');
      }, i * 34, id));
      schedule(finish, Array.from(phrase).length * 34 + 160, id);
    }, 3900, id);
  });
  pause.addEventListener('click', () => setPaused(!paused));
  motion.addEventListener('change', (event) => setPaused(event.matches));
  document.addEventListener('visibilitychange', () => {
    if (document.hidden) { clear(); finish(); }
  });
}
