//
//  String+Range.swift
//  AllCache
//
//  Created by Juan Jose Arreola on 14/03/17.
//
//

import Foundation

extension String {
    
    var wholeRange: Range<String.Index> {
        return startIndex..<endIndex
    }
    
    var wholeNSRange: NSRange {
        return NSRange(location: 0, length: characters.count)
    }
}
