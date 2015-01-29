//
//  AKPickerView.swift
//  AKPickerView
//
//  Created by Akio Yasui on 1/29/15.
//  Copyright (c) 2015 Akkyie Y. All rights reserved.
//

import UIKit

public enum AKPickerViewStyle {
	case Wheel
	case Flat
}

@objc public protocol AKPickerViewDataSource {
	func numberOfItemsInPickerView(pickerView: AKPickerView) -> Int
	optional func pickerView(pickerView: AKPickerView, titleForItem item:Int) -> NSString
	optional func pickerView(pickerView: AKPickerView, imageForItem item:Int) -> UIImage
}

@objc public protocol AKPickerViewDelegate: UIScrollViewDelegate {
	optional func pickerView(pickerView: AKPickerView, didSelectItem item:Int)
	optional func pickerView(pickerView: AKPickerView, marginForItem item:Int) -> CGSize
	optional func pickerView(pickerView: AKPickerView, configureLabel label:UILabel, forItem item:Int)
}

private protocol AKCollectionViewLayoutDelegate {
	func pickerViewStyleForCollectionViewLayout(layout: AKCollectionViewLayout) -> AKPickerViewStyle
}

private class AKCollectionViewCell: UICollectionViewCell {
	var label: UILabel!
	var imageView: UIImageView!
	var font = UIFont.systemFontOfSize(UIFont.systemFontSize())
	var highlightedFont = UIFont.systemFontOfSize(UIFont.systemFontSize())
	var _selected: Bool = false {
		didSet(selected) {
			let animation = CATransition()
			animation.type = kCATransitionFade
			animation.duration = 0.15
			self.label.layer.addAnimation(animation, forKey: "")
			self.label.font = self.selected ? self.highlightedFont : self.font
		}
	}

	func initialize() {
		self.layer.doubleSided = false
		self.layer.shouldRasterize = true
		self.layer.rasterizationScale = UIScreen.mainScreen().scale
		self.label = UILabel(frame: self.contentView.bounds)
		self.label.backgroundColor = UIColor.clearColor()
		self.label.textAlignment = .Center
		self.label.textColor = UIColor.grayColor()
		self.label.numberOfLines = 1
		self.label.lineBreakMode = .ByTruncatingTail
		self.label.highlightedTextColor = UIColor.blackColor()
		self.label.font = self.font
		self.label.autoresizingMask =
			.FlexibleTopMargin |
			.FlexibleLeftMargin |
			.FlexibleBottomMargin |
			.FlexibleRightMargin;
		self.contentView.addSubview(self.label)

		self.imageView = UIImageView(frame: self.contentView.bounds)
		self.imageView.backgroundColor = UIColor.clearColor()
		self.imageView.contentMode = .Center
		self.imageView.autoresizingMask = .FlexibleWidth | .FlexibleHeight;
		self.contentView.addSubview(self.imageView)
	}

	override init() {
		super.init()
		self.initialize()
	}

	override init(frame: CGRect) {
		super.init(frame: frame)
		self.initialize()
	}

	required init(coder aDecoder: NSCoder) {
		super.init(coder: aDecoder)
		self.initialize()
	}
}

private class AKCollectionViewLayout: UICollectionViewFlowLayout {
	var delegate: AKCollectionViewLayoutDelegate!
	var width: CGFloat!
	var midX: CGFloat!
	var maxAngle: CGFloat!

	func initialize() {
		self.sectionInset = UIEdgeInsetsMake(0.0, 0.0, 0.0, 0.0)
		self.scrollDirection = .Horizontal
		self.minimumLineSpacing = 0.0
	}

	override init() {
		super.init()
		self.initialize()
	}

	required init(coder aDecoder: NSCoder) {
		super.init(coder: aDecoder)
		self.initialize()
	}

	private override func prepareLayout() {
		let visibleRect = CGRect(origin: self.collectionView!.contentOffset, size: self.collectionView!.bounds.size)
		self.midX = CGRectGetMidX(visibleRect);
		self.width = CGRectGetWidth(visibleRect) / 2;
		self.maxAngle = CGFloat(M_PI_2);
	}

	private override func shouldInvalidateLayoutForBoundsChange(newBounds: CGRect) -> Bool {
		return true
	}

