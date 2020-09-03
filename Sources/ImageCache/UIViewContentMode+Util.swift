//
//  UIViewContentMode+Util.swift
//  ImageCache
//
//  Created by JuanJo on 02/09/20.
//

#if os(iOS) || os(tvOS)

import UIKit
import AllCache

extension UIView.ContentMode {
    var resizerMode: DefaultImageResizer.ContentMode {
        return DefaultImageResizer.ContentMode(rawValue: rawValue)!
    }
}

#endif
