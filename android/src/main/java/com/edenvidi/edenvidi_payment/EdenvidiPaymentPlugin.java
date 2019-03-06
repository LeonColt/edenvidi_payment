package com.edenvidi.edenvidi_payment;

import android.content.Intent;
import android.util.Log;

import com.midtrans.sdk.corekit.callback.TransactionFinishedCallback;
import com.midtrans.sdk.corekit.core.MidtransSDK;
import com.midtrans.sdk.corekit.core.TransactionRequest;
import com.midtrans.sdk.corekit.core.UIKitCustomSetting;
import com.midtrans.sdk.corekit.models.CustomerDetails;
import com.midtrans.sdk.corekit.models.ItemDetails;
import com.midtrans.sdk.corekit.models.snap.TransactionResult;
import com.midtrans.sdk.uikit.SdkUIFlowBuilder;
import com.midtrans.sdk.uikit.activities.UserDetailsActivity;

import org.json.JSONArray;
import org.json.JSONObject;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.Map;

import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodChannel.MethodCallHandler;
import io.flutter.plugin.common.MethodChannel.Result;
import io.flutter.plugin.common.PluginRegistry.Registrar;

/** EdenvidiPaymentPlugin */
public class EdenvidiPaymentPlugin implements MethodCallHandler {
	private final Registrar registrar;
	private final MethodChannel method_channel;

	private EdenvidiPaymentPlugin(Registrar registrar, MethodChannel method_channel) {
		this.registrar = registrar;
		this.method_channel = method_channel;
	}

	/** Plugin registration. */
	public static void registerWith(Registrar registrar) {
		final MethodChannel channel = new MethodChannel(registrar.messenger(), "com.edenvidi.payment");
		channel.setMethodCallHandler(new EdenvidiPaymentPlugin(registrar, channel));
	}
	@Override
	public void onMethodCall(MethodCall call, Result result) {
		switch (call.method) {
			case "getPlatformVersion":
				result.success("Android " + android.os.Build.VERSION.RELEASE);
				break;
			case "init":
				initMidtransSdk(call, result);
				break;
			case "makePayment":
				makePayment(call, result);
				break;
			default:
				result.notImplemented();
				break;
		}
	}
	private void initMidtransSdk( MethodCall call, Result result ) {
		final String client_key = call.argument("client_key");
		final String base_url = call.argument("base_url");
		SdkUIFlowBuilder.init()
				.setClientKey(client_key)
				.setContext(registrar.context())
				.setTransactionFinishedCallback(new TransactionFinishedCallback() {
					@Override
					public void onTransactionFinished(TransactionResult transaction_result) {
						Map<String, Object> content = new HashMap<>();
						content.put("transaction_cancelled", transaction_result.isTransactionCanceled());
						content.put("status", transaction_result.getStatus());
						content.put("source", transaction_result.getSource());
						content.put("status_message", transaction_result.getStatusMessage());
						if ( transaction_result.getResponse() == null ) content.put("response", "");
						else content.put("response", transaction_result.getResponse().getString());
						method_channel.invokeMethod("onTransactionFinished", content);
					}
				})
				.setMerchantBaseUrl(base_url)
				.enableLog(true)
				.buildSDK();
		result.success(null);
	}

	private void makePayment(MethodCall call, Result result) {
		try {
			JSONObject json = new JSONObject((String) call.arguments);
			JSONObject customer_json = json.getJSONObject("customer");
			JSONArray transacted_items = json.getJSONArray("items");

			final String order_id = json.getString("transaction_id");
			final double total = json.getDouble("total");

			TransactionRequest transaction_request = new TransactionRequest(order_id, total);

			Log.d("test", " has first name " + customer_json.has("first_name"));
			Log.d("test", customer_json.getString("first_name"));

			CustomerDetails customer_details = new CustomerDetails();
			customer_details.setFirstName(customer_json.getString("first_name"));
			customer_details.setLastName(customer_json.getString("last_name"));
			customer_details.setEmail(customer_json.getString("email"));
			customer_details.setPhone(customer_json.getString("phone"));
			transaction_request.setCustomerDetails(customer_details);

			transaction_request.setCustomField1(json.getString("user_id"));

			ArrayList<ItemDetails> items = new ArrayList<>();
			for ( int i = 0; i < transacted_items.length(); ++i ) {
				JSONObject transacted_item = transacted_items.getJSONObject(i);
				ItemDetails item = new ItemDetails(
					transacted_item.getString("id"),
					transacted_item.getDouble("price"),
					transacted_item.getInt("quantity"),
					transacted_item.getString("name")
				);
				items.add(item);
			}
			transaction_request.setItemDetails(items);

			UIKitCustomSetting setting = MidtransSDK.getInstance().getUIKitCustomSetting();

			if ( json.has("skip_customer_details_page") ) setting.setSkipCustomerDetailsPages(json.getBoolean("skip_customer_details_page"));
			if ( json.has("show_email_in_cc_form") ) setting.setShowEmailInCcForm(json.getBoolean("show_email_in_cc_form"));
			if ( json.has("auto_read_sms") ) setting.setEnableAutoReadSms( json.getBoolean("auto_read_sms") );
			if ( json.has("enable_animation") ) setting.setEnabledAnimation( json.getBoolean( "enable_animation" ) );
			if ( json.has("save_card_checked") ) setting.setSaveCardChecked( json.getBoolean("save_card_checked") );
			if ( json.has("show_payment_status") ) setting.setShowPaymentStatus( json.getBoolean("show_payment_status") );

			MidtransSDK.getInstance().setUIKitCustomSetting(setting);
			MidtransSDK.getInstance().setTransactionRequest(transaction_request);
			Intent intent = new Intent(registrar.context(), UserDetailsActivity.class);
			intent.setFlags(Intent.FLAG_ACTIVITY_NEW_TASK);
			registrar.context().startActivity(intent);
		} catch (Exception e) {
			result.error(e.getMessage(), e.getLocalizedMessage(), e);
		}

	}
}
