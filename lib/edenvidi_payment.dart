import 'dart:async';
import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:meta/meta.dart';

typedef Future<void> TransactionFinishedCallback(TransactionFinished transactionFinished);

class EdenvidiPayment {
	TransactionFinishedCallback _transactionFinishedCallback;
	static const MethodChannel _channel = const MethodChannel('com.edenvidi.payment');
	static EdenvidiPayment _instance = EdenvidiPayment._internal();
	static get instance => _instance;
	static Future<String> get platformVersion async {
		final String version = await _channel.invokeMethod('getPlatformVersion');
		return version;
	}
	EdenvidiPayment._internal() {
		_channel.setMethodCallHandler( ( MethodCall call ) async {
			if ( call.method == "onTransactionFinished" ) {
				if ( _transactionFinishedCallback == null ) return null;
				await _transactionFinishedCallback(
					new TransactionFinished(
						transaction_canceled: call.arguments["transaction_cancelled"],
						status: call.arguments["status"],
						source: call.arguments["source"],
						status_message: call.arguments["status_message"],
						response: call.arguments["response"],
					),
				);
			}
			return null;
		});
	}
	
	void setTransactionFinishedCallback( TransactionFinishedCallback callback ) => _transactionFinishedCallback = callback;
	
	Future<void> init(String client_key, String base_url) async {
		await _channel.invokeMethod("init", {
			"client_key": client_key,
			"base_url": base_url,
		});
	}
	
	Future<void> makePayment( MidtransTransaction transaction ) async => await _channel.invokeMethod("makePayment", json.encode( transaction.toJson() ));
}

class MidtransCustomer {
	final String first_name;
	final String last_name;
	final String email;
	final String phone;
	MidtransCustomer(this.first_name, this.last_name, this.email, this.phone);
	MidtransCustomer.fromJson(Map<String, dynamic> json)
			: first_name = json["first_name"],
				last_name = json["last_name"],
				email = json["email"],
				phone = json["phone"];
	Map<String, dynamic> toJson() {
		return {
			"first_name": first_name,
			"last_name": last_name,
			"email": email,
			"phone": phone,
		};
	}
}

class MidtransItem {
	final String id;
	final int price;
	final int quantity;
	final String name;
	MidtransItem(this.id, this.price, this.quantity, this.name);
	MidtransItem.fromJson(Map<String, dynamic> json)
			: id = json["id"],
				price = json["price"],
				quantity = json["quantity"],
				name = json["name"];
	Map<String, dynamic> toJson() {
		return {
			"id": id,
			"price": price,
			"quantity": quantity,
			"name": name,
		};
	}
}

class MidtransTransaction {
	final String transaction_id, user_id;
	final int total;
	final MidtransCustomer customer;
	final List<MidtransItem> items;
	final bool skip_customer_details_page, show_email_in_cc_form, auto_read_sms,
			enable_animation, save_card_checked, show_payment_status;
	MidtransTransaction({
		@required this.transaction_id,
		@required this.user_id,
		@required this.total,
		@required this.customer,
		@required this.items,
		this.skip_customer_details_page = true,
		this.show_email_in_cc_form,
		this.auto_read_sms,
		this.enable_animation = true,
		this.save_card_checked,
		this.show_payment_status,
	});
	Map<String, dynamic> toJson() {
		final data = {
			"transaction_id": transaction_id,
			"user_id": user_id,
			"total": total,
			"skip_customer": skip_customer_details_page,
			"enable_animation": enable_animation,
			"items": items.map((v) => v.toJson()).toList(),
			"customer": customer.toJson(),
		};
		if ( skip_customer_details_page != null ) data["skip_customer_details_page"] = skip_customer_details_page;
		if ( show_email_in_cc_form != null ) data["show_email_in_cc_form"] = show_email_in_cc_form;
		if ( auto_read_sms != null ) data["auto_read_sms"] = auto_read_sms;
		if ( save_card_checked != null ) data["save_card_checked"] = save_card_checked;
		if ( show_payment_status != null ) data["show_payment_status"] = show_payment_status;
		return data;
	}
}

class TransactionFinished {
	final bool transaction_canceled;
	final String status;
	final String source;
	final String status_message;
	final String response;
	TransactionFinished({ this.transaction_canceled, this.status, this.source, this.status_message, this.response });
}
