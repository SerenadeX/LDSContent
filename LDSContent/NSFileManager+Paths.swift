//
//  NSFileManager+Paths.swift
//  Pods
//
//  Created by Stephan Heilner on 4/28/16.
//
//

import Foundation

public extension NSFileManager {
    
    class func applicationLibraryDirectory() -> NSURL {
        if let URL = NSFileManager.defaultManager().URLsForDirectory(.LibraryDirectory, inDomains: .UserDomainMask).last {
            return URL
        }
        fatalError("Unable to load Application Library directory")
    }
    
    public class func privateDocumentsDirectory() -> NSURL {
        return applicationLibraryDirectory().URLByAppendingPathComponent("Private Documents")
    }
    
    public class func itemPackagesDirectory() -> NSURL {
        return privateDocumentsDirectory().URLByAppendingPathComponent("ItemPackages")
    }
    
}