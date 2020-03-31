//
//  ShareViewController.swift
//  Add Bookmark
//
//  Created by Mathias Lindholm on 04.07.2016.
//  Copyright © 2016 Mathias Lindholm. All rights reserved.
//

import UIKit
import Social

struct Bookmark {
    var url: NSURL
    var description: String
    var tags: [String]
    var personal: Bool
    var toread: Bool

    init() {
        self.url = NSURL()
        self.description = ""
        self.tags = []
        self.personal = false
        self.toread = false
    }
}

class ShareViewController: SLComposeServiceViewController, OptionsTableViewDelegate {
    let groupDefaults = UserDefaults(suiteName: "group.ml.simplepin")!
    var addBookmarkTask: URLSessionTask?
    var bookmark = Bookmark()

    override func viewDidLoad() {
        super.viewDidLoad()
        getUrl()
        bookmark.personal = groupDefaults.bool(forKey: "privateByDefault")
        bookmark.toread = groupDefaults.bool(forKey: "toreadByDefault")

        if groupDefaults.string(forKey: "userToken") == nil {
            let alert = UIAlertController(title: "Please Log In", message: "Sharing requires you to be logged in. Open Simplepin, log in and try again.", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: { _ in self.cancel() }))
            self.present(alert, animated: true, completion: nil)
        }

        var openExtensionCount = groupDefaults.object(forKey: "openShareExtension") as? [Int] ?? [Int]()
        openExtensionCount.append(1)
        groupDefaults.set(openExtensionCount, forKey: "openShareExtension")
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        addBookmarkTask?.cancel()
    }

    override func isContentValid() -> Bool {
        if contentText.isEmpty {
            return false
        }
        if groupDefaults.string(forKey: "userToken") == nil {
            return false
        }
        return true
    }

    override func didSelectPost() {
        self.addBookmarkTask = self.addBookmark(url: self.bookmark.url, title: self.contentText, shared: self.bookmark.personal, description: self.bookmark.description, tags: self.bookmark.tags, toread: self.bookmark.toread) { resultCode in

            if resultCode != "done" {
                let alert = UIAlertController(title: "Something Went Wrong", message: resultCode, preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
                self.present(alert, animated: true, completion: nil)
                return
            }

            var postToPinboardCount = self.groupDefaults.object(forKey: "postToPinboard") as? [Int] ?? [Int]()
            postToPinboardCount.append(1)
            self.groupDefaults.set(postToPinboardCount, forKey: "postToPinboard")

            self.extensionContext?.completeRequest(returningItems: [], completionHandler:nil)
        }
    }
    
    override func configurationItems() -> [Any]! {
        [optionsConfigurationItem]
    }

    lazy var optionsConfigurationItem: SLComposeSheetConfigurationItem = {
        let item = SLComposeSheetConfigurationItem()
        item!.title = "Options"
        item!.tapHandler = self.showOptions
        return item!
    }()

    func showOptions() {
        let vc = OptionsTableViewController(style: .plain)
        vc.passedBookmark = bookmark
        vc.delegate = self
        self.pushConfigurationViewController(vc)
    }

    func getUrl() {
        if let item = extensionContext?.inputItems.first as? NSExtensionItem {
            if let itemProvider = item.attachments?.first {
                if itemProvider.hasItemConformingToTypeIdentifier("public.url") {
                    itemProvider.loadItem(forTypeIdentifier: "public.url", options: nil, completionHandler: { (url, error) -> Void in
                        if let shareURL = url as? NSURL {
                            self.bookmark.url = shareURL
                        }
                    })
                }
            }
        }
    }

    func didEnterInformation(data: Bookmark) {
        bookmark = data
        self.popConfigurationViewController()
    }

    func addBookmark(url: NSURL, title: String, shared: Bool, description: String = "", tags: [String] = [], toread: Bool = false, completion: @escaping (String?) -> Void) -> URLSessionTask? {
        let userToken = groupDefaults.string(forKey: "userToken")! as String
        let urlString = url.absoluteString
        let tagsString = tags.joined(separator: " ")
        let shared = !shared

        var urlQuery = URLComponents()
        urlQuery.scheme = "https"
        urlQuery.host = "api.pinboard.in"
        urlQuery.path = "/v1/posts/add"
        urlQuery.queryItems = [
            URLQueryItem(name: "url", value: urlString),
            URLQueryItem(name: "description", value: title),
            URLQueryItem(name: "extended", value: description),
            URLQueryItem(name: "tags", value: tagsString),
            URLQueryItem(name: "shared", value: shared.boolToString),
            URLQueryItem(name: "toread", value: toread.boolToString),
            URLQueryItem(name: "auth_token", value: userToken),
            URLQueryItem(name: "format", value: "json"),
        ]

        guard let url = urlQuery.url else {
            completion(nil)
            return nil
        }

        let task = URLSession.shared.dataTask(with: url) { (data, httpResponse, error) -> Void in
            DispatchQueue.main.async {
                guard let data = data, error == nil else {
                    completion(nil)
                    return
                }
                let resultCode = self.parseJSON(data: data, key: "result_code")
                completion(resultCode)
            }
        }

        task.resume()
        return task
    }

    func parseJSON(data: Data, key: String) -> String? {
        if let jsonObject = (try? JSONSerialization.jsonObject(with: data, options: [])) as? [String: AnyObject] {
            return jsonObject["\(key)"] as? String
        }
        return nil
    }
}
