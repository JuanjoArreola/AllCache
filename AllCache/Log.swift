//
//  Log.swift
//  AllCache
//
//  Created by Juan Jose Arreola on 2/5/16.
//  Copyright © 2016 Juanjo. All rights reserved.
//

import Foundation

public enum LogLevel: Int {
    case debug = 1, warning, error, severe
}

public final class Log {
    public static var logLevel = LogLevel(rawValue: Configuration.logLevel)!
    static var showDate = true
    static var showFile = Configuration.showFile
    static var showFunc = Configuration.showFunc
    static var showLine = Configuration.showLine
    
    static var formatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "MM-dd HH:mm:ss.SSS"
        return f
    }()
    
    class func debug(_ message: @autoclosure () -> Any, file: String = #file, function: StaticString = #function, line: Int = #line) {
        if LogLevel.debug.rawValue >= logLevel.rawValue {
            log("Debug", message: String(message()), file: file, function: function, line: line)
        }
    }
    
    class func warn(_ message: @autoclosure () -> Any, file: String = #file, function: StaticString = #function, line: Int = #line) {
        if LogLevel.warning.rawValue >= logLevel.rawValue {
            log("Warning", message: String(message()), file: file, function: function, line: line)
        }
    }
    
    class func error(_ message: @autoclosure () -> Any, file: String = #file, function: StaticString = #function, line: Int = #line) {
        if LogLevel.error.rawValue >= logLevel.rawValue {
            log("Error", message: String(message()), file: file, function: function, line: line)
        }
    }
    
    class func severe(_ message: @autoclosure () -> Any, file: String = #file, function: StaticString = #function, line: Int = #line) {
        if LogLevel.severe.rawValue >= logLevel.rawValue {
            log("Severe", message: String(message()), file: file, function: function, line: line)
        }
    }
    
    fileprivate class func log(_ level: String, message: String, file: String, function: StaticString, line: Int) {
        var s = ""
        s += showDate ? formatter.string(from: Date()) + " " : ""
        s += showFile ? file.components(separatedBy: "/").last ?? "" : ""
        s += showFunc ? " \(function)" : ""
        s += showLine ? " [\(line)] " : ""
        s += level + ": "
        s += message
        print(s)
    }
    
}
