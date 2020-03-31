//
//  TagCollectionViewCell.swift
//  Simplepin
//
//  Created by Mathias Lindholm on 01.06.2016.
//  Copyright © 2016 Mathias Lindholm. All rights reserved.
//

import UIKit

class TagCollectionViewCell: UICollectionViewCell  {
    @IBOutlet var tagLabel: UILabel!

    override func layoutSubviews() {
        super.layoutSubviews()

        guard let string = tagLabel.text else { return }
        let index = string.startIndex...string.index(string.startIndex, offsetBy: 0)

        tagLabel.layer.masksToBounds = true
        tagLabel.layer.cornerRadius = 2
        tagLabel.layer.borderWidth = 0.5

        if string[index] == "." {
            tagLabel.textColor = UIColor.darkGray
            tagLabel.highlightedTextColor = UIColor.darkGray
            tagLabel.backgroundColor = UIColor.groupTableViewBackground
            tagLabel.layer.borderColor = UIColor.blue.withAlphaComponent(0.12).cgColor
        } else {
            tagLabel.textColor = Colors.Blue
            tagLabel.highlightedTextColor = Colors.Blue
            tagLabel.backgroundColor = Colors.LightBlue
            tagLabel.layer.borderColor = Colors.DarkBlue.withAlphaComponent(0.12).cgColor
        }
    }
}
