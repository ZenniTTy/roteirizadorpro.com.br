// Screen 13: Component library showcase

function ScreenComponents() {
  const Section = ({ title, children }) => (
    <div style={{ marginBottom: 28 }}>
      <div style={{ fontSize: 11, fontWeight: 700, letterSpacing: 1.2, color: RP.textMuted, textTransform: 'uppercase', marginBottom: 12 }}>{title}</div>
      <div style={{ display: 'flex', flexDirection: 'column', gap: 10 }}>{children}</div>
    </div>
  );
  return (
    <Phone hideNav>
      <TopBar title="Componentes"/>
      <div style={{ flex: 1, padding: '8px 20px 24px', overflowY: 'auto', background: RP.surface }}>
        <Section title="Botões primários">
          <PrimaryButton>Padrão</PrimaryButton>
          <PrimaryButton style={{ background: RP.primaryDark }}>Pressionado</PrimaryButton>
          <PrimaryButton disabled>Desabilitado</PrimaryButton>
          <PrimaryButton locked>Iniciar Navegação</PrimaryButton>
        </Section>

        <Section title="Cards de parada">
          <StopCard stop={{ n: 1, a1: 'R. Augusta, 1234', a2: 'Apto 502 · Consolação', s: 'pending' }}/>
          <StopCard stop={{ n: 2, a1: 'Av. Paulista, 2200', a2: 'Loja 14 · Bela Vista', s: 'delivered' }} faded/>
          <StopCard stop={{ n: 3, a1: 'R. Oscar Freire, 875', a2: 'Apto 1201 · Jardins', s: 'failed' }}/>
        </Section>

        <Section title="Badges">
          <div style={{ display: 'flex', gap: 8, flexWrap: 'wrap' }}>
            <Badge variant="warning">Pendente</Badge>
            <Badge variant="success">Entregue</Badge>
            <Badge variant="error">Falhou</Badge>
            <Badge variant="primary">Entrega</Badge>
            <Badge variant="neutral">Neutro</Badge>
          </div>
          <div style={{ display: 'flex', gap: 8 }}>
            <span style={{ display: 'inline-flex', alignItems: 'center', gap: 4, height: 30, padding: '0 10px', background: RP.primaryLight, color: RP.primary, borderRadius: 999, fontSize: 12, fontWeight: 600 }}><I.Clock size={14}/> ~14:30</span>
            <span style={{ display: 'inline-flex', alignItems: 'center', gap: 4, height: 30, padding: '0 10px', background: RP.surface, border: `1px solid ${RP.border}`, color: RP.textMuted, borderRadius: 999, fontSize: 12, fontWeight: 600 }}><I.MapPin size={14}/> 47</span>
          </div>
        </Section>

        <Section title="Inputs">
          <Input placeholder="Padrão" value="" onChange={() => {}}/>
          <Input value="motoboy@email.com" onChange={() => {}} focused/>
          <Input value="ab" onChange={() => {}} error="E-mail inválido"/>
        </Section>

        <Section title="Bottom Nav">
          <div style={{ background: '#fff', borderRadius: 12, overflow: 'hidden', border: `1px solid ${RP.border}` }}>
            <BottomNav active="route"/>
          </div>
        </Section>
      </div>
    </Phone>
  );
}

window.ScreenComponents = ScreenComponents;
