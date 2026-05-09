// Screens 7-12: OCR, Optimize, Stop Detail, Paywall, Settings, Share

// ─── Screen 7: OCR Scanner ───────────────────────────────
function ScreenOCR({ goto }) {
  const [stage, setStage] = useState('scan'); // 'scan' | 'result'
  return (
    <Phone dark statusBarDark>
      <div style={{ flex: 1, position: 'relative', background: '#0E0E1A', overflow: 'hidden' }}>
        {/* Mock camera viewfinder */}
        <div style={{ position: 'absolute', inset: 0, background: `
          radial-gradient(ellipse at 30% 20%, #2a2540 0%, #0E0E1A 70%),
          linear-gradient(180deg, #1a1730 0%, #0E0E1A 100%)
        ` }}/>
        {/* Faint package mockup */}
        <div style={{
          position: 'absolute', left: '50%', top: '46%', transform: 'translate(-50%, -50%) rotate(-3deg)',
          width: 240, height: 200, background: '#D4C9A8', borderRadius: 4, opacity: 0.7,
          boxShadow: '0 20px 60px rgba(0,0,0,0.5)',
        }}>
          <div style={{ padding: 16, fontFamily: 'monospace', fontSize: 9, color: '#3a2f1a', lineHeight: 1.6 }}>
            <div style={{ fontWeight: 700, fontSize: 11 }}>DESTINATÁRIO:</div>
            <div>MARIA SOUZA</div>
            <div>R. HADDOCK LOBO, 1500</div>
            <div>APTO 1201 · JARDINS</div>
            <div>SÃO PAULO · SP</div>
            <div>CEP 01414-002</div>
          </div>
        </div>

        {/* Top bar */}
        <div style={{ position: 'absolute', top: 0, left: 0, right: 0, padding: '12px 16px', display: 'flex', alignItems: 'center', gap: 12 }}>
          <button onClick={() => goto && goto('add-stop')} style={{
            width: 40, height: 40, borderRadius: 20, border: 'none',
            background: 'rgba(255,255,255,0.15)', backdropFilter: 'blur(10px)',
            color: '#fff', display: 'flex', alignItems: 'center', justifyContent: 'center', cursor: 'pointer',
          }}><I.X size={22}/></button>
          <div style={{ color: '#fff', fontWeight: 600, fontSize: 14 }}>
            Aponte para a etiqueta do pacote
          </div>
        </div>

        {/* Frame brackets */}
        <div style={{
          position: 'absolute', left: '50%', top: '50%', transform: 'translate(-50%, -50%)',
          width: 280, height: 220, border: `2px dashed rgba(255,255,255,0.4)`, borderRadius: 16,
        }}>
          {[
            { l: -2, t: -2, br: '0 0 0 4px' }, { r: -2, t: -2, br: '0 0 4px 0' },
            { l: -2, b: -2, br: '0 4px 0 0' }, { r: -2, b: -2, br: '4px 0 0 0' },
          ].map((p, i) => (
            <div key={i} style={{
              position: 'absolute', width: 28, height: 28,
              borderTop: p.t !== undefined ? `3px solid ${RP.accent}` : 'none',
              borderBottom: p.b !== undefined ? `3px solid ${RP.accent}` : 'none',
              borderLeft: p.l !== undefined ? `3px solid ${RP.accent}` : 'none',
              borderRight: p.r !== undefined ? `3px solid ${RP.accent}` : 'none',
              left: p.l, right: p.r, top: p.t, bottom: p.b, borderRadius: p.br,
            }}/>
          ))}
        </div>

        {/* Result card */}
        {stage === 'result' && (
          <div style={{
            position: 'absolute', left: 16, right: 16, bottom: 110,
            background: '#fff', borderRadius: RP.rCard, padding: 20,
            boxShadow: '0 12px 40px rgba(0,0,0,0.4)',
          }}>
            <div style={{ fontSize: 12, color: RP.textMuted, fontWeight: 500, marginBottom: 8 }}>Endereço encontrado:</div>
            <div style={{ fontSize: 17, fontWeight: 600, color: RP.primary, lineHeight: 1.4 }}>
              R. Haddock Lobo, 1500 · Apto 1201<br/>Jardins, São Paulo
            </div>
            <div style={{ display: 'flex', gap: 8, marginTop: 16 }}>
              <button style={{
                flex: 1, height: 44, border: 'none', background: 'transparent',
                color: RP.primary, fontFamily: RP.font, fontWeight: 600, fontSize: 14, cursor: 'pointer',
              }}>Editar</button>
              <button onClick={() => goto && goto('home-list')} style={{
                flex: 2, height: 44, border: 'none', borderRadius: 22,
                background: RP.primary, color: '#fff', fontFamily: RP.font, fontWeight: 600, fontSize: 14, cursor: 'pointer',
              }}>Confirmar</button>
            </div>
          </div>
        )}

        {/* Capture button */}
        {stage === 'scan' && (
          <div style={{ position: 'absolute', bottom: 50, left: 0, right: 0, display: 'flex', justifyContent: 'center' }}>
            <button onClick={() => setStage('result')} style={{
              width: 76, height: 76, borderRadius: '50%',
              background: '#fff', border: `4px solid rgba(255,255,255,0.3)`,
              display: 'flex', alignItems: 'center', justifyContent: 'center',
              cursor: 'pointer', color: RP.primary,
            }}><I.Camera size={28} stroke={2}/></button>
          </div>
        )}
      </div>
    </Phone>
  );
}

