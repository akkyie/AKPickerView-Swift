//
//  AKPickerView.swift
//  AKPickerView
//
//  Created by Akio Yasui on 1/29/15.
//  Copyright (c) 2015 Akkyie Y. All rights reserved.
//

import UIKit

/**
Styles of AKPickerView.

- Wheel: Style with 3D appearance like UIPickerView.
- Flat:  Flat style.
*/
public enum AKPickerViewStyle {
	case Wheel
	case Flat
}

// MARK: - Protocols
// MARK: AKPickerViewDataSource
/**
Protocols to specify the number and type of contents.
*/
@objc public protocol AKPickerViewDataSource {
	func numberOfItemsInPickerView(pickerView: AKPickerView) -> Int
	optional func pickerView(pickerView: AKPickerView, titleForItem item: Int) -> String
	optional func pickerView(pickerView: AKPickerView, imageForItem item: Int) -> UIImage
}

// MARK: AKPickerViewDelegate
/**
Protocols to specify the attitude when user selected an item,
and customize the appearance of labels.
*/
@objc public protocol AKPickerViewDelegate: UIScrollViewDelegate {
	optional func pickerView(pickerView: AKPickerView, didSelectItem item: Int)
	optional func pickerView(pickerView: AKPickerView, marginForItem item: Int) -> CGSize
	optional func pickerView(pickerView: AKPickerView, configureLabel label: UILabel, forItem item: Int)
}

// MARK: - Private Classes and Protocols
// MARK: AKCollectionViewLayoutDelegate
/**
Private. Used to deliver the style of the picker.
*/
private protocol AKCollectionViewLayoutDelegate {
	func pickerViewStyleForCollectionViewLayout(layout: AKCollectionViewLayout) -> AKPickerViewStyle
}

// MARK: AKCollectionViewCell
/**
Private. A subclass of UICollectionViewCell used in AKPickerView's collection view.
*/
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

	init() {
		super.init(frame: CGRectZero)
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

// MARK: AKCollectionViewLayout
/**
Private. A subclass of UICollectionViewFlowLayout used in the collection view.
*/
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
			if self.collectionView!.numberOfSections() > 0 {
				for i in 0 ..< self.collectionView!.numberOfItemsInSection(0) {
					let indexPath = NSIndexPath(forItem: i, inSection: 0)
					attributes.append(self.layoutAttributesForItemAtIndexPath(indexPath))
				}
			}
			return attributes
		}
	}

}

// MARK: AKPickerViewDelegateIntercepter
/**
Private. Used to hook UICollectionViewDelegate and throw it AKPickerView,
and if it conforms to UIScrollViewDelegate, also throw it to AKPickerView's delegate.
*/
private class AKPickerViewDelegateIntercepter: NSObject, UICollectionViewDelegate {
	weak var pickerView: AKPickerView?
	weak var delegate: UIScrollViewDelegate?

	init(pickerView: AKPickerView, delegate: UIScrollViewDelegate?) {
		self.pickerView = pickerView
		self.delegate = delegate
	}

	private override func forwardingTargetForSelector(aSelector: Selector) -> AnyObject? {
		if self.pickerView!.respondsToSelector(aSelector) {
			return self.pickerView
		} else if self.delegate != nil && self.delegate!.respondsToSelector(aSelector) {
			return self.delegate
		} else {
			return nil
		}
	}

	private override func respondsToSelector(aSelector: Selector) -> Bool {
		if self.pickerView!.respondsToSelector(aSelector) {
			return true
		} else if self.delegate != nil && self.delegate!.respondsToSelector(aSelector) {
			return true
		} else {
			return super.respondsToSelector(aSelector)
		}
	}

}

// MARK: - AKPickerView
// TODO: Make these delegate conformation private
/**
Horizontal picker view. This is just a subclass of UIView, contains a UICollectionView.
*/
public class AKPickerView: UIView, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, AKCollectionViewLayoutDelegate {

	// MARK: - Properties
	// MARK: Readwrite Properties
	/// Readwrite. Data source of picker view.
	public weak var dataSource: AKPickerViewDataSource? = nil
	/// Readwrite. Delegate of picker view.
	public weak var delegate: AKPickerViewDelegate? = nil {
		didSet(delegate) {
			self.intercepter.delegate = delegate
		}
	}
	/// Readwrite. A font which used in NOT selected cells.
	public lazy var font = UIFont.systemFontOfSize(20)

	/// Readwrite. A font which used in selected cells.
	public lazy var highlightedFont = UIFont.boldSystemFontOfSize(20)

	/// Readwrite. A color of the text on NOT selected cells.
	@IBInspectable public lazy var textColor: UIColor = UIColor.darkGrayColor()

	/// Readwrite. A color of the text on selected cells.
	@IBInspectable public lazy var highlightedTextColor: UIColor = UIColor.blackColor()

	/// Readwrite. A float value which indicates the spacing between cells.
	@IBInspectable public var interitemSpacing: CGFloat = 0.0

	/// Readwrite. The style of the picker view. See AKPickerViewStyle.
	public var pickerViewStyle = AKPickerViewStyle.Wheel

	/// Readwrite. A float value which determines the perspective representation which used when using AKPickerViewStyle.Wheel style.
	@IBInspectable public var viewDepth: CGFloat = 1000.0 {
		didSet {
			self.collectionView.layer.sublayerTransform = self.viewDepth > 0.0 ? {
				var transform = CATransform3DIdentity;
				transform.m34 = -1.0 / self.viewDepth;
				return transform;
				}() : CATransform3DIdentity;
		}
	}
	/// Readwrite. A boolean value indicates whether the mask is disabled.
	@IBInspectable public var maskDisabled: Bool! = nil {
		didSet {
			self.collectionView.layer.mask = self.maskDisabled == true ? nil : {
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
				return maskLayer
				}()
		}
	}

