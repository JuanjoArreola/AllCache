//
//  Log.swift
//  AllCache
//
//  Created by Juan Jose Arreola on 2/5/16.
//  Copyright © 2016 Juanjo. All rights reserved.
//

import Foundation

enum LogLevel: Int {
    case DEBUG = 1, WARNING, ERROR, SEVERE
}

final class Log {
    static var logLevel = LogLevel(rawValue: Configuration.logLevel)!
    static var showDate = true
    static var showFile = Configuration.showFile
    static var showFunc = Configuration.showFunc
    static var showLine = Configuration.showLine
    
    static var formatter: NSDateFormatter = {
        let f = NSDateFormatter()
        f.dateFormat = "MM-dd HH:mm:ss.SSS"
        return f
    }()
    
    class func debug(@autoclosure message: () -> Any, file: String = #file, function: StaticString = #function, line: Int = #line) {
        if LogLevel.DEBUG.rawValue >= logLevel.rawValue {
            log("Debug", message: String(message()), file: file, function: function, line: line)
        }
    }
    
    class func warn(@autoclosure message: () -> Any, file: String = #file, function: StaticString = #function, line: Int = #line) {
        if LogLevel.WARNING.rawValue >= logLevel.rawValue {
            log("Warning", message: String(message()), file: file, function: function, line: line)
        }
    }
    
    class func error(@autoclosure message: () -> Any, file: String = #file, function: StaticString = #function, line: Int = #line) {
        if LogLevel.ERROR.rawValue >= logLevel.rawValue {
            log("Error", message: String(message()), file: file, function: function, line: line)
        }
    }
    
    class func severe(@autoclosure message: () -> Any, file: String = #file, function: StaticString = #function, line: Int = #line) {
        if LogLevel.SEVERE.rawValue >= logLevel.rawValue {
            log("Severe", message: String(message()), file: file, function: function, line: line)
        }
    }
    
    private class func log(level: String, message: String, file: String, function: StaticString, line: Int) {
        var s = ""
        s += showDate ? formatter.stringFromDate(NSDate()) + " " : ""
        s += showFile ? file.componentsSeparatedByString("/").last ?? "" : ""
        s += showFunc ? " \(function)" : ""
        s += showLine ? " [\(line)] " : ""
        s += level + ": "
        s += message
        print(s)
    }
    
}