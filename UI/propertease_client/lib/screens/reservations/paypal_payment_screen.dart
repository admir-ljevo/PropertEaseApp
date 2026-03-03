import 'package:flutter/material.dart';
import 'package:flutter_paypal/flutter_paypal.dart';

class PayPalScreen extends StatefulWidget {
  double? totalPrice;

  PayPalScreen({super.key, this.totalPrice});

  @override
  _PayPalScreenState createState() => _PayPalScreenState();
}

class _PayPalScreenState extends State<PayPalScreen> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text("Payment"),
        ),
        body: Center(
          child: TextButton(
              onPressed: () => {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (BuildContext context) => UsePaypal(
                            sandboxMode: true,
                            clientId:
                                "Aa4UrYVUFKfSX4ycInfeVySsTt_WlnUkLJeM6De_prYj_X3vNOGLV0X8GNNc5rn0f-_g6h_3XrGm4FOT",
                            secretKey:
                                "EHnPNKulzJhrWUG7eDCx1Gs4UPntxq-QXeqAeUkuQLTwcVocqWVA0sLKTG7NKRiK7YmrfNPO84Yklq1v",
                            returnURL: "success.snippetcoder.com",
                            cancelURL: "https://sampleSite.com",
                            transactions: [
                              {
                                "amount": {
                                  "total": widget.totalPrice!.toString(),
                                  "currency": "USD",
                                  "details": {
                                    "subtotal": widget.totalPrice!.toString(),
                                    "shipping": '0',
                                    "shipping_discount": 0
                                  }
                                },
                                "description":
                                    "The payment transaction description.",
                                // "payment_options": {
                                //   "allowed_payment_method":
                                //       "INSTANT_FUNDING_SOURCE"
                                // },
                                "item_list": {
                                  "items": [
                                    {
                                      "name": "A demo product",
                                      "quantity": 1,
                                      "price": widget.totalPrice!.toString(),
                                      "currency": "USD"
                                    }
                                  ],

                                  // shipping address is not required though
                                  // "shipping_address": {
                                  //   "recipient_name": "Jane Foster",
                                  //   "line1": "Travis County",
                                  //   "line2": "",
                                  //   "city": "Austin",
                                  //   "country_code": "US",
                                  //   "postal_code": "73301",
                                  //   "phone": "+00000000",
                                  //   "state": "Texas"
                                  // },
                                }
                              }
                            ],
                            note: "Contact us for any questions on your order.",
                            onSuccess: (Map params) async {
                              print("onSuccess: $params");
                            },
                            onError: (error) {
                              print("onError: $error");
                            },
                            onCancel: (params) {
                              print('cancelled: $params');
                            }),
                      ),
                    )
                  },
              child: const Text("Make Payment")),
        ));
  }
}
