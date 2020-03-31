//
//  Network.swift
//  simplepin
//
//  Created by Mathias Lindholm on 29.3.2016.
//  Copyright © 2016 Mathias Lindholm. All rights reserved.
//

import Foundation
import SystemConfiguration

//MARK: - Network

private let defaults = UserDefaults(suiteName: "group.ml.simplepin")!

struct Network {
    static let config = URLSessionConfiguration.default
    static var urlQuery = URLComponents()
    static let userToken = defaults.string(forKey: "userToken")
    
    static func session() -> URLSession {
        config.timeoutIntervalForRequest = 20.0
        return URLSession(configuration: config)
    }
    
    static func checkHttpResponse(response: URLResponse) -> Bool {
        let notification = NotificationCenter.default
        let statusCode = (response as? HTTPURLResponse)?.statusCode
        
        if statusCode == 401 {
            if defaults.string(forKey: "userToken") != nil {
                notification.post(name: Notification.Name(rawValue: "tokenChanged"), object: nil)
            }
            return false
        } else if statusCode == 429 {
            notification.post(name: Notification.Name(rawValue: "handleRequestError"), object: nil, userInfo: ["title": "Too Many Requests", "message": "Try again in a couple of minutes"])
            return false
        } else if statusCode == 500 {
            return false
        } else if response.mimeType == "text/html" {
            notification.post(name: Notification.Name(rawValue: "handleRequestError"), object: nil, userInfo: ["title": "Trouble Connecting to Pinboard", "message": "Pinboard might be down. Try again in a while."])
            return false
        }
        
        return true
    }
    
    static func checkError(error: Error) -> Bool {
        guard let urlError = error as? URLError else { return true }
        
        let notification = NotificationCenter.default
        if urlError.code == .timedOut {
            notification.post(name: Notification.Name(rawValue: "handleRequestError"), object: nil, userInfo: ["title": "Connection Timed Out", "message": "Try again later."])
            return false
        }
        return true
    }
    
    // MARK: - Login with Username and Password
    static func loginWithUsernamePassword(username: String, _ password: String, completion: @escaping (String?) -> Void) -> URLSessionTask? {
        urlQuery.scheme = "https"
        urlQuery.host = "api.pinboard.in"
        urlQuery.path = "/v1/user/api_token/"
        
        let userPasswordString = username + ":" + password
        let userPasswordData = userPasswordString.data(using: .utf8)
        let base64EncodedCredential = userPasswordData!.base64EncodedString(options: [])
        let authString = "Basic \(base64EncodedCredential)"
        config.httpAdditionalHeaders = ["Authorization" : authString]
        urlQuery.queryItems = [
            (URLQueryItem(name: "format", value: "json") as URLQueryItem)
        ]
        
        guard let url = urlQuery.url else {
            completion(nil)
            return nil
        }
        
        let task = Network.session().dataTask(with: url) { (data, httpResponse, error) -> Void in
            DispatchQueue.main.async {
                if let response = httpResponse {
                    if checkHttpResponse(response: response) == false {
                        completion(nil)
                        return
                    }
                }
                
                if let err = error {
                    if checkError(error: err) == false {
                        completion(nil)
                        return
                    }
                }
                
                guard let data = data, error == nil else {
                    completion(nil)
                    return
                }
                
                let userToken = ParseJSON.string(data: data, key: "result")
                completion(userToken)
            }
        }
        
        task.resume()
        return task
    }
    
    // MARK: - Login with API Token
    static func loginWithApiToken(token: String, completion: @escaping (String?) -> Void) -> URLSessionTask? {
        urlQuery.scheme = "https"
        urlQuery.host = "api.pinboard.in"
        urlQuery.path = "/v1/user/api_token/"
        
        urlQuery.queryItems = [
            (URLQueryItem(name: "auth_token", value: token.removeExcessiveSpaces) as URLQueryItem),
            (URLQueryItem(name: "format", value: "json") as URLQueryItem)
        ]
        
        guard let url = urlQuery.url else {
            completion(nil)
            return nil
        }
        
        let task = Network.session().dataTask(with: url) { (data, httpResponse, error) -> Void in
            DispatchQueue.main.async {
                if let response = httpResponse {
                    if checkHttpResponse(response: response) == false {
                        completion(nil)
                        return
                    }
                }
                
                if let err = error {
                    if checkError(error: err) == false {
                        completion(nil)
                        return
                    }
                }
                
                guard let data = data, error == nil else {
                    completion(nil)
                    return
                }
                
                let userToken = ParseJSON.string(data: data, key: "result")
                completion(userToken)
            }
        }
        
        task.resume()
        return task
    }
    
