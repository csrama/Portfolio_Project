/**
 * Better Auth – تهيئة المصادقة الشاملة (Email, Google, Apple)
 * ══════════════════════════════════════════════════════════
 */

const { betterAuth } = require('better-auth');

const auth = betterAuth({
  secret: process.env.BETTER_AUTH_SECRET,
  baseURL: process.env.BETTER_AUTH_URL || 'http://localhost:3000',

  socialProviders: {
    // ── Google OAuth ─────────────────────────────────────────────────────
    google: {
      clientId: process.env.GOOGLE_CLIENT_ID,
      clientSecret: process.env.GOOGLE_CLIENT_SECRET,
    },

    // ── Apple Sign-In ────────────────────────────────────────────────────
    // يتطلب حساب Apple Developer (99$/سنة) لتهيئة الخدمة
    apple: {
      clientId: process.env.APPLE_CLIENT_ID,
      teamId: process.env.APPLE_TEAM_ID,
      keyId: process.env.APPLE_KEY_ID,
      privateKey: process.env.APPLE_PRIVATE_KEY, // نص المفتاح الخاص .p8
    },
  },

  // ── البريد الإلكتروني وكلمة المرور ──────────────────────────────────────
  emailAndPassword: {
    enabled: true,
    autoSignIn: true, // تسجيل الدخول تلقائياً بعد إنشاء الحساب
  },

  // ── إعدادات الجلسة ──────────────────────────────────────────────────────
  session: {
    expiresIn: 60 * 60 * 24 * 7, // 7 أيام
    updateAge: 60 * 60 * 24,     // تجديد يومي
  },
});

module.exports = auth;