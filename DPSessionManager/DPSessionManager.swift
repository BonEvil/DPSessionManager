//
//  DPSessionManager.swift
//  DPSessionManager
//
//  Created by Daniel Person on 8/30/16.
//  Copyright © 2016 Daniel Person. All rights reserved.
//

import Foundation
import BoltsSwift

open class DPSessionManager:NSObject
{
    fileprivate static var instance:DPSessionManager?
    
    open static var errorDomain = "errordomain"
    
    lazy var queue:OperationQueue = {
        let queue = OperationQueue()
        queue.name = "Service Queue"
        queue.maxConcurrentOperationCount = 4
        return queue
    }()
    
    var session:Foundation.URLSession!
    var credential:URLCredential?
    
    override init()
    {
        super.init()
        createSession()
    }
    
    // MARK: SHARED INSTANCE
    
    open class func sharedInstance() -> DPSessionManager
    {
        guard let sessionManager = DPSessionManager.instance else {
            DPSessionManager.instance = DPSessionManager()
            return DPSessionManager.instance!
        }
        
        return sessionManager
    }
    
    // MARK: SETUP METHODS
    
    fileprivate func createSession()
    {
        session = Foundation.URLSession(configuration: URLSessionConfiguration.default, delegate: self, delegateQueue: queue)
    }
    
    // MARK: PUBLIC METHODS
    
    open func resetSession()
    {
        session = nil
        credential = nil
        createSession()
    }
    
    open func start(_ service:DPService) -> Task<AnyObject>
    {
        let source = TaskCompletionSource<AnyObject>()
        
        if let serviceCredential = service.credential
        {
            credential = serviceCredential
        }
        
        let request = createRequest(service)
        session.dataTask(with: request, completionHandler: {(data, response, error) in
            DispatchQueue.main.async(execute: { () -> Void in
                if let err = error
                {
                    source.set(error: err)
                }
                else
                {
                    if let urlResponse = response as? HTTPURLResponse
                    {
                        if let headers = urlResponse.allHeaderFields as? [String:AnyObject]
                        {
                            if let contentTypeHeader = headers["Content-Type"] as? String
                            {
                                var contentType = ""
                                let contentTypeArray = contentTypeHeader.components(separatedBy: ";")
                                if contentTypeArray.count > 0
                                {
                                    contentType = contentTypeArray[0]
                                }
                                var acceptType = service.acceptType.rawValue
                                if let customAcceptType = service.customAcceptType
                                {
                                    acceptType = customAcceptType
                                }
                                
                                if acceptType == contentType
                                {
                                    if let responseData = data
                                    {
                                        if let parser = service.responseParser // IF THE SERVICE HAS A CUSTOM PARSER
                                        {
                                            if let parsedData = parser.parse(responseData)
                                            {
                                                source.set(result: parsedData)
                                            }
                                            else
                                            {
                                                let error = NSError(domain: DPSessionManager.errorDomain, code: -1, userInfo: [NSLocalizedDescriptionKey:"Could not parse response.","Response":responseData])
                                                source.set(error: error)
                                            }
                                        }
                                        else // USE DEFAULT PARSERS
                                        {
                                            switch service.acceptType
                                            {
                                            case .JSON:
                                                if let parsedData = DPJsonResponseParser().parse(responseData)
                                                {
                                                    source.set(result: parsedData)
                                                }
                                                else
                                                {
                                                    let error = NSError(domain: DPSessionManager.errorDomain, code: -1, userInfo: [NSLocalizedDescriptionKey:"Could not parse response.","Response":responseData])
                                                    source.set(error: error)
                                                }
                                            case .HTML,.TEXT:
                                                if let text = String(data: responseData, encoding: String.Encoding.utf8)
                                                {
                                                    source.set(result: text as AnyObject)
                                                }
                                                else if let text = String(data: responseData, encoding: String.Encoding.ascii)
                                                {
                                                    source.set(result: text as AnyObject)
                                                }
                                                else
                                                {
                                                    let error = NSError(domain: DPSessionManager.errorDomain, code: -1, userInfo: [NSLocalizedDescriptionKey:"Could not parse response.","Response":responseData])
                                                    source.set(error: error)
                                                }
                                            case .XML:
                                                source.set(result: XMLParser(data: responseData))
                                            default:source.set(result: responseData as AnyObject)
                                            }
                                        }
                                    }
                                    else
                                    {
                                        source.set(result: "" as AnyObject)
                                    }
                                }
                                else
                                {
                                    let error = NSError(domain: DPSessionManager.errorDomain, code: -1, userInfo: [NSLocalizedDescriptionKey:"Invalid content type. Expected '\(acceptType)' but received '\(contentType)' from response."])
                                    source.set(error: error)
                                }
                            }
                            else
                            {
                                let error = NSError(domain: DPSessionManager.errorDomain, code: -1, userInfo: [NSLocalizedDescriptionKey:"No content type specified."])
                                source.set(error: error)
                            }
                        }
                    }
                    else
                    {
                        let error = NSError(domain: DPSessionManager.errorDomain, code: -1, userInfo: [NSLocalizedDescriptionKey:"No data returned from server."])
                        source.set(error: error)
                    }
                }
            })
        }).resume()
        
        return source.task
    }
    
