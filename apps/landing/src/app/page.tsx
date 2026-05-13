import Image from 'next/image';

import { LiveCounter } from '@/components/landing/LiveCounter';

const APK_URL = '/roteirizador-pro-v1.0.0.apk';
const APK_FILENAME = 'roteirizador-pro-v1.0.0.apk';

export default function HomePage() {
  return (
    <>
      {/* ───── NAV ───── */}
      <nav className="top">
        <div className="wrap row">
          <div className="logo">
            <div className="logo-mark">
              <Image
                src="/logo.png"
                alt="Roteirizador Pro"
                width={36}
                height={36}
                priority
              />
            </div>
            <span>Roteirizador Pro</span>
          </div>
          <div className="links">
            <a href="#features">Recursos</a>
            <a href="#how">Como funciona</a>
            <a href={APK_URL} download={APK_FILENAME}>
              Baixar app
            </a>
          </div>
          <div className="cta">
            <a className="login" href="#">
              Entrar
            </a>
            <a className="download" href={APK_URL} download={APK_FILENAME}>
              <svg
                width="14"
                height="14"
                viewBox="0 0 24 24"
                fill="none"
                stroke="currentColor"
                strokeWidth="2.4"
                strokeLinecap="round"
                strokeLinejoin="round"
                aria-hidden="true"
              >
                <path d="M21 15v4a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2v-4" />
                <polyline points="7 10 12 15 17 10" />
                <line x1="12" y1="15" x2="12" y2="3" />
              </svg>
              Baixar app
            </a>
          </div>
        </div>
      </nav>

      {/* ───── HERO ───── */}
      <section className="hero">
        <div className="wrap grid">
          <div>
            <LiveCounter />
            <h1>
              Faça o <span className="hl">dobro de entregas</span> no mesmo
              tempo.
            </h1>
            <p className="lede">
              O app de rota inteligente para motoboys e entregadores
              brasileiros. Adicione paradas por voz, foto ou mapa e otimize sua
              rota em segundos. Sem mensalidade fixa.
            </p>
            <div className="ctas">
              <a
                className="btn-primary"
                href={APK_URL}
                download={APK_FILENAME}
              >
                Baixar app
                <span className="neon-dot"></span>
              </a>
            </div>
            <div className="trust">
              <span className="stars">★★★★★</span>
              <strong>4,9+</strong>
              <span className="sep"></span>
              <span>Pix · pague só quando rodar</span>
            </div>
          </div>

          <div className="phone-stack">
            {/* Floating chip top-left */}
            <div className="float-chip eta">
              <div
                className="icon-wrap"
                style={{ background: 'var(--neon)' }}
              >
                <svg
                  width="20"
                  height="20"
                  viewBox="0 0 24 24"
                  fill="none"
                  stroke="#3D5400"
                  strokeWidth="2"
                  strokeLinecap="round"
                  strokeLinejoin="round"
                  aria-hidden="true"
                >
                  <polyline points="3 11 22 2 13 21 11 13 3 11" />
                </svg>
              </div>
              <div>
                <div className="label">Próxima parada</div>
                <div className="value">2,4 km · 8 min</div>
              </div>
            </div>

            {/* Phone 1 — list view */}
            <div className="phone phone-1">
              <div className="notch"></div>
              <div
                style={{
                  padding: '38px 16px 16px',
                  height: '100%',
                  display: 'flex',
                  flexDirection: 'column',
                  gap: 10,
                  background: '#fff',
                }}
              >
                <div
                  style={{
                    display: 'flex',
                    alignItems: 'center',
                    gap: 10,
                    marginTop: 4,
                  }}
                >
                  <div style={{ flex: 1 }}>
                    <div
                      style={{
                        fontSize: 11,
                        color: 'var(--text-muted)',
                        fontWeight: 600,
                      }}
                    >
                      ROTA DE HOJE
                    </div>
                    <div style={{ fontSize: 18, fontWeight: 700 }}>
                      27 paradas
                    </div>
                  </div>
                  <div
                    style={{
                      background: 'var(--neon)',
                      color: 'var(--neon-ink)',
                      padding: '6px 10px',
                      borderRadius: 12,
                      fontSize: 11,
                      fontWeight: 700,
                    }}
                  >
                    −1h 24min
                  </div>
                </div>
                <div
                  style={{
                    height: 80,
                    background: 'var(--surface)',
                    borderRadius: 12,
                    padding: '10px 12px',
                    display: 'flex',
                    alignItems: 'center',
                    gap: 10,
                  }}
                >
                  <div
                    style={{
                      width: 28,
                      height: 28,
                      borderRadius: '50%',
                      background: 'var(--primary)',
                      color: '#fff',
                      display: 'flex',
                      alignItems: 'center',
                      justifyContent: 'center',
                      fontWeight: 700,
                      fontSize: 12,
                    }}
                  >
                    1
                  </div>
                  <div style={{ flex: 1, minWidth: 0 }}>
                    <div
                      style={{
                        fontSize: 13,
                        fontWeight: 600,
                        whiteSpace: 'nowrap',
                        overflow: 'hidden',
                        textOverflow: 'ellipsis',
                      }}
                    >
                      R. Joaquim Floriano, 834
                    </div>
                    <div
                      style={{ fontSize: 11, color: 'var(--text-muted)' }}
                    >
                      São Paulo · 09:24
                    </div>
                  </div>
                </div>
                <div
                  style={{
                    height: 60,
                    background: 'var(--surface)',
                    borderRadius: 12,
                    padding: '10px 12px',
                    display: 'flex',
                    alignItems: 'center',
                    gap: 10,
                  }}
                >
                  <div
                    style={{
                      width: 28,
                      height: 28,
                      borderRadius: '50%',
                      background: '#fff',
                      border: '1.5px solid var(--primary)',
                      color: 'var(--primary)',
                      display: 'flex',
                      alignItems: 'center',
                      justifyContent: 'center',
                      fontWeight: 700,
                      fontSize: 12,
                    }}
                  >
                    2
                  </div>
                  <div style={{ flex: 1, minWidth: 0 }}>
                    <div style={{ fontSize: 13, fontWeight: 600 }}>
                      R. Oscar Freire, 875
                    </div>
                  </div>
                </div>
                <div
                  style={{
                    height: 60,
                    background: 'var(--surface)',
                    borderRadius: 12,
                    padding: '10px 12px',
                    display: 'flex',
                    alignItems: 'center',
                    gap: 10,
                  }}
                >
                  <div
                    style={{
                      width: 28,
                      height: 28,
                      borderRadius: '50%',
                      background: '#fff',
                      border: '1.5px solid var(--primary)',
                      color: 'var(--primary)',
                      display: 'flex',
                      alignItems: 'center',
                      justifyContent: 'center',
                      fontWeight: 700,
                      fontSize: 12,
                    }}
                  >
                    3
                  </div>
                  <div style={{ flex: 1, minWidth: 0 }}>
                    <div style={{ fontSize: 13, fontWeight: 600 }}>
                      Av. Brigadeiro, 2200
                    </div>
                  </div>
                </div>
                <div
                  style={{
                    marginTop: 'auto',
                    height: 48,
                    background: 'var(--primary)',
                    color: '#fff',
                    borderRadius: 24,
                    display: 'flex',
                    alignItems: 'center',
                    justifyContent: 'center',
                    gap: 6,
                    fontWeight: 600,
                    fontSize: 14,
                    boxShadow: '0 6px 18px rgba(108,63,197,0.3)',
                    position: 'relative',
                  }}
                >
                  <svg
                    width="16"
                    height="16"
                    viewBox="0 0 24 24"
                    fill="none"
                    stroke="currentColor"
                    strokeWidth="2"
                    strokeLinecap="round"
                    strokeLinejoin="round"
                    aria-hidden="true"
                  >
                    <polygon points="3 11 22 2 13 21 11 13 3 11" />
                  </svg>
                  Iniciar navegação
                  <span
                    style={{
                      position: 'absolute',
                      right: 14,
                      width: 7,
                      height: 7,
                      borderRadius: '50%',
                      background: 'var(--neon)',
                      boxShadow: '0 0 6px var(--neon)',
                    }}
                  ></span>
                </div>
              </div>
            </div>

            {/* Phone 2 — map view */}
            <div className="phone phone-2">
              <div className="notch"></div>
              <div className="map-bg" style={{ paddingTop: 32 }}>
                <svg
                  viewBox="0 0 280 580"
                  preserveAspectRatio="xMidYMid slice"
                  aria-hidden="true"
                >
                  <rect width="280" height="580" fill="#EAEDF2" />
                  <rect x="10" y="40" width="60" height="50" rx="3" fill="#DCE0E8" />
                  <rect x="80" y="30" width="80" height="50" rx="3" fill="#DCE0E8" />
                  <rect x="170" y="40" width="100" height="60" rx="3" fill="#DCE0E8" />
                  <rect x="20" y="120" width="60" height="80" rx="3" fill="#DCE0E8" />
                  <rect x="90" y="120" width="80" height="60" rx="3" fill="#DCE0E8" />
                  <rect x="180" y="130" width="80" height="80" rx="3" fill="#DCE0E8" />
                  <rect x="20" y="240" width="60" height="60" rx="3" fill="#DCE0E8" />
                  <rect x="90" y="220" width="80" height="80" rx="3" fill="#DCE0E8" />
                  <rect x="180" y="240" width="80" height="60" rx="3" fill="#DCE0E8" />
                  <rect x="20" y="340" width="60" height="80" rx="3" fill="#DCE0E8" />
                  <rect x="90" y="340" width="80" height="60" rx="3" fill="#DCE0E8" />
                  <rect x="180" y="340" width="80" height="80" rx="3" fill="#DCE0E8" />
                  <rect x="20" y="450" width="60" height="60" rx="3" fill="#DCE0E8" />
                  <rect x="90" y="430" width="80" height="80" rx="3" fill="#DCE0E8" />
                  <rect x="180" y="440" width="80" height="80" rx="3" fill="#DCE0E8" />
                  <path d="M 0 110 L 280 110" stroke="#fff" strokeWidth="10" />
                  <path d="M 0 215 L 280 215" stroke="#fff" strokeWidth="10" />
                  <path d="M 0 320 L 280 320" stroke="#fff" strokeWidth="12" />
                  <path d="M 0 425 L 280 425" stroke="#fff" strokeWidth="10" />
                  <path d="M 0 530 L 280 530" stroke="#fff" strokeWidth="10" />
                  <path d="M 80 0 L 80 580" stroke="#fff" strokeWidth="10" />
                  <path d="M 170 0 L 170 580" stroke="#fff" strokeWidth="10" />
                  <path
                    d="M 60 480 Q 80 400 130 360 Q 170 280 60 220 Q 100 160 220 130 Q 230 80 130 50"
                    stroke="#6C3FC5"
                    strokeWidth="5"
                    fill="none"
                    strokeLinecap="round"
                    strokeLinejoin="round"
                  />
                  <path
                    d="M 130 360 Q 170 280 60 220"
                    stroke="#C6FF3D"
                    strokeWidth="5"
                    fill="none"
                    strokeLinecap="round"
                    strokeDasharray="2 6"
                    style={{
                      filter: 'drop-shadow(0 0 6px rgba(198,255,61,0.8))',
                    }}
                  />
                  <g transform="translate(60, 480)">
                    <circle r="14" fill="rgba(34,197,94,0.18)" />
                    <circle r="10" fill="#22C55E" stroke="#fff" strokeWidth="2" />
                    <text y="3" textAnchor="middle" fill="#fff" fontSize="9" fontWeight="700" fontFamily="Poppins">
                      1
                    </text>
                  </g>
                  <g transform="translate(220, 130)">
                    <circle r="14" fill="rgba(34,197,94,0.18)" />
                    <circle r="10" fill="#22C55E" stroke="#fff" strokeWidth="2" />
                    <text y="3" textAnchor="middle" fill="#fff" fontSize="9" fontWeight="700" fontFamily="Poppins">
                      2
                    </text>
                  </g>
                  <g transform="translate(60, 220)">
                    <circle r="22" fill="rgba(198,255,61,0.35)">
                      <animate attributeName="r" values="14;26;14" dur="2s" repeatCount="indefinite" />
                      <animate attributeName="opacity" values="0.6;0;0.6" dur="2s" repeatCount="indefinite" />
                    </circle>
                    <circle r="12" fill="#C6FF3D" stroke="#fff" strokeWidth="2" />
                    <text y="4" textAnchor="middle" fill="#3D5400" fontSize="10" fontWeight="700" fontFamily="Poppins">
                      3
                    </text>
                  </g>
                  <g transform="translate(130, 360)">
                    <circle r="10" fill="#6C3FC5" stroke="#fff" strokeWidth="2" />
                    <text y="3" textAnchor="middle" fill="#fff" fontSize="9" fontWeight="700" fontFamily="Poppins">
                      4
                    </text>
                  </g>
                  <g transform="translate(130, 50)">
                    <circle r="10" fill="#6C3FC5" stroke="#fff" strokeWidth="2" />
                    <text y="3" textAnchor="middle" fill="#fff" fontSize="9" fontWeight="700" fontFamily="Poppins">
                      5
                    </text>
                  </g>
                </svg>
              </div>
            </div>

            {/* Floating chip bottom-right */}
            <div className="float-chip saved">
              <div
                className="icon-wrap"
                style={{ background: 'rgba(198,255,61,0.15)' }}
              >
                <svg
                  width="20"
                  height="20"
                  viewBox="0 0 24 24"
                  fill="#C6FF3D"
                  stroke="none"
                  aria-hidden="true"
                >
                  <path d="M12 3l2 5 5 2-5 2-2 5-2-5-5-2 5-2z" />
                </svg>
              </div>
              <div>
                <div className="label">Você economizou</div>
                <div className="value">1h 24min · 35 km</div>
              </div>
            </div>
          </div>
        </div>
      </section>

      {/* ───── LOGOS BAR ───── */}
      <div className="logos-bar">
        <div className="wrap row">
          <span className="label">Usado por entregadores de</span>
          <div className="marks">
            <span>iFood</span>
            <span>Loggi</span>
            <span>RAPPI</span>
            <span>99Food</span>
            <span>shopee</span>
            <span>MagaLu</span>
          </div>
        </div>
      </div>

      {/* ───── STATS ───── */}
      <section style={{ padding: '64px 0' }}>
        <div className="wrap">
          <div className="stats">
            <div className="grid">
              <div>
                <div className="num">+50k</div>
                <div className="lbl">motoboys ativos</div>
              </div>
              <div>
                <div className="num">+8M</div>
                <div className="lbl">paradas otimizadas</div>
              </div>
              <div>
                <div className="num">37%</div>
                <div className="lbl">menos tempo na rua</div>
              </div>
              <div>
                <div className="num">4,9★</div>
                <div className="lbl">na Google Play</div>
              </div>
            </div>
          </div>
        </div>
      </section>

      {/* ───── HOW IT WORKS ───── */}
      <section id="how" className="how-section">
        <div className="wrap">
          <div className="sec-head">
            <span className="pill">
              <span className="dot"></span>
              Como funciona
            </span>
            <h2>
              Da lista de paradas à entrega em{' '}
              <span style={{ color: 'var(--primary)' }}>3 passos</span>
            </h2>
            <p>
              Sem planilha, sem digitar endereço a endereço. Você cuida das
              entregas, o app cuida da rota.
            </p>
          </div>
          <div className="steps">
            <div className="step">
              <div className="num-circle">1</div>
              <h3>Adicione as paradas</h3>
              <p>
                Fale o endereço, fotografe a etiqueta com a câmera ou toque no
                mapa. Adicione 30 paradas em menos de 2 minutos.
              </p>
            </div>
            <div className="step">
              <div className="num-circle">2</div>
              <h3>Otimize com 1 toque</h3>
              <p>
                Nossa IA calcula a rota mais curta levando em conta trânsito,
                sentido das vias e janelas de horário.
              </p>
            </div>
            <div className="step">
              <div className="num-circle">3</div>
              <h3>Entregue mais rápido</h3>
              <p>
                Navegação turn-by-turn integrada, marcação de entregue/falhou e
                compartilhamento da rota com o despachante.
              </p>
            </div>
          </div>
        </div>
      </section>

      {/* ───── CAPTURE METHODS ───── */}
      <section id="features">
        <div className="wrap">
          <div className="sec-head">
            <span className="pill">
              <span className="dot"></span>
              Captura inteligente
            </span>
            <h2>3 jeitos de adicionar uma parada — escolha o seu</h2>
            <p>Esqueça digitar. Use o que for mais rápido na hora do aperto.</p>
          </div>
          <div className="methods">
            <div className="method big">
              <div>
                <div className="tag">Por voz · mais usado</div>
                <h3>&ldquo;Adicionar Rua Oscar Freire, 875.&rdquo;</h3>
                <p>
                  Fale como se estivesse falando com um amigo. O app entende
                  português brasileiro com gírias e abreviações.
                </p>
              </div>
              <div className="visual">
                <div className="voice-rings">
                  <div className="ring"></div>
                  <div className="ring"></div>
                  <div className="ring"></div>
                  <div className="core">
                    <svg
                      width="28"
                      height="28"
                      viewBox="0 0 24 24"
                      fill="none"
                      stroke="currentColor"
                      strokeWidth="2.2"
                      strokeLinecap="round"
                      strokeLinejoin="round"
                      aria-hidden="true"
                    >
                      <path d="M12 1a3 3 0 0 0-3 3v8a3 3 0 0 0 6 0V4a3 3 0 0 0-3-3z" />
                      <path d="M19 10v2a7 7 0 0 1-14 0v-2" />
                      <line x1="12" y1="19" x2="12" y2="23" />
                      <line x1="8" y1="23" x2="16" y2="23" />
                    </svg>
                  </div>
                </div>
              </div>
            </div>

            <div className="method dark-card">
              <div>
                <div className="tag" style={{ color: 'var(--neon)' }}>
                  Por foto
                </div>
                <h3>Aponte a câmera para a etiqueta</h3>
                <p style={{ color: 'rgba(255,255,255,0.75)' }}>
                  OCR brasileiro reconhece CEP, número e complemento direto da
                  AWB.
                </p>
              </div>
              <div className="visual">
                <div className="ocr-mock">
                  <div className="corners">
                    <span></span>
                  </div>
                  <div className="scan"></div>
                  <div className="text-lines">
                    <span></span>
                    <span></span>
                    <span></span>
                    <span></span>
                  </div>
                </div>
              </div>
            </div>

            <div className="method neon-card">
              <div>
                <div className="tag">Pelo mapa</div>
                <h3>Toque e arraste</h3>
                <p style={{ color: 'rgba(61,84,0,0.85)' }}>
                  Visualize a área da entrega e adicione paradas com um toque
                  no mapa.
                </p>
              </div>
              <div className="visual">
                <div className="map-mini">
                  <svg
                    viewBox="0 0 240 240"
                    style={{ width: '100%', height: '100%' }}
                    aria-hidden="true"
                  >
                    <rect width="240" height="240" fill="#fff" />
                    <rect x="10" y="10" width="50" height="40" rx="3" fill="#EAEDF2" />
                    <rect x="70" y="10" width="80" height="40" rx="3" fill="#EAEDF2" />
                    <rect x="160" y="10" width="70" height="50" rx="3" fill="#EAEDF2" />
                    <rect x="10" y="60" width="50" height="60" rx="3" fill="#EAEDF2" />
                    <rect x="70" y="60" width="80" height="50" rx="3" fill="#EAEDF2" />
                    <rect x="160" y="70" width="70" height="60" rx="3" fill="#EAEDF2" />
                    <rect x="10" y="130" width="50" height="50" rx="3" fill="#EAEDF2" />
                    <rect x="70" y="120" width="80" height="60" rx="3" fill="#EAEDF2" />
                    <rect x="160" y="140" width="70" height="50" rx="3" fill="#EAEDF2" />
                    <rect x="10" y="190" width="50" height="40" rx="3" fill="#EAEDF2" />
                    <rect x="70" y="190" width="80" height="40" rx="3" fill="#EAEDF2" />
                    <rect x="160" y="200" width="70" height="30" rx="3" fill="#EAEDF2" />
                    <g transform="translate(50, 60)">
                      <rect x="-10" y="-10" width="20" height="20" rx="4" fill="#6C3FC5" />
                      <circle r="3" fill="#fff" />
                    </g>
                    <g transform="translate(120, 90)">
                      <rect x="-10" y="-10" width="20" height="20" rx="4" fill="#6C3FC5" />
                      <circle r="3" fill="#fff" />
                    </g>
                    <g transform="translate(180, 130)">
                      <rect x="-10" y="-10" width="20" height="20" rx="4" fill="#1A1A2E" stroke="#3D5400" strokeWidth="2" />
                      <circle r="3" fill="#3D5400" />
                    </g>
                    <g transform="translate(80, 170)">
                      <rect x="-10" y="-10" width="20" height="20" rx="4" fill="#6C3FC5" />
                      <circle r="3" fill="#fff" />
                    </g>
                    <g transform="translate(160, 200)">
                      <rect x="-10" y="-10" width="20" height="20" rx="4" fill="#6C3FC5" />
                      <circle r="3" fill="#fff" />
                    </g>
                  </svg>
                </div>
              </div>
            </div>
          </div>
        </div>
      </section>

      {/* ───── FEATURES GRID ───── */}
      <section style={{ paddingTop: 0 }}>
        <div className="wrap">
          <div className="sec-head">
            <span className="pill">
              <span className="dot"></span>
              Recursos
            </span>
            <h2>Feito para quem entrega de verdade</h2>
            <p>Cada detalhe pensado pra economizar minutos preciosos do seu dia.</p>
          </div>
          <div className="features">
            <div className="feature">
              <div className="icon">
                <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.8" strokeLinecap="round" strokeLinejoin="round" aria-hidden="true">
                  <path d="M12 3l2 5 5 2-5 2-2 5-2-5-5-2 5-2z" />
                </svg>
              </div>
              <h3>Otimização com IA</h3>
              <p>
                Algoritmo de TSP que considera trânsito em tempo real, mãos de
                direção e janelas horárias.
              </p>
            </div>
            <div className="feature accent">
              <div className="icon">
                <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.8" strokeLinecap="round" strokeLinejoin="round" aria-hidden="true">
                  <polygon points="3 11 22 2 13 21 11 13 3 11" />
                </svg>
              </div>
              <h3>Navegação integrada</h3>
              <p>
                Turn-by-turn dentro do app — sem trocar pra Waze ou Google
                Maps a cada parada.
              </p>
            </div>
            <div className="feature">
              <div className="icon">
                <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.8" strokeLinecap="round" strokeLinejoin="round" aria-hidden="true">
                  <circle cx="18" cy="5" r="3" />
                  <circle cx="6" cy="12" r="3" />
                  <circle cx="18" cy="19" r="3" />
                  <line x1="8.59" y1="13.51" x2="15.42" y2="17.49" />
                  <line x1="15.41" y1="6.51" x2="8.59" y2="10.49" />
                </svg>
              </div>
              <h3>Compartilhe a rota</h3>
              <p>
                Mande pro despachante por WhatsApp em 1 toque. Ele acompanha em
                tempo real.
              </p>
            </div>
            <div className="feature">
              <div className="icon">
                <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.8" strokeLinecap="round" strokeLinejoin="round" aria-hidden="true">
                  <path d="M3 17l6-6 4 4 8-8" />
                </svg>
              </div>
              <h3>Reordenar com 1 traço</h3>
              <p>
                Cliente urgente apareceu? Desenhe um laço no mapa, reotimize e
                pronto.
              </p>
            </div>
            <div className="feature">
              <div className="icon">
                <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.8" strokeLinecap="round" strokeLinejoin="round" aria-hidden="true">
                  <polyline points="20 6 9 17 4 12" />
                </svg>
              </div>
              <h3>Marca entregue/falhou</h3>
              <p>
                Histórico das entregas com horário, foto e motivo. Comprovação
                fácil pro contratante.
              </p>
            </div>
            <div className="feature">
              <div className="icon">
                <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.8" strokeLinecap="round" strokeLinejoin="round" aria-hidden="true">
                  <path d="M12 22s8-4 8-10V5l-8-3-8 3v7c0 6 8 10 8 10z" />
                </svg>
              </div>
              <h3>Funciona offline</h3>
              <p>
                Mapa salvo no celular. Sinal fraco no condomínio? A rota
                continua funcionando.
              </p>
            </div>
          </div>
        </div>
      </section>

      {/* ───── COMPARE ───── */}
      <section className="compare-section">
        <div className="wrap">
          <div className="sec-head">
            <span className="pill">
              <span className="dot"></span>
              Sem o Roteirizador Pro vs. com
            </span>
            <h2>A diferença é dinheiro no bolso</h2>
          </div>
          <div className="compare">
            <div className="left">
              <h4>Antes</h4>
              <ul>
                <li>
                  <span className="check">
                    <svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="3" strokeLinecap="round" strokeLinejoin="round" aria-hidden="true">
                      <line x1="18" y1="6" x2="6" y2="18" />
                      <line x1="6" y1="6" x2="18" y2="18" />
                    </svg>
                  </span>
                  45 minutos digitando endereços no Maps
                </li>
                <li>
                  <span className="check">
                    <svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="3" strokeLinecap="round" strokeLinejoin="round" aria-hidden="true">
                      <line x1="18" y1="6" x2="6" y2="18" />
                      <line x1="6" y1="6" x2="18" y2="18" />
                    </svg>
                  </span>
                  Rota na cabeça — voltando duas vezes no mesmo bairro
                </li>
                <li>
                  <span className="check">
                    <svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="3" strokeLinecap="round" strokeLinejoin="round" aria-hidden="true">
                      <line x1="18" y1="6" x2="6" y2="18" />
                      <line x1="6" y1="6" x2="18" y2="18" />
                    </svg>
                  </span>
                  Despachante ligando pra saber onde você está
                </li>
                <li>
                  <span className="check">
                    <svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="3" strokeLinecap="round" strokeLinejoin="round" aria-hidden="true">
                      <line x1="18" y1="6" x2="6" y2="18" />
                      <line x1="6" y1="6" x2="18" y2="18" />
                    </svg>
                  </span>
                  Gasolina queimando rodando em círculos
                </li>
              </ul>
            </div>
            <div className="right">
              <h4>Depois</h4>
              <ul>
                <li>
                  <span className="check">
                    <svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="3" strokeLinecap="round" strokeLinejoin="round" aria-hidden="true">
                      <polyline points="20 6 9 17 4 12" />
                    </svg>
                  </span>
                  <span>
                    <strong>2 minutos</strong> ditando ou fotografando as
                    etiquetas
                  </span>
                </li>
                <li>
                  <span className="check">
                    <svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="3" strokeLinecap="round" strokeLinejoin="round" aria-hidden="true">
                      <polyline points="20 6 9 17 4 12" />
                    </svg>
                  </span>
                  <span>
                    Rota otimizada por IA —{' '}
                    <strong>até 37% mais curta</strong>
                  </span>
                </li>
                <li>
                  <span className="check">
                    <svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="3" strokeLinecap="round" strokeLinejoin="round" aria-hidden="true">
                      <polyline points="20 6 9 17 4 12" />
                    </svg>
                  </span>
                  <span>Despachante acompanha tudo em tempo real</span>
                </li>
                <li>
                  <span className="check">
                    <svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="3" strokeLinecap="round" strokeLinejoin="round" aria-hidden="true">
                      <polyline points="20 6 9 17 4 12" />
                    </svg>
                  </span>
                  <span>
                    <strong>R$ 200+ por mês</strong> economizados em combustível
                  </span>
                </li>
              </ul>
            </div>
          </div>
        </div>
      </section>

      {/* ───── TESTIMONIALS ───── */}
      <section>
        <div className="wrap">
          <div className="sec-head">
            <span className="pill">
              <span className="dot"></span>
              Depoimentos
            </span>
            <h2>O que os motoboys estão falando</h2>
          </div>
          <div className="quotes">
            <div className="quote">
              <div className="stars">★★★★★</div>
              <p>
                &ldquo;Em 1 semana já paguei o app no combustível que economizei.
                Antes fazia 18 entregas por dia, agora faço 27.&rdquo;
              </p>
              <div className="who">
                <div className="avatar">CR</div>
                <div>
                  <div className="name">Carlos Ribeiro</div>
                  <div className="role">Motoboy · São Paulo</div>
                </div>
              </div>
            </div>
            <div className="quote">
              <div className="stars">★★★★★</div>
              <p>
                &ldquo;O ditado por voz salvou minha vida. Tô com 80 paradas no
                condomínio e adiciono tudo enquanto carrego a moto.&rdquo;
              </p>
              <div className="who">
                <div
                  className="avatar"
                  style={{
                    background:
                      'linear-gradient(135deg, var(--neon), var(--neon-dark))',
                    color: 'var(--neon-ink)',
                  }}
                >
                  JS
                </div>
                <div>
                  <div className="name">Juliana Silva</div>
                  <div className="role">Entregadora · Rio de Janeiro</div>
                </div>
              </div>
            </div>
            <div className="quote">
              <div className="stars">★★★★★</div>
              <p>
                &ldquo;Compartilhei a rota com meu chefe e ele parou de me
                ligar a cada hora. Sossego que não tem preço.&rdquo;
              </p>
              <div className="who">
                <div className="avatar">RM</div>
                <div>
                  <div className="name">Rafael Macedo</div>
                  <div className="role">Motoboy · Belo Horizonte</div>
                </div>
              </div>
            </div>
          </div>
        </div>
      </section>

      {/* ───── FINAL CTA ───── */}
      <section id="cta" style={{ padding: '64px 0 96px' }}>
        <div className="wrap">
          <div className="final-cta">
            <span className="pill neon" style={{ marginBottom: 18 }}>
              <span className="dot"></span>
              Pague só pela rota
            </span>
            <h2>
              Sua próxima entrega pode ser{' '}
              <span style={{ color: 'var(--neon)' }}>37% mais rápida</span>.
            </h2>
            <p>
              Otimize sua rota e veja o ganho antes de pagar. Pix na hora
              de iniciar, só pelo que rodar. Sem mensalidade.
            </p>
            <a
              className="btn-primary"
              href={APK_URL}
              download={APK_FILENAME}
            >
              Baixar app
              <span className="neon-dot"></span>
            </a>
            <div className="meta"></div>
          </div>
        </div>
      </section>

      {/* ───── FOOTER ───── */}
      <footer>
        <div className="wrap row">
          <div className="logo" style={{ fontSize: 15 }}>
            <div
              className="logo-mark"
              style={{ width: 28, height: 28, borderRadius: 7 }}
            >
              <Image
                src="/logo.png"
                alt="Roteirizador Pro"
                width={28}
                height={28}
              />
            </div>
            <span>Roteirizador Pro</span>
          </div>
          <div className="links">
            <a href="#">Termos</a>
            <a href="#">Privacidade</a>
            <a href="#">Contato</a>
            <a href="#">Para empresas</a>
          </div>
          <div
            style={{ display: 'flex', alignItems: 'center', gap: 6 }}
          >
            Desenvolvido com
            <svg
              width="14"
              height="14"
              viewBox="0 0 24 24"
              fill="#6C3FC5"
              stroke="none"
              style={{ display: 'inline-block', verticalAlign: 'middle' }}
              aria-hidden="true"
            >
              <path d="M12 21s-7-4.5-9.5-9C0.5 8 3 4 7 4c2 0 3.5 1 5 3 1.5-2 3-3 5-3 4 0 6.5 4 4.5 8C19 16.5 12 21 12 21z" />
            </svg>
            por{' '}
            <a
              href="https://elovisiondigital.com"
              style={{ color: 'var(--primary)', fontWeight: 600 }}
            >
              elovisiondigital.com
            </a>
          </div>
        </div>
      </footer>
    </>
  );
}
