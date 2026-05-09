// Screens 1-6: Login, Register, Home Empty, Home List, Add Stop, Voice Input

// ─── Screen 1: Login ─────────────────────────────────────
function ScreenLogin({ goto }) {
  const [email, setEmail] = useState('');
  const [pwd, setPwd] = useState('');
  const [showPwd, setShowPwd] = useState(false);
  return (
    <Phone>
      <div style={{ flex: 1, padding: '32px 24px', display: 'flex', flexDirection: 'column', overflowY: 'auto' }}>
        <div style={{ marginTop: 40, display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 16 }}>
          <Logo size={72}/>
          <div style={{ textAlign: 'center' }}>
            <div style={{ fontSize: 26, fontWeight: 600, letterSpacing: -0.4 }}>Roteirizador Pro</div>
            <div style={{ fontSize: 14, color: RP.textMuted, marginTop: 6, fontWeight: 400 }}>
              Entregue mais. Chegue em casa cedo.
            </div>
          </div>
        </div>

        <div style={{ marginTop: 56, display: 'flex', flexDirection: 'column', gap: 14 }}>
          <Input label="E-mail" value={email} onChange={setEmail} type="email" placeholder="seu@email.com"/>
          <Input label="Senha" value={pwd} onChange={setPwd} type={showPwd ? 'text' : 'password'} placeholder="••••••••"
            suffix={
              <button onClick={() => setShowPwd(!showPwd)} style={{ border: 'none', background: 'transparent', color: RP.textMuted, cursor: 'pointer', padding: 4 }}>
                {showPwd ? <I.EyeOff size={20}/> : <I.Eye size={20}/>}
              </button>
            }/>
          <div style={{ textAlign: 'right', marginTop: -2 }}>
            <span style={{ fontSize: 13, color: RP.primary, fontWeight: 500 }}>Esqueci minha senha</span>
          </div>
        </div>

        <div style={{ marginTop: 24 }}>
          <PrimaryButton onClick={() => goto && goto('home-list')}>Entrar</PrimaryButton>
        </div>

        <div style={{ display: 'flex', alignItems: 'center', gap: 12, margin: '24px 0' }}>
          <div style={{ flex: 1, height: 1, background: RP.border }}/>
          <span style={{ fontSize: 12, color: RP.textMuted, fontWeight: 500 }}>ou</span>
          <div style={{ flex: 1, height: 1, background: RP.border }}/>
        </div>

        <GhostButton>
          <svg width="18" height="18" viewBox="0 0 18 18"><path d="M17.64 9.2a10.34 10.34 0 0 0-.16-1.84H9v3.48h4.84a4.14 4.14 0 0 1-1.79 2.71v2.26h2.9a8.78 8.78 0 0 0 2.69-6.61z" fill="#4285F4"/><path d="M9 18a8.59 8.59 0 0 0 5.95-2.18l-2.9-2.26a5.39 5.39 0 0 1-8.05-2.83H.96v2.33A9 9 0 0 0 9 18z" fill="#34A853"/><path d="M3.95 10.71a5.41 5.41 0 0 1 0-3.42V4.96H.96a9 9 0 0 0 0 8.07l2.99-2.32z" fill="#FBBC05"/><path d="M9 3.58a4.86 4.86 0 0 1 3.44 1.34l2.58-2.58A8.65 8.65 0 0 0 9 0a9 9 0 0 0-8.04 4.96l2.99 2.32A5.39 5.39 0 0 1 9 3.58z" fill="#EA4335"/></svg>
          Continuar com Google
        </GhostButton>

        <div style={{ flex: 1 }}/>
        <div style={{ textAlign: 'center', fontSize: 14, color: RP.textMuted, paddingTop: 24, paddingBottom: 8 }}>
          Não tem conta? <span onClick={() => goto && goto('register')} style={{ color: RP.primary, fontWeight: 600, cursor: 'pointer' }}>Cadastre-se</span>
        </div>
      </div>
    </Phone>
  );
}