    // MARK: HELPER METHODS
    
    fileprivate func createRequest(_ service:DPService) -> URLRequest
    {
        let request = NSMutableURLRequest()
        
        request.url = URL(string: service.requestURL)
        
        request.httpMethod = service.requestType.rawValue
        
        request.timeoutInterval = service.timeout
        
        if let additionalHeaders = service.additionalHeaders
        {
            for (key,value) in additionalHeaders
            {
                request.setValue(value, forHTTPHeaderField: key)
            }
        }
        
        if let customContentType = service.customContentType
        {
            request.setValue(customContentType, forHTTPHeaderField: "Content-Type")
        } else {
            if service.contentType.rawValue != ""
            {
                request.setValue(service.contentType.rawValue, forHTTPHeaderField: "Content-Type")
            }
        }
        
        if let customAcceptType = service.customAcceptType
        {
            request.setValue(customAcceptType, forHTTPHeaderField: "Accept")
        } else {
            if service.acceptType.rawValue != ""
            {
                request.setValue(service.acceptType.rawValue, forHTTPHeaderField: "Accept")
            }
        }
        
        guard let requestParams = service.requestParams else {
            return request as URLRequest
        }
        
        if requestParams.count > 0
        {
            if let serializer = service.requestSerializer // IF THE SERVICE HAS A CUSTOM SERIALIZER
            {
                if let data = serializer.serialize(requestParams as AnyObject)
                {
                    request.httpBody = data
                }
            }
            else
            {
                switch service.contentType // USE DEFAULT SERIALIZERS
                {
                case.JSON:
                    if let data = DPJsonRequestSerializer().serialize(requestParams as AnyObject)
                    {
                        request.httpBody = data
                    }
                case.FORM:
                    if let data = DPFormRequestSerializer().serialize(requestParams as AnyObject)
                    {
                        if service.requestType == .GET
                        {
                            let vars = NSString(data: data, encoding: String.Encoding.utf8.rawValue) as! String
                            request.url = URL(string: service.requestURL+"?"+vars)
                        }
                        else
                        {
                            request.httpBody = data
                        }
                    }
                case.XML:break // TODO: HANDLE XML BODY
                case.NONE:break
                }
            }
        }
        
        return request as URLRequest
    }
}

extension DPSessionManager:URLSessionTaskDelegate
{
    public func urlSession(_ session: URLSession, task: URLSessionTask, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void)
    {
        if challenge.previousFailureCount == 0
        {
            let authMethod = challenge.protectionSpace.authenticationMethod
            print("authentication method: \(authMethod)")
            switch authMethod
            {
            case NSURLAuthenticationMethodClientCertificate:completionHandler(Foundation.URLSession.AuthChallengeDisposition.useCredential,credential)
            //case NSURLAuthenticationMethodServerTrust:completionHandler(NSURLSessionAuthChallengeDisposition.UseCredential,NSURLCredential(forTrust: challenge.protectionSpace.serverTrust!)) // FIXME: REMOVE FOR PRODUCTION
            default:completionHandler(Foundation.URLSession.AuthChallengeDisposition.performDefaultHandling,nil)
            }
        } else {
            completionHandler(Foundation.URLSession.AuthChallengeDisposition.performDefaultHandling,nil)
        }
    }
}