    // MARK: - Fetch posts
    static func fetchAllPosts(fromdt: Date? = nil, completion: @escaping ([BookmarkItem]) -> Void) -> URLSessionTask? {
        urlQuery.scheme = "https"
        urlQuery.host = "api.pinboard.in"
        urlQuery.path = "/v1/posts/all"
        urlQuery.queryItems = [
            URLQueryItem(name: "fromdt", value: fromdt?.dateToString) as URLQueryItem,
            (URLQueryItem(name: "auth_token", value: userToken) as URLQueryItem),
            (URLQueryItem(name: "format", value: "json") as URLQueryItem),
        ]
        
        guard let url = urlQuery.url else {
            completion([])
            return nil
        }
        
        let task = Network.session().dataTask(with: url) { (data, httpResponse, error) -> Void in
            DispatchQueue.main.async {
                if let response = httpResponse {
                    if checkHttpResponse(response: response) == false {
                        completion([])
                        return
                    }
                }
                
                if let err = error {
                    if checkError(error: err) == false {
                        completion([])
                        return
                    }
                }
                
                guard let data = data, error == nil else {
                    completion([])
                    return
                }
                
                let optionalBookmarks = ParseJSON.bookmarks(data: data)
                completion(optionalBookmarks)
            }
        }
        
        task.resume()
        return task
    }
    
    // MARK: - Check for updates
    static func checkForUpdates(completion: @escaping (Date?) -> Void) -> URLSessionTask? {
        urlQuery.scheme = "https"
        urlQuery.host = "api.pinboard.in"
        urlQuery.path = "/v1/posts/update"
        urlQuery.queryItems = [
            (URLQueryItem(name: "auth_token", value: userToken) as URLQueryItem),
            (URLQueryItem(name: "format", value: "json") as URLQueryItem),
        ]
        
        guard let url = urlQuery.url else {
            completion(nil)
            return nil
        }
        
        let task = Network.session().dataTask(with: url) { (data, httpResponse, error) -> Void in
            DispatchQueue.main.async {
                if let response = httpResponse {
                    if checkHttpResponse(response: response) == false {
                        completion(nil)
                        return
                    }
                }
                
                if let err = error {
                    if checkError(error: err) == false {
                        completion(nil)
                        return
                    }
                }
                
                guard let data = data, error == nil else {
                    completion(nil)
                    return
                }
                let updateDate = ParseJSON.date(data: data, key: "update_time")
                completion(updateDate)
            }
        }
        
        task.resume()
        return task
    }
    
    // MARK: - Delete bookmark
    static func deleteBookmark(url: URL, completion: @escaping (String?) -> Void) -> URLSessionTask? {
        let urlString = url.absoluteString
        
        urlQuery.scheme = "https"
        urlQuery.host = "api.pinboard.in"
        urlQuery.path = "/v1/posts/delete"
        urlQuery.queryItems = [
            URLQueryItem(name: "url", value: urlString) as URLQueryItem,
            (URLQueryItem(name: "auth_token", value: userToken) as URLQueryItem),
            (URLQueryItem(name: "format", value: "json") as URLQueryItem),
        ]
        
        guard let url = urlQuery.url else {
            completion(nil)
            return nil
        }
        
        let task = Network.session().dataTask(with: url) { (data, httpResponse, error) -> Void in
            DispatchQueue.main.async {
                guard let data = data, error == nil else {
                    completion(nil)
                    return
                }
                let resultCode = ParseJSON.string(data: data, key: "result_code")
                completion(resultCode)
            }
        }
        
        task.resume()
        return task
    }
    
    // MARK: - Add bookmark
    static func addBookmark(url: URL, title: String, shared: Bool, description: String = "", tags: [String] = [], dt: Date? = nil, toread: Bool = false, completion: @escaping (String?) -> Void) -> URLSessionTask? {
        let urlString = url.absoluteString
        let tagsString = tags.joined(separator: " ")
        let shared = !shared
        
        urlQuery.scheme = "https"
        urlQuery.host = "api.pinboard.in"
        urlQuery.path = "/v1/posts/add"
        urlQuery.queryItems = [
            URLQueryItem(name: "url", value: urlString) as URLQueryItem,
            (URLQueryItem(name: "description", value: title) as URLQueryItem),
            (URLQueryItem(name: "extended", value: description) as URLQueryItem),
            (URLQueryItem(name: "tags", value: tagsString) as URLQueryItem),
            (URLQueryItem(name: "dt", value: dt?.dateToString) as URLQueryItem),
            (URLQueryItem(name: "shared", value: shared.boolToString) as URLQueryItem),
            (URLQueryItem(name: "toread", value: toread.boolToString) as URLQueryItem),
            (URLQueryItem(name: "auth_token", value: userToken) as URLQueryItem),
            (URLQueryItem(name: "format", value: "json") as URLQueryItem),
        ]
        
        guard let url = urlQuery.url else {
            completion(nil)
            return nil
        }
        
        let task = Network.session().dataTask(with: url) { (data, httpResponse, error) -> Void in
            DispatchQueue.main.async {
                guard let data = data, error == nil else {
                    completion(nil)
                    return
                }
                
                let resultCode = ParseJSON.string(data: data, key: "result_code")
                completion(resultCode)
            }
        }
        
        task.resume()
        return task
    }
    
