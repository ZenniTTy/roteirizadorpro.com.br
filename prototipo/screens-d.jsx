// Screen 13: Map view with stops + dual add buttons (top + bottom)

function ScreenMapStops({ goto }) {
  const stops = [
    { n: 1, x: 18, y: 28, s: 'delivered' },
    { n: 2, x: 62, y: 22, s: 'delivered' },
    { n: 3, x: 38, y: 48, s: 'current' },
    { n: 4, x: 75, y: 58, s: 'pending' },
    { n: 5, x: 28, y: 72, s: 'pending' },
    { n: 6, x: 70, y: 84, s: 'pending' },
  ];
  return (
    <Phone>
      <div style={{ flex: 1, position: 'relative', overflow: 'hidden', background: '#EAEDF2' }}>
        {/* Map background */}
        <svg width="100%" height="100%" viewBox="0 0 390 700" preserveAspectRatio="xMidYMid slice" style={{ position: 'absolute', inset: 0 }}>
          <rect width="390" height="700" fill="#EAEDF2"/>
          {/* Blocks */}
          {[
            [10, 10, 80, 80], [110, 20, 100, 60], [240, 10, 90, 70], [340, 30, 60, 90],
            [20, 110, 70, 100], [120, 100, 80, 80], [220, 100, 60, 60], [310, 130, 80, 80],
            [10, 240, 90, 80], [120, 200, 100, 100], [240, 200, 80, 80], [340, 240, 60, 80],
            [20, 350, 80, 90], [120, 330, 70, 70], [220, 330, 90, 80], [330, 350, 70, 70],
            [10, 470, 80, 70], [110, 440, 90, 90], [220, 450, 100, 60], [340, 460, 60, 80],
            [10, 570, 80, 100], [110, 560, 80, 100], [210, 540, 90, 110], [320, 580, 70, 90],
          ].map(([x,y,w,h], i) => <rect key={i} x={x} y={y} width={w} height={h} rx="4" fill="#DCE0E8"/>)}
          {/* Roads */}
          <path d="M 0 100 L 390 100" stroke="#fff" strokeWidth="14"/>
          <path d="M 0 230 L 390 230" stroke="#fff" strokeWidth="10"/>
          <path d="M 0 340 L 390 340" stroke="#fff" strokeWidth="14"/>
          <path d="M 0 450 L 390 450" stroke="#fff" strokeWidth="10"/>
          <path d="M 0 550 L 390 550" stroke="#fff" strokeWidth="12"/>
          <path d="M 100 0 L 100 700" stroke="#fff" strokeWidth="12"/>
          <path d="M 215 0 L 215 700" stroke="#fff" strokeWidth="14"/>
          <path d="M 325 0 L 325 700" stroke="#fff" strokeWidth="10"/>
          {/* Optimized route line */}
          <path d="M 70 196 Q 130 200 240 154 Q 280 200 148 336 Q 200 380 290 406 Q 220 470 110 504 Q 200 540 273 588"
                stroke={RP.primary} strokeWidth="5" fill="none" strokeLinecap="round" strokeLinejoin="round" opacity="0.95"/>
          {/* Neon glow segment for the "current → next" leg */}
          <path d="M 148 336 Q 200 380 290 406"
                stroke={RP.neon} strokeWidth="5" fill="none" strokeLinecap="round" strokeDasharray="2 6"
                style={{ filter: 'drop-shadow(0 0 6px rgba(198,255,61,0.8))' }}/>
        </svg>

        {/* Pins */}
        {stops.map((p) => {
          const left = `${p.x}%`, top = `${p.y}%`;
          const sty = {
            delivered: { bg: RP.success, ring: RP.successBg },
            pending: { bg: RP.primary, ring: RP.primaryLight },
            current: { bg: RP.neon, ring: 'rgba(198,255,61,0.35)' },
          }[p.s];
          const ink = p.s === 'current' ? RP.neonInk : '#fff';
          return (
            <div key={p.n} style={{
              position: 'absolute', left, top, transform: 'translate(-50%, -100%)',
              display: 'flex', flexDirection: 'column', alignItems: 'center',
            }}>
              {p.s === 'current' && (
                <div style={{ position: 'absolute', top: -2, left: '50%', transform: 'translate(-50%, -50%)', width: 60, height: 60, borderRadius: '50%', background: sty.ring, animation: 'rpPulse 2s ease-out infinite' }}/>
              )}
              <div style={{
                width: 36, height: 36, borderRadius: '50% 50% 50% 0',
                background: sty.bg, transform: 'rotate(-45deg)',
                border: `2px solid #fff`,
                boxShadow: '0 6px 16px rgba(26,26,46,0.3)',
                display: 'flex', alignItems: 'center', justifyContent: 'center',
              }}>
                <span style={{ transform: 'rotate(45deg)', color: ink, fontWeight: 700, fontSize: 13 }}>{p.n}</span>
              </div>
            </div>
          );
        })}

        {/* Top header card */}
        <div style={{
          position: 'absolute', top: 12, left: 12, right: 12,
          background: '#fff', borderRadius: RP.rCard, padding: '10px 12px',
          display: 'flex', alignItems: 'center', gap: 10,
          boxShadow: '0 4px 16px rgba(26,26,46,0.12)',
        }}>
          <button onClick={() => goto && goto('home-list')} style={{
            width: 36, height: 36, border: 'none', background: RP.surface, borderRadius: 18,
            display: 'flex', alignItems: 'center', justifyContent: 'center', cursor: 'pointer',
          }}><I.ArrowLeft size={18}/></button>
          <div style={{ flex: 1, minWidth: 0 }}>
            <div style={{ fontSize: 14, fontWeight: 600, color: RP.text }}>Rota de hoje · 6 paradas</div>
            <div style={{ fontSize: 11, color: RP.textMuted, marginTop: 1 }}>
              <span style={{ color: RP.success, fontWeight: 600 }}>2 entregues</span> · 4 pendentes · ~14:30
            </div>
          </div>
          <button onClick={() => goto && goto('add-stop')} style={{
            height: 36, padding: '0 12px', border: 'none', borderRadius: 18,
            background: RP.primary, color: '#fff', cursor: 'pointer',
            display: 'inline-flex', alignItems: 'center', gap: 4,
            fontFamily: RP.font, fontWeight: 600, fontSize: 12,
          }}>
            <I.Plus size={16} stroke={2.4}/> Adicionar
          </button>
        </div>

        {/* Floating mini ETA chip (top-right under header) */}
        <div style={{
          position: 'absolute', top: 76, right: 12,
          display: 'inline-flex', alignItems: 'center', gap: 6,
          height: 32, padding: '0 12px',
          background: RP.neon, color: RP.neonInk,
          borderRadius: 16, fontWeight: 700, fontSize: 12,
          boxShadow: '0 4px 14px rgba(198,255,61,0.5)',
        }}>
          <span style={{ width: 6, height: 6, borderRadius: '50%', background: RP.neonInk, animation: 'rpPulseDot 1s ease-in-out infinite' }}/>
          AO VIVO
        </div>

        {/* Map controls */}
        <div style={{
          position: 'absolute', right: 12, top: 130, display: 'flex', flexDirection: 'column', gap: 8,
        }}>
          {[<I.Plus size={20}/>, <span style={{ fontSize: 18, fontWeight: 700, color: RP.text }}>−</span>, <I.Navigation size={18} color={RP.primary}/>].map((c, i) => (
            <button key={i} style={{
              width: 40, height: 40, borderRadius: 12, border: 'none',
              background: '#fff', cursor: 'pointer',
              display: 'flex', alignItems: 'center', justifyContent: 'center',
              boxShadow: '0 2px 8px rgba(26,26,46,0.15)', color: RP.text,
            }}>{c}</button>
          ))}
        </div>

        {/* Bottom action panel */}
        <div style={{
          position: 'absolute', left: 12, right: 12, bottom: 16,
          background: '#fff', borderRadius: RP.rCard, padding: 14,
          boxShadow: '0 8px 24px rgba(26,26,46,0.18)',
        }}>
          {/* Current stop preview */}
          <div style={{ display: 'flex', alignItems: 'center', gap: 12, paddingBottom: 12, borderBottom: `1px solid ${RP.border}` }}>
            <div style={{
              width: 36, height: 36, borderRadius: '50%', flexShrink: 0,
              background: RP.neon, color: RP.neonInk, fontWeight: 700, fontSize: 14,
              display: 'flex', alignItems: 'center', justifyContent: 'center',
              boxShadow: '0 0 0 3px rgba(198,255,61,0.3)',
            }}>3</div>
            <div style={{ flex: 1, minWidth: 0 }}>
              <div style={{ fontSize: 11, color: RP.neonDark, fontWeight: 700, letterSpacing: 0.6, textTransform: 'uppercase' }}>Próxima parada</div>
              <div style={{ fontSize: 14, fontWeight: 600, color: RP.text, whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis' }}>
                R. Oscar Freire, 875
              </div>
            </div>
            <div style={{ textAlign: 'right' }}>
              <div style={{ fontSize: 14, fontWeight: 700, color: RP.text }}>2,4 km</div>
              <div style={{ fontSize: 11, color: RP.textMuted }}>~8 min</div>
            </div>
          </div>

          {/* Two buttons */}
          <div style={{ display: 'flex', gap: 8, marginTop: 12 }}>
            <button onClick={() => goto && goto('add-stop')} style={{
              flex: 1, height: 48, borderRadius: RP.rBtn,
              background: RP.surface, border: `1.5px solid ${RP.border}`, color: RP.text,
              fontFamily: RP.font, fontWeight: 600, fontSize: 14, cursor: 'pointer',
              display: 'flex', alignItems: 'center', justifyContent: 'center', gap: 6,
            }}>
              <I.Plus size={18} stroke={2.2}/> Adicionar
            </button>
            <button onClick={() => goto && goto('home-list')} style={{
              flex: 1, height: 48, borderRadius: RP.rBtn,
              background: '#fff', border: `1.5px solid ${RP.primary}`, color: RP.primary,
              fontFamily: RP.font, fontWeight: 600, fontSize: 14, cursor: 'pointer',
              display: 'flex', alignItems: 'center', justifyContent: 'center', gap: 6,
            }}>
              <I.GripVertical size={18}/> Editar
            </button>
          </div>

          {/* Primary nav CTA — uses neon as the unlocked accent */}
          <button onClick={() => goto && goto('stop-detail')} style={{
            width: '100%', height: 52, marginTop: 8, borderRadius: RP.rBtn, border: 'none', cursor: 'pointer',
            background: `linear-gradient(135deg, ${RP.primary} 0%, ${RP.primaryDark} 100%)`,
            color: '#fff', fontFamily: RP.font, fontWeight: 600, fontSize: 15,
            display: 'flex', alignItems: 'center', justifyContent: 'center', gap: 8,
            boxShadow: '0 4px 16px rgba(108,63,197,0.32)',
            position: 'relative', overflow: 'hidden',
          }}>
            <I.Navigation size={18}/> Iniciar navegação
            <span style={{
              position: 'absolute', right: 14, top: '50%', transform: 'translateY(-50%)',
              width: 8, height: 8, borderRadius: '50%', background: RP.neon,
              boxShadow: '0 0 8px rgba(198,255,61,0.9)',
            }}/>
          </button>
        </div>
      </div>
    </Phone>
  );
}

window.ScreenMapStops = ScreenMapStops;