// ─── Screen 2: Register ──────────────────────────────────
function ScreenRegister({ goto }) {
  const [v, setV] = useState({ name: '', email: '', phone: '', pwd: '' });
  const upd = (k) => (val) => setV({ ...v, [k]: val });
  return (
    <Phone>
      <TopBar title="Criar conta" onBack={() => goto && goto('login')}/>
      <div style={{ flex: 1, padding: '8px 24px 24px', display: 'flex', flexDirection: 'column', overflowY: 'auto' }}>
        <div style={{ fontSize: 14, color: RP.textMuted, marginBottom: 24 }}>
          Comece a otimizar suas rotas em menos de 1 minuto.
        </div>
        <div style={{ display: 'flex', flexDirection: 'column', gap: 14 }}>
          <Input label="Nome completo" value={v.name} onChange={upd('name')} placeholder="João Silva"/>
          <Input label="E-mail" value={v.email} onChange={upd('email')} type="email" placeholder="seu@email.com"/>
          <Input label="Telefone" value={v.phone} onChange={upd('phone')} prefix="+55" placeholder="11 99999-0000"/>
          <Input label="Senha" value={v.pwd} onChange={upd('pwd')} type="password" placeholder="Mínimo 8 caracteres"/>
        </div>
        <div style={{ marginTop: 24 }}>
          <PrimaryButton onClick={() => goto && goto('home-empty')}>Criar conta</PrimaryButton>
        </div>
        <div style={{ fontSize: 12, color: RP.textMuted, textAlign: 'center', marginTop: 16, lineHeight: 1.5 }}>
          Ao criar conta você aceita nossos<br/>
          <span style={{ color: RP.primary, fontWeight: 500 }}>Termos</span> e <span style={{ color: RP.primary, fontWeight: 500 }}>Política de privacidade</span>.
        </div>
        <div style={{ flex: 1 }}/>
        <div style={{ textAlign: 'center', fontSize: 14, color: RP.textMuted, paddingTop: 24 }}>
          Já tem conta? <span onClick={() => goto && goto('login')} style={{ color: RP.primary, fontWeight: 600, cursor: 'pointer' }}>Entrar</span>
        </div>
      </div>
    </Phone>
  );
}

// ─── Top Bar ─────────────────────────────────────────────
function TopBar({ title, onBack, right }) {
  return (
    <div style={{
      height: 56, padding: '0 8px 0 4px', display: 'flex', alignItems: 'center',
      gap: 4, flexShrink: 0, background: '#fff',
    }}>
      {onBack !== undefined ? (
        <button onClick={onBack} style={{
          width: 44, height: 44, border: 'none', background: 'transparent',
          display: 'flex', alignItems: 'center', justifyContent: 'center',
          borderRadius: 22, cursor: 'pointer', color: RP.text,
        }}><I.ArrowLeft size={22}/></button>
      ) : <div style={{ width: 16 }}/>}
      <div style={{ flex: 1, fontSize: 18, fontWeight: 600, color: RP.text, paddingLeft: 4 }}>{title}</div>
      {right}
    </div>
  );
}

// ─── Empty Illustration ──────────────────────────────────
function EmptyIllustration() {
  return (
    <svg width="180" height="140" viewBox="0 0 180 140" fill="none">
      <ellipse cx="90" cy="125" rx="70" ry="6" fill={RP.primaryLight}/>
      {/* Dashed route */}
      <path d="M 30 90 Q 60 50 90 70 T 150 50" stroke={RP.accent} strokeWidth="2.5" strokeDasharray="4 6" strokeLinecap="round" fill="none"/>
      <circle cx="30" cy="90" r="6" fill={RP.primary}/>
      <circle cx="150" cy="50" r="6" fill={RP.primary}/>
      {/* Bike */}
      <g transform="translate(70 75)">
        <circle cx="10" cy="32" r="10" stroke={RP.primary} strokeWidth="2.5" fill="#fff"/>
        <circle cx="40" cy="32" r="10" stroke={RP.primary} strokeWidth="2.5" fill="#fff"/>
        <path d="M 10 32 L 22 12 L 32 12 L 40 32" stroke={RP.primary} strokeWidth="2.5" strokeLinejoin="round" fill="none"/>
        <path d="M 22 12 L 28 32" stroke={RP.primary} strokeWidth="2.5"/>
        <rect x="30" y="2" width="14" height="12" rx="2" fill={RP.accent}/>
      </g>
    </svg>
  );
}

// ─── Screen 3: Home Empty ────────────────────────────────
function ScreenHomeEmpty({ goto }) {
  return (
    <Phone>
      <HomeTopBar eta={null} count={0}/>
      <div style={{ flex: 1, display: 'flex', flexDirection: 'column', alignItems: 'center', justifyContent: 'center', padding: 24, position: 'relative' }}>
        <EmptyIllustration/>
        <div style={{ fontSize: 20, fontWeight: 600, marginTop: 24 }}>Nenhuma entrega ainda</div>
        <div style={{ fontSize: 14, color: RP.textMuted, marginTop: 8, textAlign: 'center', lineHeight: 1.5, maxWidth: 280 }}>
          Adicione sua primeira parada para começar a planejar a rota.
        </div>
        <div style={{ marginTop: 28 }}>
          <button onClick={() => goto && goto('add-stop')} style={{
            display: 'inline-flex', alignItems: 'center', gap: 6, height: 40, padding: '0 16px',
            background: RP.primaryLight, color: RP.primary, border: 'none', borderRadius: 20,
            fontFamily: RP.font, fontWeight: 600, fontSize: 13, cursor: 'pointer',
          }}>
            <I.Sparkle size={16}/> Como funciona?
          </button>
        </div>
      </div>
      <FAB onClick={() => goto && goto('add-stop')}/>
      <BottomNav active="route"/>
    </Phone>
  );
}

