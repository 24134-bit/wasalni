# دليل نشر الـ Backend باستخدام Docker

لقد قمنا بتحضير كود الـ Backend ليعمل داخل حاويات Docker، مما يسهل عملية رفعه على خدمات الاستضافة السحابية.

## 1. الملفات المضافة
- **Dockerfile**: ملف بناء حاوية الـ PHP والـ Apache.
- **docker-compose.yml**: ملف لتشغيل الـ PHP وقاعدة البيانات MySQL معاً.
- **db.php**: تم تحديثه ليدعم "Variables" البيئة (Environment Variables).

## 2. بناء وتشغيل الحاوية (Docker Image)

إذا كنت ترغب في بناء الصورة (Image) ونشرها مباشرة:

### أ- البناء محلياً
في مجلد `backend` قم بتشغيل:
```bash
docker build -t wasalni-backend .
```

### ب- التشغيل الفوري
لتشغيل الحاوية على أي سيرفر يدعم Docker:
```bash
docker run -d -p 8080:80 --name wasalni-app wasalni-backend
```

## 3. التشغيل باستخدام Compose (الأفضل للمبتدئين)
إذا كان لديك Docker مثبت على جهازك أو السيرفر، يمكنك تشغيل النظام بالكامل (الـ PHP مع قاعدة البيانات) بضغطة واحدة:
1. افتح Terminal في مجلد `backend`.
2. قم بتشغيل الأمر: `docker-compose up -d --build`.
3. سيكون الرابط المحلي للـ API هو: `http://localhost:8080`.

## 3. الرفع على استضافة مجانية
هناك العديد من الخدمات التي تدعم Docker بشكل مجاني أو بأسعار منخفضة جداً:

### أ- Railway.app (سهل جداً)
1. قم بإنشاء حساب على [Railway.app](https://railway.app/).
2. اربط حسابك بـ GitHub وانشر مجلد الـ backend هناك.
3. سيتعرف Railway تلقائياً على الـ `Dockerfile` ويقوم بالبناء.
4. أضف متغيرات البيئة (Variables) في إعدادات Railway:
   - `DB_HOST`: رابط قاعدة البيانات التي سيوفرها لك Railway.
   - `DB_USER`: اسم المستخدم.
   - `DB_PASS`: كلمة المرور.
   - `DB_NAME`: wasalni.

### ب- Render.com
1. يدعم Render الـ Docker كـ "Web Service".
2. يمكنك إنشاء قاعدة بيانات MySQL منفصلة على Render ثم ربطها بالـ Web Service عبر المتغيرات المذكورة أعلاه.

---

> [!TIP]
> بعد رفع الـ backend والحصول على الرابط النهائي (مثلاً: `https://wasalni-api.up.railway.app`), لا تنسى تحديث رابط `baseUrl` في ملف `lib/config.dart` في تطبيق Flutter لكي يتمكن التطبيق من التواصل مع السيرفر الحقيقي.
