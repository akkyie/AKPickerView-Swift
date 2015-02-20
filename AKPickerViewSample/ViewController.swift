//
//  ViewController.swift
//  AKPickerViewSample
//
//  Created by Akio Yasui on 2/10/15.
//  Copyright (c) 2015 Akio Yasui. All rights reserved.
//

import UIKit

class ViewController: UIViewController, AKPickerViewDataSource, AKPickerViewDelegate {

	@IBOutlet var pickerView: AKPickerView!

	let titles = ["Tokyo", "Kanagawa", "Osaka", "Aichi", "Saitama", "Chiba", "Hyogo", "Hokkaido", "Fukuoka", "Shizuoka"]

	override func viewDidLoad() {
		super.viewDidLoad()
		self.pickerView.delegate = self
		self.pickerView.dataSource = self

		self.pickerView.font = UIFont(name: "HelveticaNeue-Light", size: 20)!
		self.pickerView.highlightedFont = UIFont(name: "HelveticaNeue", size: 20)!
		self.pickerView.interitemSpacing = 20.0
		self.pickerView.viewDepth = 1000.0
		self.pickerView.pickerViewStyle = .Wheel
		self.pickerView.maskDisabled = false
		self.pickerView.reloadData()
	}

	// MARK: - AKPickerViewDataSource

	func numberOfItemsInPickerView(pickerView: AKPickerView) -> Int {
		return self.titles.count
	}

	/*

	Image Support
	-------------
	Please comment '-pickerView:titleForItem:' entirely and
	uncomment '-pickerView:imageForItem:' to see how it works.

	*/
	func pickerView(pickerView: AKPickerView, titleForItem item: Int) -> String {
		return self.titles[item]
	}

	func pickerView(pickerView: AKPickerView, imageForItem item: Int) -> UIImage {
		return UIImage(named: self.titles[item])!
	}

	// MARK: - AKPickerViewDelegate

	func pickerView(pickerView: AKPickerView, didSelectItem item: Int) {
		println("Your favorite city is \(self.titles[item])")
	}

	/*

	Label Customization
	-------------------
	You can customize labels by their any properties (except for fonts,)
	and margin around text.
	These methods are optional, and ignored when using images.

	*/

	/*
	func pickerView(pickerView: AKPickerView, configureLabel label: UILabel, forItem item: Int) {
	label.textColor = UIColor.lightGrayColor()
	label.highlightedTextColor = UIColor.whiteColor()
	label.backgroundColor = UIColor(
	hue: CGFloat(item) / CGFloat(self.titles.count),
	saturation: 1.0,
	brightness: 0.5,
	alpha: 1.0)
	}

	func pickerView(pickerView: AKPickerView, marginForItem item: Int) -> CGSize {
	return CGSizeMake(40, 20)
	}
	*/

	/*

	UIScrollViewDelegate Support
	----------------------------
	AKPickerViewDelegate inherits UIScrollViewDelegate.
	You can use UIScrollViewDelegate methods
	by simply setting pickerView's delegate.

	*/

	func scrollViewDidScroll(scrollView: UIScrollView) {
		// println("\(scrollView.contentOffset.x)")
	}
	
}
