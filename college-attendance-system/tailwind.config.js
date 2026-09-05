/** @type {import('tailwindcss').Config} */
export default {
  content: [
    './index.html',
    './src/**/*.{js,ts,jsx,tsx}',
  ],
  darkMode: 'class',
  theme: {
    extend: {
      colors: {
        campus: {
          50: '#f0fdf4',
          100: '#dcfce7',
          200: '#bbf7d0',
          300: '#86efac',
          400: '#4ade80',
          500: '#22c55e',
          600: '#16a34a',
          700: '#15803d',
          800: '#166534',
          900: '#14532d',
          950: '#052e16',
        },
        academic: {
          50: '#eef2ff',
          100: '#e0e7ff',
          200: '#c7d2fe',
          300: '#a5b4fc',
          400: '#818cf8',
          500: '#6366f1',
          600: '#4f46e5',
          700: '#4338ca',
          800: '#3730a3',
          900: '#312e81',
          950: '#1e1b4b',
        },
        dark: {
          bg: '#080b11',
          card: '#0f1422',
          cardHover: '#151b2e',
          border: '#1a2238',
          input: '#121828',
        }
      },
      fontFamily: {
        sans: ['Plus Jakarta Sans', 'Inter', 'system-ui', 'sans-serif'],
      },
      backgroundImage: {
        'academic-grid': 'radial-gradient(rgba(99, 102, 241, 0.12) 1px, transparent 1px)',
        'academic-grid-light': 'radial-gradient(rgba(99, 102, 241, 0.18) 1px, transparent 1px)',
      },
      backgroundSize: {
        'grid-24': '24px 24px',
      },
      boxShadow: {
        'glow-indigo': '0 0 25px -5px rgba(99, 102, 241, 0.35)',
        'glow-emerald': '0 0 25px -5px rgba(34, 197, 94, 0.35)',
        'glow-rose': '0 0 25px -5px rgba(244, 63, 94, 0.35)',
        'glow-amber': '0 0 25px -5px rgba(245, 158, 11, 0.35)',
        'card': '0 4px 24px -2px rgba(0, 0, 0, 0.06), 0 2px 8px -1px rgba(0, 0, 0, 0.03)',
        'card-dark': '0 8px 32px -4px rgba(0, 0, 0, 0.6), 0 4px 12px -2px rgba(0, 0, 0, 0.4)',
      }
    },
  },
  plugins: [],
}