	// MARK: Readonly Properties
	/// Readonly. Index of currently selected item.
	public private(set) var selectedItem: Int = 0
	/// Readonly. The point at which the origin of the content view is offset from the origin of the picker view.
	public var contentOffset: CGPoint {
		get {
			return self.collectionView.contentOffset
		}
	}

	// MARK: Private Properties
	/// Private. A UICollectionView which shows contents on cells.
	private var collectionView: UICollectionView!
	/// Private. An intercepter to hook UICollectionViewDelegate then throw it picker view and its delegate
	private var intercepter: AKPickerViewDelegateIntercepter!
	/// Private. A UICollectionViewFlowLayout used in picker view's collection view.
	private var collectionViewLayout: AKCollectionViewLayout {
		let layout = AKCollectionViewLayout()
		layout.delegate = self
		return layout
	}

	// MARK: - Functions
	// MARK: View Lifecycle
	/**
	Private. Initializes picker view's subviews and friends.
	*/
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

		self.maskDisabled = self.maskDisabled == nil ? false : self.maskDisabled
	}

	public init() {
		super.init(frame: CGRectZero)
		self.initialize()
	}

	public override init(frame: CGRect) {
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

	// MARK: Layout

	public override func layoutSubviews() {
		super.layoutSubviews()
		if self.dataSource != nil && self.dataSource!.numberOfItemsInPickerView(self) > 0 {
			self.collectionView.collectionViewLayout = self.collectionViewLayout
			self.scrollToItem(self.selectedItem, animated: false)
		}
		self.collectionView.layer.mask?.frame = self.collectionView.bounds
	}

	public override func intrinsicContentSize() -> CGSize {
		return CGSizeMake(UIViewNoIntrinsicMetric, max(self.font.lineHeight, self.highlightedFont.lineHeight))
	}

	// MARK: Calculation Functions

	/**
	Private. Used to calculate bounding size of given string with picker view's font and highlightedFont

	:param: string A NSString to calculate size
	:returns: A CGSize which contains given string just.
	*/
	private func sizeForString(string: NSString) -> CGSize {
		let size = string.sizeWithAttributes([NSFontAttributeName: self.font])
		let highlightedSize = string.sizeWithAttributes([NSFontAttributeName: self.highlightedFont])
		return CGSize(
			width: ceil(max(size.width, highlightedSize.width)),
			height: ceil(max(size.height, highlightedSize.height)))
	}

	/**
	Private. Used to calculate the x-coordinate of the content offset of specified item.

	:param: item An integer value which indicates the index of cell.
	:returns: An x-coordinate of the cell whose index is given one.
	*/
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

	// MARK: View Controls
	/**
	Reload the picker view's contents and styles. Call this method always after any property is changed.
	*/
	public func reloadData() {
		self.invalidateIntrinsicContentSize()
		self.collectionView.collectionViewLayout.invalidateLayout()
		self.collectionView.reloadData()
		if self.dataSource != nil && self.dataSource!.numberOfItemsInPickerView(self) > 0 && self.dataSource!.numberOfItemsInPickerView(self) > self.selectedItem {
			self.selectItem(self.selectedItem, animated: false, notifySelection: false)
		}
	}

	/**
	Move to the cell whose index is given one without selection change.

	:param: item     An integer value which indicates the index of cell.
	:param: animated True if the scrolling should be animated, false if it should be immediate.
	*/
	public func scrollToItem(item: Int, animated: Bool = false) {
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

	/**
	Select a cell whose index is given one and move to it.

	:param: item     An integer value which indicates the index of cell.
	:param: animated True if the scrolling should be animated, false if it should be immediate.
	*/
	public func selectItem(item: Int, animated: Bool = false) {
		self.selectItem(item, animated: animated, notifySelection: true)
	}

	/**
	Private. Select a cell whose index is given one and move to it, with specifying whether it calls delegate method.

	:param: item            An integer value which indicates the index of cell.
	:param: animated        True if the scrolling should be animated, false if it should be immediate.
	:param: notifySelection True if the delegate method should be called, false if not.
	*/
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

	// MARK: Delegate Handling
	/**
	Private.
	*/
	private func didEndScrolling() {
		switch self.pickerViewStyle {
		case .Flat:
			let center = self.convertPoint(self.collectionView.center, toView: self.collectionView)
			if let indexPath = self.collectionView.indexPathForItemAtPoint(center) {
				self.selectItem(indexPath.item, animated: true, notifySelection: true)
			}
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

	// MARK: UICollectionViewDataSource
	public func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
		return self.dataSource != nil && self.dataSource!.numberOfItemsInPickerView(self) > 0 ? 1 : 0
	}

	public func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
		return self.dataSource != nil ? self.dataSource!.numberOfItemsInPickerView(self) : 0
	}

	public func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
		let cell = collectionView.dequeueReusableCellWithReuseIdentifier(NSStringFromClass(AKCollectionViewCell.self), forIndexPath: indexPath) as! AKCollectionViewCell
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

	// MARK: UICollectionViewDelegateFlowLayout
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

	// MARK: UICollectionViewDelegate
	public func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
		self.selectItem(indexPath.item, animated: true)
	}

	// MARK: UIScrollViewDelegate
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
		self.collectionView.layer.mask?.frame = self.collectionView.bounds
		CATransaction.commit()
	}

	// MARK: AKCollectionViewLayoutDelegate
	private func pickerViewStyleForCollectionViewLayout(layout: AKCollectionViewLayout) -> AKPickerViewStyle {
		return self.pickerViewStyle
	}
	
}

