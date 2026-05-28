import plugin from 'tailwindcss/plugin';

/** @type {import('tailwindcss').Config} */
export default {
  content: [
    "./index.html",
    "./src/**/*.{vue,js,ts,jsx,tsx}",
  ],
  theme: {
    extend: {
      colors: {
        gold: {
          50: 'rgb(var(--gold-50, 252 249 242) / <alpha-value>)',
          100: 'rgb(var(--gold-100, 247 236 212) / <alpha-value>)',
          200: 'rgb(var(--gold-200, 239 217 169) / <alpha-value>)',
          300: 'rgb(var(--gold-300, 230 197 125) / <alpha-value>)',
          400: 'rgb(var(--gold-400, 222 178 82) / <alpha-value>)',
          500: 'rgb(var(--gold-500, 214 158 39) / <alpha-value>)',
          600: 'rgb(var(--gold-600, 184 115 0) / <alpha-value>)',
          700: 'rgb(var(--gold-700, 158 101 0) / <alpha-value>)',
          800: 'rgb(var(--gold-800, 107 69 0) / <alpha-value>)',
          900: 'rgb(var(--gold-900, 61 39 0) / <alpha-value>)',
        },
      },
      fontFamily: {
        sans: ["Inter", "Tajawal", "ui-sans-serif", "system-ui", "sans-serif"],
        tajawal: ["Tajawal", "sans-serif"],
      },
      boxShadow: {
        luxury: '0 10px 40px -10px rgba(0, 0, 0, 0.05), 0 2px 10px -2px rgba(184, 115, 0, 0.05)',
        'luxury-lg': '0 20px 50px -12px rgba(0, 0, 0, 0.08), 0 4px 20px -4px rgba(184, 115, 0, 0.08)',
      }
    },
  },
  plugins: [
    plugin(function({ addComponents }) {
      addComponents({
        '.gold-gradient-bg': {
          background: 'linear-gradient(135deg, rgb(var(--gold-500, 214 158 39)) 0%, rgb(var(--gold-600, 184 115 0)) 100%)',
        },
      })
    })
  ],
}
