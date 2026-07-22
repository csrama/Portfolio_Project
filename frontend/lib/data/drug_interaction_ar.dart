/// ترجمة عربية لبيانات التداخلات الدوائية (المواد الفعالة + الوصف + التوصية).
/// المصدر الإنجليزي: backend/src/db/migrations/006_seed_drug_interactions.sql
/// أي تحديث لتلك القائمة لازم ينعكس هنا أيضاً.
///
/// ملاحظة: التوصيات مكتوبة بصيغة عامة غير مخاطبة (بدون تذكير/تأنيث)،
/// زي "يُنصح بمراقبة..." بدل "راقبي/راقب...".
library;

/// أسماء المواد الفعالة بالعربي (المفتاح: الاسم الإنجليزي lowercase تماماً
/// زي ما هو مخزّن بعمود ingredient_a / ingredient_b بقاعدة البيانات).
const Map<String, String> kIngredientNamesAr = {
  'amiodarone': 'أميودارون',
  'aspirin': 'أسبرين',
  'atorvastatin': 'أتورفاستاتين',
  'calcium carbonate': 'كربونات الكالسيوم',
  'carbamazepine': 'كاربامازيبين',
  'ciprofloxacin': 'سيبروفلوكساسين',
  'clarithromycin': 'كلاريثروميسين',
  'clopidogrel': 'كلوبيدوقرل',
  'digoxin': 'ديجوكسين',
  'diltiazem': 'ديلتيازيم',
  'doxycycline': 'دوكسيسايكلين',
  'ferrous sulfate': 'كبريتات الحديدوز',
  'fluconazole': 'فلوكونازول',
  'furosemide': 'فوروسيميد',
  'gentamicin': 'جنتاميسين',
  'glibenclamide': 'جليبنكلاميد',
  'ibuprofen': 'إيبوبروفين',
  'insulin': 'الأنسولين',
  'isosorbide mononitrate': 'آيزوسوربيد مونونيترات',
  'levothyroxine': 'ليفوثيروكسين',
  'lisinopril': 'ليزينوبريل',
  'lithium': 'الليثيوم',
  'losartan': 'لوسارتان',
  'metformin': 'ميتفورمين',
  'methotrexate': 'ميثوتريكسات',
  'metronidazole': 'ميترونيدازول',
  'omeprazole': 'أوميبرازول',
  'phenelzine': 'فينلزين',
  'phenytoin': 'فينيتوين',
  'potassium chloride': 'كلوريد البوتاسيوم',
  'prednisone': 'بريدنيزون',
  'propranolol': 'بروبرانولول',
  'rifampin': 'ريفامبين',
  'sertraline': 'سيرترالين',
  'sildenafil': 'سيلدينافيل',
  'simvastatin': 'سيمفاستاتين',
  'spironolactone': 'سبيرونولاكتون',
  'theophylline': 'ثيوفيلين',
  'tramadol': 'ترامادول',
  'trimethoprim-sulfamethoxazole': 'تراي ميثوبريم-سلفاميثوكسازول',
  'verapamil': 'فيراباميل',
  'warfarin': 'وارفارين',
};

/// وصف/توصية كل زوج بالعربي. المفتاح = "ingredient_a|ingredient_b"
/// بنفس ترتيب وحروف قاعدة البيانات (a قبل b أبجدياً، lowercase).
class InteractionArText {
  final String descriptionAr;
  final String recommendationAr;
  const InteractionArText(this.descriptionAr, this.recommendationAr);
}

