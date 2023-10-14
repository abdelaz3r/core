// See the Tailwind configuration guide for advanced usage
// https://tailwindcss.com/docs/configuration

const plugin = require("tailwindcss/plugin")
const fs = require("fs")
const path = require("path")

module.exports = {
  content: [
    "./js/**/*.js",
    "../lib/interface.ex",
    "../lib/interface/**/*.*ex"
  ],
  theme: {
    colors: {
      white: '#ffffff',
      black: '#000000',
      gray: {
        25: 'rgb(202, 211, 245)',
        50: 'rgb(184, 192, 224)',
        75: 'rgb(165, 173, 203)',
        100: 'rgb(147, 154, 183)',
        200: 'rgb(128, 135, 162)',
        300: 'rgb(110, 115, 141)',
        400: 'rgb(91, 96, 120)',
        500: 'rgb(73, 77, 100)',
        600: 'rgb(54, 58, 79)',
        700: 'rgb(36, 39, 58)',
        800: 'rgb(30, 32, 48)',
        900: 'rgb(24, 25, 38)',
      },
      pink: '#f5bde6',
      mauve: '#c6a0f6',
      red: '#ed8796',
      peach: '#f5a97f',
      yellow: '#eed49f',
      green: '#a6da95',
      teal: '#8bd5ca',
      sky: '#91d7e3',
      sapphire: '#7dc4e4',
      blue: '#8aadf4',
      lavender: '#b7bdf8',
    },
    fontFamily: {
      sans: ['Graphik', 'sans-serif'],
      serif: ['Merriweather', 'serif'],
    },
    extend: {
      colors: {
        brand: "#FD4F00",
      }
    },
  },
  plugins: [
    require("@tailwindcss/forms"),
    // Allows prefixing tailwind classes with LiveView classes to add rules
    // only when LiveView classes are applied, for example:
    //
    //     <div class="phx-click-loading:animate-ping">
    //
    plugin(({addVariant}) => addVariant("phx-no-feedback", [".phx-no-feedback&", ".phx-no-feedback &"])),
    plugin(({addVariant}) => addVariant("phx-click-loading", [".phx-click-loading&", ".phx-click-loading &"])),
    plugin(({addVariant}) => addVariant("phx-submit-loading", [".phx-submit-loading&", ".phx-submit-loading &"])),
    plugin(({addVariant}) => addVariant("phx-change-loading", [".phx-change-loading&", ".phx-change-loading &"])),
  ]
}
