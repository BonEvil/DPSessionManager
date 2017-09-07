//
//  DPSessionManager.swift
//  DPSessionManager
//
//  Created by Daniel Person on 8/30/16.
//  Copyright © 2016 Daniel Person. All rights reserved.
//

import Foundation

public typealias DPServiceResponse = (NSError?,Any?) -> ()

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
    
    fileprivate var session:Foundation.URLSession!
    fileprivate var credential:URLCredential?
    
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
    
    open func start(_ service:DPService, serviceResponse:@escaping DPServiceResponse)
    {
        if let serviceCredential = service.credential
        {
            credential = serviceCredential
        }
        
        let request = createRequest(service)
        session.dataTask(with: request, completionHandler: { [unowned self] (data, response, error) in
            DispatchQueue.main.async(execute: { () -> Void in
                if let err = error as? NSError
                {
                    serviceResponse(err,nil)
                }
                else
                {
                    if let urlResponse = response as? HTTPURLResponse
                    {
                        if let headers = urlResponse.allHeaderFields as? [String:AnyObject]
                        {
                            if let contentTypeHeader = headers["Content-Type"] as? String
                            {
                                let contentType = self.getContentType(contentTypeHeader: contentTypeHeader);
                                
                                let acceptType = self.getAcceptType(service: service)
                                
                                if acceptType == contentType
                                {
                                    if let responseData = data
                                    {
                                        if let parser = service.responseParser // CUSTOM PARSER
                                        {
                                            if let parsedData = parser.parse(responseData)
                                            {
                                                switch parsedData {
                                                case is NSError:serviceResponse(parsedData as! NSError,nil)
                                                default:serviceResponse(nil,parsedData)
                                                }
                                            }
                                            else
                                            {
                                                let error = NSError(domain: DPSessionManager.errorDomain, code: -1, userInfo: [NSLocalizedDescriptionKey:"Could not parse response.","Response":responseData])
                                                serviceResponse(error,nil)
                                            }
                                        }
                                        else // USE DEFAULT PARSERS
                                        {
                                            switch service.acceptType
                                            {
                                            case .JSON:
                                                if let parsedData = DPJsonResponseParser().parse(responseData)
                                                {
                                                    serviceResponse(nil,parsedData)
                                                }
                                                else
                                                {
                                                    let error = NSError(domain: DPSessionManager.errorDomain, code: -1, userInfo: [NSLocalizedDescriptionKey:"Could not parse response.","Response":responseData])
                                                    serviceResponse(error,nil)
                                                }
                                            case .HTML,.TEXT:
                                                if let text = String(data: responseData, encoding: String.Encoding.utf8)
                                                {
                                                    serviceResponse(nil,text)
                                                }
                                                else if let text = String(data: responseData, encoding: String.Encoding.ascii)
                                                {
                                                    serviceResponse(nil,text)
                                                }
                                                else
                                                {
                                                    let error = NSError(domain: DPSessionManager.errorDomain, code: -1, userInfo: [NSLocalizedDescriptionKey:"Could not parse response.","Response":responseData])
                                                    serviceResponse(error,nil)
                                                }
                                            case .XML:
                                                serviceResponse(nil,XMLParser(data: responseData))
                                            default:
                                                serviceResponse(nil,responseData)
                                            }
                                        }
                                    }
                                    else
                                    {
                                        serviceResponse(nil,nil)
                                    }
                                }
                                else
                                {
                                    let error = NSError(domain: DPSessionManager.errorDomain, code: -1, userInfo: [NSLocalizedDescriptionKey:"Invalid content type. Expected '\(acceptType)' but received '\(contentType)' from response."])
                                    serviceResponse(error,nil)
                                }
                            }
                            else
                            {
                                let error = NSError(domain: DPSessionManager.errorDomain, code: -1, userInfo: [NSLocalizedDescriptionKey:"No content type specified."])
                                serviceResponse(error,nil)
                            }
                        }
                    }
                    else
                    {
                        let error = NSError(domain: DPSessionManager.errorDomain, code: -1, userInfo: [NSLocalizedDescriptionKey:"No data returned from server."])
                        serviceResponse(error,nil)
                    }
                }
            })
        }).resume()
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
                if let data = serializer.serialize(requestParams as Any)
                {
                    request.httpBody = data
                }
            }
            else
            {
                switch service.contentType // USE DEFAULT SERIALIZERS
                {
                case.JSON:
                    if let data = DPJsonRequestSerializer().serialize(requestParams as Any)
                    {
                        request.httpBody = data
                    }
                case.FORM:
                    if let data = DPFormRequestSerializer().serialize(requestParams as Any)
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
    
    fileprivate func getContentType(contentTypeHeader: String) -> String
    {
        var contentType = contentTypeHeader
        let contentTypeArray = contentTypeHeader.components(separatedBy: ";")
        if contentTypeArray.count > 0
        {
            contentType = contentTypeArray[0]
        }
        
        return contentType
    }
    
    fileprivate func getAcceptType(service: DPService) -> String
    {
        var acceptType = service.acceptType.rawValue
        if let customAcceptType = service.customAcceptType
        {
            acceptType = customAcceptType
        }
        
        return acceptType
    }
}

// MARK: SESSION TASK DELEGATE
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
