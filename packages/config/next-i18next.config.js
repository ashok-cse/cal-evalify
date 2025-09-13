const path = require("path");
const fs = require("fs");

// Try multiple possible paths to find i18n.json
let i18n;
const possiblePaths = [
  path.resolve(__dirname, "../../i18n.json"),
  path.resolve(process.cwd(), "i18n.json"),
  path.resolve(process.cwd(), "../../i18n.json"),
  path.join(__dirname, "..", "..", "i18n.json")
];

for (const i18nPath of possiblePaths) {
  try {
    if (fs.existsSync(i18nPath)) {
      i18n = JSON.parse(fs.readFileSync(i18nPath, 'utf8'));
      break;
    }
  } catch (error) {
    // Continue to next path
  }
}

// Fallback configuration if file is not found
if (!i18n) {
  i18n = {
    locale: {
      source: "en",
      targets: [
        "ar", "az", "bg", "bn", "ca", "cs", "da", "de", "el", "es", "es-419", "eu", "et", "fi", "fr", "he", "hu", "it", "ja", "km", "ko", "nl", "no", "pl", "pt-BR", "pt", "ro", "ru", "sk-SK", "sr", "sv", "tr", "uk", "vi", "zh-CN", "zh-TW"
      ]
    }
  };
}

/** @type {import("next-i18next").UserConfig} */
const config = {
  i18n: {
    defaultLocale: i18n.locale.source,
    locales: i18n.locale.targets.concat([i18n.locale.source]),
  },
  fallbackLng: {
    default: ["en"],
    zh: ["zh-CN"],
  },
  reloadOnPrerender: process.env.NODE_ENV !== "production",
};

module.exports = config;