// ─── Home Top Bar ────────────────────────────────────────
function HomeTopBar({ eta, count, showMore }) {
  return (
    <div style={{
      padding: '8px 16px 12px', display: 'flex', alignItems: 'center', gap: 8,
      background: '#fff', flexShrink: 0,
    }}>
      <div style={{ flex: 1, fontSize: 22, fontWeight: 600, letterSpacing: -0.3 }}>Rota de hoje</div>
      <div style={{
        display: 'inline-flex', alignItems: 'center', gap: 4,
        height: 30, padding: '0 10px',
        background: eta ? RP.primaryLight : '#F1EFF7',
        color: eta ? RP.primary : '#A09DB0',
        borderRadius: 999, fontSize: 12, fontWeight: 600,
      }}>
        <I.Clock size={14}/> {eta || '--:--'}
      </div>
      <div style={{
        display: 'inline-flex', alignItems: 'center', gap: 4,
        height: 30, padding: '0 10px',
        background: RP.surface, border: `1px solid ${RP.border}`,
        color: RP.textMuted, borderRadius: 999, fontSize: 12, fontWeight: 600,
      }}>
        <I.MapPin size={14}/> {count}
      </div>
      {showMore && (
        <button style={{
          width: 36, height: 36, border: 'none', background: 'transparent',
          display: 'flex', alignItems: 'center', justifyContent: 'center', cursor: 'pointer',
          color: RP.text, borderRadius: 18,
        }}><I.MoreVertical size={20}/></button>
      )}
    </div>
  );
}

// ─── Stop Card ───────────────────────────────────────────
const SAMPLE_STOPS = [
  { n: 1, a1: 'Rua Augusta, 1234', a2: 'Apto 502 · Consolação, São Paulo', s: 'delivered' },
  { n: 2, a1: 'Av. Paulista, 2200', a2: 'Loja 14 · Bela Vista, São Paulo', s: 'delivered' },
  { n: 3, a1: 'R. Oscar Freire, 875', a2: 'Apto 1201 · Jardins, São Paulo', s: 'pending', swiped: true },
  { n: 4, a1: 'Al. Santos, 456', a2: 'Bloco B · Cerqueira César, São Paulo', s: 'pending' },
  { n: 5, a1: 'R. Haddock Lobo, 1500', a2: 'Casa · Cerqueira César, São Paulo', s: 'pending' },
  { n: 6, a1: 'Av. Rebouças, 3970', a2: 'Sala 302 · Pinheiros, São Paulo', s: 'pending' },
];

