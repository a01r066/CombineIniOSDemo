//
//  SampleController.swift
//  CombineDemo
//
//  Created by Thanh Minh on 11/10/2021.
//

import UIKit
import Combine

class BasicCombineController: UIViewController {
    
    var subscriptions: Set<AnyCancellable> = []
    let dealtHand = PassthroughSubject<Hand, HandError>()
   
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        // Part I - Publishers and Subscribers
        publishersAndSubscribers()
        
        // Part II - Transforming and Filtering with operators
        transformingAndFilteringOperators()
        
        // Part III - Combining Operators
        combiningOperators()
    }
    
    /// Part I - Publishers and Subscribers
    func publishersAndSubscribers(){
        Helper.example(of: "publisher") {
            let center = NotificationCenter.default
            let myNotification = NSNotification.Name("myNotification")

            let publisher = center.publisher(for: myNotification, object: nil)
            let subscription = publisher
                .print()
                .sink { _ in
                print("Notification received from a publisher!")
            }

            center.post(name: myNotification, object: nil)
            subscription.cancel()
        }

        Helper.example(of: "just Publisher") {
            let just = Just("Hello, World")
            just.sink {
                print("Received complete \($0)")
            } receiveValue: {
                print("Received value: \($0)")
            }
            .store(in: &self.subscriptions)
        }

        Helper.example(of: "assign(to:on:)") {
            class SomeObject {
                var value: String = "" {
                    didSet {
                        print(value)
                    }
                }
            }

            let object = SomeObject()
            ["Hello", "World"]
                .publisher
                .assign(to: \.value, on: object)
                .store(in: &self.subscriptions)
        }

        Helper.example(of: "PassThroughSubject") {
            let subject = PassthroughSubject<String, Never>()
            subject.sink { print($0) }
            .store(in: &self.subscriptions)

            subject.send("Hello")
            subject.send("World")
            subject.send(completion: .finished)
            subject.send("Still there?")
        }

        Helper.example(of: "CurrentValueSubject") {
            let subject = CurrentValueSubject<Int, Never>(0)

            subject
                .print()
                .sink(receiveValue: { print($0) })
                .store(in: &self.subscriptions)

            print(subject.value)

            subject.send(1)
            subject.send(2)

            print(subject.value)
            subject.send(completion: .finished)
        }

        Helper.example(of: "Type erasure") {
            let subject = PassthroughSubject<Int, Never>()
            let publisher = subject.eraseToAnyPublisher()

            publisher.sink(receiveValue: { print($0) })
                .store(in: &self.subscriptions)

            subject.send(1)
        }
        
        // Challenge
        Helper.example(of: "Create a Blackjack card dealer") {
            self.dealtHand
                .sink(receiveCompletion: {
                if case let .failure(error) = $0 {
                    print(error)
                }
            }, receiveValue: { hand in
                print("\(hand.cardString) for \(hand.points) points.")
            })
                .store(in: &self.subscriptions)
            self.deal(3)
        }
    }
    
    func deal(_ cardCount: UInt){
        var deck = cards
        var cardRemaining = 52
        var hand = Hand()
        
        for _ in 0..<cardCount {
            let randomIndex = Int.random(in: 0..<cardRemaining)
            hand.append(deck[randomIndex])
            deck.remove(at: randomIndex)
            cardRemaining -= 1
        }
        
        // Add code to update dealtHand here
        if(hand.points > 21){
            dealtHand.send(completion: .failure(.busted))
        } else {
            dealtHand.send(hand)
        }
    }
    
    
    /// Part II
    func transformingAndFilteringOperators(){
        Helper.example(of: "collect") {
            ["A", "B", "C", "D"].publisher
                .collect(2) // Gathers individual values from publisher into an array
                .sink(receiveCompletion: { print($0) }, receiveValue: {
                    print($0)
                })
                .store(in: &self.subscriptions)
            
        }
        
        let formatter = NumberFormatter()
        formatter.numberStyle = .spellOut
        Helper.example(of: "map") {
            [123, 4, 56].publisher
                .map { // Transforms values based on a passed in closure you provide
//                    formatter.string(from: NSNumber(value: $0))
                    formatter.string(for: NSNumber(integerLiteral: $0))
                }
                .sink(receiveCompletion: { print($0) }, receiveValue: { $0.map { print($0) } })
                .store(in: &self.subscriptions)
        }
        
        Helper.example(of: "replaceNil") {
            ["A", nil, "C"].publisher
                .replaceNil(with: "-") // Replaces nils publishers with the value you specify
                .map { $0! }
                .sink(receiveCompletion: { print($0) }, receiveValue: { print($0) })
                .store(in: &self.subscriptions)
        }
        
        Helper.example(of: "replaceEmpty(with:)") {
            let empty = Empty<Int,Never>()
            empty.replaceEmpty(with: 1) // Replaces empty publishers with the value you specify
                .sink(receiveCompletion: { print($0) }, receiveValue: { print($0) })
                .store(in: &self.subscriptions)
        }
        
        Helper.example(of: "scan") {
            var dailyGainLost: Int { .random(in: -10...10) }
            
            let october2021 = (0..<22).map { _ in dailyGainLost }
                .publisher
            october2021
                .scan(50, { latest, current in max(0, latest + current) }) // Lets you build upon the most recent output from the operator
                .sink(receiveValue: { _ in }).store(in: &self.subscriptions)
        }
        
        Helper.example(of: "flatMap") {
            let charlotte = Chatter(name: "Charlotte", message: "Hi, I'm charlotte!")
            let james = Chatter(name: "James", message: "Hi, I'm Jame!")
            
            let chat = CurrentValueSubject<Chatter, Never>(charlotte)
            chat
                .flatMap { $0.message } // Allows you to combine output from more than one publisher into one publisher to send to downstream consumers
                .sink(receiveValue: { print($0) })
                .store(in: &self.subscriptions)
            
            charlotte.message.value = "Charlotte: How's it going?"
            chat.value = james
            
            james.message.value = "James: Doing greate. You?"
            charlotte.message.value = "Charlotte: Doing well, Thanks!"
        }
        
        // Challenge
        Helper.example(of: "Challenge: Transforming & Filtering operators") {
            let phoneNumber = PhoneNumber()
            let input = PassthroughSubject<String, Never>()
           
            input
                .map(phoneNumber.convert)
                .replaceNil(with: 0)
                .collect(10)
                .map(phoneNumber.format)
                .map(phoneNumber.dial)
                .sink (receiveValue: { print($0) })
                .store(in: &self.subscriptions)
            
            "❤️234567890".forEach { input.send(String($0)) }
            "4085554321".forEach { input.send("\($0)") }
            "2175551212".forEach { input.send("\($0)") }
        }
        
        Helper.example(of: "filter") {
            let numbers = (1...10).publisher
          
            numbers.filter { $0.isMultiple(of: 3) } // Removes values from the stream based on a predicate you pass in
            .sink(receiveValue: { n in
                print("\(n) is a multiple of 3")
            })
            .store(in: &self.subscriptions)
        }
        
        Helper.example(of: "removeDuplicates") {
            let words = "Hi there! I don't don't wanna wanna miss a thing to thing"
                .components(separatedBy: " ")
                .publisher
            words
                .removeDuplicates() // Removes all duplicates from a stream, no argument need
                .sink(receiveValue: { print($0) })
                .store(in: &self.subscriptions)
        }
        
        Helper.example(of: "compactMap") {
            let strings = ["1.2", "3.a", "c.5", "4.5", "a.6"].publisher
            strings
                .compactMap { Float($0) } // Removes nils in the stream that apperear as a result of map operation
            .sink(receiveValue: { print($0) })
            .store(in: &self.subscriptions)
        }
        
        Helper.example(of: "ignoreOutput") {
            let numbers = (0...10_000).publisher
            numbers
                .ignoreOutput() // Simply ignores all output from publisher and waits until the completion event has been sent
                .sink(receiveCompletion: { print("Complete with ", $0) }, receiveValue: { print($0) })
                .store(in: &self.subscriptions)
        }
        
        Helper.example(of: "first(where:)") {
            let numbers = (1...9).publisher
            numbers
                .first(where: { $0 % 2 == 0 }) // Finds the first value satisfy to a predicate, and is lazy
                .sink(receiveCompletion: { print("Complete with \($0)") }, receiveValue: { print($0) })
                .store(in: &self.subscriptions)
        }
        
        Helper.example(of: "last(where:)") {
            let numbers = (1...9).publisher
            numbers
                .last(where: { $0 % 2 == 0 }) // Finds the last value satisfy to a predicate, and is greedy
                .sink(receiveCompletion: { print("Complete with \($0)") }, receiveValue: { print($0) })
                .store(in: &self.subscriptions)
        }
        
        Helper.example(of: "last(where:)") {
            let numbers = PassthroughSubject<Int, Never>()
            
            numbers
                .last(where: { $0 % 2 == 0 })
                .sink(receiveCompletion: { print("Complete with \($0)") }, receiveValue: { print($0) })
                .store(in: &self.subscriptions)
            
            numbers.send(1)
            numbers.send(2)
            numbers.send(3)
            numbers.send(4)
            numbers.send(5)
            numbers.send(completion: .finished)
        }
        
        Helper.example(of: "prefix") {
            let numbers = (0...10).publisher
            numbers.prefix(2) // Takes values from the publisher before the subscription is cancelled
                .sink(receiveCompletion: { print("Complte with \($0)") }, receiveValue: { print($0) })
                .store(in: &self.subscriptions)
        }
        
        Helper.example(of: "drop(while:)") {
            let numbers = (1...10).publisher
            numbers.drop(while: { $0 % 5 != 0 }) // Ignores values from the publisher before the subscription is cancelled
                .sink(receiveValue: { print($0) })
                .store(in: &self.subscriptions)
        }
        
        // Challenge
        Helper.example(of: "Challenge - Transforming & Filtering") {
            let numbers = (1...100).publisher
            
            numbers
//                .drop(while: { $0 % 50 != 0 })
                .dropFirst(50)
                .prefix(20)
                .filter { $0 % 2 == 0 }
                .sink(receiveCompletion: { print($0) }, receiveValue: { print($0) })
                .store(in: &self.subscriptions)
        }
    }
    
    
    /// Part III - Combining Operators
    func combiningOperators(){
        Helper.example(of: "prepend(output)") {
            let publisher = [3,4].publisher
            publisher
                .prepend(1, 2) // Works on variadic list of values and prepends that list onto the original publisher
                .prepend(-1, 0)
                .sink(receiveValue: { print($0) })
                .store(in: &self.subscriptions)
        }
        
        Helper.example(of: "prepend(sequence)") {
            let publisher = [5, 6, 7].publisher
            publisher
                .prepend([3, 4]) // Works on a object that conforms the Sequence protocol
                .prepend(Set(1...2))
                .prepend(stride(from: 6, through: 11, by: 2))
                .sink(receiveValue: { print($0) })
                .store(in: &self.subscriptions)
        }
        
        Helper.example(of: "prepend(publisher)") {
            let publisher1 = [3, 4].publisher
            let publisher2 = [1, 2].publisher
            
            publisher1
                .prepend(publisher2) // Prepend the values from a publisher before the original publisher
                .sink(receiveValue: { print($0) })
                .store(in: &self.subscriptions)
        }
        
        Helper.example(of: "prepend(publisher) #2") {
            let publisher1 = [3, 4].publisher
            let publisher2 = PassthroughSubject<Int, Never>()
            
            publisher1
                .prepend(publisher2) // The passed in publisher must send a completion event so the original publisher can start emitting its values
                .sink(receiveValue: { print($0) })
                .store(in: &self.subscriptions)
            
            publisher2.send(1)
            publisher2.send(2)
            publisher2.send(completion: .finished)
        }
        
        Helper.example(of: "append(output:") {
            let numbers = [1]
                .publisher
            numbers.append(2, 3) // Append the values from a publisher after the original publisher completes
                .append(4)
                .sink(receiveValue: { print($0) })
                .store(in: &self.subscriptions)
        }
        
        Helper.example(of: "append(output) #2") {
            let publisher = PassthroughSubject<Int, Never>()
            publisher.append(3, 4)
                .append(5).sink(receiveValue: { print($0) }).store(in: &self.subscriptions)
            
            publisher.send(1)
            publisher.send(2)
            publisher.send(completion: .finished)
        }
        
        Helper.example(of: "append(sequence)") {
            let numbers = [1, 2].publisher
            numbers.append(Set(3...5)) // Works on a Sequence conforming collection of values
                .append(Set([6,7]))
                .append(stride(from: 8, through: 15, by: 2))
                .sink(receiveValue: { print($0) })
                .store(in: &self.subscriptions)
        }
        
        Helper.example(of: "append(publisher)") {
            let publisher1 = [1, 2].publisher
            let publisher2 = [3, 4].publisher
            
            publisher1
                .append(publisher2) // Appends the entries set of the passed in publisher after original publisher has completed
                .sink(receiveValue: { print($0) })
                .store(in: &self.subscriptions)
        }
        
        Helper.example(of: "Challenge: Making Phone Numbers") {
            let phoneNumbersPublisher = ["123-4567"].publisher
            let areaCode = "410"
            let phoneExtension = "901"
            
            phoneNumbersPublisher
                .prepend("1-", areaCode, "-")
                .append(" EXT ", phoneExtension)
                .collect()
//                .map { $0.joined() }
                .sink(receiveValue: { print($0.joined()) })
                .store(in: &self.subscriptions)
        }
        
        Helper.example(of: "switchToLatest") {
            let publisher1 = PassthroughSubject<Int, Never>()
            let publisher2 = PassthroughSubject<Int, Never>()
            let publisher3 = PassthroughSubject<Int, Never>()
            
            let publishers = PassthroughSubject<PassthroughSubject<Int, Never>, Never>()
            
            publishers
                .switchToLatest()
                .sink(receiveCompletion: { _ in print("Completed!") }, receiveValue: { print($0) })
                .store(in: &self.subscriptions)
            
            publishers.send(publisher1)
            publisher1.send(1)
            publisher1.send(2)
            publishers.send(publisher2)
            publisher1.send(3)
            publisher2.send(4)
            publisher2.send(5)
            publishers.send(publisher3)
            publisher2.send(6)
            publisher3.send(7)
            publisher3.send(8)
            
            publisher3.send(completion: .finished)
            publishers.send(completion: .finished)
        }
        
        Helper.example(of: "merge(with:)") {
            let publisher1 = PassthroughSubject<Int, Never>()
            let publisher2 = PassthroughSubject<Int, Never>()
            
            publisher1
                .merge(with: publisher2).sink { _ in
                print("Completed!")
            } receiveValue: { print($0) }
            .store(in: &self.subscriptions)
            
            publisher1.send(1)
            publisher1.send(2)
            publisher2.send(3)
            publisher1.send(4)
            publisher2.send(5)
            
            publisher1.send(completion: .finished)
            publisher2.send(completion: .finished)
        }
        
        Helper.example(of: "combineLatest") {
            let publisher1 = PassthroughSubject<Int, Never>()
            let publisher2 = PassthroughSubject<String, Never>()
            
            publisher1.combineLatest(publisher2)
                .sink { _ in
                print("Completed!")
            } receiveValue: { print($0) }
            .store(in: &self.subscriptions)
            
            publisher1.send(1)
            publisher1.send(2)
            publisher2.send("a")
            publisher2.send("b")
            publisher1.send(3)
            publisher2.send("c")
            
            publisher1.send(completion: .finished)
            publisher2.send(completion: .finished)
        }
        
        Helper.example(of: "zip") {
            let publisher1 = PassthroughSubject<Int, Never>()
            let publisher2 = PassthroughSubject<String, Never>()
            
            publisher1.zip(publisher2).sink { _ in
                print("Completed!")
            } receiveValue: { print($0) }.store(in: &self.subscriptions)
            
            publisher1.send(1)
            publisher1.send(2)
            publisher2.send("a")
            publisher2.send("b")
            publisher1.send(3)
            publisher2.send("c")
            publisher2.send("d")
            
            publisher1.send(completion: .finished)
            publisher2.send(completion: .finished)
        }
        
        Helper.example(of: "Challenge: Making Phone Numbers Part 2") {
            let phoneNumbersPublisher = ["123-4567", "555-1212", "555-1111", "123-6789"].publisher
            let areaCodePublisher = ["410", "757", "800", "540"].publisher
            let phoneExtensionPublisher = ["EXT 901", "EXT 523", "EXT 137", "EXT 100"].publisher
            
            areaCodePublisher
                .zip(phoneNumbersPublisher)
                .map { $0 + "-" + $1 }
                .zip(phoneExtensionPublisher)
                .map { $0 + " " + $1 }
                .sink { _ in
                    print("Completed!")
                } receiveValue: { print($0) }
                .store(in: &self.subscriptions)
        }
    }
}


