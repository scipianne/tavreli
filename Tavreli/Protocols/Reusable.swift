//
//  Reusable.swift
//  Tavreli
//
//  Created by Maria Dagaeva on 01.05.2018.
//  Copyright © 2018 scipianne. All rights reserved.
//

import UIKit

public protocol Reusable: class {
    
    static var reuseIdentifier: String { get }
    
}

public extension Reusable where Self: UIView {
    
    public static var reuseIdentifier: String {
        return String(describing: self)
    }
    
}
