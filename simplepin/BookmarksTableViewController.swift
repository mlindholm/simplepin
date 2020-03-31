//
//  BookmarksTableViewController.swift
//  simplepin
//
//  Created by Mathias Lindholm on 29.2.2016.
//  Copyright © 2016 Mathias Lindholm. All rights reserved.
//

import UIKit
import Fabric
import Crashlytics
import SafariServices

class BookmarksTableViewController: UITableViewController, UISearchBarDelegate, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
    let appDelegate = UIApplication.shared.delegate as? AppDelegate
    let activityIndicator = UIActivityIndicatorView(style: .gray)
    let defaults = UserDefaults(suiteName: "group.ml.simplepin")!
    let searchController = UISearchController(searchResultsController: nil)
    let notifications = NotificationCenter.default
    var bookmarksArray = [BookmarkItem]()
    var filteredBookmarks = [BookmarkItem]()
    var tagsArray = [TagItem]()
    var fetchAllPostsTask: URLSessionTask?
    var checkForUpdatesTask: URLSessionTask?
    var deleteBookmarkTask: URLSessionTask?
    var addBookmarkTask: URLSessionTask?
    var fetchTagsTask: URLSessionTask?
    var bookmarkToPass: BookmarkItem?
    var urlToPass: URL?
    var dontAddThisUrl: URL?
    var searchIsActive: Bool {return searchController.isActive && searchController.searchBar.text != ""}
    var searchTimer: Timer?

    @IBOutlet var emptyState: UIView!
    @IBOutlet var emptyStateSpinner: UIActivityIndicatorView!
    @IBOutlet var emptyStateLabel: UILabel!

    //MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()

        notifications.addObserver(forName: Notification.Name(rawValue: "loginSuccessful"), object: nil, queue: nil, using: successfullAddOrLogin)
        notifications.addObserver(forName: Notification.Name(rawValue: "bookmarkAdded"), object: nil, queue: nil, using: successfullAddOrLogin)
        notifications.addObserver(forName: Notification.Name(rawValue: "handleRequestError"), object: nil, queue: nil, using: handleRequestError)
        notifications.addObserver(forName: Notification.Name(rawValue: "tokenChanged"), object: nil, queue: nil, using: tokenChanged)
        notifications.addObserver(self, selector: #selector(self.didBecomeActive), name: UIApplication.didBecomeActiveNotification, object: nil)

        if defaults.string(forKey: "userToken") != nil {
            startFetchAllPosts()
        }

        sendExtensionAnalyticsToFabric()

        configureSearchController()

        self.refreshControl?.tintColor = UIColor.lightGray
        self.refreshControl?.addTarget(self, action: #selector(handleRefresh(_:)), for: UIControl.Event.valueChanged)

        let longPressRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(self.longPress(longPressGestureRecognizer:)))
        self.view.addGestureRecognizer(longPressRecognizer)

        tableView.estimatedRowHeight = 128.0
        tableView.rowHeight = UITableView.automaticDimension
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        checkForUpdatesTask?.cancel()
        deleteBookmarkTask?.cancel()
        fetchTagsTask?.cancel()
    }

    func sendExtensionAnalyticsToFabric() {
        if let openShareExtension = defaults.object(forKey: "openShareExtension") as? [Int] {
            for _ in openShareExtension {
                Answers.logContentView(withName: "Open Share Extension", contentType: "Extension", contentId: "extension-1", customAttributes: [:])
            }
            defaults.removeObject(forKey: "openShareExtension")
        }

        if let postToPinboard = defaults.object(forKey: "postToPinboard") as? [Int] {
            for _ in postToPinboard {
                Answers.logContentView(withName: "Post to Pinboard", contentType: "Extension", contentId: "extension-2", customAttributes: [:])
            }
            defaults.removeObject(forKey: "postToPinboard")
        }
    }

    func configureSearchController() {
        searchController.searchBar.delegate = self
        searchController.searchResultsUpdater = self
        searchController.dimsBackgroundDuringPresentation = false
        searchController.searchBar.autocapitalizationType = .none
        searchController.searchBar.spellCheckingType = .no
        searchController.searchBar.searchBarStyle = .default
        searchController.searchBar.barTintColor = .white
        searchController.searchBar.isTranslucent = false
        searchController.searchBar.layer.borderColor = UIColor.white.cgColor
        searchController.searchBar.layer.borderWidth = 1
        searchController.searchBar.setSearchFieldBackgroundImage(UIImage(named: "bg_searchfield"), for: .normal)
        searchController.searchBar.searchTextPositionAdjustment = UIOffset.init(horizontal: 7.0, vertical: 0.0)
        definesPresentationContext = true
        tableView.tableHeaderView = searchController.searchBar
    }

    func checkPasteboard() {
        if defaults.bool(forKey: "addClipboard") == true {
            if let pasteboardUrl = UIPasteboard.general.url {
                let filteredBookmarks = bookmarksArray.filter({ (item: BookmarkItem) -> Bool in
                    item.url == pasteboardUrl
                })
                if filteredBookmarks.count == 0 && self.dontAddThisUrl != pasteboardUrl {
                    let alert = UIAlertController(title: "Add Link to Pinboard?", message: "\(pasteboardUrl)", preferredStyle: UIAlertController.Style.alert)
                    alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { action in
                        self.dontAddThisUrl = pasteboardUrl as URL
                    }))
                    alert.addAction(UIAlertAction(title: "Add", style: .default, handler: { action in
                        self.urlToPass = pasteboardUrl as URL
                        self.performSegue(withIdentifier: "openEditBookmarkModal", sender: self)
                    }))
                    self.present(alert, animated: true, completion: nil)
                }
            }
        }
    }

    func showEmptyState(message: String, spinner: Bool) {
        emptyState.isHidden = false
        emptyStateLabel.text = message

        if spinner == true {
            emptyStateSpinner.startAnimating()
        } else {
            emptyStateSpinner.stopAnimating()
        }
    }

    func hideEmptyState() {
        emptyState.isHidden = true
        emptyStateSpinner.stopAnimating()
    }

    // MARK: - Events

    @objc func didBecomeActive() {
        if defaults.string(forKey: "userToken") != nil {
            checkPasteboard()
            startCheckForUpdates()
        }
    }

    func successfullAddOrLogin(notification: Notification) {
        startFetchAllPosts()
    }

    func handleRequestError(notification: Notification) {
        if let info = notification.userInfo as? Dictionary<String, String> {
            guard let title = info["title"],
                let message = info["message"] else {
                    return
            }
            alertError(title: title, message: message)
        }
    }

    func tokenChanged(notification: Notification) {
        dismiss(animated: true, completion: nil)
        appDelegate?.logOut()
    }

    // MARK: - Bookmark stuff

    func startFetchAllPosts() {
        if Reachability.isConnectedToNetwork() == false {
            showEmptyState(message: "No internet connection.", spinner: false)
        } else {
            showEmptyState(message: "Loading bookmarks…", spinner: true)
            fetchAllPostsTask = Network.fetchAllPosts() { [weak self] bookmarks in
                self?.bookmarksArray = bookmarks
                if bookmarks.count > 0 {
                    self?.hideEmptyState()
                } else {
                    self?.showEmptyState(message: "No bookmarks.", spinner: false)
                }
                self?.defaults.set(Date(), forKey: "lastUpdateDate")
                self?.tableView.reloadData()
                self?.checkPasteboard()
                self?.filterContentForSearchText(searchText: self?.searchController.searchBar.text ?? "")
            }
            fetchTagsTask = Network.fetchTags() { [weak self] tags in
                self?.tagsArray = tags
            }
        }
    }

    func startCheckForUpdates() {
        if Reachability.isConnectedToNetwork() == false {
            alertError(title: "Couldn't Refresh Bookmarks", message: "Try again when you're back online.")
        } else {
            checkForUpdatesTask = Network.checkForUpdates() { updateDate in
                guard let lastUpdateDate = self.defaults.object(forKey: "lastUpdateDate") as? Date, let updateDate = updateDate else {
                    return
                }
                if lastUpdateDate > updateDate && self.bookmarksArray.isEmpty {
                    self.startFetchAllPosts()
                } else if lastUpdateDate < updateDate {
                    self.startFetchAllPosts()
                } else {
                    return
                }
            }
        }
    }

    func showBookmark(currentUrl: URL?) {
        if let url = currentUrl {
            if defaults.bool(forKey: "openInSafari") == true {
                Helpers.open(scheme: url.absoluteString)
            } else {
                let config = SFSafariViewController.Configuration()
                config.entersReaderIfAvailable = true
                let vc = SFSafariViewController(url: url as URL, configuration: config)
                present(vc, animated: true, completion: nil)
            }
        }
    }

    @objc func handleRefresh(_ refreshControl: UIRefreshControl) {
        startCheckForUpdates()
        refreshControl.endRefreshing()
    }

    // MARK: - Search

    func filterContentForSearchText(searchText: String, scope: String = "All") {
        let searchTextArray = searchText.lowercased().components(separatedBy: " ")
        var searchResults: [Set<BookmarkItem>] = []

        for item in searchTextArray where !item.isEmpty {
            let searchResult = bookmarksArray.filter { bookmark in
                let title = bookmark.title.lowercased().contains(item)
                let description = bookmark.description.lowercased().contains(item)
                let tags = bookmark.tags.joined(separator: " ").lowercased().contains(item)
                if scope == "Tag" {
                    return tags
                }
                return title || description || tags
            }
            searchResults.append(Set(searchResult))
        }

        if let first = searchResults.first {
            var result = first
            for item in searchResults[1..<searchResults.count] {
                result = result.intersection(item)
            }
            let sortedResult = result.sorted(by: { $0.date > $1.date })
            filteredBookmarks = Array(sortedResult)
        } else {
            filteredBookmarks = []
        }

        if !searchText.isEmpty && filteredBookmarks.isEmpty {
            showEmptyState(message: "Couldn't find \(searchText)", spinner: false)
        } else {
            hideEmptyState()
        }

        tableView.reloadData()
    }

    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        searchTimer?.invalidate()
        searchTimer = Timer.scheduledTimer(timeInterval: 2.0, target: self, selector: #selector(self.logSearchQuery), userInfo: searchText, repeats: false)
    }

    @objc func logSearchQuery() {
        if let search = searchTimer?.userInfo as? String {
            if search.count > 2 {
                Answers.logSearch(withQuery: search, customAttributes: nil)
            }
        }
    }

    // MARK: - Table view

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if searchIsActive {
            return filteredBookmarks.count
        }
        return bookmarksArray.count
    }


    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "BookmarkCell", for: indexPath as IndexPath) as! BookmarkTableViewCell
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .none

        var bookmark: BookmarkItem
        if searchIsActive {
            bookmark = filteredBookmarks[indexPath.row]
        } else {
            bookmark = bookmarksArray[indexPath.row]
        }

        cell.titleLabel.text = bookmark.title

        if defaults.bool(forKey: "relativeDate") == true {
            cell.dateLabel.text = bookmark.date.timeAgo()
        } else {
            cell.dateLabel.text = formatter.string(from: bookmark.date)
        }

        if bookmark.description.isEmpty {
            cell.descriptionLabel.isHidden = true
        } else {
            cell.descriptionLabel.isHidden = false
            cell.descriptionLabel.text = bookmark.description
        }

        if bookmark.tags.count == 0 {
            cell.collectionView.collectionViewLayout.invalidateLayout()
            cell.collectionView.isHidden = true
        } else {
            cell.collectionView.isHidden = false
        }

        if bookmark.toread == false {
            cell.unreadIndicator.isHidden = true
            cell.titleLabel.font = UIFont.preferredFont(forTextStyle: UIFont.TextStyle.body)
        } else {
            cell.unreadIndicator.isHidden = false
            cell.titleLabel.font = UIFont.preferredFont(forTextStyle: UIFont.TextStyle.headline)
        }

        cell.privateIndicator.isHidden = bookmark.personal == false

        return cell
    }
    
    override func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        let cell = cell as! BookmarkTableViewCell
        cell.setCollectionViewDataSourceDelegate(dataSourceDelegate: self, forRow: indexPath.row)
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        var bookmark: BookmarkItem
        if searchIsActive {
            bookmark = filteredBookmarks[indexPath.row]
        } else {
            bookmark = bookmarksArray[indexPath.row]
        }

        if ((defaults.bool(forKey: "markAsRead") == true) && bookmark.toread == true) {
            if Reachability.isConnectedToNetwork() == true {
                self.addBookmarkTask = Network.addBookmark(url: bookmark.url, title: bookmark.title, shared: bookmark.personal, description: bookmark.description, tags: bookmark.tags, dt: bookmark.date, toread: false) { resultCode in
                    if resultCode == "done" {
                        bookmark.toread = false
                        self.tableView.reloadRows(at: [indexPath], with: .none)
                    }
                }
            }
        }

        self.tableView.deselectRow(at: indexPath as IndexPath, animated: true)
        self.showBookmark(currentUrl: bookmark.url as URL)
    }

    // MARK: - Collection View

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if searchIsActive {
            return filteredBookmarks[collectionView.tag].tags.count
        }
        return bookmarksArray[collectionView.tag].tags.count
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        var bookmark: BookmarkItem
        if searchIsActive {
            bookmark = filteredBookmarks[collectionView.tag]
        } else {
            bookmark = bookmarksArray[collectionView.tag]
        }

        let tag = bookmark.tags[indexPath.row]
        let size = tag.size(withAttributes: [NSAttributedString.Key.font: UIFont.preferredFont(forTextStyle: UIFont.TextStyle.subheadline)])
        let finalSize = CGSize(width: size.width + 12, height: 24)

        return finalSize
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "TagCell", for: indexPath as IndexPath) as! TagCollectionViewCell

        var bookmark: BookmarkItem
        if searchIsActive {
            bookmark = filteredBookmarks[collectionView.tag]
        } else {
            bookmark = bookmarksArray[collectionView.tag]
        }

        cell.tagLabel.text = bookmark.tags[indexPath.row]

        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        var bookmark: BookmarkItem
        if searchIsActive {
            bookmark = filteredBookmarks[collectionView.tag]
        } else {
            bookmark = bookmarksArray[collectionView.tag]
        }
        searchController.isActive = true
        searchController.searchBar.text = bookmark.tags[indexPath.row]
        filterContentForSearchText(searchText: bookmark.tags[indexPath.row], scope: "Tag")
        collectionView.deselectItem(at: indexPath as IndexPath, animated: true)
    }
    
    // MARK: - Navigation
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "openEditBookmarkModal" || segue.identifier == "openAddBookmarkModal" {
            let navigationController = segue.destination as! UINavigationController
            if let vc = navigationController.topViewController as? AddBookmarkTableViewController {
                if bookmarkToPass != nil {
                    vc.bookmark = bookmarkToPass
                } else {
                    vc.passedUrl = urlToPass as URL?
                }
                bookmarkToPass = nil
                vc.tagsArray = self.tagsArray
            }
        }

        if segue.identifier == "openSettingsModal" {
            let navigationController = segue.destination as! UINavigationController
            if let vc = navigationController.topViewController as? SettingsModalViewController {
                vc.bookmarksArray = self.bookmarksArray
            }
        }
    }
    // MARK: - Editing

    @objc func longPress(longPressGestureRecognizer: UILongPressGestureRecognizer) {
        if longPressGestureRecognizer.state == UIGestureRecognizer.State.began {
            let touchPoint = longPressGestureRecognizer.location(in: self.view)

            if let indexPath = tableView.indexPathForRow(at: touchPoint) {
                var bookmark: BookmarkItem
                if searchIsActive {
                    bookmark = filteredBookmarks[indexPath.row]
                } else {
                    bookmark = bookmarksArray[indexPath.row]
                }

                let alertController = UIAlertController(title: bookmark.title, message: nil, preferredStyle: UIAlertController.Style.actionSheet)

                func actionReadUnread(toread: Bool) -> UIAlertAction {
                    let title = toread == true ? "Read" : "Unread"
                    let action = UIAlertAction(title: "Mark as \(title)", style: UIAlertAction.Style.default, handler: { action in
                        self.addBookmarkTask = Network.addBookmark(url: bookmark.url, title: bookmark.title, shared: bookmark.personal, description: bookmark.description, tags: bookmark.tags, dt: bookmark.date, toread: !toread) { resultCode in
                            if resultCode == "done" {
                                bookmark.toread = !toread
                                self.tableView.reloadRows(at: [indexPath], with: .none)
                            } else {
                                self.alertErrorWithReachability(title: "Something Went Wrong", message: resultCode)
                                return
                            }
                        }
                    })
                    return action
                }
                let actionEdit = UIAlertAction(title: "Edit", style: UIAlertAction.Style.default, handler: { action in
                    self.bookmarkToPass = bookmark
                    self.performSegue(withIdentifier: "openEditBookmarkModal", sender: self)
                })
                let actionDelete = UIAlertAction(title: "Delete", style: UIAlertAction.Style.destructive, handler: { action in
                    self.deleteBookmarkTask = Network.deleteBookmark(url: bookmark.url) { resultCode in
                        if resultCode == "done" {
                            if self.searchController.isActive {
                                self.filteredBookmarks.remove(at: indexPath.row)
                                self.bookmarksArray.remove(at: indexPath.row)
                            } else {
                                self.bookmarksArray.remove(at: indexPath.row)
                            }
                            self.defaults.set(self.bookmarksArray.count, forKey: "bookmarkCount")
                            self.tableView.deleteRows(at: [indexPath], with: .left)
                            self.tableView.reloadData()
                        } else {
                            self.alertErrorWithReachability(title: "Something Went Wrong", message: resultCode)
                            return
                        }
                    }
                })
                let actionCancel = UIAlertAction(title: "Cancel", style: UIAlertAction.Style.cancel, handler: nil)

                alertController.addAction(actionReadUnread(toread: bookmark.toread))
                alertController.addAction(actionEdit)
                alertController.addAction(actionDelete)
                alertController.addAction(actionCancel)

                if let popoverController = alertController.popoverPresentationController {
                    popoverController.sourceView = tableView.cellForRow(at: indexPath)
                    popoverController.sourceRect = tableView.cellForRow(at: indexPath)!.bounds
                }
                
                self.present(alertController, animated: true, completion: nil)
            }
        }
    }

    deinit {
        notifications.removeObserver(self, name: Notification.Name(rawValue: "loginSuccessful"), object: nil)
        notifications.removeObserver(self, name: Notification.Name(rawValue: "bookmarkAdded"), object: nil)
        notifications.removeObserver(self, name: Notification.Name(rawValue: "handleRequestError"), object: nil)
        notifications.removeObserver(self, name: Notification.Name(rawValue: "tokenChanged"), object: nil)
        notifications.removeObserver(self, name: UIApplication.didBecomeActiveNotification, object: nil)
    }
}

// MARK: - Search result update

extension BookmarksTableViewController: UISearchResultsUpdating {
    func updateSearchResults(for searchController: UISearchController) {
        
    }
    
    func updateSearchResultsForSearchController(searchController: UISearchController) {
        filterContentForSearchText(searchText: searchController.searchBar.text!)
    }
}

// implement Hashable to support Sets (and Equatable to support Hashable)
extension BookmarkItem: Hashable, Equatable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(title)
        hasher.combine(description)
    }
}
func ==(lhs: BookmarkItem, rhs: BookmarkItem) -> Bool {
    return lhs.title == rhs.title && lhs.description == rhs.description
}