final Map<String, InteractionArText> kInteractionTextAr = {
  'amiodarone|digoxin': const InteractionArText(
    'الأميودارون يرفع مستوى الديجوكسين بالدم، مما يزيد خطر تسمم الديجوكسين.',
    'يُنصح بمراقبة مستوى الديجوكسين بالدم؛ قد يحتاج الأمر تخفيض الجرعة.',
  ),
  'amiodarone|warfarin': const InteractionArText(
    'الأميودارون يعزز تأثير الوارفارين، مما يزيد خطر النزيف.',
    'يُنصح بمراقبة مؤشر INR بانتظام؛ غالباً تحتاج جرعة الوارفارين للتخفيض.',
  ),
  'aspirin|warfarin': const InteractionArText(
    'الجمع بينهما يزيد بشكل كبير من خطر النزيف.',
    'يُنصح بتجنب الجمع إلا بتوجيه طبي مباشر، ومراقبة علامات النزيف.',
  ),
  'aspirin|methotrexate': const InteractionArText(
    'الأسبرين يقلل من تخلص الجسم من الميثوتريكسات، مما يزيد خطر التسمم.',
    'يُنصح بتجنب الجمع، خصوصاً مع جرعات الميثوتريكسات العالية.',
  ),
  'atorvastatin|clarithromycin': const InteractionArText(
    'المضادات الحيوية من نوع الماكروليد تثبط استقلاب الستاتين، مما يرفع خطر اعتلال العضلات.',
    'يُفضّل إيقاف الستاتين مؤقتاً أثناء فترة المضاد الحيوي.',
  ),
  'atorvastatin|fluconazole': const InteractionArText(
    'مضاد الفطريات يثبط استقلاب الستاتين، مما يرفع خطر اعتلال العضلات.',
    'يُنصح بمراقبة أي ألم بالعضلات، مع إمكانية تعديل الجرعة.',
  ),
  'carbamazepine|warfarin': const InteractionArText(
    'الكاربامازيبين يحفّز إنزيمات الكبد، مما يقلل فعالية الوارفارين.',
    'يُنصح بمراقبة INR عند بدء أو إيقاف الكاربامازيبين.',
  ),
  'ciprofloxacin|theophylline': const InteractionArText(
    'السيبروفلوكساسين يثبط استقلاب الثيوفيلين، مما يعرّض لخطر التسمم (تشنجات، اضطراب نظم القلب).',
    'يُنصح بمراقبة مستوى الثيوفيلين وتجنب الجمع إن أمكن.',
  ),
  'ciprofloxacin|warfarin': const InteractionArText(
    'الكينولونات يمكن أن ترفع INR وخطر النزيف.',
    'يُنصح بمراقبة INR بانتظام أثناء وبعد العلاج بالمضاد الحيوي.',
  ),
  'calcium carbonate|ciprofloxacin': const InteractionArText(
    'الكالسيوم يرتبط بمضادات الكينولون، مما يقلل امتصاص المضاد الحيوي.',
    'يُنصح بالفصل بين الجرعتين بساعتين على الأقل.',
  ),
  'calcium carbonate|levothyroxine': const InteractionArText(
    'الكالسيوم يقلل امتصاص الليفوثيروكسين.',
    'يُنصح بالفصل بين الجرعتين ٤ ساعات على الأقل.',
  ),
  'clopidogrel|omeprazole': const InteractionArText(
    'الأوميبرازول يثبط تفعيل الكلوبيدوقرل، مما يقلل مفعوله المضاد للتجلط.',
    'يمكن التفكير باستخدام مثبط مضخة بروتون بديل (مثل بانتوبرازول) أو حاصرات H2.',
  ),
  'digoxin|furosemide': const InteractionArText(
    'فقدان البوتاسيوم الناتج عن الفوروسيميد يزيد خطر تسمم الديجوكسين.',
    'يُنصح بمراقبة مستوى البوتاسيوم والديجوكسين بانتظام.',
  ),
  'digoxin|verapamil': const InteractionArText(
    'الفيراباميل يرفع مستوى الديجوكسين، وكلاهما يبطئ التوصيل الكهربائي بالقلب، مما يعرّض لبطء ضربات القلب.',
    'يُنصح بمراقبة معدل ضربات القلب ومستوى الديجوكسين؛ غالباً يحتاج الأمر تعديل الجرعة.',
  ),
  'doxycycline|ferrous sulfate': const InteractionArText(
    'الحديد يرتبط بمضادات التتراسايكلين، مما يقلل امتصاص المضاد الحيوي.',
    'يُنصح بالفصل بين الجرعتين ٢-٣ ساعات على الأقل.',
  ),
  'fluconazole|warfarin': const InteractionArText(
    'الفلوكونازول يثبط استقلاب الوارفارين، مما يزيد خطر النزيف.',
    'يُنصح بمراقبة INR بانتظام؛ غالباً تحتاج جرعة الوارفارين للتخفيض.',
  ),
  'furosemide|gentamicin': const InteractionArText(
    'الجمع بينهما يزيد خطر تسمم الأذن والكلى.',
    'يُنصح بمراقبة وظائف الكلى والسمع، وتجنب الاستخدام المشترك المطوّل.',
  ),
  'glibenclamide|propranolol': const InteractionArText(
    'حاصرات بيتا يمكن أن تخفي أعراض هبوط السكر الناتج عن أدوية السلفونيل يوريا.',
    'يُنصح بمراقبة سكر الدم بانتظام، مع إمكانية استخدام حاصر بيتا انتقائي للقلب.',
  ),
  'ibuprofen|lisinopril': const InteractionArText(
    'مضادات الالتهاب غير الستيرويدية تقلل من تأثير خافضات الضغط الحامية للكلى، وقد تضعف وظائف الكلى.',
    'يُنصح باستخدام أقل جرعة فعالة من مضاد الالتهاب، ومراقبة ضغط الدم ووظائف الكلى.',
  ),
  'ibuprofen|warfarin': const InteractionArText(
    'مضادات الالتهاب غير الستيرويدية تزيد خطر النزيف عند الجمع مع الوارفارين.',
    'يُنصح بتجنب الجمع، مع إمكانية استخدام الباراسيتامول لتسكين الألم.',
  ),
  'furosemide|ibuprofen': const InteractionArText(
    'مضادات الالتهاب غير الستيرويدية قد تقلل مفعول الفوروسيميد المدر للبول وتضعف وظائف الكلى.',
    'يُنصح بمراقبة ضغط الدم ووظائف الكلى وحالة السوائل بالجسم.',
  ),
  'insulin|propranolol': const InteractionArText(
    'حاصرات بيتا يمكن أن تخفي أعراض هبوط السكر (الرعشة، تسارع النبض) عند مرضى الأنسولين.',
    'يُنصح بتوعية المريض بعلامات هبوط السكر غير المرتبطة بالأدرينالين (التعرّق، التشوش الذهني).',
  ),
  'lisinopril|potassium chloride': const InteractionArText(
    'مثبطات الإنزيم المحول للأنجيوتنسين تقلل من إفراز البوتاسيوم؛ الجمع مع مكملات البوتاسيوم قد يسبب ارتفاعاً خطيراً بمستواه.',
    'يُنصح بمراقبة مستوى البوتاسيوم بالدم بانتظام، وتجنب المكملات غير الضرورية.',
  ),
  'lisinopril|spironolactone': const InteractionArText(
    'كلا الدوائين يرفعان مستوى البوتاسيوم، مما يعرّض لارتفاع خطير بمستواه.',
    'يُنصح بمراقبة البوتاسيوم عن قرب؛ الجمع يتطلب معايرة دقيقة للجرعة.',
  ),
  'lisinopril|losartan': const InteractionArText(
    'الحصار المزدوج لجهاز الرينين-أنجيوتنسين يزيد خطر ارتفاع البوتاسيوم وضعف وظائف الكلى دون فائدة إضافية تُذكر.',
    'يُنصح بتجنب الجمع بين مثبطات الإنزيم المحول وحاصرات مستقبلات الأنجيوتنسين إلا بتوجيه أخصائي.',
  ),
  'ibuprofen|lithium': const InteractionArText(
    'مضادات الالتهاب غير الستيرويدية تقلل تخلص الكلى من الليثيوم، مما يرفع مستواه نحو التسمم.',
    'يُنصح بمراقبة مستوى الليثيوم، وتجنب الاستخدام المنتظم لمضادات الالتهاب إن أمكن.',
  ),
  'lisinopril|lithium': const InteractionArText(
    'مثبطات الإنزيم المحول تقلل إفراز الليثيوم، مما يزيد خطر التسمم.',
    'يُنصح بمراقبة مستوى الليثيوم عن قرب بعد بدء أو تعديل مثبط الإنزيم المحول.',
  ),
  'furosemide|metformin': const InteractionArText(
    'مدرات البول قد تؤثر على ضبط سكر الدم ووظائف الكلى المهمة لسلامة استخدام الميتفورمين.',
    'يُنصح بمراقبة وظائف الكلى وضبط السكر بشكل دوري.',
  ),
  'methotrexate|trimethoprim-sulfamethoxazole': const InteractionArText(
    'الجمع بينهما يزيد خطر تثبيط نخاع العظم.',
    'يُنصح بتجنب الجمع؛ وإن تعذر ذلك، مراقبة صورة الدم عن قرب.',
  ),
  'metronidazole|warfarin': const InteractionArText(
    'الميترونيدازول يثبط استقلاب الوارفارين، مما يزيد خطر النزيف.',
    'يُنصح بمراقبة INR بانتظام أثناء وبعد العلاج.',
  ),
  'levothyroxine|omeprazole': const InteractionArText(
    'قلة حموضة المعدة الناتجة عن مثبطات مضخة البروتون قد تقلل امتصاص الليفوثيروكسين.',
    'يُنصح بمراقبة وظائف الغدة الدرقية، مع إمكانية الفصل بين الجرعتين.',
  ),
  'phenytoin|warfarin': const InteractionArText(
    'التفاعل متغيّر وقد يرفع أو يخفض INR.',
    'يُنصح بمراقبة INR عن قرب عند بدء أو إيقاف أو تعديل جرعة الفينيتوين.',
  ),
  'rifampin|warfarin': const InteractionArText(
    'الريفامبين يحفّز إنزيمات الكبد بقوة، مما يقلل تأثير الوارفارين بشكل ملحوظ.',
    'يُنصح بمراقبة INR عن قرب؛ غالباً تحتاج زيادة كبيرة بجرعة الوارفارين.',
  ),
  'ibuprofen|sertraline': const InteractionArText(
    'مثبطات استرداد السيروتونين مع مضادات الالتهاب غير الستيرويدية تزيد خطر النزيف الهضمي.',
    'يمكن التفكير بحماية المعدة (مثل مثبط مضخة بروتون) إذا كان الجمع ضرورياً.',
  ),
  'sertraline|tramadol': const InteractionArText(
    'الجمع بينهما يزيد خطر متلازمة السيروتونين.',
    'يُنصح بتجنب الجمع إن أمكن، ومراقبة أي تهيّج أو رعشة أو حمى.',
  ),
  'isosorbide mononitrate|sildenafil': const InteractionArText(
    'الجمع بينهما قد يسبب هبوطاً حاداً وخطيراً بضغط الدم يهدد الحياة.',
    'ممنوع منعاً باتاً - يُمنع الجمع بينهما تحت أي ظرف.',
  ),
  'clarithromycin|simvastatin': const InteractionArText(
    'المضادات الحيوية من نوع الماكروليد تثبط استقلاب الستاتين، مما يرفع خطر اعتلال العضلات.',
    'يُفضّل إيقاف الستاتين مؤقتاً أثناء فترة المضاد الحيوي.',
  ),
  'diltiazem|simvastatin': const InteractionArText(
    'الديلتيازيم يثبط استقلاب الستاتين، مما يرفع خطر اعتلال العضلات بالجرعات العالية.',
    'يُنصح بتقليل جرعة الستاتين أو استخدام بديل له.',
  ),
  'phenelzine|tramadol': const InteractionArText(
    'مثبطات أوكسيديز أحادي الأمين مع الترامادول قد تسبب متلازمة سيروتونين تهدد الحياة.',
    'ممنوع منعاً باتاً - يجب ترك فترة زمنية فاصلة بين استخدامهما.',
  ),
  'trimethoprim-sulfamethoxazole|warfarin': const InteractionArText(
    'هذا المضاد الحيوي المركّب يزيد INR وخطر النزيف بشكل ملحوظ.',
    'يُنصح بمراقبة INR عن قرب؛ عادة يحتاج الأمر تعديل بالجرعة.',
  ),
  'metformin|prednisone': const InteractionArText(
    'الكورتيزونات ترفع سكر الدم، مما يقلل فعالية الميتفورمين.',
    'يُنصح بمراقبة سكر الدم عن قرب عند بدء أو إيقاف الكورتيزون.',
  ),
};


List<String> extractKnownIngredients(String text) {
  final normalized = text.trim().toLowerCase();
  if (normalized.isEmpty) return [];

 
  final keys = kIngredientNamesAr.keys.toList()
    ..sort((a, b) => b.length.compareTo(a.length));

  final found = <String>[];
  for (final key in keys) {
    if (normalized.contains(key)) {
      found.add(key);
    }
  }
  return found;
}
String ingredientNameAr(String englishName) {
  final key = englishName.trim().toLowerCase();
  return kIngredientNamesAr[key] ?? englishName;
}
InteractionArText? interactionTextAr(String ingredientA, String ingredientB) {
  final a = ingredientA.trim().toLowerCase();
  final b = ingredientB.trim().toLowerCase();
  return kInteractionTextAr['$a|$b'];
}

/// ترتيب رقمي للخطورة، يُستخدم للفرز تنازلياً (الأخطر أولاً).
int severityRank(String severity) {
  switch (severity) {
    case 'contraindicated':
      return 3;
    case 'major':
      return 2;
    case 'moderate':
      return 1;
    case 'minor':
    default:
      return 0;
  }
}