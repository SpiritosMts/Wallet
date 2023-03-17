import 'package:expansion_tile_card/expansion_tile_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_sms_inbox/flutter_sms_inbox.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:responsive_sizer/responsive_sizer.dart';
import 'package:syncfusion_flutter_datepicker/datepicker.dart';
import 'package:wallet/main.dart';
import 'package:telephony/telephony.dart' as tlf;
import 'dart:async';

import 'package:wallet/manager/notifications/awesome_notifications.dart';

class SMSCtr extends GetxController {
  final SmsQuery query = SmsQuery();
  List<SmsMessage> foundMessages = [];
  List<SmsMessage> allMessages = [];
  List<GlobalKey<ExpansionTileCardState>> keyCap = [];
  String searchValue = '';

  int maxLocLength = 13;
  bool firstLoading = true;
  DateTime startDate =    DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day, 0, 0, 0);
  DateTime endDate = DateTime.now().add(const Duration(days: 1));
  double total = 0.00;
  double balance = 0.00;
  int messagesLimit = 50;
  int lastMonth = 0;
  int lastYear = 0;
  bool isLimit = true;
  bool isPeriod = false;

  String currency = 'AED';

  final TextEditingController numberLimitCtr = TextEditingController();
  tlf.Telephony telephony = tlf.Telephony.instance;

  @override
  void onInit() {
    super.onInit();
    NotificationController.startListeningNotificationEvents();

    initPlatformState();
    getAllMessages(messagesLimit);
    numberLimitCtr.text = messagesLimit.toString();
  }

  Future<void> initPlatformState() async {

    final bool? result = await telephony.requestPhoneAndSmsPermissions;

    if (result != null && result) {
      telephony.listenIncomingSms(

          onNewMessage: (tlf.SmsMessage msg) {
            print('## SMS_BODY_LISTEN: ${msg.body!}');
            checkReceivedMsg(msg);
            isLimit = true;
            isPeriod = false;
            getAllMessages(4000);

          },
          onBackgroundMessage: onBackgroundMessage);
    }
  }

  // fetch all SMSs from device
  void getAllMessages(int limit) async {
    var permission = await Permission.sms.status;
    if (permission.isGranted) {
      Future.delayed(Duration.zero, () async {
        showDialog(// show loading window
            barrierDismissible: false,
            context: navigatorKey.currentContext!,
            builder: (_) {
              return Dialog(
                backgroundColor: Colors.white,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children:  [
                      // Some text
                      Text('Loading...'.tr)
                    ],
                  ),
                ),
              );
            });

        /// Fetch all SMSs ////////////////
        List<SmsMessage> messages = await query.querySms(
          kinds: [SmsQueryKind.inbox], //filter Inbox messages
          count: 0, //number of sms to read '0' for all
          sort: true,
        );
        /// /////////////////////////////////////:

        Navigator.of(navigatorKey.currentContext!).pop(); // hide loading window
        firstLoading = false;
        update();
        // allMessages = messages;

        /// fetch only transactions //////////////
        allMessages = messages.where((SmsMessage msg) {
          return (msg.body!.toLowerCase().contains("you have made a purchase of") ||
             // msg.address!.toLowerCase().contains("la poste") ||
              msg.address!.toLowerCase().contains("ei sms") ||
              msg.address!.toLowerCase().contains("el sms"));
        }).toList();
        /// ///////////////////

        /// fetch Limit & Period /////////////////
        allMessages = fetchMessagesWithLimit(isLimit,limit);  //fetch with specific number
        allMessages = fetchMessagesWithPeriod(isPeriod);  //fetch with specific period
        /// ////////////

        foundMessages = allMessages;
        total = calculateTotal(foundMessages);
        getBalance();

        keyCap = List<GlobalKey<ExpansionTileCardState>>.generate(foundMessages.length, (index) => GlobalKey(debugLabel: 'key_$index'),
            growable: false); // create this to expand messages after search
        //print('## all messages number: ${allMessages.length}');
        update();

        // show snackBar
        SnackBar snackBar = SnackBar(
          content: Text(foundMessages.isNotEmpty ? '${foundMessages.length} ' + 'transactions loaded successfully'.tr : 'no transactions found'.tr),
        );
        ScaffoldMessenger.of(navigatorKey.currentContext!).showSnackBar(snackBar);
      });
    } else {
      await Permission.sms.request();
      getAllMessages(messagesLimit);
    }
  }

  List<SmsMessage> fetchMessagesWithPeriod(bool withRange) {
    print(('## fetchMessagesWithPeriod: $withRange'));
    List<SmsMessage> messages = [];
    for (SmsMessage msg in allMessages) {
      bool isInRange = (msg.date!.isBefore(endDate) && msg.date!.isAfter(startDate));
      if (isInRange) {
        print('## ${msg.date!} in range => ADD');
        messages.add(msg);
      }
    }
    return withRange ? messages : allMessages;
  }
  List<SmsMessage> fetchMessagesWithLimit(bool withLimit,int limit) {
    print(('## fetchMessagesWithLimit: $withLimit'));
    List<SmsMessage> messages = [];

    print('## allMessages BEFORE sublist = ${allMessages.length}');
    messages = allMessages.sublist(0, limit.clamp(0, allMessages.length));
    print('## allMessages AFTER sublist(limit=$limit) = ${allMessages.length}');

    return withLimit ? messages : allMessages;
  }

  void getBalance() {
    // get balance
    if(foundMessages.isNotEmpty){
      String balanceMsg = foundMessages[0].body!;
      String lastWord = balanceMsg.substring(balanceMsg.lastIndexOf(" ") + 1);
      lastWord = lastWord.replaceAll(",", "").substring(0, lastWord.length - 1);
      balance = double.tryParse(lastWord.substring(0, lastWord.length - 1))!;
      update();
    }

  }

  // This function is called whenever the search text field changes
  void runFilter(String enteredKeyword) {
    print('## running filter ...');
    List<SmsMessage> results = [];
    if (enteredKeyword.isEmpty) {
      /// all messages
      // if the search field is empty or only contains white-space, we'll display all users
      results = allMessages;
    } else {
      /// filtred messages
      results = allMessages.where((SmsMessage msg) {
        return (msg.body!.toLowerCase().contains(enteredKeyword.toLowerCase()) || msg.address!.toLowerCase().contains(enteredKeyword.toLowerCase()));
      }).toList();
    }

    foundMessages = results;
    total = calculateTotal(foundMessages);

    Future.delayed(Duration(milliseconds: 80), () async {
      if (searchValue != '' && foundMessages.isNotEmpty) {
        for (GlobalKey<ExpansionTileCardState> key in keyCap) {
          key.currentState?.expand();
        }
      } else {
        for (GlobalKey<ExpansionTileCardState> key in keyCap) {
          key.currentState?.collapse();
        }
      }
    });
    update(); // Refresh the UI
  }

  // detect amount in "AED" of each msg
  double detectAmount(msg) {
    //print('## detecting "${msg.address}" transaction...' );
    double moneyD = 0.00;
    if (msg.body!.contains(currency)) {
      //print('msg_$index contain money');

      String clearBody = msg.body!.replaceAll(RegExp('$currency\\S+'), currency);

      List<String> words = clearBody.split(" ");
      int i = words.indexOf(currency);
      //print('## $words');
      if (i > 0) {
        String amount = words[i + 1]; // get word after "AED" which is the amount
        amount.replaceAll(RegExp('[:,]'), ''); // remove any comma if exists
        moneyD = double.tryParse(amount) ?? 0.00; // parse money string to double
      }
    }
    return moneyD;
  }

  String detectLocation(String msgBody, int index) {
    String resultString = 'Transaction '.tr + '${index+1}';

    if (msgBody.toLowerCase().contains("you have made a purchase of")) {
      String startWord = " at";
      String endWord = ". Available";

      int startIndex = msgBody.indexOf(startWord) + startWord.length;
      int endIndex = msgBody.indexOf(endWord);

      resultString = msgBody.substring(startIndex, endIndex).trim();
    }
    return resultString;
  }

  // calculate total amount of many msg
  double calculateTotal(List<SmsMessage> messages) {
    double total = 0.00;

    for (SmsMessage msg in messages) {
      double amountOfMsg = detectAmount(msg); //get money amount from msg
      total += amountOfMsg; //add amount to total
    }

    return total;
  }

  // show filter window
 void filterDialog() {
    showDialog(
      barrierDismissible: false,
      context: navigatorKey.currentContext!,
      builder: (_) => AlertDialog(

        title: Text('filter results'.tr),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(
            Radius.circular(12.0),
          ),
        ),
        content: Builder(
          builder: (context) {
            return SizedBox(
              //height: 100.h / 2.2,
              width: 100.w,
              child: GetBuilder<SMSCtr>(
                  builder: (ctr) {
                    return SingleChildScrollView(
                      child: ListBody(
                        children: <Widget>[
                          Padding(
                            padding: const EdgeInsets.only(top: 0.0,bottom: 0),
                            child: Row(
                              children: [
                                Checkbox(

                                  value: isLimit,
                                  onChanged: (bool? value) {
                                    isLimit = value!;
                                    isPeriod = !value!;
                                    update();
                                  },
                                ),
                                Text("Show last".tr,
                                  style: TextStyle(
                                      fontSize: 15
                                  ),
                                ),
                                SizedBox(width: 7),

                                SizedBox(
                                  width: 50,
                                  height: 30,
                                  child: TextFormField(
                                    controller: numberLimitCtr,
                                    decoration: InputDecoration(
                                      contentPadding: EdgeInsets.symmetric(horizontal: 5, vertical: 0),
                                      //labelText: "Transactions".tr,
                                      border:  OutlineInputBorder(
                                        borderRadius:  BorderRadius.circular(5.0),
                                        borderSide:  BorderSide(),
                                      ),
                                    ),
                                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                                    keyboardType: TextInputType.number,
                                  ),
                                ),
                                //SizedBox(width: 7),

                                // Text("transactions".tr,
                                //   style: TextStyle(
                                //       fontSize: 15
                                //   ),
                                // ),

                              ],
                            ),
                          ),
                          SizedBox(height: 7),

                          Padding(
                            padding: const EdgeInsets.all(0.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Checkbox(
                                      value: isPeriod,
                                      onChanged: (bool? value) {
                                        isPeriod = value!;
                                        isLimit = !value!;

                                        update();
                                      },
                                    ),
                                    Text("Choose period".tr+':',
                                      style: TextStyle(
                                          fontSize: 15
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 7),
                                if(isPeriod) SfDateRangePicker(
                                  onSelectionChanged: (DateRangePickerSelectionChangedArgs args) {
                                    startDate = args.value.startDate;
                                    endDate = args.value.endDate ?? startDate.add(const Duration(days: 1));
                                    update();
                                    print('## from "$startDate" to "$endDate"');
                                  },
                                  selectionMode: DateRangePickerSelectionMode.range,
                                  initialSelectedRange: PickerDateRange(startDate, endDate),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  }
              ),
            );
          },
        ),
        actions: <Widget>[
          TextButton(
            child: Text("Apply".tr),
            onPressed: () {
              getAllMessages(int.tryParse(numberLimitCtr.text) ?? messagesLimit);
              Get.back();
            },
          ),
          TextButton(
            child: Text("Cancel".tr),
            onPressed: () {
              Get.back();
            },
          ),
          TextButton(
            child: Text("Show all".tr),
            onPressed: () {
              isLimit = true;
              isPeriod = false;
              getAllMessages(4000);

              update();
              Get.back();
            },
          ),
        ],

      ),
    );
  }
}
