library flutter_tap_payment;

import 'dart:async';
import 'dart:core';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_tap_payment/src/screens/complete_payment.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:webview_flutter/webview_flutter.dart';

import 'src/TapServices.dart';
import 'src/errors/network_error.dart';

class TapPayment extends StatefulWidget {
  final Function onSuccess, onError;
  final String apiKey, redirectUrl, postUrl;
  final Map paymentData;

  const TapPayment({
    Key? key,
    required this.onSuccess,
    required this.onError,
    //
    required this.apiKey,
    required this.redirectUrl,
    required this.postUrl,
    required this.paymentData,
  }) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return TapPaymentState();
  }
}

class TapPaymentState extends State<TapPayment> {
  final Completer<WebViewController> _controller =
      Completer<WebViewController>();
  String checkoutUrl = '';
  String navUrl = '';
  bool loading = true;
  bool pageloading = true;
  bool loadingError = false;
  late TapServices services;
  int pressed = 0;

  loadPayment() async {
    setState(() {
      loading = true;
    });
    try {
      Map getPayment = await services.sendPayment();
      if (getPayment['message']?['transaction']?["url"] != null) {
        setState(() {
          checkoutUrl = getPayment['message']['transaction']["url"].toString();
          navUrl = getPayment['message']['transaction']["url"].toString();
          loading = false;
          pageloading = false;
          loadingError = false;
        });
      } else {
        widget.onError(getPayment);
        setState(() {
          loading = false;
          pageloading = false;
          loadingError = true;
        });
      }
    } catch (e) {
      widget.onError(e);
      setState(() {
        loading = false;
        pageloading = false;
        loadingError = true;
      });
    }
  }

  JavascriptChannel _toasterJavascriptChannel(BuildContext context) {
    return JavascriptChannel(
        name: 'Toaster',
        onMessageReceived: (JavascriptMessage message) {
          widget.onError(message.message);
        });
  }

  @override
  void initState() {
    super.initState();
    services =
        TapServices(apiKey: widget.apiKey, paymentData: widget.paymentData);
    setState(() {
      navUrl = 'checkout.payments.tap.company';
    });
    // Enable hybrid composition.
    if (Platform.isAndroid) WebView.platform = SurfaceAndroidWebView();
    loadPayment();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        if (pressed < 2) {
          setState(() {
            pressed++;
          });
          final snackBar = SnackBar(
              content: Text(
                  'Press back ${3 - pressed} more times to cancel transaction'));
          ScaffoldMessenger.of(context).showSnackBar(snackBar);
          return false;
        } else {
          return true;
        }
      },
      child: Scaffold(
          appBar: AppBar(
            backgroundColor: const Color(0xFF272727),
            leading: GestureDetector(
              child: const Icon(Icons.arrow_back_ios),
              onTap: () => Navigator.pop(context),
            ),
            title: Row(
              children: [
                Expanded(
                    child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(20)),
                  child: Row(
                    children: [
                      Icon(
                        Icons.lock_outline,
                        color: Uri.parse(navUrl).hasScheme
                            ? Colors.green
                            : Colors.blue,
                        size: 18,
                      ),
                      const SizedBox(width: 5),
                      Expanded(
                        child: Text(
                          navUrl,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 14),
                        ),
                      ),
                      SizedBox(width: pageloading ? 5 : 0),
                      pageloading
                          ? const SpinKitFadingCube(
                              color: Color(0xFFEB920D),
                              size: 10.0,
                            )
                          : const SizedBox()
                    ],
                  ),
                ))
              ],
            ),
            elevation: 0,
          ),
          body: SizedBox(
            height: MediaQuery.of(context).size.height,
            width: MediaQuery.of(context).size.width,
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
                                  loadData: loadPayment,
                                  message: "Something went wrong,"),
                            ),
                          ),
                        ],
                      )
                    : Column(
                        children: [
                          Expanded(
                            child: WebView(
                              initialUrl: checkoutUrl,
                              javascriptMode: JavascriptMode.unrestricted,
                              gestureNavigationEnabled: true,
                              onWebViewCreated:
                                  (WebViewController webViewController) {
                                _controller.complete(webViewController);
                              },
                              javascriptChannels: <JavascriptChannel>[
                                _toasterJavascriptChannel(context),
                              ].toSet(),
                              navigationDelegate:
                                  (NavigationRequest request) async {
                                if (request.url
                                    .startsWith('https://www.youtube.com/')) {
                                  return NavigationDecision.prevent;
                                }
                                if (request.url.contains(widget.redirectUrl)) {
                                  final uri = Uri.parse(request.url);
                                  print("Got back: ${uri.queryParameters}");
                                  Navigator.pushReplacement(
                                    context,
                                    MaterialPageRoute(
                                        builder: (context) => CompletePayment(
                                            url: request.url,
                                            services: services,
                                            onSuccess: widget.onSuccess,
                                            onError: widget.onError)),
                                  );
                                }
                                return NavigationDecision.navigate;
                              },
                              onPageStarted: (String url) {
                                setState(() {
                                  pageloading = true;
                                  loadingError = false;
                                });
                              },
                              onPageFinished: (String url) {
                                setState(() {
                                  navUrl = url;
                                  pageloading = false;
                                });
                              },
                            ),
                          ),
                        ],
                      ),
          )),
    );
  }
}
