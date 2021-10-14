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

        // 1 - Networking
//        networkingWithCombine()
        
        // 2 - Sharing
        /* Note: Publisher usually a Struct (pass by value) instead of a class (pass by reference)
            if want to pass by a reference, use share()
        */
        sharingWithCombine()
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
    
    func sharingWithCombine(){
        guard let url = URL(string: "https://www.raywenderlich.com/") else { return }
        let shared = URLSession.shared
            .dataTaskPublisher(for: url)
            .map(\.data)
            .print()
            .share()
        
        shared.sink { _ in } receiveValue: { print("Subscription1 received \($0)") }.store(in: &self.subscriptions)
        
        print("Subscribing second")
        shared.sink { _ in } receiveValue: { print("Subscription2 received \($0)")
        }.store(in: &self.subscriptions)

        //        var subscription2: AnyCancellable? = nil
        //        DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
        //            print("Subscribing second")
        //            subscription2 = shared.sink(receiveCompletion: { _ in
        //
        //            }, receiveValue: { print("Subscription2 received \($0)") })
        //        }
        
        Helper.example(of: "multicast") {
            guard let url = URL(string: "https://www.raywenderlich.com/") else { return }
            let subject = PassthroughSubject<Data, URLError>()
            
            let multicasted = URLSession.shared.dataTaskPublisher(for: url)
                .map(\.data)
                .print("shared")
                .multicast(subject: subject)
            
            multicasted.sink { _ in
                
            } receiveValue: { print("Subscription1 received \($0)")
            }.store(in: &self.subscriptions)

            multicasted.sink { _ in
                
            } receiveValue: { print("Subscription2 received \($0)")
            }.store(in: &self.subscriptions)

            multicasted.connect()
            
            subject.send(Data())
        }
        
        Helper.example(of: "map & tryMap") {
            enum NameError: Error {
                case tooShort(String)
                case unknown
            }
            
            Just("Hello")
                .setFailureType(to: NameError.self)
//                .map { $0 + " world" } // Custom error
                .tryMap { $0 + " world" } // Swift.Error
//                .tryMap { throw NameError.tooShort($0)} // Test
                .mapError { $0 as? NameError ?? .unknown }
            .sink { completion in
                switch completion {
                case .finished:
                    print("Done!")
                case .failure(.tooShort(let name)):
                    print("\(name) too short!")
                case .failure(.unknown):
                    print("An unknown error occurred!")
                }
            } receiveValue: { print($0) }.store(in: &self.subscriptions)
        }
        
        Helper.example(of: "retry and catch") {
            let photoService = PhotoService()
            
            photoService.fetchPhoto(quality: .high)
                .handleEvents(
                    receiveSubscription: { _ in print("Trying...") },
                    receiveCompletion: {
                        guard case .failure(let error) = $0 else { return }
                        print("Got error: \(error)")
                    }
                )
                .retry(3)
                .catch { error -> PhotoService.Publisher in
                    print("Failed fetching high quality, falling back to low quality")
                    return photoService.fetchPhoto(quality: .low)
                }
                .replaceError(with: UIImage(named: "na.jpg")!)
                .sink(
                    receiveCompletion: { print("\($0)") },
                    receiveValue: { image in
//                        image
                        print("Got image: \(image)")
                    }
                )
                .store(in: &self.subscriptions)
        }
    }
}