function StopCard({ stop, onClick, faded }) {
  const badge = {
    pending: <Badge variant="warning">Pendente</Badge>,
    delivered: <Badge variant="success">Entregue</Badge>,
    failed: <Badge variant="error">Falhou</Badge>,
  }[stop.s];
  return (
    <div style={{ position: 'relative' }}>
      {stop.swiped && (
        <div style={{
          position: 'absolute', right: 0, top: 0, bottom: 0, width: 96,
          background: RP.error, borderRadius: RP.rCard,
          display: 'flex', alignItems: 'center', justifyContent: 'center', gap: 6,
          color: '#fff', fontWeight: 600, fontSize: 13,
        }}>
          <I.Trash size={18}/> Excluir
        </div>
      )}
      <div onClick={onClick} style={{
        background: '#fff', border: `1px solid ${RP.border}`, borderRadius: RP.rCard,
        padding: 14, display: 'flex', alignItems: 'center', gap: 12,
        boxShadow: RP.cardShadow, cursor: onClick ? 'pointer' : 'default',
        opacity: faded ? 0.55 : 1,
        transform: stop.swiped ? 'translateX(-72px)' : 'none',
        transition: 'transform .2s',
      }}>
        <div style={{
          width: 32, height: 32, flexShrink: 0, borderRadius: '50%',
          background: stop.s === 'delivered' ? RP.success : stop.s === 'failed' ? RP.error : RP.primary,
          color: '#fff', fontSize: 14, fontWeight: 600,
          display: 'flex', alignItems: 'center', justifyContent: 'center',
        }}>
          {stop.s === 'delivered' ? <I.Check size={16} stroke={2.5}/> : stop.n}
        </div>
        <div style={{ flex: 1, minWidth: 0 }}>
          <div style={{ fontSize: 14, fontWeight: 600, color: RP.text, whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis' }}>
            {stop.a1}
          </div>
          <div style={{ fontSize: 12, color: RP.textMuted, marginTop: 2, whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis' }}>
            {stop.a2}
          </div>
        </div>
        <div style={{ display: 'flex', flexDirection: 'column', alignItems: 'flex-end', gap: 6 }}>
          {badge}
          <div style={{ color: '#C8C5D6' }}><I.GripVertical size={18}/></div>
        </div>
      </div>
    </div>
  );
}

// ─── Screen 4: Home with Stops ───────────────────────────
function ScreenHomeList({ goto }) {
  return (
    <Phone>
      <HomeTopBar eta="~14:30" count={47} showMore/>
      <div style={{ flex: 1, padding: '4px 16px 8px', overflowY: 'auto', display: 'flex', flexDirection: 'column', gap: 8 }}>
        {SAMPLE_STOPS.map((s) => (
          <StopCard key={s.n} stop={s} faded={s.s === 'delivered'} onClick={() => goto && goto('stop-detail')}/>
        ))}
        <div style={{ height: 8 }}/>
      </div>
      <div style={{ padding: '8px 16px 12px', background: '#fff', flexShrink: 0 }}>
        <PrimaryButton icon={<I.Sparkle size={18}/>} neon onClick={() => goto && goto('map-stops')}>
          Otimizar rota
        </PrimaryButton>
      </div>
      <FAB onClick={() => goto && goto('add-stop')}/>
      <BottomNav active="route"/>
    </Phone>
  );
}

// ─── Screen 5: Add Stop bottom sheet ─────────────────────
function ScreenAddStop({ goto }) {
  const [method, setMethod] = useState('keyboard');
  const results = [
    'Rua Haddock Lobo, 1500 · São Paulo',
    'Rua Haddock Lobo, 150 · São Paulo',
    'Av. Henrique Lobo, 200 · São Paulo',
    'Rua Hadid Lobo, 15 · Guarulhos',
  ];
  return (
    <Phone>
      {/* Background dimmed home */}
      <div style={{ flex: 1, background: '#fff', position: 'relative', overflow: 'hidden' }}>
        <div style={{ filter: 'blur(2px)', opacity: 0.4 }}>
          <HomeTopBar eta="~14:30" count={47} showMore/>
          <div style={{ padding: '4px 16px', display: 'flex', flexDirection: 'column', gap: 8 }}>
            {SAMPLE_STOPS.slice(0, 3).map((s) => <StopCard key={s.n} stop={s}/>)}
          </div>
        </div>
        <div style={{ position: 'absolute', inset: 0, background: 'rgba(26,26,46,0.4)' }}/>
        {/* Sheet */}
        <div style={{
          position: 'absolute', left: 0, right: 0, bottom: 0,
          background: '#fff', borderTopLeftRadius: RP.rSheet, borderTopRightRadius: RP.rSheet,
          padding: '12px 24px 24px', boxShadow: RP.sheetShadow,
          display: 'flex', flexDirection: 'column', gap: 16,
        }}>
          <div style={{ display: 'flex', justifyContent: 'center' }}>
            <div style={{ width: 40, height: 4, borderRadius: 2, background: RP.border }}/>
          </div>
          <div style={{ fontSize: 18, fontWeight: 600 }}>Adicionar parada</div>
          <Input
            value="Haddock"
            onChange={() => {}}
            placeholder="Digite o endereço ou CEP..."
            focused
            prefix={<I.Search size={20} color={RP.textMuted}/>}
          />
          <div style={{ display: 'flex', gap: 8 }}>
            {[
              { id: 'keyboard', label: 'Teclado', icon: I.Keyboard },
              { id: 'voice', label: 'Voz', icon: I.Mic },
              { id: 'camera', label: 'Câmera', icon: I.Camera },
            ].map(opt => {
              const sel = method === opt.id;
              const Ic = opt.icon;
              return (
                <button key={opt.id}
                  onClick={() => {
                    setMethod(opt.id);
                    if (opt.id === 'voice') setTimeout(() => goto && goto('voice'), 200);
                    if (opt.id === 'camera') setTimeout(() => goto && goto('ocr'), 200);
                  }}
                  style={{
                    flex: 1, height: 56, borderRadius: 14, cursor: 'pointer',
                    background: sel ? RP.primaryLight : RP.surface,
                    border: `1.5px solid ${sel ? RP.primary : 'transparent'}`,
                    color: sel ? RP.primary : RP.textMuted,
                    fontFamily: RP.font, fontWeight: 600, fontSize: 12,
                    display: 'flex', flexDirection: 'column', alignItems: 'center', justifyContent: 'center', gap: 4,
                  }}>
                  <Ic size={20} stroke={sel ? 2 : 1.5}/>
                  {opt.label}
                </button>
              );
            })}
          </div>
          <div style={{ display: 'flex', flexDirection: 'column', borderRadius: 12, overflow: 'hidden', border: `1px solid ${RP.border}` }}>
            {results.map((r, i) => (
              <div key={i} style={{
                padding: '12px 14px', display: 'flex', alignItems: 'center', gap: 12,
                background: i === 0 ? RP.primaryLight : '#fff',
                borderBottom: i < results.length - 1 ? `1px solid ${RP.border}` : 'none',
              }}>
                <I.MapPin size={18} color={i === 0 ? RP.primary : RP.textMuted}/>
                <div style={{ fontSize: 13, color: i === 0 ? RP.primary : RP.text, fontWeight: i === 0 ? 600 : 400, flex: 1, whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis' }}>
                  {r}
                </div>
              </div>
            ))}
          </div>
          <PrimaryButton onClick={() => goto && goto('home-list')}>Adicionar parada</PrimaryButton>
        </div>
      </div>
    </Phone>
  );
}

// ─── Screen 6: Voice Input ───────────────────────────────
function ScreenVoice({ goto }) {
  return (
    <Phone>
      <TopBar title="Falar endereço" onBack={() => goto && goto('add-stop')}/>
      <div style={{ flex: 1, padding: 24, display: 'flex', flexDirection: 'column', alignItems: 'center' }}>
        <div style={{ flex: 1 }}/>
        <div style={{ position: 'relative', width: 200, height: 200, display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
          {/* Pulse rings */}
          <div style={{ position: 'absolute', inset: 0, borderRadius: '50%', background: RP.primaryLight, opacity: 0.4, animation: 'rpPulse 2s ease-out infinite' }}/>
          <div style={{ position: 'absolute', inset: 20, borderRadius: '50%', background: RP.primaryLight, opacity: 0.6, animation: 'rpPulse 2s ease-out 0.5s infinite' }}/>
          <div style={{ position: 'absolute', inset: 40, borderRadius: '50%', background: RP.primaryLight, opacity: 0.8 }}/>
          <div style={{
            position: 'relative', width: 100, height: 100, borderRadius: '50%',
            background: `linear-gradient(135deg, ${RP.accent} 0%, ${RP.primary} 100%)`,
            display: 'flex', alignItems: 'center', justifyContent: 'center',
            boxShadow: '0 12px 32px rgba(108,63,197,0.4)', color: '#fff',
          }}>
            <I.Mic size={42}/>
          </div>
        </div>
        <div style={{ fontSize: 15, color: RP.textMuted, marginTop: 24, fontWeight: 500 }}>Ouvindo...</div>
        <div style={{
          marginTop: 32, width: '100%', minHeight: 80, background: RP.surface,
          border: `1px solid ${RP.border}`, borderRadius: RP.rInput, padding: 16,
          fontSize: 15, color: RP.textMuted, fontStyle: 'italic', lineHeight: 1.5,
        }}>
          "Rua Haddock Lobo mil e quinhentos, apartamento doze zero um..."
        </div>
        <div style={{ flex: 1 }}/>
        <div style={{ display: 'flex', gap: 12, width: '100%' }}>
          <GhostButton onClick={() => goto && goto('home-list')}>
            <I.Square size={16}/> Parar
          </GhostButton>
          <button style={{
            flex: 1, height: 52, border: 'none', background: 'transparent',
            color: RP.primary, fontFamily: RP.font, fontWeight: 600, fontSize: 15,
            display: 'flex', alignItems: 'center', justifyContent: 'center', gap: 8, cursor: 'pointer',
          }}>
            <I.RefreshCw size={18}/> Tentar novamente
          </button>
        </div>
      </div>
    </Phone>
  );
}

Object.assign(window, {
  ScreenLogin, ScreenRegister, ScreenHomeEmpty, ScreenHomeList,
  ScreenAddStop, ScreenVoice, TopBar, HomeTopBar, StopCard, SAMPLE_STOPS,
});
