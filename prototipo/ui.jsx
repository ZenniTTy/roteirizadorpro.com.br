// Shared UI primitives + phone frame for Roteirizador Pro
const { useState, useEffect, useRef } = React;

// ─── Phone Frame ──────────────────────────────────────────
function Phone({ children, dark = false, statusBarDark = false, hideNav = false }) {
  const W = 390, H = 844;
  return (
    <div style={{
      width: W, height: H, borderRadius: 0, overflow: 'hidden',
      background: dark ? '#0E0E1A' : '#FFFFFF',
      fontFamily: RP.font, color: RP.text,
      display: 'flex', flexDirection: 'column', position: 'relative',
      WebkitFontSmoothing: 'antialiased',
    }}>
      <StatusBar dark={statusBarDark} bg={dark ? '#0E0E1A' : '#FFFFFF'}/>
      <div style={{ flex: 1, position: 'relative', overflow: 'hidden', display: 'flex', flexDirection: 'column' }}>
        {children}
      </div>
      {!hideNav && <GestureNav dark={statusBarDark}/>}
    </div>
  );
}

function StatusBar({ dark = false, bg = '#FFFFFF' }) {
  const c = dark ? '#FFFFFF' : RP.text;
  return (
    <div style={{
      height: 44, padding: '0 24px', display: 'flex', alignItems: 'center',
      justifyContent: 'space-between', background: bg, flexShrink: 0,
      fontFamily: RP.font, fontSize: 15, fontWeight: 600, color: c,
    }}>
      <span>9:41</span>
      <div style={{ display: 'flex', gap: 6, alignItems: 'center' }}>
        {/* signal */}
        <svg width="17" height="11" viewBox="0 0 17 11"><rect x="0" y="7" width="3" height="4" rx="0.5" fill={c}/><rect x="5" y="5" width="3" height="6" rx="0.5" fill={c}/><rect x="10" y="2" width="3" height="9" rx="0.5" fill={c}/></svg>
        {/* wifi */}
        <svg width="15" height="11" viewBox="0 0 15 11"><path d="M7.5 1C4.5 1 2 2.2 0 4l1.5 1.6C3 4.2 5 3.3 7.5 3.3S12 4.2 13.5 5.6L15 4C13 2.2 10.5 1 7.5 1zM7.5 5C5.7 5 4.1 5.6 3 6.7l1.5 1.5C5.3 7.4 6.3 7 7.5 7s2.2.4 3 1.2L12 6.7C10.9 5.6 9.3 5 7.5 5z" fill={c}/><circle cx="7.5" cy="9.5" r="1.5" fill={c}/></svg>
        {/* battery */}
        <svg width="25" height="11" viewBox="0 0 25 11"><rect x="0.5" y="0.5" width="21" height="10" rx="2.5" stroke={c} fill="none"/><rect x="2" y="2" width="18" height="7" rx="1.5" fill={c}/><rect x="22.5" y="3.5" width="2" height="4" rx="1" fill={c}/></svg>
      </div>
    </div>
  );
}

function GestureNav({ dark = false }) {
  return (
    <div style={{ height: 24, display: 'flex', alignItems: 'center', justifyContent: 'center', flexShrink: 0, background: 'transparent' }}>
      <div style={{ width: 134, height: 5, borderRadius: 3, background: dark ? '#FFFFFF' : RP.text, opacity: dark ? 0.85 : 1 }}/>
    </div>
  );
}

// ─── Logo ────────────────────────────────────────────────
// Purple squircle, white route arc, white start dot, neon end dot
function Logo({ size = 56 }) {
  return (
    <img src="logo.png" alt="Entrega Smart" width={size} height={size}
      style={{
        width: size, height: size, borderRadius: size * 0.22,
        display: 'block', objectFit: 'cover',
        boxShadow: '0 8px 24px rgba(108,63,197,0.3)',
      }}
    />
  );
}

// ─── Buttons ─────────────────────────────────────────────
function PrimaryButton({ children, icon, onClick, disabled, locked, full = true, neon = false, style = {} }) {
  const bg = (disabled || locked) ? '#D5D0E0'
    : neon ? `linear-gradient(135deg, ${RP.primary} 0%, ${RP.primaryDark} 100%)`
    : RP.primary;
  return (
    <button onClick={onClick} disabled={disabled || locked}
      style={{
        height: 52, width: full ? '100%' : 'auto', padding: '0 24px',
        border: 'none', borderRadius: RP.rBtn, cursor: (disabled || locked) ? 'default' : 'pointer',
        background: bg,
        color: '#fff', fontFamily: RP.font, fontSize: 16, fontWeight: 600,
        display: 'flex', alignItems: 'center', justifyContent: 'center', gap: 8,
        boxShadow: (disabled || locked) ? 'none' : '0 4px 12px rgba(108,63,197,0.24)',
        opacity: locked ? 0.55 : 1, position: 'relative',
        transition: 'transform .12s, box-shadow .12s',
        ...style,
      }}>
      {locked && <I.Lock size={18}/>}
      {icon}
      {children}
      {neon && (
        <span style={{
          position: 'absolute', right: 14, top: '50%', transform: 'translateY(-50%)',
          width: 8, height: 8, borderRadius: '50%', background: RP.neon,
          boxShadow: '0 0 8px rgba(198,255,61,0.9)',
        }}/>
      )}
    </button>
  );
}

