AKPickerView
============

<img src="./Screenshot.gif" width="200" alt="Screenshot" />
<img src="./Screenshot2.gif" width="200" alt="Screenshot" />

A simple yet customizable horizontal picker view.

The __Swift__ port of [AKPickerView](https://github.com/Akkyie/AKPickerView).

Works on iOS 7 and 8.

Installation
------------

###[CocoaPods](http://cocoapods.org/):
In your `Podfile`:
```
pod "AKPickerView-Swift"
```
And in your `*.swift`:
```swift
import AKPickerView_Swift
```

###[Carthage](https://github.com/Carthage/Carthage):
In your `Cartfile`:
```
github "Akkyie/AKPickerView-Swift"
```
And in your `*.swift`:
```swift
import AKPickerView
```

###Manual Install
Add `AKPickerView.swift` into your Xcode project.

Usage
-----

1. Instantiate and set `delegate` and `dataSource` as you know,

  ```swift
  self.pickerView = AKPickerView(frame: <#frame#>)
  self.pickerView.delegate = self
  self.pickerView.dataSource = self
  ```

1. then specify the number of items using `AKPickerViewDataSource`,
  ```swift
  func numberOfItemsInPickerView(pickerView: AKPickerView) -> Int {}
  ```
	
1. and contents to be shown. You can use either texts or images:
  ```swift
  func pickerView(pickerView: AKPickerView, titleForItem item: Int) -> NSString {}
  // OR
  func pickerView(pickerView: AKPickerView, imageForItem item: Int) -> UIImage {}
  ```
	
  - Using both texts and images are currently not supported. When you implement both, `titleForItem` will be called and the other won't. 
  - You currently cannot specify image sizes; AKPickerView shows the original image in its original size. Resize your images in advance if you need.

1. You can change its appearance with properties below:

  ```swift
  var font: UIFont
  var highlightedFont: UIFont
  var textColor: UIColor
  var highlightedTextColor: UIColor
  var interitemSpacing: CGFloat
  var viewDepth: CGFloat
  var pickerViewStyle: AKPickerViewStyle
  ```
  
    - All cells are laid out depending on the largest font, so large differnce between the sizes of *font* and *highlightedFont* is NOT recommended.  
    - viewDepth property affects the perspective distortion. A value near the screen's height or width is recommended.

1. After all settings, **never forget to reload your picker**.
  ```swift
  self.pickerView.reloadData()
  ```

1. Optional: You can use `AKPickerViewDelegate` methods to observe selection changes:
  ```swift
  func pickerView(pickerView: AKPickerView, didSelectItem item: Int) {}
  ```
  Additionally, you can also use `UIScrollViewDelegate` methods to observe scrolling.

For more detail, see the sample project.

Contact
-------

@akkyie http://twitter.com/akkyie

License
-------
MIT. See LICENSE.
