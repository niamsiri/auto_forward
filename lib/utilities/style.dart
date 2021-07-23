import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';

class MyStyle {
  Color primaryColor = Color(0xff0275d8);
  Color darkColor = Color(0xff292b2c);
  Color greyColor = Color(0xff6c757d);

  Widget showLogo() => Image.asset("assets/images/logo.png");
  Widget showImgSms() => Image.asset("assets/images/sms.png");

  toast(msg) {
    Fluttertoast.showToast(
      msg: msg,
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.CENTER,
      timeInSecForIosWeb: 1,
      backgroundColor: Colors.red,
      textColor: Colors.white,
      fontSize: 16.0,
    );
  }
}
