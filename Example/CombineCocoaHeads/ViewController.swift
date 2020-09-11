//
//  ViewController.swift
//  CombineCocoaHeads
//
//  Created by Hai\ Feng\ Kao on 09/10/2020.
//  Copyright (c) 2020 Hai\ Feng\ Kao. All rights reserved.
//

import UIKit
import OpenCombine

class ViewController: UIViewController {
    var disp: AnyCancellable?
    var resumableSubscription: (Cancellable & Resumable)?
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        /*
        let a = CurrentValueSubject<Int, Error>(1)
        self.disp = a.sink { (completion) in
            print(completion)
        } receiveValue: { (val) in
            print(val)
        }
        
        a.send(8)*/

        
        /*
        class SomeObject {
            var value: Int = 1 {
        didSet {
                print(value)
              }
        } }
        // 2
          let object = SomeObject()
          // 3
        let publisher = (1 ..< Int.max).publisher
        // 4
          _ = publisher
            .assign(to: \.value, on: object)
 */
        
        resumableSubscription = (0 ..< 100).publisher.flatMap(maxPublishers: .max(1)) { value in
            /*
            return Future<String, Never> { promise in
                            let v = value
                            DispatchQueue.main.async {
                                promise(.success("\(v)"))
                            }
            }*/
            return Just<Int>(value)
        }.resumableSink { (completion) in
            print(completion)
        } receiveValue: { (val) in
            print(val)
            
            return false
        }

    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

}

public protocol Resumable {
    func resume()
}

public extension Publisher {
    func resumableSink(
        receiveCompletion: @escaping (Subscribers.Completion<Failure>) -> Void,
        receiveValue: @escaping (Output) -> Bool
    ) -> Cancellable & Resumable {
        let sink = Subscribers.ResumableSink<Output, Failure>(
            receiveCompletion: receiveCompletion,
            receiveValue: receiveValue
        )
        subscribe(sink)
        return sink
    }
}



public extension Subscribers {
    class ResumableSink<Input, Failure: Error>: Subscriber, Cancellable, Resumable {
        let receiveCompletion: (Subscribers.Completion<Failure>) -> Void
        let receiveValue: (Input) -> Bool

        var shouldPullNewValue: Bool = false

        var subscription: Subscription?

        init(
            receiveCompletion: @escaping (Subscribers.Completion<Failure>) -> Void,
            receiveValue: @escaping (Input) -> Bool
        ) {
            self.receiveCompletion = receiveCompletion
            self.receiveValue = receiveValue
        }

        public func receive(subscription: Subscription) {
            self.subscription = subscription
            resume()
        }

        public func receive(_ input: Input) -> Subscribers.Demand {
            shouldPullNewValue = receiveValue(input)
            return shouldPullNewValue ? .max(1) : .none
        }

        public func receive(completion: Subscribers.Completion<Failure>) {
            receiveCompletion(completion)
            subscription = nil
        }

        public func cancel() {
            subscription?.cancel()
            subscription = nil
        }

        public func resume() {
            guard !shouldPullNewValue else {
                return
            }
            shouldPullNewValue = true
            subscription?.request(.max(1))
        }
    }
}

