//
//  DPFormRequestSerializer.swift
//  DPSessionManager
//
//  Created by Daniel Person on 8/30/16.
//  Copyright © 2016 Daniel Person. All rights reserved.
//

import Foundation

open class DPFormRequestSerializer:DPRequestSerializer
{
    var customCharacterSet:CharacterSet {
        var charSet = NSCharacterSet.urlQueryAllowed
        var remove = "+&"
        for char in remove.unicodeScalars
        {
            charSet.remove(char)
        }
        
        return charSet
    }
    
    open func serialize(_ object:AnyObject) -> Data?
    {
        var formData:Data?
        
        if let params = object as? Dictionary<String,AnyObject>
        {
            var body = ""
            
            for (key,value) in params
            {
                let encodedKey = urlEncode(key)
                let encodedValue = urlEncode(value as! String)
                body += encodedKey+"="+encodedValue+"&"
            }
            
            body = String(body.characters.dropLast())
            
            formData = body.data(using: String.Encoding.utf8)
        }
        
        return formData
    }
    
    func urlEncode(_ string:String) -> String
    {
        guard let encoded = string.addingPercentEncoding(withAllowedCharacters: customCharacterSet) else {
            return string
        }
        
        return encoded
    }
}
