import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';
import 'package:wallet/main.dart';

class TutoController extends GetxController {

 bool showAllTuto = true;
double opacityShadow =.8;
//Color colorShadow = Color(0XFFe9dda9);
Color colorShadow = Colors.red;
TextStyle tutoTextStyle = const TextStyle(
    color: Colors.white,
    height: 1.5,
  fontWeight: FontWeight.w500
);
bool hideSkip = true;
AlignmentGeometry alignSkip = Alignment.topCenter;
  @override
  void onInit() {
    //print('## onInit TutoController');
  }




  late TutorialCoachMark homeTCM;






  ///home
  GlobalKey searchKey = GlobalKey();
  GlobalKey filterKey = GlobalKey();
  GlobalKey totalKey = GlobalKey();
  GlobalKey balanceKey = GlobalKey();
  void showHomeTuto(ctx) {
    homeTCM = TutorialCoachMark(
      targets: _homeTargets(),
      colorShadow: colorShadow,
      textSkip: "SKIP",
      alignSkip: alignSkip ,
      hideSkip: hideSkip,
      opacityShadow: opacityShadow,
      onFinish: () {
        print("finish");
      },
      onClickTarget: (target) {
        print('onClickTarget: $target');
      },
      onClickTargetWithTapPosition: (target, tapDetails) {
        print("target: $target");
        print(
            "clicked at position local: ${tapDetails.localPosition} - global: ${tapDetails.globalPosition}");
      },
      onClickOverlay: (target) {
        print('onClickOverlay: $target');
      },
      onSkip: () {
        print("skip");
      },
    );
     bool showTuto = sharedPrefs!.getBool('homeTuto') ?? true;
     sharedPrefs!.setBool('homeTuto',false);


    ///bfr
    if(showTuto && showAllTuto){
    //if(true){
      Future.delayed(const Duration(microseconds: 300), () {
        homeTCM.show(context: ctx);
      });
    }  }
  List<TargetFocus> _homeTargets() {
    List<TargetFocus> targets = [];


    ///search
    // targets.add(
    //   TargetFocus(
    //     //enableOverlayTab: true,
    //     identify: "searchKey",
    //     keyTarget: searchKey,
    //     shape: ShapeLightFocus.RRect,
    //     paddingFocus: 50,
    //
    //     radius: 5,
    //
    //
    //     contents: [
    //       TargetContent(
    //         align: ContentAlign.bottom,
    //         builder: (context, controller) {
    //           return Container(
    //             child: Column(
    //               mainAxisSize: MainAxisSize.min,
    //               crossAxisAlignment: CrossAxisAlignment.end,
    //               children: <Widget>[
    //                 Text(
    //                   'this is a search bar you can search for any content in your previous transactions by clicking on search button'.tr,
    //                   style: tutoTextStyle,
    //                 ),
    //               ],
    //             ),
    //           );
    //         },
    //       ),
    //     ],
    //   ),
    // );
    ///filter
    targets.add(
      TargetFocus(
        identify: "filterKey",
        keyTarget: filterKey,
        paddingFocus: 0,
        contents: [
          TargetContent(
            align: ContentAlign.bottom,
            builder: (context, controller) {
              return Container(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: <Widget>[
                    Text(
                        'you can use the filter to get the desired results'.tr,
                        style: tutoTextStyle
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
    ///total
    targets.add(
      TargetFocus(
        identify: "totalKey",
        keyTarget: totalKey,
        shape: ShapeLightFocus.RRect,
        paddingFocus: 0,


        contents: [
          TargetContent(
            align: ContentAlign.top,
            builder: (context, controller) {
              return Container(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'This value indicates the total amount of money that was disbursed'.tr,
                      style: tutoTextStyle,
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    ); 
    ///balance
    targets.add(
      TargetFocus(
        identify: "balanceKey",
        keyTarget: balanceKey,
        shape: ShapeLightFocus.RRect,
        paddingFocus: 5,


        contents: [
          TargetContent(
            align: ContentAlign.bottom,
            builder: (context, controller) {
              return Container(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'while this value indicates the available balance of money on your payment card'.tr,
                      style: tutoTextStyle,
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );





    return targets;
  }










}
