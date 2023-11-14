// ignore_for_file: file_names
import 'dart:convert';

import 'package:http/http.dart' as http;

class TapServices {
  final String apiKey;
  final Map<String,dynamic> paymentData;
  String basePath = "https://api.tap.company/";
  String version = "v2";
  TapServices({required this.apiKey, required this.paymentData});
  Future<Map<String, dynamic>> sendPayment() async {
    Uri domain = Uri.parse("$basePath$version/charges/");
    try {
      final headers = {
        'Authorization': 'Bearer $apiKey',
        'accept': 'application/json',
        'content-type': 'application/json',
      };
      var data = jsonEncode(paymentData);
      final response = await http.post(domain, headers: headers, body: data);
      final status = response.statusCode;
      var body = json.decode(response.body);
      if (status == 200) {
        // debugPrint("STATUS CODE: $status");
        // debugPrint("$body");
        return {'error': false, 'message': response.body};
      } else {
        // debugPrint(body);
        return {
          'error': true,
          'message': "${body["errors"]?[0]?["description"]}"
        };
      }
    } catch (e) {
      // debugPrint("$e");
      return {
        'error': true,
        'message': "Unable to proceed, check your internet connection."
      };
    }
  }

  confirmPayment(tapId) async {
    String domain = "$basePath$version/charges/$tapId";
    try {
      var response = await http.get(Uri.parse(domain), headers: {
        "content-type": "application/json",
        'Authorization': 'Bearer $apiKey'
      });
      final body = jsonDecode(response.body);
      if (response.statusCode == 200) {
        return {'error': false, 'message': "Confirmed", 'data': body};
      } else {
        return {
          'error': true,
          'message': "Payment inconclusive.",
          'data': body
        };
      }
    } catch (e) {
      return {'error': true, 'message': e, 'exception': true, 'data': null};
    }
  }
}
