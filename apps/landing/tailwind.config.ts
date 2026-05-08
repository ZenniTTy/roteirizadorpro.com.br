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
      },
      fontFamily: {
        sans: ['var(--font-poppins)', 'system-ui', 'sans-serif'],
      },
    },
  },
  plugins: [],
};

export default config;
