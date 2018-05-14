//
//  SquareCollectionViewCell.swift
//  Tavreli
//
//  Created by Maria Dagaeva on 01.05.2018.
//  Copyright © 2018 scipianne. All rights reserved.
//

import UIKit

class SquareCollectionViewCell: UICollectionViewCell {
    
    fileprivate var color: UIColor? = nil
    fileprivate lazy var imageView: UIImageView = UIImageView()

    var isChosen: Bool = false {
        didSet {
            backgroundColor = isChosen ? .red : color
        }
    }
    
    var towerMode: Bool = false {
        didSet {
            backgroundColor = towerMode ? .green : color
        }
    }

}

extension SquareCollectionViewCell {
    
    @discardableResult
    func configure(isWhite: Bool, piece: TavreliPiece?) -> SquareCollectionViewCell {
        color = isWhite ? .white : .black
        backgroundColor = color
        
        imageView.image = piece?.image
        if imageView.superview == nil {
            setupImageView()
        }
        
        return self
    }
    
    func setupImageView() {
        imageView.frame = CGRect(origin: .zero, size: frame.size)
        addSubview(imageView)
    }
    
}
