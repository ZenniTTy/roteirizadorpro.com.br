import type { Metadata } from 'next';
import { Poppins } from 'next/font/google';
import './globals.css';

const poppins = Poppins({
  subsets: ['latin'],
  weight: ['400', '500', '600', '700'],
  variable: '--font-poppins',
  display: 'swap',
});

export const metadata: Metadata = {
  title: 'Roteirizador Pro',
  description:
    'Roteirização rápida e confiável para motoboys. Otimize sua rota e termine o dia mais perto de casa.',
};

export default function RootLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <html lang="pt-BR" className={poppins.variable}>
      <body className="min-h-screen font-sans antialiased">{children}</body>
    </html>
  );
}
