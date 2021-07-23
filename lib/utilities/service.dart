import 'package:http/http.dart' as http;
import 'dart:convert';

var header = {'Content-Type': 'application/json'};

// Future<dynamic> httpClientPost(uri, body) async {
//   try {
//     var client = http.Client();
//     var url = Uri.parse(uri);
//     http.Response response =
//         await client.post(url, headers: header, body: jsonEncode(body));
//     var result = jsonDecode(response.body);
//     client.close();
//     if (result['data'] != null) {
//       return AuthModel.fromJson(result['data']);
//     } else {
//       return null;
//     }
//   } catch (error) {
//     print(error);
//   }
// }

Future<dynamic> httpPost(uri, body) async {
  try {
    http.Response response = await http.post(
      Uri.parse(uri),
      headers: header,
      body: jsonEncode(body),
    );
    if (response.body.isNotEmpty) {
      return jsonDecode(response.body);
    } else {
      return null;
    }
  } catch (error) {
    return error;
  }
}
