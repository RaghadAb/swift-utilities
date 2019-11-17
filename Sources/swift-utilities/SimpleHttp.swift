//
//  SimpleHttp.swift
//  FFIOSTools
//
//  Created by Bill Gestrich on 10/28/17.
//  Copyright © 2017 Bill Gestrich. All rights reserved.
//

import Foundation

enum SimpleHttpError: Error {
    case NoData
    case JSONSerialization
}

struct BasicAuth {
    let username : String
    let password : String
}


class SimpleHttp: NSObject {
    
    var auth : BasicAuth?
    var headers: [String: String] = [String: String]()
    
    init(auth: BasicAuth?){
        self.auth = auth
        super.init()
    }
    
    convenience init(auth: BasicAuth?, headers: [String: String]){
        self.init(auth: auth)
        self.headers = headers
    }
    
    func getJSON(url: URL) -> NSDictionary {
        let request = URLRequest(url: url)        
        
        let config = URLSessionConfiguration.default
        
        var authHeaders = [String: String]()
        if let auth = self.auth {
            let userPasswordData = "\(auth.username):\(auth.password)".data(using: .utf8)
            let base64EncodedCredential = userPasswordData!.base64EncodedString(options: Data.Base64EncodingOptions.init(rawValue: 0))
            let authString = "Basic \(base64EncodedCredential)"
            authHeaders["authorization"] = authString
        }
        authHeaders += self.headers
        config.httpAdditionalHeaders = authHeaders
        
        print("Curl = \(curlRequestWithURL(url:url.absoluteString, headers:authHeaders))")
        
        var responseDict: NSDictionary = NSDictionary()
        let semaphore = DispatchSemaphore(value: 0)
        let session: URLSession = URLSession(configuration: config, delegate: nil, delegateQueue: nil)

        let task = session.dataTask(with: request, completionHandler: { data, response, error in
            if let error = error {
                print("Error while trying to re-authenticate the user: \(error)")
            } else if let response = response as? HTTPURLResponse,
                300..<600 ~= response.statusCode {
                print("Error while trying to re-authenticate the user, statusCode: \(response.statusCode)")
            } else {
                do {
                    guard let data = data else {
                        print("No data available")
                        throw(SimpleHttpError.NoData)
                    }
                    if let jsonDictionary = try JSONSerialization.jsonObject(with: data, options: []) as? NSDictionary {
                        responseDict = jsonDictionary
//                        print("No data available")
                    } else if let jsonArray =  try JSONSerialization.jsonObject(with: data, options: []) as? NSArray {
                        responseDict = ["FFIOSToolsHack":jsonArray]
                    } else {
                        throw(SimpleHttpError.JSONSerialization)
                    }
                    
                    
                    
                } catch {
                    print(error)
                }
            }
            semaphore.signal()
        }) 
        
        task.resume()
        _ = semaphore.wait(timeout: DispatchTime.distantFuture)
        return responseDict
    }
}

func += <K, V> (left: inout [K:V], right: [K:V]) { 
    for (k, v) in right { 
        left[k] = v
    } 
}

func curlRequestWithURL (url: String, headers:Dictionary<String, String>) -> String {
    
    //Example output:
    //curl --header "Date: January 10, 2017 14:37:21" -L  "https://jsum.jeppesen.com/oem/foreflight"
    
    var toRet = "curl "
    
    if headers.count > 0 {
        for (headerKey, headerValue) in headers {
            toRet += "--header "
            toRet += " \"\(headerKey): \(headerValue)\" "            
        }
        
        toRet += "-L "
        
        toRet += "\"\(url)\""
    }
    
    return toRet
}
