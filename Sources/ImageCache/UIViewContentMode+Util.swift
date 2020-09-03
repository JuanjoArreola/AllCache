//
//  UIViewContentMode+Util.swift
//  ImageCache
//
//  Created by JuanJo on 02/09/20.
//

#if os(iOS) || os(tvOS)

import UIKit
import NewCache

extension UIView.ContentMode {
    var resizerMode: DefaultImageResizer.ContentMode {
        switch self {
        case .scaleAspectFit: return .scaleAspectFit
        case .scaleAspectFill: return .scaleAspectFill
        case .center: return .center
        case .top: return .top
        case .bottom: return .bottom
        case .left: return .left
        case .right: return .right
        case .topLeft: return .topLeft
        case .topRight: return .topRight
        case .bottomLeft: return .bottomLeft
        case .bottomRight: return . bottomRight
        default:
            return .center
        }
    }
}

#endif
