//
//  IntermediateCombineViewController.swift
//  CombineDemo
//
//  Created by Thanh Minh on 14/10/2021.
//

import UIKit
import Combine

class IntermediateCombineViewController: UIViewController {
    var subscriptions: Set<AnyCancellable> = []
    let decoder = JSONDecoder()

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        networkingWithCombine()
    }
    
    func networkingWithCombine(){
        Helper.example(of: "Networking with combine") {
            guard let url = URL(string: "https://jsonplaceholder.typicode.com/todos/1") else { return }
            URLSession.shared
                .dataTaskPublisher(for: url)
                .sink { completion in
                if case .failure(let err) = completion {
                    print("Retrieving data failed with error: \(err.localizedDescription)")
                }
            } receiveValue: { data, response in
                print("Retrieved data of size \(data.count), response \(response)")
            }.store(in: &self.subscriptions)
        }
        
        Helper.example(of: "decoder") {
            guard let url = URL(string: "https://jsonplaceholder.typicode.com/todos/1") else { return }
            URLSession.shared
                .dataTaskPublisher(for: url)
            //                .map(\.data)
            //                .decode(type: Todo.self, decoder: self.decoder)
                .tryMap({ data, _ in
                    try self.decoder.decode(Todo.self, from: data)
                })
                .sink { completion in
                    if case .failure(let err) = completion {
                        print("Retrieving data failed with error: \(err.localizedDescription)")
                    }
                } receiveValue: { object in
                    print("Retrieved object: \(object)")
                }.store(in: &self.subscriptions)
        }
    }
}
