//
//  DPJsonRequestSerializer.swift
//  DPSessionManager
//
//  Created by Daniel Person on 8/30/16.
//  Copyright © 2016 Daniel Person. All rights reserved.
//

import Foundation

open class DPJsonRequestSerializer:DPRequestSerializer
{
    open func serialize(_ object:AnyObject) -> Data?
    {
        do
        {
            let jsonData = try JSONSerialization.data(withJSONObject: object, options: JSONSerialization.WritingOptions.prettyPrinted)
            return jsonData
        }
        catch let error as NSError
        {
            print("error serializing JsON string: \(error.localizedDescription)")
            return nil
        }
    }
}