function GhostButton({ children, onClick, full = true, style = {} }) {
  return (
    <button onClick={onClick}
      style={{
        height: 52, width: full ? '100%' : 'auto', padding: '0 24px',
        border: `1.5px solid ${RP.border}`, borderRadius: RP.rBtn,
        background: '#fff', color: RP.text,
        fontFamily: RP.font, fontSize: 16, fontWeight: 600, cursor: 'pointer',
        display: 'flex', alignItems: 'center', justifyContent: 'center', gap: 10,
        ...style,
      }}>
      {children}
    </button>
  );
}

// ─── Inputs ──────────────────────────────────────────────
function Input({ label, value, onChange, type = 'text', placeholder, prefix, suffix, focused = false, error }) {
  const [f, setF] = useState(focused);
  const isFocused = focused || f;
  return (
    <div style={{ display: 'flex', flexDirection: 'column', gap: 6 }}>
      {label && <div style={{ fontSize: 13, fontWeight: 500, color: RP.textMuted, paddingLeft: 4 }}>{label}</div>}
      <div style={{
        height: 52, display: 'flex', alignItems: 'center', gap: 8, padding: '0 16px',
        background: isFocused ? '#fff' : RP.surface,
        border: `1.5px solid ${error ? RP.error : isFocused ? RP.primary : RP.border}`,
        borderRadius: RP.rInput,
        boxShadow: isFocused ? '0 0 0 4px rgba(108,63,197,0.08)' : 'none',
        transition: 'all .15s',
      }}>
        {prefix && <span style={{ color: RP.textMuted, fontSize: 15, fontWeight: 500 }}>{prefix}</span>}
        <input
          type={type} value={value || ''} placeholder={placeholder}
          onChange={(e) => onChange && onChange(e.target.value)}
          onFocus={() => setF(true)} onBlur={() => setF(false)}
          style={{
            flex: 1, border: 'none', outline: 'none', background: 'transparent',
            fontFamily: RP.font, fontSize: 15, color: RP.text, minWidth: 0,
          }}
        />
        {suffix}
      </div>
      {error && <div style={{ fontSize: 12, color: RP.error, paddingLeft: 4 }}>{error}</div>}
    </div>
  );
}

// ─── Badge ───────────────────────────────────────────────
function Badge({ children, variant = 'neutral', size = 'sm' }) {
  const m = {
    neutral: { bg: RP.surface, fg: RP.textMuted, br: RP.border },
    primary: { bg: RP.primaryLight, fg: RP.primary, br: 'transparent' },
    success: { bg: RP.successBg, fg: '#15803D', br: 'transparent' },
    error: { bg: RP.errorBg, fg: '#B91C1C', br: 'transparent' },
    warning: { bg: RP.warningBg, fg: '#B45309', br: 'transparent' },
  }[variant];
  const px = size === 'sm' ? 10 : 12;
  return (
    <span style={{
      display: 'inline-flex', alignItems: 'center', gap: 4,
      height: size === 'sm' ? 24 : 28, padding: `0 ${px}px`,
      background: m.bg, color: m.fg,
      border: `1px solid ${m.br}`, borderRadius: 999,
      fontFamily: RP.font, fontSize: 12, fontWeight: 600, lineHeight: 1, whiteSpace: 'nowrap',
    }}>{children}</span>
  );
}

// ─── FAB ─────────────────────────────────────────────────
function FAB({ onClick, icon, style = {} }) {
  return (
    <button onClick={onClick} style={{
      position: 'absolute', right: 20, bottom: 88,
      width: 56, height: 56, borderRadius: '50%',
      background: `linear-gradient(135deg, ${RP.accent} 0%, ${RP.primary} 100%)`,
      border: 'none', cursor: 'pointer',
      display: 'flex', alignItems: 'center', justifyContent: 'center',
      color: '#fff', boxShadow: RP.fabShadow, zIndex: 5,
      ...style,
    }}>
      {icon || <I.Plus size={26} stroke={2}/>}
    </button>
  );
}

