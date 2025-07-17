#  Nuvei SimplyConnect SDK
## Requirements
| Platform | Minimum Swift Version | Installation |
| --- | --- | --- |
| iOS 15.0+ | 5.10 | [Swift Package Manager](#swift-package-manager), [Manual](#manually) |

## Installation

### Swift Package Manager

The [Swift Package Manager](https://swift.org/package-manager/) is a tool for automating the distribution of Swift code and is integrated into the `swift` compiler. 

Once you have your Swift project set up, adding NuveiSimplyConnectSDK as a dependency is as easy as adding it to the `dependencies` value of your `Package.swift`. Then you can choose which module you want to add(one or more). 

```swift
dependencies: [
	.package(url: "https://github.com/Nuvei/nuvei-mobile-simply-connect-ios.git", .upToNextMajor(from: "2.0.0"))
]
```

## Documentation
You can Option+Click on the methods and properties to view documentation.

## How to use?
```swift
let amount: String
let currency: String
let userTokenId: String
let merchantId: String
let merchantSiteId: String
let secret: String

let clientRequestId = UUID().uuidString.lowercased()

let dateFormatter = DateFormatter()
dateFormatter.locale = Locale(identifier: "en_US_POSIX")
dateFormatter.dateFormat = "yyyyMMddHHmmss"
let timeStamp = dateFormatter.string(from: Date())

let checksum: String = getCheckSum(
	amount: amount,
	currency: currency,
	merchantId: merchantId,
	merchantSiteId: merchantSiteId,
	clientRequestId: clientRequestId,
	timeStamp: timeStamp,
	secret: secret
)

let parameters: [String: Any] = [
	"amount": amount,
	"currency": currency,
	"userTokenId": userTokenId,
	"merchantId": merchantId,
	"merchantSiteId": merchantSiteId,
	"secret": secret,
	"clientRequestId": clientRequestId,
	"timeStamp": timeStamp,
	"checksum": checksum,
	"items": [[
		"price": amount,
		"quantity": "1",
		"name": "Test"
		]],
	"billingAddress": [
		"country": Locale.current.regionCode?.uppercased() ?? "US",
		"email": userTokenId
	]
]

Alamofire.Session.default
	.request("\(NuveiSimplyConnect.getEnvBaseUrl())openOrder.do", method: .post, parameters: parameters, encodingJSONEncoding.default)
	.responseJSON(queue: .main, options: []) { [weak self] (response) in
		var responseJson : JSON?
		switch response.result {
		case .success:
			// do something
		case .failure(let error):
			// handle error
		}
}


func getCheckSum(
    amount: String,
    currency: String,
    merchantId: String,
    merchantSiteId: String,
    clientRequestId: String,
    timeStamp: String,
    secret: String
    ) -> String {
    
    let string = "\(merchantId)\(merchantSiteId)\(clientRequestId)\(amount)\(currency)\(timeStamp)\(secret)"
    let byteData = sha256(data: string.data(using: .utf8)!)
    
    let hash = NSMutableString()
    for i in 0..<byteData.count {
        hash.appendFormat("%02x", byteData[i])
    }
    return hash as String
}

func sha256(data: Data) -> Data {
    var digest = Data(count: Int(CC_SHA256_DIGEST_LENGTH))
    
    _ = digest.withUnsafeMutableBytes { (digestBytes) in
        data.withUnsafeBytes { (stringBytes) in
            CC_SHA256(stringBytes, CC_LONG(data.count), digestBytes)
        }
    }
    return digest
}
```

To start payment process first you have to create HTTP request openOrder.do. In the example we use Alamofire but you can use whatevere you want. Check if the response has a session token and in this case proceed with the payment flow you want.

### ApplePay
```swift
NuveiSimplyConnect.setup(environment: {NuveiSimplyConnect.Environment})
```
With NuveiSimplyConnect.setup(environment:customization:) you setup the enviroment.

---

```swift
let applePayButton = ApplePayButton(uiOwner: {ViewController}, input: {Input}, auth3dSupported: {Auth3dSupported}, forceWebChallenge: {ForceWebChallenge}, delegate: delegate)
```
This creates instance of `ApplePayButton` pointing to its parent viewController. Auth3dSupported tells if the proccess will go through additional 3d authentication which in most case is unnecessary. You should also pass an object confirming to the `ApplePayDelegate` protocol. The `ApplePayDelegate` protocol defines one method `onSubmitResponse(response:)` that is called when the payment proccess finish either successfully or with an error and will give you the result.

### Fields

```swift
let customization = NuveiFieldCustomization()
let i18n = FieldsI18n()
NuveiFields.setup(environment: {NuveiSimplyConnect.Environment},customization: customization, i18n: i18n,transactionDetails: transactionDetails)
```

This creates instance of `NuveiFieldCustomization` with your own customization preferences.

This creates instance of `FieldsI18n` with your own localized texts. You can initialize it with the properties and text you want to modify.

You should also pass a `CheckoutTransactionDetails` object which you can create from `NVInput` object.

---

```swift
do {
    creditCardField = try NuveiFields.createCreditCardField()
    creditCardField?.onInputUpdated = {}
    creditCardField?.onInputValidated = {}
	creditCardField?.onCardDetailsUpdated = {
		creditCardField?.showCardNumberError(message: {ERROR_MESSAGE})
	}
} catch {
    // handle error
}
```
This creates instance of `NuveiCreditCardField`.

OnInputUpdated is callback that tells you when a field text is modified and when it loses focus.

OnInputValidated is callback that gives you list of error if there is any after validation of a field.

OnCardDetailsUpdated is callback that gives you detailed information about the card after the card number is valid. Then based on your requirements you can call `creditCardField.showCardNumberError(message:)` and your error message will be shown under the card number field.

---

```swift
creditCardField?.validate { result, error in
	// do something
}
creditCardField?.tokenize() { result, error in
	// do something
}
creditCardField?.createPayment(viewController: {ViewController}) { output in
	// do something
} declineFallbackDecision: { [weak self] output, viewController, completion in
	// do something
}
```
Validate method will validate the card filled in the fields. The closure tells you whether the validation was successful or there was some error.

Tokenize method will create token with which you can create payment. In the closure you can get the token or handle an error if there is so.

CreditCardField.createPayment method will create payment with the card that the user have filled in. The callback tells you when the proccess is finished either successfully or with an error. DeclineFallbackDecision tells you when there is an error.

---

```swift
let paymentOption = try? NVPaymentOption(card: NVCardDetails(ccTempToken: {TOKEN}, cardHolderName: {NAME}))
NuveiFields.createPayment(uiOwner: {ViewController}, input: {Input}) { output in
	// do something
}
```

NuveiFields.createPayment will create payment with a token. For this method you don't need the fields. You have to pass an object of type `NVInput` in which you have to put the token and optionally the card holder name. The closure tells wheter the payment was successful or there was some error.

### SimplyConnect 
```swift
let customization = NuveiUICustomization(logo: {Your logo},toolbarCustomization: {NuveiToolbarCustomization},labelCustomization: {NuveiLabelCustomization},textBoxCustomization: {NuveiTextBoxCustomization})
NuveiSimplyConnect.setup(environment: {NuveiSimplyConnect.Environment}, customization: customization)
```
This creates instance of `NuveiUICustomization` with your own customization preferences.

With NuveiSimplyConnect.setup(environment:customization:) you setup the enviroment and the customization. You can pass empty customization NuveiUICustomization().

---

```swift
NuveiSimplyConnect.authenticate3d(uiOwner: {ViewController}, input: {Input}, additionalParams: {AdditionalParams}, forceWebChallenge: {ForceWebChallenge}) { output in
	// do something
}
NuveiSimplyConnect.createPayment(uiOwner: {ViewController}, input: {Input}, additionalParams: {AdditionalParams}, forceWebChallenge: {ForceWebChallenge}) { output in
	// do something
}
```
Authenticate3d will authenticate a payment. For uiOwner you have to pass the presenting view controller. For input you must create instance of `NVInput` with the payment data.

CreatePayment will make a payment. For uiOwner you have to pass the presenting view controller. For input you must create instance of `NVInput` with the payment data.

---

```swift
let installment = Installment(options: {Options}, isNationalIdRequired: {IsNationalIdRequired}, countryCode: {CountryCode})
let i18n = CheckoutI18n()
NuveiSimplyConnect.checkout(uiOwner: {ViewController}, authenticate3dInput: {Input}, additionalParams: {AdditionalParams}, installment: installment, i18n: i18n, forceWebChallenge: {ForceWebChallenge},
	callback: { output in
		// do something
	},
	declineFallbackDecision: { output, viewController, completion in
		// do something
	}
)
```

This creates instance of `Installment` with installment options. You can choose which options you will add. If the option is not `SINGLE_PAYMENT` you have to pass list of periods from which the user can choose. You can choose if the national id is required. It depends on the country code. Country codes that we support national id are AR, BR, CL, PE, CO, MX, PY, UY, IL. It is optional.

This creates instance of `CheckoutI18n` with your own localized texts. You can initialize it with the properties and text you want to modify.

Checkout will load a screen with saved cards and other payment options so the uiOwner must be the presenting view controller. For input you must create instance of `NVInput` with the payment data. The callback tells you when the proccess is finished either successfully or with an error. DeclineFallbackDecision tells you when there is an error.
