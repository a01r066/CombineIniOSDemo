//
//  Chatter.swift
//  CombineDemo
//
//  Created by Thanh Minh on 12/10/2021.
//

import Foundation
import Combine

struct Chatter {
    let name: String
    let message: CurrentValueSubject<String, Never>
    
    init(name: String, message: String){
        self.name = name
        self.message = CurrentValueSubject(message)
    }
}
