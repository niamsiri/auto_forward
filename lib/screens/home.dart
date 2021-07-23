import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:wakelock/wakelock.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:telephony/telephony.dart';

import 'package:auto_forward/utilities/style.dart';
import 'package:auto_forward/utilities/service.dart';

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final Telephony telephony = Telephony.instance;

  double screen = 0;
  bool? started = false;
  bool? statusPermissionSms;
  bool? statusPermissionPhone;

  String? urlError = "http://13.229.117.195";
  String? urlPost = "";
  String? seq = "";

  final inputPrefixController = TextEditingController();

  @override
  void initState() {
    Wakelock.enable();
    setRequestPermission();
    super.initState();
  }

  @override
  void dispose() {
    Wakelock.disable();
    inputPrefixController.dispose();
    super.dispose();
  }

  setRequestPermission() async {
    setState(() async {
      statusPermissionSms = await telephony.requestSmsPermissions;
      statusPermissionPhone = await telephony.requestPhonePermissions;
    });
  }

  setSharedPreferences(url, seq) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setString("urlPost", url);
    prefs.setString("seq", seq);
  }

  getSharedPreferences() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      urlPost = prefs.getString("urlPost");
      seq = prefs.getString("seq");
    });
  }

  setBodyLogin() {
    var map = new Map<String, dynamic>();
    map['prefixkey'] = inputPrefixController.text;
    // map['prefixkey'] = "ZG0y1";
    return map;
  }

  setRequestReciveSms(SmsMessage message) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? seq = prefs.getString("seq");
    var map = new Map<String, dynamic>();
    map['ID'] = "0";
    map['TextDecoded'] = message.body;
    map['ReceivingDateTime'] = message.date;
    map['Read'] = message.read;
    map['Seen'] = message.seen;
    map['Subject'] = message.subject;
    map['SenderNumber'] = message.address;
    map['SMSCNumber'] = "ลำดับที่ " + seq!;
    return map;
  }

  setRequestError(error) {
    var map = new Map<String, dynamic>();
    map['urlpost'] = urlPost;
    map['error'] = error;
    return map;
  }

  onSmsStart() {
    try {
      EasyLoading.show(status: 'กำลังโหลด...');
      Future.delayed(const Duration(milliseconds: 500), () async {
        var formData = setBodyLogin();
        var uri = "https://smsbox.bigwin.cloud/logininfo.php";
        var result = await httpPost(uri, formData);
        if (result['data'] == null) {
          EasyLoading.showError('Prefix key ไม่ถูกต้อง');
        } else {
          MyStyle().toast('เริ่มทำงาน');
          await setSharedPreferences(
              result['data']['urlpost'], result['data']['seq']);
          await getSharedPreferences();
          onListenSms();
        }
        EasyLoading.dismiss();
      });
    } catch (error) {
      EasyLoading.dismiss();
      print(error);
    }
  }

  void onStopStart() {
    EasyLoading.show(status: 'กำลังโหลด...');
    Future.delayed(const Duration(milliseconds: 500), () async {
      await setSharedPreferences("", "");
      setState(() => urlPost = "");
      EasyLoading.dismiss();
      MyStyle().toast('หยุดทำงาน');
    });
  }

  void onListenSms() async {
    if (urlPost != "") {
      telephony.listenIncomingSms(
        onNewMessage: onMessageHandler,
        onBackgroundMessage: onBackgroundMessageHandler,
      );
    } else {
      MyStyle().toast("ไม่พบ url กรุณากดเริ่มใหม่อีกครั้ง");
    }
  }

  onMessageHandler(SmsMessage message) async {
    try {
      httpPost(urlPost, setRequestReciveSms(message));
    } catch (error) {
      httpPost(urlError, setRequestError(error));
    }
  }

  onBackgroundMessageHandler(SmsMessage message) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    var uri = prefs.getString("urlPost");
    var seq = prefs.getString("seq");

    try {
      var formMessage = new Map<String, dynamic>();
      formMessage['ID'] = "0";
      formMessage['TextDecoded'] = message.body;
      formMessage['ReceivingDateTime'] = message.date;
      formMessage['Read'] = message.read;
      formMessage['Seen'] = message.seen;
      formMessage['Subject'] = message.subject;
      formMessage['SenderNumber'] = message.address;
      formMessage['SMSCNumber'] = "ลำดับที่ " + seq.toString();
      httpPost(uri, formMessage);
    } catch (error) {
      var formError = new Map<String, dynamic>();
      formError['urlpost'] = uri;
      formError['error'] = error;
      httpPost(uri, formError);
    }
  }

  @override
  Widget build(BuildContext context) {
    screen = MediaQuery.of(context).size.width;
    return Scaffold(
      floatingActionButton: buildAppVersion(),
      backgroundColor: Colors.white,
      body: Stack(
        children: <Widget>[
          Container(
            height: 400,
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/images/background.png'),
                fit: BoxFit.fill,
              ),
            ),
          ),
          Center(
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.max,
                children: [
                  buildLogo(),
                  buildTextTitle("กรอก Prefix key เพื่อเริ่มทำงาน"),
                  buildInputPrefix(),
                  buildButton()
                ],
              ),
            ),
          )
        ],
      ),
    );
  }

  Text buildAppVersion() {
    return Text(
      "Version 1.0.7",
      style: TextStyle(
        color: Colors.black87,
      ),
    );
  }

  Visibility buildButton() {
    return Visibility(
      child: Container(
        margin: EdgeInsets.only(top: 10),
        width: (screen * 0.9),
        child: ElevatedButton(
          onPressed: () => urlPost == "" ? onSmsStart() : onStopStart(),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Icon(
                urlPost == "" ? Icons.play_arrow : Icons.stop,
              ),
              Text(
                urlPost == "" ? "เริ่ม" : "หยุด",
                style: TextStyle(
                  fontSize: 18,
                ),
              ),
            ],
          ),
          style: ElevatedButton.styleFrom(
            padding: EdgeInsets.all(10),
            primary: urlPost == "" ? MyStyle().primaryColor : Colors.black87,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ),
      ),
    );
  }

  Container buildLogo() {
    return Container(
      width: (screen * 0.5),
      child: MyStyle().showImgSms(),
    );
  }

  Container buildTextTitle(title) {
    return Container(
      margin: EdgeInsets.only(top: 14),
      child: Text(
        urlPost == ""
            ? "กรอก Prefix key เพื่อเริ่มทำงาน"
            : "กดหยุดเพื่อหยุดการทำงาน",
        style: TextStyle(
          fontSize: 17,
          color: Colors.black87,
        ),
      ),
    );
  }

  Visibility buildInputPrefix() {
    return Visibility(
      visible: urlPost == "" ? true : false,
      child: Container(
        margin: EdgeInsets.only(top: 6),
        width: (screen * 0.9),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Center(
          child: Material(
            shadowColor: Colors.black,
            elevation: 20.0,
            borderRadius: BorderRadius.circular(10),
            child: TextField(
              controller: inputPrefixController,
              obscureText: false,
              style: TextStyle(color: Colors.black),
              decoration: InputDecoration(
                contentPadding: EdgeInsets.all(14),
                filled: true,
                fillColor: Colors.white,
                hintText: "Prefix key",
                hintStyle: TextStyle(
                  fontSize: 18,
                  color: MyStyle().greyColor,
                ),
                prefixIcon: Icon(
                  Icons.vpn_key,
                  color: MyStyle().primaryColor,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(
                    color: Colors.white70,
                    width: 2,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(
                    color: MyStyle().primaryColor,
                    width: 2,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
