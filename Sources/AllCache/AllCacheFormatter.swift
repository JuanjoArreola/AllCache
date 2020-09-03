//
//  AllCacheFormatter.swift
//  AllCache
//
//  Created by JuanJo on 03/09/20.
//

import Foundation
import Logg

public let logger = CompositeLogger(loggers: [ConsoleLogger(formatter: AllCacheFormatter(), level: [.error, .fault])])

class AllCacheFormatter: ConsoleFormatter {
    
    override func string(from context: LogContext) -> String {
        return formatter.string(from: context.date)
    }
    
}
