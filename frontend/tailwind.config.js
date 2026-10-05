/** @type {import('tailwindcss').Config} */
export default {
  content: ["./index.html", "./src/**/*.{ts,tsx}"],
  theme: {
    extend: {
      colors: {
        // teal-green primary
        primary: {
          50: "#e6f4f1", 100: "#c8e8e0", 200: "#92d1c2",
          300: "#56b89f", 400: "#2a9c82", 500: "#0d7d65",
          600: "#077454", 700: "#065d44", 800: "#074d39", 900: "#06402f",
        },
        // navy text
        navy: {
          50: "#eef4f8", 100: "#d6e4ee", 200: "#a9c4d8",
          300: "#6e97b8", 400: "#3e6e91", 500: "#255d7f",
          600: "#1a4666", 700: "#123049", 800: "#0d2336", 900: "#081823",
        },
        accent: { DEFAULT: "#f1ab33", light: "#f8cd75", dark: "#c98817" },
        success: { DEFAULT: "#077454", light: "#e3f6ed", dark: "#06402f" },
        warning: { DEFAULT: "#b05e12", light: "#fff8ef", dark: "#7a3f08" },
        danger: { DEFAULT: "#b8311c", light: "#fdece8", dark: "#7a1f10" },
        info: { DEFAULT: "#255d7f", light: "#eef4f8", dark: "#123049" },
        surface: { DEFAULT: "#ffffff", warm: "#faf8f4", page: "#f5f3ee" },
      },
      fontFamily: {
        sans: ["system-ui", "-apple-system", "Segoe UI", "Roboto", "sans-serif"],
      },
      spacing: { "18": "4.5rem" },
      borderRadius: { "xl": "14px", "2xl": "18px" },
    },
  },
  plugins: [],
};
