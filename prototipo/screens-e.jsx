// Screens 14-19: Add Stops Map, Optimize, Navigate, Edit Stop, Reorder Lasso, Route Complete
// All inspired by reference shots — original visual identity (purple + neon green, NOT blue).

// ─── Reusable: bigger detailed map background ────────────
function BigMap({ children, dark = false }) {
  return (
    <div style={{ position: 'absolute', inset: 0, background: dark ? '#1A1A2E' : '#EAEDF2', overflow: 'hidden' }}>
      <svg width="100%" height="100%" viewBox="0 0 390 700" preserveAspectRatio="xMidYMid slice" style={{ position: 'absolute', inset: 0 }}>
        <rect width="390" height="700" fill={dark ? '#1A1A2E' : '#EAEDF2'}/>
        {/* Park */}
        <path d="M 0 280 Q 60 250 90 290 Q 130 340 90 410 Q 40 460 0 430 Z" fill={dark ? '#2A2A45' : '#D4DDD0'}/>
        {/* Blocks */}
        {[
          [10, 10, 80, 80], [110, 20, 100, 60], [240, 10, 90, 70], [340, 30, 60, 90],
          [120, 100, 80, 80], [220, 100, 60, 60], [310, 130, 80, 80],
          [120, 200, 100, 80], [240, 200, 80, 80], [340, 240, 60, 80],
          [120, 320, 70, 70], [220, 330, 90, 80], [330, 350, 70, 70],
          [110, 440, 90, 90], [220, 450, 100, 60], [340, 460, 60, 80],
          [10, 540, 80, 100], [110, 560, 80, 100], [210, 540, 90, 110], [320, 580, 70, 90],
        ].map(([x,y,w,h], i) => <rect key={i} x={x} y={y} width={w} height={h} rx="4" fill={dark ? '#252540' : '#DCE0E8'}/>)}
        {/* Roads */}
        {[100, 230, 340, 450, 550].map(y => <path key={`h${y}`} d={`M 0 ${y} L 390 ${y}`} stroke={dark ? '#3A3A55' : '#fff'} strokeWidth="12"/>)}
        {[100, 215, 325].map(x => <path key={`v${x}`} d={`M ${x} 0 L ${x} 700`} stroke={dark ? '#3A3A55' : '#fff'} strokeWidth="12"/>)}
        {/* Highway curve */}
        <path d="M 0 620 Q 100 580 220 640 Q 320 680 390 640" stroke={dark ? '#5A4520' : '#F5C97A'} strokeWidth="8" fill="none" opacity="0.7"/>
      </svg>
      {children}
    </div>
  );
}

// Pin used on Add Stops map (clustered selectable pins)
function MiniPin({ left, top, n, selected, onClick }) {
  const bg = selected ? RP.primary : '#fff';
  const fg = selected ? '#fff' : RP.primary;
  return (
    <div onClick={onClick} style={{
      position: 'absolute', left: `${left}%`, top: `${top}%`,
      transform: 'translate(-50%, -100%)',
      cursor: 'pointer',
    }}>
      <div style={{
        minWidth: 22, height: 26, padding: '0 5px', borderRadius: 6,
        background: bg, color: fg,
        border: `2px solid ${selected ? '#fff' : RP.primary}`,
        boxShadow: selected ? '0 6px 16px rgba(108,63,197,0.5)' : '0 2px 4px rgba(0,0,0,0.15)',
        display: 'flex', alignItems: 'center', justifyContent: 'center',
        fontWeight: 700, fontSize: 10, fontFamily: RP.font,
        position: 'relative',
      }}>
        {n != null ? n : <div style={{ width: 6, height: 6, borderRadius: '50%', background: fg }}/>}
        <div style={{
          position: 'absolute', bottom: -5, left: '50%', transform: 'translateX(-50%) rotate(45deg)',
          width: 8, height: 8, background: bg, borderRight: `2px solid ${selected ? '#fff' : RP.primary}`, borderBottom: `2px solid ${selected ? '#fff' : RP.primary}`,
        }}/>
      </div>
    </div>
  );
}

