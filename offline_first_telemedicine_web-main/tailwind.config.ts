import type { Config } from 'tailwindcss'

export default {
  darkMode: 'class',
  content: ['./index.html', './src/**/*.{ts,tsx}'],
  theme: {
    extend: {
      colors: {
        navy: {
          950: '#071427',
          900: '#0B1E33',
          800: '#102A45',
          700: '#163958'
        },
        teal: {
          600: '#0D9488',
          500: '#14B8A6',
          400: '#2DD4BF'
        },
        cyan: {
          500: '#06B6D4',
          400: '#22D3EE'
        },
        mist: {
          50: '#F5FAFA',
          100: '#EAF3F3',
          200: '#DCEAEA'
        }
      },
      fontFamily: {
        display: ['"Sora"', 'system-ui', 'sans-serif'],
        body: ['"Inter"', 'system-ui', 'sans-serif']
      },
      boxShadow: {
        card: '0 1px 2px rgba(11,30,51,0.06), 0 4px 16px rgba(11,30,51,0.06)'
      }
    }
  },
  plugins: []
} satisfies Config
