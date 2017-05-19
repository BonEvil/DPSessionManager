//
//  DPService.swift
//  DPSessionManager
//
//  Created by Daniel Person on 8/30/16.
//  Copyright © 2016 Daniel Person. All rights reserved.
//

import Foundation

public enum DPRequestType:String
{
    case GET = "GET"
    case POST = "POST"
    case PUT = "PUT"
    case DELETE = "DELETE"
    case HEAD = "HEAD"
}

public enum DPContentType:String
{
    case XML = "application/xml"
    case JSON = "application/json"
    case FORM = "application/x-www-form-urlencoded"
    case NONE = ""
}

public enum DPAcceptType:String
{
    case XML = "application/xml"
    case JSON = "application/json"
    case HTML = "text/html"
    case TEXT = "text/plain"
    case JAVASCRIPT = "text/javascript"
    case NONE = ""
}

public protocol DPService
{
    static var baseUrl:String? { set get }
    
    var requestType:DPRequestType { get }
    var contentType:DPContentType { get }
    var acceptType:DPAcceptType { get }
    var timeout:TimeInterval { get }
    var requestURL:String { get }
    
    var requestParams:[String:AnyObject]? { get }
    var additionalHeaders:[String:String]? { get }
    
    var customContentType:String? { get }
    var customAcceptType:String? { get }
    var requestSerializer:DPRequestSerializer? { get }
    var responseParser:DPResponseParser? { get }
    var credential:URLCredential? { get }
}
