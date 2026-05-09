import type { Config } from 'tailwindcss';

const config: Config = {
  content: ['./src/app/**/*.{ts,tsx}', './src/components/**/*.{ts,tsx}'],
  theme: {
    extend: {
      colors: {
        primary: {
          DEFAULT: '#6C3FC5',
          dark: '#4E2D91',
          light: '#EDE7F6',
        },
        accent: '#9B6DFF',
        neon: {
          DEFAULT: '#C6FF3D',
          dark: '#9BCC1F',
          light: '#F1FFCC',
          ink: '#3D5400',
        },
        ink: '#1A1A2E',
        muted: '#6B6880',
        surface: {
          DEFAULT: '#F8F7FC',
          alt: '#F2EFFA',
        },
        outline: '#E8E4F0',
      },
      fontFamily: {
        sans: ['var(--font-poppins)', 'system-ui', 'sans-serif'],
      },
      maxWidth: {
        wrap: '1200px',
      },
    },
  },
  plugins: [],
};

export default config;