	private override func layoutAttributesForItemAtIndexPath(indexPath: NSIndexPath) -> UICollectionViewLayoutAttributes! {
		let attributes = super.layoutAttributesForItemAtIndexPath(indexPath)
		switch self.delegate.pickerViewStyleForCollectionViewLayout(self) {
		case .Flat:
			return attributes
		case .Wheel:
			let distance = CGRectGetMidX(attributes.frame) - self.midX;
			let currentAngle = self.maxAngle * distance / self.width / CGFloat(M_PI_2);
			var transform = CATransform3DIdentity;
			transform = CATransform3DTranslate(transform, -distance, 0, -self.width);
			transform = CATransform3DRotate(transform, currentAngle, 0, 1, 0);
			transform = CATransform3DTranslate(transform, 0, 0, self.width);
			attributes.transform3D = transform;
			attributes.alpha = fabs(currentAngle) < self.maxAngle ? 1.0 : 0.0;
			return attributes;
		}
	}

	private override func layoutAttributesForElementsInRect(rect: CGRect) -> [AnyObject]? {
		switch self.delegate.pickerViewStyleForCollectionViewLayout(self) {
		case .Flat:
			return super.layoutAttributesForElementsInRect(rect)
		case .Wheel:
			var attributes = [AnyObject]()
			for i in 0 ..< self.collectionView!.numberOfItemsInSection(0) {
				let indexPath = NSIndexPath(forItem: i, inSection: 0)
				attributes.append(self.layoutAttributesForItemAtIndexPath(indexPath))
			}
			return attributes
		}
	}

}

private class AKPickerViewDelegateIntercepter: NSObject, UICollectionViewDelegate {
	var pickerView: AKPickerView
	var delegate: UIScrollViewDelegate?

	init(pickerView: AKPickerView, delegate: UIScrollViewDelegate?) {
		self.pickerView = pickerView
		self.delegate = delegate
	}

	private override func forwardingTargetForSelector(aSelector: Selector) -> AnyObject? {
		if self.pickerView.respondsToSelector(aSelector) {
			return self.pickerView
		} else if self.delegate != nil && self.delegate!.respondsToSelector(aSelector) {
			return self.delegate
		} else {
			return nil
		}
	}

	private override func respondsToSelector(aSelector: Selector) -> Bool {
		if self.pickerView.respondsToSelector(aSelector) {
			return true
		} else if self.delegate != nil && self.delegate!.respondsToSelector(aSelector) {
			return true
		} else {
			return super.respondsToSelector(aSelector)
		}
	}

}

// TODO: Make these delegate conformation private
public class AKPickerView: UIView, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, AKCollectionViewLayoutDelegate {

	// Public Properties
	var dataSource: AKPickerViewDataSource? = nil
	var delegate: AKPickerViewDelegate? = nil {
		didSet(delegate) {
			self.intercepter.delegate = delegate
		}
	}
	lazy var font = UIFont.systemFontOfSize(20)
	lazy var highlightedFont = UIFont.boldSystemFontOfSize(20)
	lazy var textColor = UIColor.darkGrayColor()
	lazy var highlightedTextColor = UIColor.blackColor()
	var interitemSpacing: CGFloat = 0.0
	var viewDepth: CGFloat = 1000.0
	var pickerViewStyle = AKPickerViewStyle.Wheel

	// Readonly Properties
	private(set) var selectedItem: Int = 0
	var contentOffset: CGPoint {
		get {
			return self.collectionView.contentOffset
		}
	}

	// Private Properties
	private var collectionView: UICollectionView!
	private var intercepter: AKPickerViewDelegateIntercepter!
	private var collectionViewLayout: AKCollectionViewLayout {
		let layout = AKCollectionViewLayout()
		layout.delegate = self
		return layout
	}

	private func initialize() {
		self.collectionView?.removeFromSuperview()
		self.collectionView = UICollectionView(frame: self.bounds, collectionViewLayout: self.collectionViewLayout)
		self.collectionView.showsHorizontalScrollIndicator = false
		self.collectionView.backgroundColor = UIColor.clearColor()
		self.collectionView.decelerationRate = UIScrollViewDecelerationRateFast
		self.collectionView.autoresizingMask = UIViewAutoresizing.FlexibleWidth | UIViewAutoresizing.FlexibleHeight
		self.collectionView.dataSource = self
		self.collectionView.registerClass(
			AKCollectionViewCell.self,
			forCellWithReuseIdentifier: NSStringFromClass(AKCollectionViewCell.self))
		self.addSubview(self.collectionView)

		self.intercepter = AKPickerViewDelegateIntercepter(pickerView: self, delegate: self.delegate)
		self.collectionView.delegate = self.intercepter

		let maskLayer = CAGradientLayer()
		maskLayer.frame = self.collectionView.bounds
		maskLayer.colors = [
			UIColor.clearColor().CGColor,
			UIColor.blackColor().CGColor,
			UIColor.blackColor().CGColor,
			UIColor.clearColor().CGColor]
		maskLayer.locations = [0.0, 0.33, 0.66, 1.0]
		maskLayer.startPoint = CGPointMake(0.0, 0.0)
		maskLayer.endPoint = CGPointMake(1.0, 0.0)
		self.collectionView.layer.mask = maskLayer
	}