// ─── Screen 8: Optimize Loading ──────────────────────────
function ScreenOptimize({ goto }) {
  const steps = [
    { label: 'Analisando suas paradas...', done: true },
    { label: 'Calculando tráfego...', done: true },
    { label: 'Encontrando o melhor caminho para casa...', done: false, active: true },
  ];
  return (
    <Phone>
      <div style={{ flex: 1, padding: 32, display: 'flex', flexDirection: 'column', alignItems: 'center' }}>
        <div style={{ flex: 1 }}/>
        <Logo size={48}/>

        {/* Animated dots-to-route illustration */}
        <div style={{ marginTop: 40, marginBottom: 40, position: 'relative', width: 280, height: 80 }}>
          <svg width="280" height="80" viewBox="0 0 280 80">
            <path d="M 20 60 Q 70 20 130 50 T 260 30" stroke={RP.primary} strokeWidth="3" fill="none" strokeDasharray="4 6" strokeLinecap="round" style={{ animation: 'rpDash 2s linear infinite' }}/>
            {[20, 80, 140, 200, 260].map((cx, i) => {
              const cy = [60, 32, 50, 36, 30][i];
              return <circle key={i} cx={cx} cy={cy} r="6" fill={RP.primary} style={{ animation: `rpFade 1.5s ${i * 0.2}s ease-in-out infinite` }}/>;
            })}
          </svg>
        </div>

        <div style={{ width: '100%', display: 'flex', flexDirection: 'column', gap: 16 }}>
          {steps.map((s, i) => (
            <div key={i} style={{ display: 'flex', alignItems: 'center', gap: 12 }}>
              <div style={{
                width: 24, height: 24, borderRadius: '50%', flexShrink: 0,
                background: s.done ? RP.success : 'transparent',
                border: s.active ? `2px solid ${RP.primary}` : 'none',
                display: 'flex', alignItems: 'center', justifyContent: 'center',
              }}>
                {s.done && <I.Check size={14} color="#fff" stroke={3}/>}
                {s.active && <div style={{ width: 8, height: 8, borderRadius: '50%', background: RP.primary, animation: 'rpPulseDot 1s ease-in-out infinite' }}/>}
              </div>
              <div style={{ fontSize: 14, color: s.active ? RP.text : RP.textMuted, fontWeight: s.active ? 600 : 500 }}>{s.label}</div>
            </div>
          ))}
        </div>
        <div style={{ flex: 1 }}/>

        {/* Progress bar */}
        <div style={{ width: '100%', height: 6, background: RP.surface, borderRadius: 3, overflow: 'hidden' }}>
          <div style={{ width: '80%', height: '100%', background: `linear-gradient(90deg, ${RP.accent}, ${RP.primary})`, borderRadius: 3 }}/>
        </div>
        <div style={{ fontSize: 12, color: RP.textMuted, marginTop: 12 }}>Estimando tempo de chegada...</div>
        <button onClick={() => goto && goto('home-list')} style={{ marginTop: 16, background: 'transparent', border: 'none', color: RP.primary, fontWeight: 600, cursor: 'pointer', fontFamily: RP.font }}>
          Pular →
        </button>
      </div>
    </Phone>
  );
}

