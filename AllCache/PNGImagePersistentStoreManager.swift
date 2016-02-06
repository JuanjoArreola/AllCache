//
//  ImagePersistentStoreManager.swift
//  AllCache
//
//  Created by Juan Jose Arreola on 2/6/16.
//  Copyright © 2016 Juanjo. All rights reserved.
//

import UIKit


public enum PNGImagePersistentError: ErrorType {
    case InvalidImage
}

public class PNGImagePersistentStoreManager: PersistentStoreManager<UIImage> {
    
    public required override init(storeURL: NSURL) {
        super.init(storeURL: storeURL)
    }
    
    override func persist(object: UIImage, fileName: String) throws -> (path: String, size: Int) {
        guard let path = storeURL.URLByAppendingPathComponent(fileName).path else {
            throw PersistentStoreError.InvalidPath
        }
        guard let data = UIImagePNGRepresentation(object) else {
            throw PersistentStoreError.InvalidData
        }
        data.writeToFile(path, atomically: true)
        return (path: path, size: data.length)
    }
    
    override func retrieve(path path: String) throws -> UIImage {
        guard let data = NSData(contentsOfFile: path) else {
            throw PersistentStoreError.InvalidData
        }
        guard let image = UIImage(data: data) else {
            throw PNGImagePersistentError.InvalidImage
        }
        return image
    }
    
    override func delete(path: String) throws {
        try NSFileManager.defaultManager().removeItemAtPath(path)
    }
}