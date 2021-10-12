//
//  Helper.swift
//  CombineDemo
//
//  Created by Thanh Minh on 11/10/2021.
//

import Foundation

struct Helper {
    public static func example(of topic: String, action: @escaping ()->()){
        print("\n---Example of \(topic)---")
        action()
    }
}