	override init() {
		super.init()
		self.initialize()
	}

	override init(frame: CGRect) {
		super.init(frame: frame)
		self.initialize()
	}

	public required init(coder aDecoder: NSCoder) {
		super.init(coder: aDecoder)
		self.initialize()
	}

	deinit {
		self.collectionView.delegate = nil
	}

	public override func layoutSubviews() {
		super.layoutSubviews()
		self.collectionView.collectionViewLayout = self.collectionViewLayout
		self.scrollToItem(self.selectedItem, animated: false)
		self.collectionView.layer.mask.frame = self.collectionView.bounds

		var transform = CATransform3DIdentity;
		transform.m34 = -1.0 / max(self.viewDepth, 1.0);
		self.collectionView.layer.sublayerTransform = transform;
	}

	public override func intrinsicContentSize() -> CGSize {
		return CGSizeMake(UIViewNoIntrinsicMetric, max(self.font.lineHeight, self.highlightedFont.lineHeight))
	}

	private func sizeForString(string: NSString) -> CGSize {
		let size = string.sizeWithAttributes([NSFontAttributeName: self.font])
		let highlightedSize = string.sizeWithAttributes([NSFontAttributeName: self.highlightedFont])
		return CGSize(
			width: ceil(max(size.width, highlightedSize.width)),
			height: ceil(max(size.height, highlightedSize.height)))
	}

	func reloadData() {
		self.invalidateIntrinsicContentSize()
		self.collectionView.collectionViewLayout.invalidateLayout()
		self.collectionView.reloadData()
		self.selectItem(self.selectedItem, animated: false, notifySelection: false)
	}

	private func offsetForItem(item: Int) -> CGFloat {
		var offset: CGFloat = 0
		for i in 0 ..< item {
			let indexPath = NSIndexPath(forItem: i, inSection: 0)
			let cellSize = self.collectionView(
				self.collectionView,
				layout: self.collectionView.collectionViewLayout,
				sizeForItemAtIndexPath: indexPath)
			offset += cellSize.width
		}

		let firstIndexPath = NSIndexPath(forItem: 0, inSection: 0)
		let firstSize = self.collectionView(
			self.collectionView,
			layout: self.collectionView.collectionViewLayout,
			sizeForItemAtIndexPath: firstIndexPath)
		let selectedIndexPath = NSIndexPath(forItem: item, inSection: 0)
		let selectedSize = self.collectionView(
			self.collectionView,
			layout: self.collectionView.collectionViewLayout,
			sizeForItemAtIndexPath: selectedIndexPath)
		offset -= (firstSize.width - selectedSize.width) / 2.0

		return offset
	}

	func scrollToItem(item: Int, animated: Bool = false) {
		switch self.pickerViewStyle {
		case .Flat:
			self.collectionView.scrollToItemAtIndexPath(
				NSIndexPath(
					forItem: item,
					inSection: 0),
				atScrollPosition: .CenteredHorizontally,
				animated: animated)
		case .Wheel:
			self.collectionView.setContentOffset(
				CGPoint(
					x: self.offsetForItem(item),
					y: self.collectionView.contentOffset.y),
				animated: animated)
		}
	}

	func selectItem(item: Int, animated: Bool = false) {
		self.selectItem(item, animated: animated, notifySelection: true)
	}

	private func selectItem(item: Int, animated: Bool, notifySelection: Bool) {
		self.collectionView.selectItemAtIndexPath(
			NSIndexPath(forItem: item, inSection: 0),
			animated: animated,
			scrollPosition: .None)
		self.scrollToItem(item, animated: animated)
		self.selectedItem = item
		if notifySelection {
			self.delegate?.pickerView?(self, didSelectItem: item)
		}
	}