// ─── Screen 9: Stop Detail ───────────────────────────────
function ScreenStopDetail({ goto }) {
  return (
    <Phone>
      <TopBar title="Parada 3 de 8" onBack={() => goto && goto('home-list')}/>
      <div style={{ flex: 1, padding: '0 16px 16px', overflowY: 'auto', display: 'flex', flexDirection: 'column', gap: 16 }}>
        <MapPlaceholder height={180}/>

        <div style={{ background: '#fff', border: `1px solid ${RP.border}`, borderRadius: RP.rCard, padding: 16, boxShadow: RP.cardShadow }}>
          <div style={{ display: 'flex', alignItems: 'flex-start', justifyContent: 'space-between', gap: 12 }}>
            <div style={{ flex: 1 }}>
              <div style={{ fontSize: 18, fontWeight: 600, lineHeight: 1.4 }}>R. Oscar Freire, 875</div>
              <div style={{ fontSize: 14, color: RP.textMuted, marginTop: 4 }}>Apto 1201 · Jardins, São Paulo</div>
            </div>
            <Badge variant="primary">Entrega</Badge>
          </div>
          <div style={{ display: 'flex', gap: 16, marginTop: 14, paddingTop: 14, borderTop: `1px solid ${RP.border}` }}>
            <div>
              <div style={{ fontSize: 11, color: RP.textMuted, fontWeight: 500 }}>DISTÂNCIA</div>
              <div style={{ fontSize: 14, fontWeight: 600, marginTop: 2 }}>2,4 km</div>
            </div>
            <div>
              <div style={{ fontSize: 11, color: RP.textMuted, fontWeight: 500 }}>TEMPO</div>
              <div style={{ fontSize: 14, fontWeight: 600, marginTop: 2 }}>~8 min</div>
            </div>
            <div>
              <div style={{ fontSize: 11, color: RP.textMuted, fontWeight: 500 }}>CONTATO</div>
              <div style={{ fontSize: 14, fontWeight: 600, marginTop: 2 }}>Maria S.</div>
            </div>
          </div>
        </div>

        {/* Action buttons */}
        <div style={{ display: 'flex', gap: 8 }}>
          <ActionBtn variant="success" icon={<I.Check size={18} stroke={2.2}/>}>Entregue</ActionBtn>
          <ActionBtn variant="error" icon={<I.X size={18} stroke={2.2}/>}>Falhou</ActionBtn>
          <ActionBtn variant="ghost" icon={<I.ArrowRight size={18}/>}>Próxima</ActionBtn>
        </div>

        {/* Locked nav button */}
        <div style={{ display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 8 }}>
          <PrimaryButton locked>Iniciar Navegação</PrimaryButton>
          <button onClick={() => goto && goto('paywall')} style={{
            background: 'transparent', border: 'none', color: RP.primary, fontFamily: RP.font,
            fontSize: 13, fontWeight: 600, cursor: 'pointer', padding: 4,
          }}>Assine para navegar →</button>
        </div>

        {/* Move options */}
        <div style={{ background: '#fff', border: `1px solid ${RP.border}`, borderRadius: RP.rCard, overflow: 'hidden' }}>
          <RowItem label="Tornar próxima"/>
          <RowItem label="Mover para o início"/>
          <RowItem label="Mover para o final" last/>
        </div>
      </div>
    </Phone>
  );
}

function ActionBtn({ children, icon, variant }) {
  const c = {
    success: { bg: RP.success, fg: '#fff', br: 'transparent' },
    error: { bg: RP.error, fg: '#fff', br: 'transparent' },
    ghost: { bg: '#fff', fg: RP.primary, br: RP.primary },
  }[variant];
  return (
    <button style={{
      flex: 1, height: 48, borderRadius: RP.rBtn,
      background: c.bg, color: c.fg, border: `1.5px solid ${c.br}`,
      fontFamily: RP.font, fontWeight: 600, fontSize: 13, cursor: 'pointer',
      display: 'flex', alignItems: 'center', justifyContent: 'center', gap: 6,
    }}>{icon} {children}</button>
  );
}

