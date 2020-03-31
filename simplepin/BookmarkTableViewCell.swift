//
//  BookmarkTableViewCell.swift
//  simplepin
//
//  Created by Mathias Lindholm on 29.2.2016.
//  Copyright © 2016 Mathias Lindholm. All rights reserved.
//

import UIKit

class BookmarkTableViewCell: UITableViewCell {
    let defaults = UserDefaults(suiteName: "group.ml.simplepin")!

    @IBOutlet var titleLabel: UILabel!
    @IBOutlet var descriptionLabel: UILabel!
    @IBOutlet var dateLabel: UILabel!
    @IBOutlet var unreadIndicator: UIImageView!
    @IBOutlet var privateIndicator: UIImageView!
    @IBOutlet weak var collectionView: UICollectionView!

    override func layoutSubviews() {
        super.layoutSubviews()

        privateIndicator.image = privateIndicator.image?.withRenderingMode(.alwaysTemplate)
        privateIndicator.tintColor = UIColor.gray

        unreadIndicator.image = unreadIndicator.image?.withRenderingMode(.alwaysTemplate)
        unreadIndicator.tintColor = Colors.Blue

        if defaults.bool(forKey: "boldTitleFont") == true {
            titleLabel.font = UIFont.preferredFont(forTextStyle: UIFont.TextStyle.headline)
        }
    }

    func setCollectionViewDataSourceDelegate
        <D: UICollectionViewDataSource & UICollectionViewDelegate>
        (dataSourceDelegate: D, forRow row: Int) {

        collectionView.delegate = dataSourceDelegate
        collectionView.dataSource = dataSourceDelegate
        collectionView.tag = row
        collectionView.reloadData()
    }

}
