//
//  DPJsonResponseParser.swift
//  DPSessionManager
//
//  Created by Daniel Person on 8/30/16.
//  Copyright © 2016 Daniel Person. All rights reserved.
//

import Foundation

open class DPJsonResponseParser:DPResponseParser
{
    open func parse(_ data: Data) -> AnyObject?
    {
        do {
            let responseBody = try JSONSerialization.jsonObject(with: data, options: JSONSerialization.ReadingOptions.allowFragments)
            return responseBody as AnyObject?
        }
        catch let error as NSError
        {
            print("error parsing data: \(error.localizedDescription)")
            return nil
        }
    }
}