function RowItem({ label, value, valueColor, last, onClick }) {
  return (
    <div onClick={onClick} style={{
      padding: '14px 16px', display: 'flex', alignItems: 'center', gap: 12,
      borderBottom: last ? 'none' : `1px solid ${RP.border}`,
      cursor: onClick ? 'pointer' : 'default',
    }}>
      <div style={{ flex: 1, fontSize: 14, color: RP.text, fontWeight: 500 }}>{label}</div>
      {value && <div style={{ fontSize: 13, color: valueColor || RP.textMuted, fontWeight: 500 }}>{value}</div>}
      <I.ChevronRight size={18} color={RP.textMuted}/>
    </div>
  );
}

// ─── Screen 10: Paywall ──────────────────────────────────
function ScreenPaywall({ goto }) {
  const [stage, setStage] = useState('intro'); // 'intro' | 'pix'
  return (
    <Phone>
      <div style={{ flex: 1, position: 'relative', background: '#fff', overflow: 'hidden' }}>
        {/* Faded background of stop detail */}
        <div style={{ filter: 'blur(2px)', opacity: 0.4 }}>
          <TopBar title="Parada 3 de 8"/>
          <div style={{ padding: '0 16px' }}><MapPlaceholder height={140}/></div>
        </div>
        <div style={{ position: 'absolute', inset: 0, background: 'rgba(26,26,46,0.5)' }}/>

        <div style={{
          position: 'absolute', left: 0, right: 0, bottom: 0,
          background: '#fff', borderTopLeftRadius: RP.rSheet, borderTopRightRadius: RP.rSheet,
          padding: '12px 24px 24px', boxShadow: RP.sheetShadow,
          display: 'flex', flexDirection: 'column', gap: 16, maxHeight: '90%', overflowY: 'auto',
        }}>
          <div style={{ display: 'flex', justifyContent: 'center' }}>
            <div style={{ width: 40, height: 4, borderRadius: 2, background: RP.border }}/>
          </div>

          {stage === 'intro' && (
            <>
              <div style={{ display: 'flex', justifyContent: 'center', marginTop: 4 }}>
                <div style={{
                  width: 56, height: 56, borderRadius: '50%', background: RP.primaryLight,
                  display: 'flex', alignItems: 'center', justifyContent: 'center', color: RP.primary,
                }}><I.Lock size={26}/></div>
              </div>
              <div style={{ textAlign: 'center' }}>
                <div style={{ fontSize: 24, fontWeight: 600, letterSpacing: -0.4 }}>Desbloqueie a navegação</div>
                <div style={{ fontSize: 14, color: RP.textMuted, marginTop: 6 }}>Assine e comece a navegar agora</div>
              </div>

              <div style={{
                border: `1.5px solid ${RP.primary}`, borderRadius: RP.rCard,
                padding: '20px 16px', textAlign: 'center', background: 'rgba(108,63,197,0.03)',
              }}>
                <div style={{ display: 'inline-flex', alignItems: 'baseline', gap: 4 }}>
                  <span style={{ fontSize: 36, fontWeight: 700, color: RP.primary, letterSpacing: -1 }}>R$ 25,90</span>
                </div>
                <div style={{ fontSize: 13, color: RP.textMuted, marginTop: 2 }}>/mês via Pix · cancele quando quiser</div>
              </div>

              <div style={{ display: 'flex', flexDirection: 'column', gap: 12 }}>
                {['Rotas ilimitadas', 'Otimização sentido casa', 'Suporte prioritário'].map((f) => (
                  <div key={f} style={{ display: 'flex', alignItems: 'center', gap: 10 }}>
                    <div style={{
                      width: 24, height: 24, borderRadius: '50%', background: RP.successBg,
                      display: 'flex', alignItems: 'center', justifyContent: 'center', color: RP.success,
                    }}><I.Check size={14} stroke={2.5}/></div>
                    <div style={{ fontSize: 14, color: RP.text, fontWeight: 500 }}>{f}</div>
                  </div>
                ))}
              </div>

              <PrimaryButton icon={<I.Pix size={20}/>} onClick={() => setStage('pix')}>Pagar com Pix</PrimaryButton>
            </>
          )}

          {stage === 'pix' && (
            <>
              <div style={{ textAlign: 'center' }}>
                <div style={{ fontSize: 20, fontWeight: 600 }}>Escaneie o QR Code</div>
                <div style={{ fontSize: 13, color: RP.textMuted, marginTop: 4 }}>Validade: 10 min · R$ 25,90</div>
              </div>
              <div style={{ display: 'flex', justifyContent: 'center' }}>
                <div style={{ padding: 12, border: `2px solid ${RP.primary}`, borderRadius: 16, background: '#fff' }}>
                  <QrPlaceholder size={180}/>
                </div>
              </div>
              <div style={{ fontSize: 12, color: RP.textMuted, textAlign: 'center' }}>ou copie o código:</div>
              <div style={{
                display: 'flex', alignItems: 'center', gap: 8,
                background: RP.surface, border: `1px solid ${RP.border}`,
                borderRadius: RP.rInput, padding: '10px 12px',
              }}>
                <div style={{
                  flex: 1, fontFamily: 'ui-monospace, "SF Mono", monospace', fontSize: 11,
                  color: RP.textMuted, whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis',
                }}>00020126890014BR.GOV.BCB.PIX0136a3c2e8...</div>
                <button style={{
                  height: 32, padding: '0 12px', border: 'none', background: RP.primary, color: '#fff',
                  borderRadius: 16, fontFamily: RP.font, fontWeight: 600, fontSize: 12, cursor: 'pointer',
                }}>Copiar</button>
              </div>
              <button onClick={() => goto && goto('home-list')} style={{
                height: 44, border: 'none', background: 'transparent', color: RP.primary,
                fontFamily: RP.font, fontWeight: 600, fontSize: 14, cursor: 'pointer',
              }}>Já paguei</button>
            </>
          )}
        </div>
      </div>
    </Phone>
  );
}