	private func didEndScrolling() {
		switch self.pickerViewStyle {
		case .Flat:
			let center = self.convertPoint(self.collectionView.center, toView: self.collectionView)
			let indexPath = self.collectionView.indexPathForItemAtPoint(center)
			self.selectItem(indexPath!.item, animated: true, notifySelection: true)
		case .Wheel:
			if let numberOfItems = self.dataSource?.numberOfItemsInPickerView(self) {
				for i in 0 ..< numberOfItems {
					let indexPath = NSIndexPath(forItem: i, inSection: 0)
					let cellSize = self.collectionView(
						self.collectionView,
						layout: self.collectionView.collectionViewLayout,
						sizeForItemAtIndexPath: indexPath)
					if self.offsetForItem(i) + cellSize.width / 2 > self.collectionView.contentOffset.x {
						self.selectItem(i, animated: true, notifySelection: true)
						break
					}
				}
			}
		}
	}

	public func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
		return 1
	}

	public func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
		return self.dataSource != nil ? self.dataSource!.numberOfItemsInPickerView(self) : 0
	}

	public func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
		let cell = collectionView.dequeueReusableCellWithReuseIdentifier(NSStringFromClass(AKCollectionViewCell.self), forIndexPath: indexPath) as AKCollectionViewCell
		if let title = self.dataSource?.pickerView?(self, titleForItem: indexPath.item) {
			cell.label.text = title
			cell.label.textColor = self.textColor
			cell.label.highlightedTextColor = self.highlightedTextColor
			cell.label.font = self.font
			cell.font = self.font
			cell.highlightedFont = self.highlightedFont
			cell.label.bounds = CGRect(origin: CGPointZero, size: self.sizeForString(title))
			if let delegate = self.delegate {
				delegate.pickerView?(self, configureLabel: cell.label, forItem: indexPath.item)
				if let margin = delegate.pickerView?(self, marginForItem: indexPath.item) {
					cell.label.frame = CGRectInset(cell.label.frame, -margin.width, -margin.height)
				}
			}
		} else if let image = self.dataSource?.pickerView?(self, imageForItem: indexPath.item) {
			cell.imageView.image = image
		}
		cell._selected = (indexPath.item == self.selectedItem)

		return cell
	}

	public func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {
		var size = CGSizeMake(self.interitemSpacing, collectionView.bounds.size.height)
		if let title = self.dataSource?.pickerView?(self, titleForItem: indexPath.item) {
			size.width += self.sizeForString(title).width
			if let margin = self.delegate?.pickerView?(self, marginForItem: indexPath.item) {
				size.width += margin.width * 2
			}
		} else if let image = self.dataSource?.pickerView?(self, imageForItem: indexPath.item) {
			size.width += image.size.width
		}
		return size
	}

	public func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAtIndex section: Int) -> CGFloat {
		return 0.0
	}

	public func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAtIndex section: Int) -> CGFloat {
		return 0.0
	}

	public func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAtIndex section: Int) -> UIEdgeInsets {
		let number = self.collectionView(collectionView, numberOfItemsInSection: section)
		let firstIndexPath = NSIndexPath(forItem: 0, inSection: section)
		let firstSize = self.collectionView(collectionView, layout: collectionView.collectionViewLayout, sizeForItemAtIndexPath: firstIndexPath)
		let lastIndexPath = NSIndexPath(forItem: number - 1, inSection: section)
		let lastSize = self.collectionView(collectionView, layout: collectionView.collectionViewLayout, sizeForItemAtIndexPath: lastIndexPath)
		return UIEdgeInsetsMake(
			0, (collectionView.bounds.size.width - firstSize.width) / 2,
			0, (collectionView.bounds.size.width - lastSize.width) / 2
		)
	}

	public func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
		self.selectItem(indexPath.item, animated: true)
	}

	public func scrollViewDidEndDecelerating(scrollView: UIScrollView) {
		self.delegate?.scrollViewDidEndDecelerating?(scrollView)
		self.didEndScrolling()
	}

	public func scrollViewDidEndDragging(scrollView: UIScrollView, willDecelerate decelerate: Bool) {
		self.delegate?.scrollViewDidEndDragging?(scrollView, willDecelerate: decelerate)
		if !decelerate {
			self.didEndScrolling()
		}
	}

	public func scrollViewDidScroll(scrollView: UIScrollView) {
		self.delegate?.scrollViewDidScroll?(scrollView)
		CATransaction.begin()
		CATransaction.setValue(kCFBooleanTrue, forKey: kCATransactionDisableActions)
		self.collectionView.layer.mask.frame = self.collectionView.bounds
		CATransaction.commit()
	}

	private func pickerViewStyleForCollectionViewLayout(layout: AKCollectionViewLayout) -> AKPickerViewStyle {
		return self.pickerViewStyle
	}

}

