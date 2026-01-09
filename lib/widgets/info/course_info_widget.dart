import 'package:calora/common/extensions/text_extensions.dart';
import 'package:calora/common/gen/strings.dart';
import 'package:calora/presentation/app/theme/theme_extensions.dart';
import 'package:flutter/material.dart';

class CourseInfoWidget extends StatelessWidget {
  final String description;

  const CourseInfoWidget({super.key, required this.description});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Strings.briefInformation
              .text(16, 20, 500)
              .c(context.colors.textStrong),
          SizedBox(height: 12),
          CourseDescriptions.weightLossOverview().text(14, 16, 400),
        ],
      ),
    );
  }
}

class CourseDescriptions {
  static String weightLossOverview() {
    return '''
1) Kurs haqida (Overview)
Maqsad: tana yog'ini kamaytirish, chidamlilikni oshirish, sog'lom odatlarni shakllantirish.
Format: 30 kunlik dastur; kuniga 8–20 daqiqa; uy sharoitida, jihozsiz; video + animatsion ko‘rsatmalar + ovozli trener.
Darajalar: Boshlovchi / O‘rta / Ilg‘or (har mashqga moslashtirilgan variantlar bor).
Natijalar: o‘zingni yengil his qilish, bel/son o‘lchamlarida pasayish, konditsiya yaxshilanishi.
Kimlar uchun: so‘g‘lom odamlarga; uzoq tanaffusdan keyin qaytuvchilar uchun ham mos.

2) Talablar va jihozlar
- Vaqt: 8–20 daqiqa/kun, haftasiga 5–6 kun.
- Jihoz: gilamcha, suv shishasi, (ixtiyoriy: rezina lenta).

3) Xavfsizlik: og‘riq bo‘lsa to‘xtang; surunkali kasallik bo‘lsa shifokor bilan maslahatlashing.

4) Kurs tuzilmasi (4 haftalik yo‘l xaritasi)
1-hafta — Bazani faollashtirish
   - Yengil kardio + to‘g‘ri texnika: squat, lunj, planka, glute bridge.
2-hafta — Yog‘ yo‘qotish (HIIT yengil)
   - Intervallar 20s ish / 10s dam; mashqlar almashinuvi.
3-hafta — Kuch va shakl
   - Asosiy zaruriy takrorlar, ko‘proq yadrog (core).
4-hafta — Biriktirish va barqarorlashtirish
   - Aralash protokol: kuch + HIIT + mobilizatsiya.
   - Yakunda test va o‘lchov.

5) Haftalik jadval (Namuna)
D1: To‘liq tana
D2: Kardio + Core
D3: Pastki tana
D4: Dam | Yengil yurish 6–10k qadam
D5: To‘liq tana B (HIIT yengil)
D6: Yugurish + cho‘zilish
D7: Cho‘zilish + tahlil

6) “1-kun” darsi ssenariysi (kartochka kontenti)
Isinish: 6 daqiqa (yengil yurish, qo‘l aylantirish)
Asosiy mashqlar: squat, lunj, planka
Sovutish: 2 daqiqa stretching
''';
  }
}
