import 'dart:async';
import 'package:flutter/material.dart';
import 'package:edenvidi_payment/edenvidi_payment.dart';

void main() => runApp(new MyApp());

class MyApp extends StatefulWidget {
	@override
	_MyAppState createState() => new _MyAppState();
}

class _MyAppState extends State<MyApp> {
	bool isMakePayment = false;
	@override
	void initState() {
		super.initState();
		EdenvidiPayment.instance.init("SB-Mid-client-nxIV6qUGgjz-1ACh", "https://edenvidiapi.herokuapp.com");
		EdenvidiPayment.instance.setTransactionFinishedCallback(_callback);
	}
	
	_makePayment() {
		setState(() {
			isMakePayment = true;
		});
		EdenvidiPayment.instance.makePayment(
			MidtransTransaction(
				transaction_id: new DateTime.now().toString(),
				user_id: '42fd18bd-76c0-4f71-875f-2f8b4c3b76ba',
				total: 14000,
				customer: new MidtransCustomer("abc", "def", "abcdef@abcdef.com", "08235847489"),
				items: [ new MidtransItem("abc", 7000, 2, "Ale-ale") ],
				skip_customer_details_page: true,
			)
		).catchError((err) => print("ERROR $err"));
	}
	
	Future<void> _callback(TransactionFinished finished) async {
		setState(() {
			isMakePayment = false;
		});
		return Future.value(null);
	}
	
	@override
	Widget build(BuildContext context) {
		return new MaterialApp(
			home: new Scaffold(
				appBar: new AppBar(
					title: const Text('Plugin example app'),
				),
				body: new Center(
					child: isMakePayment
							? CircularProgressIndicator()
							: RaisedButton(
						child: Text("Make Payment"),
						onPressed: () => _makePayment(),
					),
				),
			),
		);
	}
}