// ─── Bottom Nav ──────────────────────────────────────────
function BottomNav({ active = 'route' }) {
  const Item = ({ id, icon: IconC, label }) => (
    <div style={{
      flex: 1, display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 4,
      color: active === id ? RP.primary : RP.textMuted,
    }}>
      <div style={{
        width: 64, height: 32, borderRadius: 16,
        background: active === id ? RP.primaryLight : 'transparent',
        display: 'flex', alignItems: 'center', justifyContent: 'center',
      }}>
        <IconC size={22} stroke={active === id ? 2 : 1.5}/>
      </div>
      <span style={{ fontSize: 11, fontWeight: active === id ? 600 : 500 }}>{label}</span>
    </div>
  );
  return (
    <div style={{
      height: 72, padding: '8px 8px 0', display: 'flex', alignItems: 'flex-start',
      borderTop: `1px solid ${RP.border}`, background: '#fff', flexShrink: 0,
    }}>
      <Item id="route" icon={I.Route} label="Rota"/>
      <Item id="settings" icon={I.Settings} label="Configurações"/>
    </div>
  );
}

// ─── Map placeholder ─────────────────────────────────────
function MapPlaceholder({ height = 180, pin = true }) {
  return (
    <div style={{
      height, borderRadius: RP.rCard, position: 'relative', overflow: 'hidden',
      background: `
        linear-gradient(135deg, #EEF0F4 0%, #E4E7ED 100%)
      `,
    }}>
      {/* Roads */}
      <svg width="100%" height="100%" viewBox="0 0 360 180" preserveAspectRatio="xMidYMid slice" style={{ position: 'absolute', inset: 0 }}>
        <path d="M -20 110 Q 90 90 180 130 T 380 100" stroke="#fff" strokeWidth="14" fill="none"/>
        <path d="M 60 -10 Q 80 60 140 90 T 240 200" stroke="#fff" strokeWidth="10" fill="none"/>
        <path d="M -20 40 L 380 50" stroke="#fff" strokeWidth="8" fill="none"/>
        <rect x="20" y="20" width="60" height="40" fill="#DDE1E8" rx="4"/>
        <rect x="220" y="20" width="80" height="30" fill="#DDE1E8" rx="4"/>
        <rect x="240" y="120" width="100" height="50" fill="#DDE1E8" rx="4"/>
        <rect x="20" y="130" width="80" height="40" fill="#DDE1E8" rx="4"/>
      </svg>
      {pin && (
        <div style={{
          position: 'absolute', left: '50%', top: '50%', transform: 'translate(-50%, -100%)',
        }}>
          <div style={{
            width: 36, height: 36, borderRadius: '50% 50% 50% 0', background: RP.primary,
            transform: 'rotate(-45deg)', boxShadow: '0 4px 12px rgba(108,63,197,0.4)',
            display: 'flex', alignItems: 'center', justifyContent: 'center',
          }}>
            <div style={{ width: 12, height: 12, borderRadius: '50%', background: '#fff', transform: 'rotate(45deg)' }}/>
          </div>
        </div>
      )}
    </div>
  );
}

// ─── QR placeholder ──────────────────────────────────────
function QrPlaceholder({ size = 180 }) {
  // Generate a deterministic-ish 21x21 grid
  const cells = [];
  const rng = (i) => ((i * 9301 + 49297) % 233280) / 233280;
  for (let y = 0; y < 21; y++) {
    for (let x = 0; x < 21; x++) {
      // Position markers (corners 7x7)
      const corner = (x < 7 && y < 7) || (x > 13 && y < 7) || (x < 7 && y > 13);
      let on = false;
      if (corner) {
        const lx = x < 7 ? x : x - 14, ly = y < 7 ? y : y - 14;
        on = (lx === 0 || lx === 6 || ly === 0 || ly === 6) || (lx >= 2 && lx <= 4 && ly >= 2 && ly <= 4);
      } else {
        on = rng(x * 31 + y * 17) > 0.5;
      }
      if (on) cells.push(<rect key={`${x}-${y}`} x={x} y={y} width={1} height={1} fill={RP.text}/>);
    }
  }
  return (
    <svg width={size} height={size} viewBox="0 0 21 21" shapeRendering="crispEdges"
         style={{ background: '#fff', borderRadius: 8, padding: 4, boxSizing: 'content-box' }}>
      {cells}
    </svg>
  );
}

Object.assign(window, {
  Phone, StatusBar, GestureNav, Logo,
  PrimaryButton, GhostButton, Input, Badge, FAB, BottomNav,
  MapPlaceholder, QrPlaceholder,
});