// ─── Screen 11: Settings ─────────────────────────────────
function ScreenSettings({ goto }) {
  const Section = ({ title, children }) => (
    <div style={{ marginBottom: 24 }}>
      <div style={{ fontSize: 11, fontWeight: 600, color: RP.textMuted, letterSpacing: 1.2, padding: '0 16px 8px', textTransform: 'uppercase' }}>{title}</div>
      <div style={{ background: '#fff', border: `1px solid ${RP.border}`, borderRadius: RP.rCard, overflow: 'hidden', margin: '0 16px' }}>
        {children}
      </div>
    </div>
  );
  return (
    <Phone>
      <TopBar title="Configurações" onBack={() => goto && goto('home-list')}/>
      <div style={{ flex: 1, overflowY: 'auto', padding: '8px 0 24px', background: RP.surface }}>
        <Section title="Navegação">
          <RowItem label="App de GPS padrão" value={<span style={{ display: 'inline-flex', alignItems: 'center', gap: 6 }}><span style={{ width: 16, height: 16, borderRadius: 4, background: '#33CCFF', display: 'inline-block' }}/>Waze</span>}/>
        </Section>
        <Section title="Rota">
          <RowItem label="Minha casa" value="R. das Flores, 123"/>
          <RowItem label="Otimização padrão" value="Sentido casa" last/>
        </Section>
        <Section title="Conta">
          <RowItem label="E-mail" value="motoboy@email.com"/>
          <RowItem label="Alterar senha"/>
          <RowItem label="Minha assinatura" value="Ativa até 05/06/2026" valueColor={RP.success} last/>
        </Section>
        <Section title="Sobre o app">
          <RowItem label="Versão" value="1.0.0"/>
          <RowItem label="Indicar para um amigo" onClick={() => goto && goto('share')}/>
          <RowItem label="Política de privacidade"/>
          <RowItem label="Suporte" last/>
        </Section>
        <div style={{ margin: '0 16px' }}>
          <div style={{
            background: '#fff', border: `1px solid ${RP.border}`, borderRadius: RP.rCard,
            padding: '14px 16px', display: 'flex', alignItems: 'center', gap: 10,
            color: RP.error, fontWeight: 600, fontSize: 14, cursor: 'pointer',
          }} onClick={() => goto && goto('login')}>
            <I.LogOut size={18}/> Sair da conta
          </div>
        </div>
      </div>
      <BottomNav active="settings"/>
    </Phone>
  );
}

