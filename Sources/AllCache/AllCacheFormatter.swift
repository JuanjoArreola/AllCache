//
//  AllCacheFormatter.swift
//  AllCache
//
//  Created by Juan Jose Arreola on 04/05/17.
//
//

import Foundation
import Logg

class AllCacheFormatter: ConsoleFormatter {
    override func string(from context: LogContext) -> String {
        return formatter.string(from: context.date)
    }
}
