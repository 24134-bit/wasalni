import 'package:shared_preferences/shared_preferences.dart';

class Lang {
  static String curr = 'fr'; // Default French

  static Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    curr = prefs.getString('lang') ?? 'fr';
  }

  static Future<void> set(String lang) async {
    curr = lang;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('lang', lang);
  }

  static String get(String key) {
    return data[key]?[curr] ?? key;
  }

  static final Map<String, Map<String, String>> data = {
    'status_pending': {'fr': 'En attente', 'ar': 'قيد الانتظار'},
    'status_accepted': {'fr': 'Acceptée', 'ar': 'مقبولة'},
    'status_arrived': {'fr': 'Arrivé', 'ar': 'وصل الكابتن'},
    'status_on_trip': {'fr': 'En cours', 'ar': 'في الطريق'},
    'status_delivered': {'fr': 'Terminée', 'ar': 'مكتملة'},
    'status_cancelled': {'fr': 'Annulée', 'ar': 'ملغاة'},
    'login_title': {'fr': 'Connexion', 'ar': 'تسجيل الدخول'},
    'phone': {'fr': 'Numéro de téléphone', 'ar': 'رقم الهاتف'},
    'password': {'fr': 'Mot de passe', 'ar': 'كلمة المرور'},
    'login_btn': {'fr': 'SE CONNECTER', 'ar': 'دخول'},
    'car_number': {'fr': 'Numéro de voiture', 'ar': 'رقم السيارة'},
    'loc_required': {'fr': 'Localisation requise pour continuer', 'ar': 'يجب تفعيل الموقع للمتابعة'},
    'security_warning': {
      'fr': "Attention : N'envoyez pas d'argent depuis un numéro qui ne porte pas votre nom enregistré dans l'application.",
      'ar': 'تنبيه: لا تقم بتحويل الأموال من رقم غير مسجل باسمك في التطبيق.'
    },
    'search_loc': {'fr': 'Rechercher un lieu', 'ar': 'البحث عن موقع'},
    'app_name': {'fr': 'Tariki', 'ar': 'طريقي'},
    'services_fees_title': {'fr': 'Services et Frais', 'ar': 'الخدمات و الرسوم'},
    'home': {'fr': 'Accueil', 'ar': 'الرئيسية'},
    'wallet': {'fr': 'Portefeuille', 'ar': 'المحفظة'},
    'recharge': {'fr': 'Recharger', 'ar': 'شحن الرصيد'},
    'available_rides': {'fr': 'Courses Disponibles', 'ar': 'رحلات متاحة'},
    'online': {'fr': 'En ligne', 'ar': 'متصل'},
    'offline': {'fr': 'Hors ligne', 'ar': 'غير متصل'},
    'start_ride': {'fr': 'Commencer', 'ar': 'بدء الرحلة'},
    'finish_ride': {'fr': 'Terminer', 'ar': 'إنهاء الرحلة'},
    'price': {'fr': 'Prix', 'ar': 'السعر'},
    'sar': {'fr': 'MRU', 'ar': 'أوقية'},
    'logout': {'fr': 'Déconnexion', 'ar': 'خروج'},
    'admin_dash': {'fr': 'Tableau de bord', 'ar': 'لوحة التحكم'},
    'upload_proof': {'fr': 'Télécharger Reçu', 'ar': 'رفع الإيصال'},
    'select_method': {'fr': 'Mode de paiement', 'ar': 'طريقة الدفع'},
    'amount': {'fr': 'Montant', 'ar': 'المبلغ'},
    'submit': {'fr': 'Envoyer', 'ar': 'إرسال'},
    'no_rides': {'fr': 'Aucune course disponible', 'ar': 'لا توجد رحلات متاحة حالياً'},
    'to': {'fr': 'Vers', 'ar': 'إلى'},
    'pickup': {'fr': 'Départ', 'ar': 'نقطة الانطلاق'},
    'dropoff': {'fr': 'Destination', 'ar': 'وجهة الوصول'},
    'ride_details': {'fr': 'Détails de la course', 'ar': 'تفاصيل الرحلة'},
    'accept_ride': {'fr': 'Accepter la course', 'ar': 'قبول الرحلة'},
    'arrived': {'fr': 'Arrivé', 'ar': 'وصلت'},
    'on_trip': {'fr': 'En voyage', 'ar': 'في الطريق'},
    'completed': {'fr': 'Terminé', 'ar': 'تم الوصول'},
    'cancel': {'fr': 'Annuler', 'ar': 'إلغاء'},
    'confirm': {'fr': 'Confirmer', 'ar': 'تأكيد'},
    'admin_approvals': {'fr': 'Approbations', 'ar': 'الموافقات'},
    'admin_captains': {'fr': 'Capitaines', 'ar': 'الكباتن'},
    'admin_create_ride': {'fr': 'Créer une course', 'ar': 'إنشاء رحلة'},
    'admin_add_captain': {'fr': 'Ajouter Capitaine', 'ar': 'إضافة كابتن'},
    'admin_active_rides': {'fr': 'Courses Actives', 'ar': 'الرحلات الجارية'},
    'admin_live_map': {'fr': 'Carte en direct', 'ar': 'الخريطة المباشرة'},
    'sender': {'fr': 'Expéditeur', 'ar': 'المرسل'},
    'view_proof': {'fr': 'Voir la preuve', 'ar': 'رؤية الإيصال'},
    'approve': {'fr': 'Approuver', 'ar': 'موافقة'},
    'reject': {'fr': 'Rejeter', 'ar': 'رفض'},
    'on_trip_btn': {'fr': 'En cours...', 'ar': 'في الطريق'},
    'ride_finished': {'fr': 'Course terminée', 'ar': 'تم إنهاء الرحلة بنجاح'},
    'curr_balance': {'fr': 'Solde actuel', 'ar': 'الرصيد الحالي'},
    'top_up': {'fr': 'Recharger', 'ar': 'شحن الرصيد'},
    'fill_all': {'fr': 'Veuillez remplir tous les champs', 'ar': 'يرجى ملء جميع الحقول'},
    'transfer_to': {'fr': 'Transférer à:', 'ar': 'حول المبلغ إلى:'},
    'instr_recharge': {
      'fr': 'Effectuez le transfert, puis prenez une capture d\'écran.',
      'ar': 'قم بالتحويل أولاً، ثم ارفع صورة الإيصال هنا.'
    },
    'tap_upload': {'fr': 'Cliquez pour télécharger', 'ar': 'اضغط لرفع الصورة'},
    'selected': {'fr': 'Sélectionné', 'ar': 'تم اختيار'},
    'ride_type': {'fr': 'Type de Course', 'ar': 'نوع الرحلة'},
    'ride_closed': {'fr': 'Fermée', 'ar': 'محددة'},
    'ride_open': {'fr': 'Ouverte', 'ar': 'مفتوحة'},
    'customer_phone_label': {'fr': 'Tél. Client', 'ar': 'رقم هاتف الزبون'},
    'search_customer': {'fr': 'Rechercher par téléphone...', 'ar': 'بحث برقم الهاتف...'},
    'price_configs': {'fr': 'Configurations des Prix', 'ar': 'إعدادات الأسعار'},
    'price_per_km': {'fr': 'Prix par KM', 'ar': 'سعر الكيلومتر'},
    'price_per_min': {'fr': 'Prix par Minute', 'ar': 'سعر الدقيقة'},
    'base_fare': {'fr': 'Tarif de base', 'ar': 'سعر البداية'},
    'commission_label': {'fr': 'Commission (%)', 'ar': 'العمولة (%)'},
    'save_changes': {'fr': 'Enregistrer les modifications', 'ar': 'حفظ التغييرات'},
    'no_matching_rides': {'fr': 'Aucune course correspondante', 'ar': 'لا توجد رحلات مطابقة'},
    'settings': {'fr': 'Paramètres', 'ar': 'الإعدادات'},
    'dashboard': {'fr': 'Tableau de bord', 'ar': 'لوحة المعلومات'},
    'view_available_rides': {'fr': 'Voir les courses disponibles', 'ar': 'عرض الرحلات المتاحة'},
    'status': {'fr': 'Statut', 'ar': 'الحالة'},
    'ride_accepted': {'fr': 'Course acceptée ! Préparez-vous.', 'ar': 'تم قبول الرحلة! استعد للذهاب.'},
    'ride_created_success': {'fr': 'Course créée avec succès !', 'ar': 'تم إنشاء الرحلة بنجاح.'},
    'ride_completed_success': {'fr': 'Course terminée avec succès.', 'ar': 'تم إنهاء الرحلة بنجاح.'},
    'error_occurred': {'fr': 'Une erreur est survenue', 'ar': 'حدث خطأ ما'},
    'going_to': {'fr': 'Destination :', 'ar': 'الوجهة :'},
    'ongoing_ride': {'fr': 'Course en cours', 'ar': 'الرحلة الجارية'},
    'resume_ride': {'fr': 'Reprendre', 'ar': 'متابعة'},
    'notifications': {'fr': 'Notifications', 'ar': 'الإشعارات'},
    'no_notifications': {'fr': 'Aucune notification', 'ar': 'لا توجد إشعارات'},
    'min_balance_msg': {
      'fr': 'Solde minimum de 50 MRU requis pour les courses ouvertes.',
      'ar': 'يجب توفر رصيد 50 أوقية على الأقل لقبوول الرحلات المفتوحة.'
    },
    'insufficient_balance': {
      'fr': 'Solde insuffisant pour couvrir la commission.',
      'ar': 'الرصيد غير كافٍ لتغطية عمولة الرحلة.'
    },
  };
}
