import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:wallet/main.dart';


class MyLocaleCtr extends GetxController {
  //String codeLang = sharedPrefs!.getString('lang') ?? 'ar' : sharedPrefs!.getString('lang')!;
  Locale initlang = Locale(sharedPrefs!.getString('lang') ?? 'en');


  String? get currLang => Get.locale!.languageCode;

  void changeLang(String codeLang) {
    sharedPrefs!.setString('lang', codeLang);
    Locale locale = Locale(codeLang);
    Get.updateLocale(locale);
    print('## current lang => ${currLang}');
  }
}