// ─── Screen 12: Share / Referral ─────────────────────────
function ScreenShare({ goto }) {
  const [copied, setCopied] = useState(false);
  return (
    <Phone>
      <TopBar title="Indique o app" onBack={() => goto && goto('settings')}/>
      <div style={{ flex: 1, padding: '8px 16px 24px', overflowY: 'auto', display: 'flex', flexDirection: 'column', gap: 12 }}>
        <div style={{ fontSize: 14, color: RP.textMuted, padding: '0 4px 4px' }}>
          Passe o link para outro motoboy e ganhe um mês grátis quando ele assinar.
        </div>

        {/* WhatsApp */}
        <ShareCard
          icon={<div style={{ width: 40, height: 40, borderRadius: '50%', background: '#25D366', display: 'flex', alignItems: 'center', justifyContent: 'center', color: '#fff' }}><I.WhatsApp size={22}/></div>}
          title="Compartilhar no WhatsApp"
          sub="Abre o WhatsApp com mensagem pronta"
          right={<I.ChevronRight size={20} color={RP.textMuted}/>}
        />

        {/* Copiar link */}
        <ShareCard
          icon={<div style={{ width: 40, height: 40, borderRadius: '50%', background: RP.primaryLight, display: 'flex', alignItems: 'center', justifyContent: 'center', color: RP.primary }}><I.Link size={22}/></div>}
          title="Copiar link de download"
          sub={<span style={{ fontFamily: 'ui-monospace, "SF Mono", monospace', fontSize: 12 }}>roteirizadorpro.com.br/download</span>}
          right={
            <button onClick={() => { setCopied(true); setTimeout(() => setCopied(false), 1500); }}
              style={{
                height: 32, padding: '0 12px', border: `1px solid ${RP.border}`,
                background: copied ? RP.successBg : '#fff', color: copied ? RP.success : RP.primary,
                borderRadius: 16, fontFamily: RP.font, fontWeight: 600, fontSize: 12, cursor: 'pointer',
                display: 'inline-flex', alignItems: 'center', gap: 4,
              }}>
              {copied ? <><I.Check size={14} stroke={2.5}/> Copiado!</> : <><I.Copy size={14}/> Copiar</>}
            </button>
          }
        />

        {/* QR */}
        <ShareCard
          icon={<div style={{ width: 40, height: 40, borderRadius: '50%', background: RP.primaryLight, display: 'flex', alignItems: 'center', justifyContent: 'center', color: RP.primary }}><I.QrCode size={22}/></div>}
          title="Mostrar QR Code"
          sub="Outro motoboy escaneia direto"
          right={<I.ChevronDown size={20} color={RP.textMuted}/>}
        />

        {/* Expanded QR */}
        <div style={{
          marginTop: 4, padding: 20, background: '#fff', border: `2px solid ${RP.primary}`,
          borderRadius: RP.rCard, display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 12,
        }}>
          <QrPlaceholder size={180}/>
          <div style={{ fontSize: 12, color: RP.textMuted, textAlign: 'center' }}>
            Aponte a câmera para o código
          </div>
        </div>
      </div>
    </Phone>
  );
}

function ShareCard({ icon, title, sub, right }) {
  return (
    <div style={{
      background: '#fff', border: `1px solid ${RP.border}`, borderRadius: RP.rCard,
      padding: 14, display: 'flex', alignItems: 'center', gap: 12, boxShadow: RP.cardShadow,
    }}>
      {icon}
      <div style={{ flex: 1, minWidth: 0 }}>
        <div style={{ fontSize: 15, fontWeight: 600, color: RP.text }}>{title}</div>
        <div style={{ fontSize: 12, color: RP.textMuted, marginTop: 2, whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis' }}>{sub}</div>
      </div>
      {right}
    </div>
  );
}

Object.assign(window, {
  ScreenOCR, ScreenOptimize, ScreenStopDetail, ScreenPaywall, ScreenSettings, ScreenShare,
  ActionBtn, RowItem, ShareCard,
});
