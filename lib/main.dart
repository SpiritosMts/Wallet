import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:responsive_sizer/responsive_sizer.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:telephony/telephony.dart';
import 'package:vibration/vibration.dart';
import 'package:wallet/flutter_purchases.dart';
import 'package:wallet/flutter_purchases_ctr.dart';
import 'package:wallet/intro.dart';
import 'package:wallet/manager/bindings.dart';
import 'package:wallet/manager/myLocale/myLocale.dart';
import 'package:wallet/manager/myLocale/myLocaleCtr.dart';
import 'package:wallet/manager/notifications/awesome_notifications.dart';
import 'package:telephony/telephony.dart' as tlf;


final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
SharedPreferences? sharedPrefs;

onBackgroundMessage(SmsMessage msg) {
  debugPrint("## onBackgroundMessage called");
  checkReceivedMsg(msg);
}
int introTimes = 0;

void checkReceivedMsg(tlf.SmsMessage msg){
  bool shouldAlert = (msg.body!.toLowerCase().contains("you have made a purchase of") ||
      msg.address!.toLowerCase().contains("ei sms") ||
      msg.address!.toLowerCase().contains("el sms"));
  if(shouldAlert){

    Vibration.vibrate(duration: 500);

    double moneyD = Get.find<SMSCtr>().detectAmount(msg);
    String location = Get.find<SMSCtr>().detectLocation(msg.body!, 0);

    /// get last balance ///////////
    String lastWord = msg.body!.substring(msg.body!.lastIndexOf(" ") + 1);
    lastWord = lastWord.replaceAll(",", "").substring(0, lastWord.length - 1);
    String balance = lastWord.substring(0, lastWord.length - 1);
    /// ///////////
    NotificationController.createNewNotificationSMS('$location',
        //'you AED ${moneyD.toStringAsFixed(2)} ${'was spent on the last purchase'.tr}'
        '${'You spent'.tr} ${moneyD.toStringAsFixed(2)} ${'AED'.tr} ${'on the last purchase'.tr}'
        +' - '
        + '${'Available balance'.tr}: $balance ${'AED'.tr}');

  }
}

void main() async{
  await WidgetsFlutterBinding.ensureInitialized();
  sharedPrefs = await SharedPreferences.getInstance();
  await NotificationController.initializeLocalNotifications();//awesome notif
  introTimes = sharedPrefs!.getInt('intro')??0 ;

  runApp( MyApp());

}




class MyApp extends StatefulWidget {
   MyApp({super.key});
   //static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  MyLocaleCtr langCtr =   Get.put(MyLocaleCtr());

  @override
  Widget build(BuildContext context) {
    return ResponsiveSizer(
        builder: (context, orientation, deviceType) {
          return GetMaterialApp(
            navigatorKey: navigatorKey,
            debugShowCheckedModeBanner: false,

            title: 'Wallet',
            theme: ThemeData(
              primarySwatch: Colors.blue,
            ),
            initialBinding: GetxBinding(),

            locale: langCtr.initlang,
            translations: MyLocale(),

            initialRoute: '/',
            getPages: [
              GetPage(name: '/', page: () => introTimes<3 ? OnBoardingPage():SMSscreen()),
              //GetPage(name: '/', page: () => ScreenManager()),//in test mode

            ],
          );
        }
    );
  }
}

/// Buttons Page Route
class ScreenManager extends StatefulWidget {
  @override
  _ScreenManagerState createState() => _ScreenManagerState();
}


class _ScreenManagerState extends State<ScreenManager> {
  @override
  Widget build(BuildContext context) {
    return Container(
      child: ListView(
        children: <Widget>[


          TextButton(
              onPressed: () {
                Get.to(() => SMSscreen());
              },
              child: Text('SMSscreen')),

      TextButton(
              onPressed: () {
                Get.to(() => NotifPage(title: 'Awesome Notifications Example App'));
              },
              child: Text('NotifPage')),

          TextButton(
              onPressed: () {
                //sharedPrefs!.remove('saved_purchases');
                sharedPrefs!.clear();
                print('##prefs_cleared');

              },
              child: Text('clear prefs')),
          TextButton(
              onPressed: () {
                Get.to(() => OnBoardingPage());


              },
              child: Text('intro')),

        ],
      ),
    );
  }
}
