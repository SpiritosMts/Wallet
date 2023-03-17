import 'package:easy_search_bar/easy_search_bar.dart';
import 'package:expansion_tile_card/expansion_tile_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

//import 'package:sms/sms.dart';
//import 'package:flutter_sms/flutter_purchases.dart';
import 'package:flutter_sms_inbox/flutter_sms_inbox.dart';
import 'package:wallet/manager/constants.dart';
import 'package:wallet/flutter_purchases_ctr.dart';
import 'package:wallet/main.dart';
import 'package:wallet/manager/notifications/awesome_notifications.dart';
import 'package:wallet/manager/styles.dart';
import 'package:get/get.dart';

//import 'package:highlight_text/highlight_text.dart';
import 'package:intl/intl.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:responsive_sizer/responsive_sizer.dart';
import 'dart:ui' as ui;

import 'package:substring_highlight/substring_highlight.dart';
import 'package:wallet/manager/tutoCtr.dart';

class SMSscreen extends StatefulWidget {
  @override
  _SMSscreenState createState() => _SMSscreenState();
}

class _SMSscreenState extends State<SMSscreen> {
  final SMSCtr c = Get.put(SMSCtr());
  final TutoController ttr = Get.find<TutoController>();

  // message card widget
  Widget messageCard(SmsMessage message, int index) {
    DateFormat dateFormat = DateFormat("dd/MM/yyyy");
    String body = message.body!;
    String address = message.address!;
    DateTime dateTime = message.date!;
    String date = dateFormat.format(dateTime);
    double moneyD = c.detectAmount(message);
    String location = c.detectLocation(message.body!, index);

    // detect if this message is the head of the month
    double monthAmount = 0.00;
    bool isNewMonth = false;
    if (dateTime.month != c.lastMonth || dateTime.year != c.lastYear) {
      isNewMonth = true;
      c.lastMonth = dateTime.month;
      c.lastYear = dateTime.year;
      List<SmsMessage> monthMessages = [];
      for (SmsMessage msg in c.foundMessages) {
        if (msg.date!.month == c.lastMonth && msg.date!.year == c.lastYear) {
          monthMessages.add(msg);
        }
      }
      monthAmount = c.calculateTotal(monthMessages);
    }
    //

    return Container(
      child: Column(
        children: [
          ///month, year ,month_amount
          if (isNewMonth)
            SizedBox(
              width: 100.w,
              child: Padding(
                  padding: const EdgeInsets.only(top: 15.0, bottom: 15.0, right: 10, left: 10),
                  child: Row(
                    children: <Widget>[
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0),
                        child: Text(
                          '${monthFromIndex[c.lastMonth]!.tr}  ${c.lastYear}',
                          maxLines: 1,
                          style: TextStyle(),
                        ),
                      ),

                      /// monthName, year
                      Expanded(
                        child: Divider(
                          color: Colors.black,
                          thickness: 1,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0),
                        child: Text(
                          "AED ${monthAmount.toStringAsFixed(2)}",
                          maxLines: 1,
                        ),
                      ),

                      ///monthAmount
                    ],
                  )),
            ),

          ExpansionTileCard(
            key: c.keyCap[index],
            title: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(location.length > c.maxLocLength ? '${location.substring(0, c.maxLocLength)}...' : location),
                Text(date),
              ],
            ),
            subtitle: Text('AED ${moneyD.toStringAsFixed(2)}'),
            children: <Widget>[
              Divider(
                thickness: 1.0,
                height: 1.0,
              ),
              Align(
                alignment: Alignment.centerLeft,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 8.0,
                  ),
                  child: SubstringHighlight(text: body, term: c.searchValue, textStyle: bodyStyle, textStyleHighlight: highlightStyle),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// ###################################################################################
  /// ###################################################################################

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: EasySearchBar(
          searchBackIconTheme: IconThemeData(),
          actions: [
            IconButton(
              key: ttr.filterKey,
              padding: EdgeInsets.only(left: 0.0),
              icon: const Icon(Icons.filter_list),
              onPressed: () {
                c.filterDialog();
              },
            )
          ],
          searchHintText: 'search...'.tr,
          title: Row(
            children: [
              SizedBox(width: 15),
              Image.asset('assets/images/logo.png',width: 20,),
              SizedBox(width: 10),

              Container(
                padding: EdgeInsets.symmetric(horizontal: 0),
                  child: Text('Transactions'.tr)
              ),
            ],
          ),
          onSearch: (value) {
            setState(() {
              c.searchValue = value;
              c.runFilter(c.searchValue);
            });
          },
        ),
        body: GetBuilder<SMSCtr>(
          initState: (_) {
            Future.delayed(const Duration(seconds: 1), () {
              ttr.showHomeTuto(context);
            });
          },
          builder: (ctr) {
            return Stack(
              children: [
                ///messages
                Padding(
                  padding: const EdgeInsets.only(bottom: 25.0, top: 35.0),
                  child: SingleChildScrollView(
                    child: Container(
                      padding: EdgeInsets.all(20),
                      child: c.foundMessages.isNotEmpty
                          ? Column(
                              children: c.foundMessages.map((msg) {
                              int idx = c.foundMessages.indexOf(msg);
                              return messageCard(msg, idx);
                            }).toList())
                          : c.searchValue == ''
                              ? c.firstLoading
                                  ? Center(child: CircularProgressIndicator())
                                  : Padding(
                                      padding: const EdgeInsets.only(top: 8.0),
                                      child: Center(
                                        child: Column(
                                          children: [
                                            Text(
                                              'no transactions found'.tr,
                                              style: TextStyle(
                                                fontSize: 18,
                                              ),
                                              textAlign: TextAlign.center,
                                            ),
                                            SizedBox(height: 15),
                                            ElevatedButton(
                                              onPressed: () {
                                                c.getAllMessages(4000);
                                              },
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: Colors.lightBlue,
                                                shape: RoundedRectangleBorder(
                                                  borderRadius: BorderRadius.circular(8.0),
                                                ),
                                              ),
                                              child: Text(
                                                'Show all'.tr,
                                                style: TextStyle(color: Colors.white),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    )
                              : Padding(
                                  padding: const EdgeInsets.only(top: 8.0),
                                  child: Center(
                                    child: Text(
                                      'no transactions found containing'.tr + '"${c.searchValue}"',
                                      style: TextStyle(
                                        fontSize: 18,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                ),
                    ),
                  ),
                ),

                /// total
                if (c.foundMessages.isNotEmpty)
                  Align(
                    alignment: Alignment.bottomCenter,
                    child: Container(
                      key: ttr.totalKey,
                      color: Colors.blue.shade100,
                      width: 100.w,
                      height: 45,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 15.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Total'.tr),
                            Text('AED ${c.total.toStringAsFixed(2)}'),
                          ],
                        ),
                      ),
                    ),
                  ),

                /// available balance
                if (c.foundMessages.isNotEmpty)
                  Align(
                    alignment: Alignment.topCenter,
                    child: Container(
                      key: ttr.balanceKey,
                      color: Colors.blue.shade50,
                      width: 100.w,
                      height: 45,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 15.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Available balance'.tr),
                            Text(
                              'AED ${c.balance.toStringAsFixed(2)}',
                              style: TextStyle(fontWeight: FontWeight.w700),
                            ),
                          ],
                        ),
                      ),
                    ),
                  )
              ],
            );
          },
        ));
  }
}
