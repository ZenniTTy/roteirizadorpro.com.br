'use client';

import { useEffect, useState } from 'react';

const BASE = 52361;

const formatBR = (n: number): string =>
  n.toString().replace(/\B(?=(\d{3})+(?!\d))/g, '.');

export function LiveCounter() {
  const [count, setCount] = useState(BASE);

  useEffect(() => {
    const start = Date.now();
    let timeoutId: ReturnType<typeof setTimeout>;

    const tick = () => {
      const elapsedSec = (Date.now() - start) / 1000;
      const growth = Math.floor(elapsedSec / (4 + Math.random() * 5));
      setCount(BASE + growth);
      timeoutId = setTimeout(tick, 2500 + Math.random() * 4500);
    };

    tick();
    return () => clearTimeout(timeoutId);
  }, []);

  return (
    <div className="live-counter hero-live" aria-live="polite">
      <span className="live-dot"></span>
      <span className="live-label">Ao vivo</span>
      <span className="live-num">{formatBR(count)}</span>
      <span className="live-text">motoboys ativos agora</span>
    </div>
  );
}