// ─── 14 · Add Stops Map (multi-pin picker) ───────────────
function ScreenAddStopsMap({ goto }) {
  const [sel, setSel] = React.useState(7);
  const pins = [
    { x: 28, y: 18 }, { x: 52, y: 14 }, { x: 70, y: 18 },
    { x: 22, y: 30 }, { x: 44, y: 26 }, { x: 62, y: 30 }, { x: 80, y: 28 },
    { x: 50, y: 42 }, // selected (current)
    { x: 18, y: 50 }, { x: 30, y: 56 }, { x: 72, y: 52 }, { x: 86, y: 56 },
    { x: 38, y: 64 }, { x: 56, y: 66 }, { x: 76, y: 70 },
    { x: 26, y: 78 }, { x: 46, y: 80 }, { x: 64, y: 82 },
  ];
  return (
    <Phone>
      <div style={{ flex: 1, position: 'relative', overflow: 'hidden' }}>
        <BigMap/>
        {/* Top header */}
        <div style={{
          position: 'absolute', top: 12, left: 12, right: 12,
          display: 'flex', alignItems: 'center', gap: 8,
        }}>
          <button onClick={() => goto && goto('home-list')} style={{
            width: 40, height: 40, borderRadius: 20, border: 'none',
            background: '#fff', boxShadow: '0 4px 12px rgba(26,26,46,0.18)',
            cursor: 'pointer', display: 'flex', alignItems: 'center', justifyContent: 'center',
          }}><I.ArrowLeft size={18}/></button>
          <div style={{
            flex: 1, height: 40, background: '#fff', borderRadius: 20, padding: '0 14px',
            display: 'flex', alignItems: 'center', gap: 8,
            boxShadow: '0 4px 12px rgba(26,26,46,0.18)',
          }}>
            <I.Search size={16} color={RP.textMuted}/>
            <span style={{ fontSize: 13, color: RP.textMuted, fontFamily: RP.font }}>Buscar endereço…</span>
          </div>
        </div>

        {/* Pins */}
        {pins.map((p, i) => (
          <MiniPin key={i} left={p.x} top={p.y} n={i === 7 ? null : null} selected={i === sel} onClick={() => setSel(i)}/>
        ))}

        {/* Home pin */}
        <div style={{ position: 'absolute', left: '60%', top: '60%', transform: 'translate(-50%, -100%)' }}>
          <div style={{
            width: 30, height: 30, borderRadius: '50%', background: RP.primaryDark,
            border: '2px solid #fff', display: 'flex', alignItems: 'center', justifyContent: 'center',
            boxShadow: '0 4px 12px rgba(78,45,145,0.5)',
          }}><I.Home size={14} color="#fff" stroke={2.2}/></div>
        </div>

        {/* Selected pin gets a halo */}
        <div style={{
          position: 'absolute', left: `${pins[sel].x}%`, top: `${pins[sel].y}%`,
          transform: 'translate(-50%, -100%)', pointerEvents: 'none',
        }}>
          <div style={{
            position: 'absolute', top: -8, left: '50%', transform: 'translate(-50%, -50%)',
            width: 60, height: 60, borderRadius: '50%',
            background: 'rgba(108,63,197,0.18)',
          }}/>
        </div>

        {/* Bottom sheet — selected address with two buttons */}
        <div style={{
          position: 'absolute', left: 0, right: 0, bottom: 0,
          background: '#fff', borderTopLeftRadius: 24, borderTopRightRadius: 24,
          padding: '8px 20px 20px',
          boxShadow: '0 -8px 32px rgba(108,63,197,0.16)',
        }}>
          <div style={{ width: 40, height: 4, borderRadius: 2, background: RP.border, margin: '0 auto 14px' }}/>
          <div style={{ display: 'flex', alignItems: 'flex-start', gap: 10, marginBottom: 14 }}>
            <div style={{
              width: 36, height: 36, borderRadius: 18, background: RP.primaryLight,
              display: 'flex', alignItems: 'center', justifyContent: 'center', flexShrink: 0,
            }}><I.MapPin size={18} color={RP.primary}/></div>
            <div style={{ flex: 1, minWidth: 0 }}>
              <div style={{ fontSize: 16, fontWeight: 600, color: RP.text }}>R. Joaquim Floriano, 834</div>
              <div style={{ fontSize: 13, color: RP.textMuted, marginTop: 2 }}>São Paulo, 04535-011</div>
            </div>
            <button style={{
              width: 36, height: 36, borderRadius: 18, border: `1.5px solid ${RP.border}`,
              background: '#fff', cursor: 'pointer',
              display: 'flex', alignItems: 'center', justifyContent: 'center', color: RP.textMuted,
            }}>
              <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><path d="M12 20h9"/><path d="M16.5 3.5a2.121 2.121 0 0 1 3 3L7 19l-4 1 1-4z"/></svg>
            </button>
          </div>
          <PrimaryButton onClick={() => goto && goto('home-list')} icon={<I.Plus size={18} stroke={2.2}/>}>Adicionar parada</PrimaryButton>
          <div style={{ height: 8 }}/>
          <GhostButton onClick={() => goto && goto('edit-stop')}>Adicionar e editar</GhostButton>
        </div>
      </div>
    </Phone>
  );
}

