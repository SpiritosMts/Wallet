

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:wallet/manager/tutoCtr.dart';

class GetxBinding implements Bindings {
  @override
  void dependencies() {


    //tuto
    Get.lazyPut<TutoController>(() => TutoController(),fenix: true);


    //print("## getx dependency injection completed (Get.put() )");

  }
}