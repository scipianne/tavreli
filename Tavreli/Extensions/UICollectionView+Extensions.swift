//
//  UICollectionView+Extensions.swift
//  Tavreli
//
//  Created by Maria Dagaeva on 01.05.2018.
//  Copyright © 2018 scipianne. All rights reserved.
//

import UIKit

public extension UICollectionView {
    
    @discardableResult
    public func register<T: UICollectionViewCell>(_: T.Type) -> UICollectionView {
        register(T.self, forCellWithReuseIdentifier: T.reuseIdentifier)
        
        return self
    }
    
    public func dequeueReusableCell<T: UICollectionViewCell>(for indexPath: IndexPath) -> T {
        guard let cell = dequeueReusableCell(withReuseIdentifier: T.reuseIdentifier, for: indexPath) as? T else {
            fatalError("Could not dequeue cell: \(T.reuseIdentifier)")
        }
        
        return cell
    }
    
}