// ─── 15 · Optimize Route (numbered route + sheet) ────────
function ScreenOptimizeRoute({ goto }) {
  // Generate a closed-loop numbered route
  const routePts = [];
  const cx = 200, cy = 240, rx = 130, ry = 150;
  for (let i = 0; i < 27; i++) {
    const a = (i / 27) * Math.PI * 2 - Math.PI / 2;
    // Add some jaggedness
    const j = (i % 3) * 6 - 6;
    routePts.push({
      n: i + 1,
      x: cx + Math.cos(a) * (rx + j),
      y: cy + Math.sin(a) * (ry + j),
    });
  }
  const startPt = { x: cx, y: cy + 30 };
  const pathD = `M ${startPt.x} ${startPt.y} L ${routePts[0].x} ${routePts[0].y} ` +
    routePts.slice(1).map(p => `L ${p.x} ${p.y}`).join(' ') + ` L ${cx + 10} ${cy - ry - 20}`;

  return (
    <Phone>
      <div style={{ flex: 1, position: 'relative', overflow: 'hidden' }}>
        {/* Top map area */}
        <div style={{ position: 'relative', height: 460, overflow: 'hidden' }}>
          <BigMap/>
          {/* Route line */}
          <svg width="100%" height="100%" viewBox="0 0 390 460" preserveAspectRatio="xMidYMid slice" style={{ position: 'absolute', inset: 0 }}>
            <path d={pathD} stroke={RP.primary} strokeWidth="5" fill="none" strokeLinecap="round" strokeLinejoin="round"/>
          </svg>
          {/* Start dot */}
          <div style={{
            position: 'absolute', left: startPt.x - 8, top: startPt.y - 8,
            width: 16, height: 16, borderRadius: '50%', background: RP.primary, border: '3px solid #fff',
            boxShadow: '0 2px 8px rgba(108,63,197,0.5)',
          }}/>
          {/* End flag pin */}
          <div style={{ position: 'absolute', left: cx + 10, top: cy - ry - 30, transform: 'translate(-50%, -100%)' }}>
            <div style={{
              width: 28, height: 28, borderRadius: 6, background: '#fff', border: `2px solid ${RP.primary}`,
              display: 'flex', alignItems: 'center', justifyContent: 'center',
            }}>
              <svg width="14" height="14" viewBox="0 0 24 24" fill={RP.primary} stroke="none"><path d="M5 3v18h2v-7h12L17 9l2-6H5z"/></svg>
            </div>
          </div>
          {/* Numbered pins */}
          {routePts.map(p => (
            <div key={p.n} style={{
              position: 'absolute', left: p.x, top: p.y, transform: 'translate(-50%, -100%)',
            }}>
              <div style={{
                minWidth: 22, height: 24, padding: '0 4px', borderRadius: 5, background: '#fff',
                border: `2px solid ${RP.primary}`, color: RP.primary,
                fontWeight: 700, fontSize: 10, fontFamily: RP.font,
                display: 'flex', alignItems: 'center', justifyContent: 'center',
                boxShadow: '0 2px 4px rgba(0,0,0,0.12)',
              }}>{p.n}</div>
            </div>
          ))}
          {/* Close button */}
          <button onClick={() => goto && goto('home-list')} style={{
            position: 'absolute', top: 12, left: 12, width: 40, height: 40, borderRadius: 20,
            border: 'none', background: '#fff', boxShadow: '0 4px 12px rgba(26,26,46,0.18)', cursor: 'pointer',
            display: 'flex', alignItems: 'center', justifyContent: 'center',
          }}><I.ArrowLeft size={18}/></button>
          {/* Live badge */}
          <div style={{
            position: 'absolute', top: 16, right: 16,
            display: 'inline-flex', alignItems: 'center', gap: 6,
            height: 28, padding: '0 10px',
            background: RP.neon, color: RP.neonInk, borderRadius: 14,
            fontWeight: 700, fontSize: 11, fontFamily: RP.font,
            boxShadow: '0 4px 12px rgba(198,255,61,0.5)',
          }}>
            <span style={{ width: 6, height: 6, borderRadius: '50%', background: RP.neonInk, animation: 'rpPulseDot 1s infinite' }}/>
            ROTA OTIMIZADA
          </div>
        </div>

        {/* Bottom sheet */}
        <div style={{
          flex: 1, background: '#fff', borderTopLeftRadius: 20, borderTopRightRadius: 20,
          marginTop: -20, position: 'relative', zIndex: 2,
          padding: '10px 16px 16px', overflow: 'hidden',
          boxShadow: '0 -8px 24px rgba(108,63,197,0.1)',
        }}>
          <div style={{ width: 40, height: 4, borderRadius: 2, background: RP.border, margin: '0 auto 12px' }}/>
          {/* Search */}
          <div style={{
            height: 44, background: RP.surface, border: `1px solid ${RP.border}`, borderRadius: 22,
            display: 'flex', alignItems: 'center', gap: 8, padding: '0 14px', marginBottom: 12,
          }}>
            <I.Search size={16} color={RP.textMuted}/>
            <span style={{ flex: 1, fontSize: 13, color: RP.textMuted }}>Adicione ou busque</span>
            <I.Camera size={16} color={RP.textMuted}/>
            <I.Mic size={16} color={RP.textMuted}/>
            <I.MoreVertical size={16} color={RP.textMuted}/>
          </div>
          {/* Title */}
          <div style={{ fontSize: 18, fontWeight: 700, color: RP.text, marginBottom: 10 }}>São Paulo · 27 paradas</div>
          {/* Action chips */}
          <div style={{ display: 'flex', gap: 8, marginBottom: 12, flexWrap: 'wrap' }}>
            <button style={{
              height: 32, padding: '0 12px', borderRadius: 16,
              border: `1px solid ${RP.border}`, background: '#fff', cursor: 'pointer',
              display: 'inline-flex', alignItems: 'center', gap: 6,
              fontFamily: RP.font, fontSize: 12, fontWeight: 600, color: RP.text,
            }}><I.Share size={13} color={RP.primary}/> Compartilhar rota</button>
            <button style={{
              height: 32, padding: '0 12px', borderRadius: 16,
              border: `1px solid ${RP.border}`, background: '#fff', cursor: 'pointer',
              display: 'inline-flex', alignItems: 'center', gap: 6,
              fontFamily: RP.font, fontSize: 12, fontWeight: 600, color: RP.text,
            }}><I.Truck size={13} color={RP.primary}/> Carregar veículo</button>
          </div>
          {/* List preview */}
          <div style={{ borderTop: `1px solid ${RP.border}`, paddingTop: 8 }}>
            {[
              { n: 'home', label: 'R. Vizeu, 84', sub: 'São Paulo, 04537-011', t: '09:00' },
              { n: '1', label: 'R. Clodomiro Amazonas, 719', sub: 'São Paulo, 04537-011', t: '09:24' },
              { n: '2', label: 'R. Joaquim Floriano, 834', sub: 'São Paulo, 04535-011', t: '09:41' },
            ].map((s, i) => (
              <div key={i} style={{ display: 'flex', alignItems: 'center', gap: 10, padding: '8px 0' }}>
                <div style={{
                  width: 28, height: 28, borderRadius: 14,
                  background: s.n === 'home' ? RP.primaryLight : '#fff',
                  border: s.n === 'home' ? 'none' : `1.5px solid ${RP.primary}`,
                  color: RP.primary, fontWeight: 700, fontSize: 11,
                  display: 'flex', alignItems: 'center', justifyContent: 'center', flexShrink: 0,
                }}>{s.n === 'home' ? <I.Home size={14}/> : s.n}</div>
                <div style={{ flex: 1, minWidth: 0 }}>
                  <div style={{ fontSize: 13, fontWeight: 600, color: RP.text, whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis' }}>{s.label}</div>
                  <div style={{ fontSize: 11, color: RP.textMuted }}>{s.sub}</div>
                </div>
                <div style={{ fontSize: 12, fontWeight: 600, color: RP.textMuted }}>{s.t}</div>
              </div>
            ))}
          </div>
        </div>
      </div>
    </Phone>
  );
}

// ─── 16 · Navigate (turn-by-turn) ────────────────────────
function ScreenNavigate({ goto }) {
  return (
    <Phone hideNav>
      <div style={{ flex: 1, position: 'relative', overflow: 'hidden', background: '#E5EAF1' }}>
        {/* Simplified perspective road map */}
        <svg width="100%" height="100%" viewBox="0 0 390 800" preserveAspectRatio="xMidYMid slice" style={{ position: 'absolute', inset: 0 }}>
          <rect width="390" height="800" fill="#E5EAF1"/>
          {/* Grid blocks */}
          {[
            [0, 0, 110, 200], [130, 0, 130, 180], [280, 0, 110, 180],
            [0, 220, 110, 180], [280, 200, 110, 180],
            [0, 420, 100, 200], [130, 400, 130, 220], [280, 400, 110, 220],
            [0, 640, 110, 160], [130, 640, 130, 160], [280, 640, 110, 160],
          ].map(([x,y,w,h], i) => <rect key={i} x={x} y={y} width={w} height={h} fill="#F5F7FA"/>)}
          {/* Vertical road */}
          <rect x="110" y="0" width="170" height="800" fill="#fff"/>
          {/* Horizontal road */}
          <rect x="0" y="180" width="390" height="40" fill="#fff"/>
          <rect x="0" y="380" width="390" height="40" fill="#fff"/>
          <rect x="0" y="620" width="390" height="20" fill="#fff"/>
          {/* Active route — going up then turning right */}
          <path d="M 195 750 L 195 200 L 390 200" stroke={RP.primary} strokeWidth="14" fill="none" strokeLinecap="round" strokeLinejoin="round" opacity="0.95"/>
          <path d="M 195 750 L 195 200 L 390 200" stroke={RP.primaryDark} strokeWidth="3" fill="none" strokeLinecap="round" strokeLinejoin="round"/>
          {/* Turn arrow */}
          <path d="M 195 220 L 195 200 L 220 200" stroke="#fff" strokeWidth="3" fill="none"/>
        </svg>

        {/* Top instruction card */}
        <div style={{
          position: 'absolute', top: 12, left: 12, right: 12,
          background: RP.text, color: '#fff',
          borderRadius: 16, padding: '14px 16px',
          display: 'flex', alignItems: 'center', gap: 14,
          boxShadow: '0 8px 24px rgba(26,26,46,0.4)',
        }}>
          <div style={{
            width: 40, height: 40, flexShrink: 0,
            display: 'flex', alignItems: 'center', justifyContent: 'center',
          }}>
            <svg width="40" height="40" viewBox="0 0 24 24" fill="none" stroke="#fff" strokeWidth="2.4" strokeLinecap="round" strokeLinejoin="round">
              <path d="M5 21V11"/>
              <path d="M5 11h7"/>
              <path d="M9 7l3 4-3 4"/>
            </svg>
          </div>
          <div style={{ flex: 1, minWidth: 0 }}>
            <div style={{ fontSize: 11, fontWeight: 600, color: RP.neon, textTransform: 'uppercase', letterSpacing: 0.8 }}>Vire à direita em</div>
            <div style={{ fontSize: 14, fontWeight: 700, marginTop: 2, color: '#fff' }}>0,36 km · R. Bandeira Paulista</div>
          </div>
        </div>

        {/* End-time chip */}
        <div style={{
          position: 'absolute', top: 90, right: 16,
          background: '#fff', borderRadius: 18, padding: '8px 12px',
          display: 'inline-flex', alignItems: 'center', gap: 6,
          fontSize: 13, fontWeight: 700, color: RP.text,
          boxShadow: '0 4px 12px rgba(0,0,0,0.12)',
        }}>
          <svg width="14" height="14" viewBox="0 0 24 24" fill={RP.primary} stroke="none"><path d="M5 3v18h2v-7h12L17 9l2-6H5z"/></svg>
          14:59
        </div>

        {/* Right side controls */}
        <div style={{
          position: 'absolute', right: 14, top: '38%',
          display: 'flex', flexDirection: 'column', gap: 10,
        }}>
          {[<I.Settings size={18}/>, <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke={RP.text} strokeWidth="1.5" strokeLinecap="round" strokeLinejoin="round"><polygon points="12 2 22 8.5 22 15.5 12 22 2 15.5 2 8.5 12 2"/><line x1="12" y1="22" x2="12" y2="15.5"/><polyline points="22 8.5 12 15.5 2 8.5"/></svg>, <I.Navigation size={18} color={RP.primary}/>].map((c, i) => (
            <button key={i} style={{
              width: 44, height: 44, borderRadius: 22, border: 'none', background: '#fff',
              cursor: 'pointer', display: 'flex', alignItems: 'center', justifyContent: 'center',
              boxShadow: '0 4px 12px rgba(0,0,0,0.15)', color: RP.text,
            }}>{c}</button>
          ))}
        </div>

        {/* Speed indicator */}
        <div style={{
          position: 'absolute', left: 14, bottom: 240,
          width: 56, height: 56, borderRadius: 28, background: '#fff',
          display: 'flex', flexDirection: 'column', alignItems: 'center', justifyContent: 'center',
          boxShadow: '0 4px 12px rgba(0,0,0,0.15)',
          border: `3px solid ${RP.primary}`,
        }}>
          <div style={{ fontSize: 18, fontWeight: 800, color: RP.text, lineHeight: 1 }}>67</div>
          <div style={{ fontSize: 9, color: RP.textMuted, fontWeight: 600 }}>km/h</div>
        </div>

        {/* Vehicle marker */}
        <div style={{
          position: 'absolute', left: '50%', top: '60%', transform: 'translate(-50%, -50%)',
        }}>
          <div style={{
            width: 44, height: 44, borderRadius: 22, background: '#fff',
            display: 'flex', alignItems: 'center', justifyContent: 'center',
            boxShadow: '0 4px 14px rgba(108,63,197,0.4)',
            border: `3px solid ${RP.primary}`,
          }}>
            <svg width="20" height="20" viewBox="0 0 24 24" fill={RP.primary} stroke="none"><path d="M12 2l8 18-8-5-8 5z"/></svg>
          </div>
        </div>

        {/* Bottom stop card */}
        <div style={{
          position: 'absolute', left: 12, right: 12, bottom: 70,
          background: '#fff', borderRadius: 16, padding: 14,
          boxShadow: '0 8px 24px rgba(26,26,46,0.18)',
        }}>
          <div style={{ display: 'flex', alignItems: 'center', gap: 8, marginBottom: 8 }}>
            <div style={{ fontSize: 15, fontWeight: 700, color: RP.text, flex: 1, minWidth: 0, whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis' }}>
              R. Joaquim Floriano, 834
            </div>
          </div>
          <div style={{ display: 'flex', alignItems: 'center', gap: 12, fontSize: 11, color: RP.textMuted, marginBottom: 12 }}>
            <span style={{ display: 'inline-flex', alignItems: 'center', gap: 4 }}>
              <span style={{ width: 8, height: 8, borderRadius: '50%', background: RP.warning }}/>
              <strong style={{ color: RP.text, fontWeight: 700 }}>3/27</strong>
            </span>
            <span>📦 Pequeno</span>
            <span>🛍️ Sacola</span>
          </div>
          <div style={{ display: 'flex', gap: 8 }}>
            <button style={{
              flex: 1, height: 44, borderRadius: 12,
              background: RP.errorBg, border: 'none', cursor: 'pointer',
              display: 'flex', alignItems: 'center', justifyContent: 'center', gap: 6,
              fontFamily: RP.font, fontSize: 13, fontWeight: 600, color: '#B91C1C',
            }}>
              <I.X size={16}/> Falhou
            </button>
            <button onClick={() => goto && goto('route-complete')} style={{
              flex: 1, height: 44, borderRadius: 12,
              background: RP.successBg, border: 'none', cursor: 'pointer',
              display: 'flex', alignItems: 'center', justifyContent: 'center', gap: 6,
              fontFamily: RP.font, fontSize: 13, fontWeight: 600, color: '#15803D',
            }}>
              <I.Check size={16}/> Entregue
            </button>
          </div>
        </div>

        {/* Bottom black bar */}
        <div style={{
          position: 'absolute', left: 0, right: 0, bottom: 0,
          height: 60, background: RP.text, color: '#fff',
          display: 'flex', alignItems: 'center', padding: '0 18px',
        }}>
          <button style={{
            width: 36, height: 36, border: 'none', background: 'transparent', cursor: 'pointer',
            display: 'flex', alignItems: 'center', justifyContent: 'center', color: '#fff',
          }}>
            <I.X size={20}/>
          </button>
          <div style={{ flex: 1, textAlign: 'center' }}>
            <div style={{ fontSize: 16, fontWeight: 700 }}>12 min</div>
            <div style={{ fontSize: 11, opacity: 0.7 }}>09:41 · 0,49 km</div>
          </div>
          <button style={{
            width: 36, height: 36, border: 'none', background: 'transparent', cursor: 'pointer',
            display: 'flex', alignItems: 'center', justifyContent: 'center', color: '#fff',
          }}>
            <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><line x1="3" y1="6" x2="21" y2="6"/><line x1="3" y1="12" x2="21" y2="12"/><line x1="3" y1="18" x2="21" y2="18"/></svg>
          </button>
        </div>
      </div>
    </Phone>
  );
}

// ─── 17 · Edit Stop (full personalization sheet) ─────────
function ScreenEditStop({ goto }) {
  const [order, setOrder] = React.useState('Automática');
  const [type, setType] = React.useState('Entrega');
  const [pkgs, setPkgs] = React.useState(1);

  const Seg = ({ value, options, onChange }) => (
    <div style={{
      display: 'inline-flex', height: 34, padding: 3, borderRadius: 17,
      background: RP.surface, border: `1px solid ${RP.border}`,
    }}>
      {options.map(o => (
        <button key={o} onClick={() => onChange(o)} style={{
          height: 28, padding: '0 12px', borderRadius: 14, border: 'none', cursor: 'pointer',
          background: value === o ? '#fff' : 'transparent',
          color: value === o ? RP.primary : RP.textMuted,
          fontFamily: RP.font, fontWeight: 600, fontSize: 11,
          boxShadow: value === o ? '0 1px 3px rgba(0,0,0,0.08)' : 'none',
        }}>{o}</button>
      ))}
    </div>
  );

  const Row = ({ icon, label, right, last }) => (
    <div style={{
      display: 'flex', alignItems: 'center', gap: 12, padding: '11px 0',
      borderBottom: last ? 'none' : `1px solid ${RP.border}`,
    }}>
      <div style={{ width: 20, color: RP.textMuted, display: 'flex' }}>{icon}</div>
      <div style={{ flex: 1, fontSize: 14, fontWeight: 500, color: RP.text }}>{label}</div>
      <div>{right}</div>
    </div>
  );

  return (
    <Phone>
      <div style={{ flex: 1, position: 'relative', background: RP.surface, overflow: 'hidden' }}>
        {/* Faded map behind */}
        <div style={{ position: 'absolute', inset: 0, opacity: 0.5 }}><BigMap/></div>
        <div style={{ position: 'absolute', inset: 0, background: 'rgba(26,26,46,0.25)' }}/>

        {/* Sheet */}
        <div style={{
          position: 'absolute', left: 0, right: 0, top: 80, bottom: 0,
          background: '#fff', borderTopLeftRadius: 24, borderTopRightRadius: 24,
          display: 'flex', flexDirection: 'column',
          boxShadow: '0 -8px 32px rgba(108,63,197,0.18)',
        }}>
          {/* Sheet header */}
          <div style={{ padding: '12px 20px 0' }}>
            <div style={{ width: 40, height: 4, borderRadius: 2, background: RP.border, margin: '0 auto 12px' }}/>
            <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between' }}>
              <button style={{
                width: 32, height: 32, borderRadius: 16, border: 'none', background: RP.surface, cursor: 'pointer',
                display: 'flex', alignItems: 'center', justifyContent: 'center',
              }}><I.HelpCircle size={16} color={RP.textMuted}/></button>
              <div style={{ fontSize: 16, fontWeight: 700, color: RP.text }}>Editar parada</div>
              <button onClick={() => goto && goto('home-list')} style={{
                fontSize: 14, fontWeight: 700, color: RP.primary, background: 'transparent', border: 'none', cursor: 'pointer', padding: 4,
              }}>Concluído</button>
            </div>
          </div>

          {/* Body */}
          <div style={{ flex: 1, overflowY: 'auto', padding: '16px 20px' }}>
            {/* Color tag */}
            <button style={{
              height: 30, padding: '0 12px', borderRadius: 15,
              border: `1px solid ${RP.border}`, background: '#fff', cursor: 'pointer',
              display: 'inline-flex', alignItems: 'center', gap: 8,
              fontFamily: RP.font, fontSize: 12, fontWeight: 600, color: RP.text, marginBottom: 14,
            }}>
              <span style={{ width: 10, height: 10, borderRadius: '50%', background: RP.warning }}/>
              Laranja
            </button>

            {/* Address */}
            <div style={{ fontSize: 18, fontWeight: 700, color: RP.text, lineHeight: 1.25 }}>R. Joaquim Floriano, 834</div>
            <div style={{ fontSize: 13, color: RP.textMuted, marginTop: 2, marginBottom: 14 }}>São Paulo, 04535-011</div>

            {/* Code chip */}
            <button style={{
              width: '100%', height: 44, padding: '0 14px',
              border: `1px solid ${RP.border}`, borderRadius: 12, background: '#fff',
              display: 'flex', alignItems: 'center', gap: 10, cursor: 'pointer', marginBottom: 10,
            }}>
              <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke={RP.primary} strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><circle cx="7.5" cy="15.5" r="5.5"/><path d="m21 2-9.6 9.6"/><path d="m15.5 7.5 3 3L22 7l-3-3"/></svg>
              <span style={{ flex: 1, textAlign: 'left', fontSize: 13, fontWeight: 500, color: RP.text }}>O código do portão é 1684</span>
              <I.ChevronRight size={16} color={RP.textMuted}/>
            </button>

            {/* Note */}
            <div style={{
              padding: '12px 14px', background: RP.surface, borderRadius: 12,
              fontSize: 13, color: RP.textMuted, fontStyle: 'italic', marginBottom: 16,
            }}>
              "O destinatário não está em casa hoje. Deixe o p..."
            </div>

            {/* Options */}
            <Row
              icon={<svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.5"><path d="M21 16V8a2 2 0 0 0-1-1.73l-7-4a2 2 0 0 0-2 0l-7 4A2 2 0 0 0 3 8v8a2 2 0 0 0 1 1.73l7 4a2 2 0 0 0 2 0l7-4A2 2 0 0 0 21 16z"/><polyline points="3.27 6.96 12 12.01 20.73 6.96"/><line x1="12" y1="22.08" x2="12" y2="12"/></svg>}
              label="Localizador"
              right={<span style={{ fontSize: 13, fontWeight: 600, color: RP.primary }}>Grande, Sacola</span>}
            />
            <Row
              icon={<svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.5"><path d="M21 16V8a2 2 0 0 0-1-1.73l-7-4a2 2 0 0 0-2 0l-7 4A2 2 0 0 0 3 8v8a2 2 0 0 0 1 1.73l7 4a2 2 0 0 0 2 0l7-4A2 2 0 0 0 21 16z"/></svg>}
              label="Pacotes"
              right={
                <div style={{ display: 'flex', alignItems: 'center', gap: 4, border: `1px solid ${RP.border}`, borderRadius: 8, padding: 2 }}>
                  <button onClick={() => setPkgs(Math.max(1, pkgs - 1))} style={{ width: 26, height: 26, borderRadius: 6, border: 'none', background: 'transparent', cursor: 'pointer', color: RP.text, fontSize: 16, fontWeight: 700 }}>−</button>
                  <span style={{ minWidth: 18, textAlign: 'center', fontSize: 13, fontWeight: 700 }}>{pkgs}</span>
                  <button onClick={() => setPkgs(pkgs + 1)} style={{ width: 26, height: 26, borderRadius: 6, border: 'none', background: 'transparent', cursor: 'pointer', color: RP.text, fontSize: 16, fontWeight: 700 }}>+</button>
                </div>
              }
            />
            <Row
              icon={<svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.5"><line x1="3" y1="6" x2="21" y2="6"/><line x1="3" y1="12" x2="15" y2="12"/><line x1="3" y1="18" x2="9" y2="18"/></svg>}
              label="Ordem"
              right={<Seg value={order} options={['Primeira','Auto','Última']} onChange={(v) => setOrder(v)}/>}
            />
            <Row
              icon={<svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.5"><polyline points="18 15 12 9 6 15"/></svg>}
              label="Tipo"
              right={<Seg value={type} options={['Entrega','Coleta']} onChange={(v) => setType(v)}/>}
            />
            <Row
              icon={<I.Clock size={18}/>}
              label="Horário de chegada"
              right={<span style={{ fontSize: 13, color: RP.textMuted }}>Qualquer momento</span>}
            />
            <Row
              icon={<svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.5"><circle cx="12" cy="13" r="8"/><path d="M12 9v4l2 2"/><path d="M9 1h6"/></svg>}
              label="Tempo na parada"
              right={<span style={{ fontSize: 13, color: RP.textMuted }}>5 minutos</span>}
              last
            />

            {/* Actions */}
            <div style={{ marginTop: 16, background: RP.surface, borderRadius: 12, padding: '4px 14px' }}>
              <Row
                icon={<I.Search size={18}/>}
                label="Mudar endereço"
                right={<I.ChevronRight size={16} color={RP.textMuted}/>}
              />
              <Row
                icon={<I.Copy size={18}/>}
                label="Duplicar parada"
                right={<I.ChevronRight size={16} color={RP.textMuted}/>}
                last
              />
            </div>
          </div>
        </div>
      </div>
    </Phone>
  );
}

// ─── 18 · Reorder with Lasso ─────────────────────────────
function ScreenReorder({ goto }) {
  // generate route + lasso group
  const stops = [];
  for (let i = 0; i < 33; i++) {
    const a = (i / 33) * Math.PI * 2 - Math.PI / 2;
    const r = 130 + (i % 4) * 8;
    stops.push({
      n: i + 1,
      x: 195 + Math.cos(a) * r,
      y: 320 + Math.sin(a) * (r * 0.95),
    });
  }
  const pathD = `M ${stops[0].x} ${stops[0].y} ` + stops.slice(1).map(p => `L ${p.x} ${p.y}`).join(' ');

  return (
    <Phone>
      <div style={{ flex: 1, position: 'relative', overflow: 'hidden' }}>
        <BigMap/>

        {/* Top notification */}
        <div style={{
          position: 'absolute', top: 12, left: 12, right: 12,
          background: 'rgba(255,255,255,0.95)', borderRadius: 16, padding: '10px 12px',
          display: 'flex', alignItems: 'center', gap: 10,
          boxShadow: '0 4px 16px rgba(26,26,46,0.18)',
          backdropFilter: 'blur(8px)',
        }}>
          <div style={{
            width: 36, height: 36, borderRadius: 18, background: RP.primaryLight,
            display: 'flex', alignItems: 'center', justifyContent: 'center', flexShrink: 0,
            color: RP.primary, fontWeight: 700, fontSize: 14,
          }}>D</div>
          <div style={{ flex: 1, minWidth: 0 }}>
            <div style={{ display: 'flex', alignItems: 'baseline', gap: 6 }}>
              <span style={{ fontSize: 13, fontWeight: 700, color: RP.text }}>Despachante</span>
              <span style={{ fontSize: 11, color: RP.textMuted, marginLeft: 'auto' }}>8:46</span>
            </div>
            <div style={{ fontSize: 12, color: RP.text, lineHeight: 1.3, marginTop: 1 }}>
              Pode ir para Vila Nova Conceição primeiro?
            </div>
          </div>
        </div>

        {/* Route line */}
        <svg width="100%" height="100%" viewBox="0 0 390 700" preserveAspectRatio="xMidYMid slice" style={{ position: 'absolute', inset: 0, pointerEvents: 'none' }}>
          <path d={pathD} stroke={RP.primary} strokeWidth="4" fill="none" strokeLinecap="round" strokeLinejoin="round"/>
          {/* Lasso */}
          <ellipse cx="295" cy="430" rx="80" ry="100" fill="none" stroke={RP.error} strokeWidth="4" strokeLinecap="round" strokeDasharray="0"/>
        </svg>

        {/* Numbered pins */}
        {stops.map((p, i) => (
          <div key={p.n} style={{
            position: 'absolute', left: p.x, top: p.y, transform: 'translate(-50%, -100%)',
          }}>
            <div style={{
              minWidth: 22, height: 22, padding: '0 4px', borderRadius: 4, background: '#fff',
              border: `1.5px solid ${RP.primary}`, color: RP.primary,
              fontWeight: 700, fontSize: 9, fontFamily: RP.font,
              display: 'flex', alignItems: 'center', justifyContent: 'center',
              boxShadow: '0 1px 3px rgba(0,0,0,0.12)',
            }}>{p.n}</div>
          </div>
        ))}

        {/* Lasso badge */}
        <div style={{
          position: 'absolute', left: 320, top: 530, transform: 'translate(-50%, -50%)',
          width: 28, height: 28, borderRadius: 14, background: RP.error, color: '#fff',
          display: 'flex', alignItems: 'center', justifyContent: 'center',
          fontSize: 12, fontWeight: 700, fontFamily: RP.font,
          boxShadow: '0 4px 12px rgba(239,68,68,0.5)',
        }}>9</div>

        {/* Undo */}
        <button style={{
          position: 'absolute', left: 14, bottom: 220,
          height: 38, padding: '0 14px', borderRadius: 19, border: 'none', background: '#fff', cursor: 'pointer',
          display: 'inline-flex', alignItems: 'center', gap: 6,
          boxShadow: '0 4px 12px rgba(0,0,0,0.15)',
          fontFamily: RP.font, fontSize: 13, fontWeight: 600, color: RP.text,
        }}>
          <I.RefreshCw size={14}/> Desfazer
        </button>

        {/* Bottom panel */}
        <div style={{
          position: 'absolute', left: 0, right: 0, bottom: 0,
          background: '#fff', borderTopLeftRadius: 20, borderTopRightRadius: 20,
          padding: '14px 16px 18px',
          boxShadow: '0 -8px 24px rgba(108,63,197,0.16)',
        }}>
          <div style={{ width: 40, height: 4, borderRadius: 2, background: RP.border, margin: '0 auto 12px' }}/>
          <div style={{ fontSize: 13, color: RP.textMuted, textAlign: 'center', marginBottom: 10 }}>
            <strong style={{ color: RP.error, fontWeight: 700 }}>9 paradas</strong> selecionadas no grupo
          </div>
          <GhostButton style={{ height: 44, marginBottom: 8 }}>
            <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.5" strokeLinecap="round" strokeLinejoin="round"><path d="M3 17l6-6 4 4 8-8"/><circle cx="3" cy="17" r="1.5" fill="currentColor"/></svg>
            Desenhar o grupo seguinte
          </GhostButton>
          <PrimaryButton onClick={() => goto && goto('optimize')} icon={<I.Sparkle size={18}/>} neon>
            Reotimizar rota
          </PrimaryButton>
        </div>
      </div>
    </Phone>
  );
}

// ─── 19 · Route Complete ─────────────────────────────────
function ScreenRouteComplete({ goto }) {
  return (
    <Phone>
      <div style={{ flex: 1, position: 'relative', overflow: 'hidden' }}>
        {/* Faded background map */}
        <div style={{ position: 'absolute', inset: 0, opacity: 0.4 }}><BigMap/></div>
        <div style={{ position: 'absolute', inset: 0, background: 'rgba(255,255,255,0.55)' }}/>

        {/* Confetti accents */}
        <div style={{ position: 'absolute', inset: 0, pointerEvents: 'none' }}>
          {[
            { l: 12, t: 18, r: -15, c: RP.neon },
            { l: 82, t: 14, r: 25, c: RP.primary },
            { l: 18, t: 60, r: 30, c: RP.warning },
            { l: 78, t: 66, r: -20, c: RP.success },
            { l: 30, t: 84, r: 10, c: RP.accent },
            { l: 70, t: 86, r: -30, c: RP.neonDark },
          ].map((p, i) => (
            <div key={i} style={{
              position: 'absolute', left: `${p.l}%`, top: `${p.t}%`,
              width: 8, height: 14, background: p.c,
              transform: `rotate(${p.r}deg)`, borderRadius: 2, opacity: 0.85,
            }}/>
          ))}
        </div>

        {/* Card */}
        <div style={{
          position: 'absolute', top: '50%', left: '50%', transform: 'translate(-50%, -50%)',
          width: 320, background: '#fff', borderRadius: 24,
          padding: '28px 24px',
          boxShadow: '0 24px 48px rgba(108,63,197,0.18), 0 8px 24px rgba(26,26,46,0.08)',
          textAlign: 'center',
        }}>
          {/* Check circle */}
          <div style={{
            width: 72, height: 72, borderRadius: 36, margin: '0 auto 16px',
            background: `linear-gradient(135deg, ${RP.success} 0%, #15803D 100%)`,
            display: 'flex', alignItems: 'center', justifyContent: 'center',
            boxShadow: '0 8px 20px rgba(34,197,94,0.4)',
            position: 'relative',
          }}>
            <I.Check size={36} color="#fff" stroke={3}/>
            {/* Neon ring accent */}
            <div style={{
              position: 'absolute', inset: -6, borderRadius: 42,
              border: `2px solid ${RP.neon}`, opacity: 0.6,
            }}/>
          </div>

          <div style={{ fontSize: 22, fontWeight: 700, color: RP.text, marginBottom: 4 }}>
            Rota concluída!
          </div>
          <div style={{ fontSize: 13, color: RP.textMuted, marginBottom: 18 }}>
            27 paradas em <strong style={{ color: RP.text }}>4h 12min</strong>
          </div>

          {/* Stats */}
          <div style={{ display: 'flex', gap: 8, marginBottom: 18 }}>
            <div style={{
              flex: 1, padding: '10px 8px', background: RP.primaryLight, borderRadius: 12,
            }}>
              <div style={{ fontSize: 18, fontWeight: 800, color: RP.primary }}>27</div>
              <div style={{ fontSize: 10, fontWeight: 600, color: RP.primary, marginTop: 2 }}>Entregues</div>
            </div>
            <div style={{
              flex: 1, padding: '10px 8px', background: RP.surface, borderRadius: 12,
            }}>
              <div style={{ fontSize: 18, fontWeight: 800, color: RP.text }}>87 km</div>
              <div style={{ fontSize: 10, fontWeight: 600, color: RP.textMuted, marginTop: 2 }}>Percorridos</div>
            </div>
          </div>

          {/* Saved banner */}
          <div style={{
            background: RP.neonLight, border: `1px solid ${RP.neon}`,
            borderRadius: 14, padding: '12px 14px', marginBottom: 16,
            display: 'flex', alignItems: 'center', gap: 10,
          }}>
            <div style={{
              width: 32, height: 32, borderRadius: 16, background: RP.neon,
              display: 'flex', alignItems: 'center', justifyContent: 'center', flexShrink: 0,
            }}>
              <I.Sparkle size={16} color={RP.neonInk}/>
            </div>
            <div style={{ flex: 1, textAlign: 'left' }}>
              <div style={{ fontSize: 11, fontWeight: 700, color: RP.neonInk, textTransform: 'uppercase', letterSpacing: 0.5 }}>Você economizou</div>
              <div style={{ fontSize: 14, fontWeight: 700, color: RP.text }}>1h 24min · 35 km 🎉</div>
            </div>
          </div>

          <PrimaryButton onClick={() => goto && goto('home-empty')}>
            Voltar para casa
          </PrimaryButton>
          <button onClick={() => goto && goto('share')} style={{
            background: 'transparent', border: 'none', cursor: 'pointer',
            fontFamily: RP.font, fontSize: 13, fontWeight: 600, color: RP.primary,
            marginTop: 10,
          }}>Compartilhar conquista →</button>
        </div>
      </div>
    </Phone>
  );
}

Object.assign(window, {
  ScreenAddStopsMap, ScreenOptimizeRoute, ScreenNavigate,
  ScreenEditStop, ScreenReorder, ScreenRouteComplete,
});
