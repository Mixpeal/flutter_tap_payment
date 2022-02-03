import 'package:flutter/material.dart';
import 'package:flutter_tap_payment/src/errors/network_error.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';

import '../TapServices.dart';

class CompletePayment extends StatefulWidget {
  final Function onSuccess, onError;
  final TapServices services;
  final String url;
  const CompletePayment({
    Key? key,
    required this.onSuccess,
    required this.onError,
    required this.services,
    required this.url,
  }) : super(key: key);

  @override
  _CompletePaymentState createState() => _CompletePaymentState();
}

class _CompletePaymentState extends State<CompletePayment> {
  bool loading = true;
  bool loadingError = false;

  String getMessage(data) {
    String message = "";
    switch (data['status']) {
      case "CAPTURED":
        message = "The transaction completed successfully";
        break;
      case "ABANDONED":
        message = "The transaction has been abandoned";
        break;
      case "CANCELLED":
        message = "The transaction has been cancelled";
        break;
      case "FAILED":
        message = "The transaction has failed";
        break;
      case "DECLINED":
        message = "The transaction has been declined";
        break;
      case "RESTRICTED":
        message = "The transaction is restricted";
        break;
      case "VOID":
        message = "The transaction is voided";
        break;
      case "TIMEDOUT":
        message = "The transaction is timedout";
        break;
      case "UNKNOWN":
        message = "The transaction is unknown";
        break;
      default:
        message = "The transaction cannot be completed";
    }
    return message;
  }

  complete() async {
    final uri = Uri.parse(widget.url);
    final tapID = uri.queryParameters['tap_id'];
    if (tapID != null) {
      setState(() {
        loading = true;
        loadingError = false;
      });

      Map resp = await widget.services.confirmPayment(tapID);
      if (resp['error'] == false) {
        if (resp['data']?['status'] == "CAPTURED") {
          Map data = resp['data'];
          data['message'] = getMessage(resp['data']);
          await widget.onSuccess(data);
          setState(() {
            loading = false;
            loadingError = false;
          });
          Navigator.pop(context);
        } else {
          Map data = resp['data'];
          data['message'] = getMessage(resp['data']);
          widget.onError(data);
          setState(() {
            loading = false;
            loadingError = false;
          });
          Navigator.pop(context);
        }
      } else {
        if (resp['exception'] != null && resp['exception'] == true) {
          widget.onError({"message": resp['message']});
          setState(() {
            loading = false;
            loadingError = true;
          });
        } else {
          await widget.onError(resp['data']);
          Navigator.of(context).pop();
        }
      }
      //return NavigationDecision.prevent;
    } else {
      Navigator.of(context).pop();
    }
  }

  @override
  void initState() {
    super.initState();
    complete();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        child: loading
            ? Column(
                children: const [
                  Expanded(
                    child: Center(
                      child: SpinKitFadingCube(
                        color: Color(0xFFEB920D),
                        size: 30.0,
                      ),
                    ),
                  ),
                ],
              )
            : loadingError
                ? Column(
                    children: [
                      Expanded(
                        child: Center(
                          child: NetworkError(
                              loadData: complete,
                              message: "Something went wrong,"),
                        ),
                      ),
                    ],
                  )
                : const Center(
                    child: Text("Payment Completed"),
                  ),
      ),
    );
  }
}
