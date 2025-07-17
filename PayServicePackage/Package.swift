// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
	name: "PayServicePackage",
	platforms: [.iOS(.v15)],
	products: [
		.library(
			name: "PayServicePackage",
			targets: ["PayService"]
		),
	],
	
	targets: [
		.binaryTarget(
			name: "PayService",
			path: "PayService.xcframework"
		)
	]
)
