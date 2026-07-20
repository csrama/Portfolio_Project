# استخدم صورة Node.js مع Alpine (خفيفة)
FROM node:20-alpine

# تثبيت أدوات البناء اللازمة لـ bcrypt
RUN apk add --no-cache python3 make g++ gcc

# تحديد مجلد العمل
WORKDIR /app

# نسخ ملفات package.json أولاً (للاستفادة من التخزين المؤقت)
COPY package*.json ./

# تثبيت التبعيات
RUN npm install --production

# نسخ باقي ملفات المشروع
COPY . .

# فتح المنفذ
EXPOSE 3000

# أمر تشغيل التطبيق
CMD ["npm", "start"]