    // MARK: - Get tags
    static func fetchTags(completion: @escaping ([TagItem]) -> Void) -> URLSessionTask? {
        urlQuery.scheme = "https"
        urlQuery.host = "api.pinboard.in"
        urlQuery.path = "/v1/tags/get"
        urlQuery.queryItems = [
            (URLQueryItem(name: "auth_token", value: userToken) as URLQueryItem),
            (URLQueryItem(name: "format", value: "json") as URLQueryItem),
        ]
        
        guard let url = urlQuery.url else {
            completion([])
            return nil
        }
        
        let task = Network.session().dataTask(with: url) { (data, httpResponse, error) -> Void in
            DispatchQueue.main.async {
                guard let data = data, error == nil else {
                    completion([])
                    return
                }
                
                let optionalTags = ParseJSON.tags(data: data)
                completion(optionalTags)
            }
        }
        
        task.resume()
        return task
    }
}

//MARK: - Parse JSON

struct ParseJSON {
    static func string(data: Data, key: String) -> String? {
        if let jsonObject = (try? JSONSerialization.jsonObject(with: data as Data, options: [])) as? [String: AnyObject] {
            return jsonObject["\(key)"] as? String
        }
        return nil
    }
    
    static func date(data: Data, key: String) -> Date? {
        if let jsonObject = (try? JSONSerialization.jsonObject(with: data as Data, options: [])) as? [String: AnyObject] {
            let dateString = jsonObject["\(key)"] as? String
            return dateString?.stringToDate as Date?
        }
        return nil
    }
    
    static func tags(data: Data) -> [TagItem] {
        var tags = [TagItem]()
        do {
            if let jsonObject = try JSONSerialization.jsonObject(with: data as Data, options: []) as? [String: String] {
                for item in jsonObject {
                    guard let tag = TagItem(key: item.0, value: item.1) else { continue }
                    tags.append(tag)
                }
            }
        } catch {
            debugPrint("Error parsing tags JSON")
        }
        return tags
    }
    
    static func bookmarks(data: Data) -> [BookmarkItem] {
        var bookmarks = [BookmarkItem]()
        do {
            if let jsonObject = try JSONSerialization.jsonObject(with: data as Data, options: []) as? [AnyObject] {
                defaults.set(jsonObject.count, forKey: "bookmarkCount")
                for item in jsonObject {
                    guard let bookmarkDict = item as? [String: AnyObject],
                        let bookmark = BookmarkItem(json: bookmarkDict)
                        else { continue }
                    bookmarks.append(bookmark)
                }
            }
        } catch {
            debugPrint("Error parsing bookmarks JSON")
        }
        return bookmarks
    }
}

//MARK: - Network reachability
public class Reachability {
    class func isConnectedToNetwork() -> Bool {
        var zeroAddress = sockaddr_in(sin_len: 0, sin_family: 0, sin_port: 0, sin_addr: in_addr(s_addr: 0), sin_zero: (0, 0, 0, 0, 0, 0, 0, 0))
        zeroAddress.sin_len = UInt8(MemoryLayout.size(ofValue: zeroAddress))
        zeroAddress.sin_family = sa_family_t(AF_INET)
        
        let defaultRouteReachability = withUnsafePointer(to: &zeroAddress) {
            $0.withMemoryRebound(to: sockaddr.self, capacity: 1) {zeroSockAddress in
                SCNetworkReachabilityCreateWithAddress(nil, zeroSockAddress)
            }
        }
        var flags: SCNetworkReachabilityFlags = SCNetworkReachabilityFlags(rawValue: 0)
        if SCNetworkReachabilityGetFlags(defaultRouteReachability!, &flags) == false {
            return false
        }
        let isReachable = (flags.rawValue & UInt32(kSCNetworkFlagsReachable)) != 0
        let needsConnection = (flags.rawValue & UInt32(kSCNetworkFlagsConnectionRequired)) != 0
        return (isReachable && !needsConnection)
    }
}
