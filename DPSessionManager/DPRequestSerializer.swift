//
//  DPRequestSerializer.swift
//  DPSessionManager
//
//  Created by Daniel Person on 8/30/16.
//  Copyright © 2016 Daniel Person. All rights reserved.
//

import Foundation

public protocol DPRequestSerializer
{
    func serialize(_ object:AnyObject) -> Data?
}