export default function HomePage() {
  return (
    <main className="flex min-h-screen flex-col items-center justify-center bg-primary-light px-6 py-24 text-center">
      <span className="rounded-full bg-primary px-4 py-1 text-xs font-semibold uppercase tracking-wider text-white">
        Em construção
      </span>
      <h1 className="mt-6 text-4xl font-bold text-primary-dark sm:text-5xl">
        Roteirizador Pro
      </h1>
      <p className="mt-4 max-w-xl text-base text-gray-700 sm:text-lg">
        A landing oficial está em construção. Em breve estará disponível em{' '}
        <strong>roteirizadorpro.com.br</strong> com download direto do APK e
        todas as informações de assinatura.
      </p>
      <button
        type="button"
        disabled
        className="mt-10 cursor-not-allowed rounded-lg bg-neon px-6 py-3 text-sm font-semibold text-neon-ink opacity-60"
      >
        Baixar APK (em breve)
      </button>
    </main>
  );
}
