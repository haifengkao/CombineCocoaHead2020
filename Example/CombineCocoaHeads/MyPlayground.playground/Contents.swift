import Combine
import UIKit

var subscription: AnyCancellable?
var image: UIImage?
let url = URL(string: "https://source.unsplash.com/random")!

func getImage() -> AnyPublisher<UIImage?, Never> {
    return URLSession.shared
        .dataTaskPublisher(for: url)
        .map { data, _ in UIImage(data: data) }
        .print("image")
        .replaceError(with: nil)
        .eraseToAnyPublisher()
}

subscription = getImage().sink { img in
    image = img
    print("\(String(describing: img))")
}
















/*
let subject = CurrentValueSubject<Int, Error>(1)


subscription = subject.sink { completion in
    print(completion)
} receiveValue: { val in
    print(val)
}

subject.send(8)
subject.send(completion: .finished)*/






















/*: Sink
 ````
 extension Publisher {
    public func sink(
        receiveCompletion: @escaping (Subscribers.Completion<Failure>) -> Void,
        receiveValue: @escaping ((Output) -> Void)
    )  -> AnyCancellable
 }
 ````
 */

/*: Subscribers
 ````
 extension Subscribers {
    public func receive(subscription: Subscription)
    public func receive(_ value: Input) -> Subscribers.Demand
    public func receive(completion: Subscribers.Completion<Failure>)
    public func cancel()
 }
 ````
 */

/*: Publisher
 ````
 public protocol Publisher {
     func receive<Subscriber: OpenCombine.Subscriber>(subscriber: Subscriber)
 }
 ````
 */

/*: Subscription
 ````
 public protocol Subscription {
     func request(_ demand: Subscribers.Demand)
     func cancel()
 }
 ````
 */



















/*: Sink: YouTube App
 ````
 extension Publisher {
    public func sink(
        receiveCompletion: @escaping (Subscribers.Completion<Failure>) -> Void,
        receiveValue: @escaping ((Output) -> Void)
    )
 }
 ````
 */

/*: Subscribers: 粉絲
 ````
 extension Subscribers {
    public func receive(subscription: Subscription) 收到粉絲證了，開心☺️☺️☺️。用粉絲證要求片片
    public func receive(_ value: Input) -> Subscribers.Demand 收到直播主的最新直播
    public func receive(completion: Subscribers.Completion<Failure>) 直播主賺飽了宣布退休 or 直播主賺不到錢宣布引退倒台
    public func cancel() 爛頻道脫粉😡😡🤬，粉絲證滾
 }
 ````
 */

/*: Publisher: 直播主
 ````
 public protocol Publisher {
     func receive<Subscriber: OpenCombine.Subscriber>(subscriber: Subscriber) 有粉絲加入了，快發粉絲證給粉絲
 }
 ````
 */

/*: Subscription: 粉絲證
 ````
 public protocol Subscription {
     func request(_ demand: Subscribers.Demand) 敲碗~~~向直播主要求新片片
     func cancel() 撕掉粉絲證😡😡🤬
 }
 ````
 */



















/*
 subscription = (0 ..< Int.max).publisher.sink { (completion) in
 print(completion)
 } receiveValue: { (val) in
 print(val)
 }*/
 




















/*: Subscribers.Sink: 有一個粉絲叫Sink
 ````
 extension Subscribers {

    /// A simple subscriber that requests an unlimited number of values upon subscription.
    public final class Sink<Input, Failure: Error> {
        public func receive(subscription: Subscription) {
            switch status {
            case .subscribed, .terminal:
                subscription.cancel()
            case .awaitingSubscription:
                status = .subscribed(subscription)
                subscription.request(.unlimited)
            }
        }
    }
 }
 ````
 */



















// credit: https://onevcat.com/2019/12/backpressure-in-combine/

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




















/*
 var resumableSubscription2: (Cancellable & Resumable)?
 resumableSubscription2 = (0 ..< Int.max).publisher.resumableSink { (completion) in
 print(completion)
 } receiveValue: { (val) in
 print(val)

 return true
 }
 
*/


















var resumableSubscription: (Cancellable & Resumable)?
/*
resumableSubscription = (0 ..< Int.max).publisher.resumableSink { completion in
    print(completion)
} receiveValue: { val in
    print(val)

    return false
}

resumableSubscription?.resume()

resumableSubscription?.resume()

resumableSubscription?.resume()*/
 



















/*
 resumableSubscription = (0 ..< 100).publisher.flatMap { value in
    return Just<String>(String(value))
 }.resumableSink { (completion) in
 print(completion)
 } receiveValue: { (val) in
 print(val)

 return false
 }
 */





















// https://dev.to/yimajo/using-back-pressure-by-flatmap-in-combine-framework-4jmp
resumableSubscription = (0 ..< 100).publisher.flatMap(maxPublishers: .max(10)) { value in
    Future<String, Never> { promise in
        let v = value
        DispatchQueue.main.async {
            promise(.success("\(v)"))
        }
    }
}.resumableSink { completion in
    print(completion)
} receiveValue: { val in
    print(val)

    return false
}



























/*
class SomeObject {
    var value: Int = -1 {
        didSet {
            print(value)
        }
    }
}

let object = SomeObject()

let publisher = (0 ..< 100).publisher

subscription = publisher.assign(to: \.value, on: object)
 */























/*:
 ````
 extension Subscribers {

     public final class Assign<Root, Input>: Subscriber,
                                             Cancellable,
                                             CustomStringConvertible,
                                             CustomReflectable,
                                             CustomPlaygroundDisplayConvertible
     {
        
         public func receive(subscription: Subscription) {
             switch status {
             case .subscribed, .terminal:
                 subscription.cancel()
             case .awaitingSubscription:
                 status = .subscribed(subscription)
                 subscription.request(.unlimited)
             }
         }
 }

 ````
 */















internal enum SubscriptionStatus {
    case awaitingSubscription
    case subscribed(Subscription)
    case terminal
}


extension Subscribers {
    public final class LimitiedAssign<Root, Input>: Subscriber,
        Cancellable,
        Resumable,
        CustomStringConvertible,
        CustomReflectable,
        CustomPlaygroundDisplayConvertible {
        // NOTE: this class has been audited for thread safety.
        // Combine doesn't use any locking here.

        public typealias Failure = Never

        public private(set) var object: Root?

        public let keyPath: ReferenceWritableKeyPath<Root, Input>

        private var status = SubscriptionStatus.awaitingSubscription
        
        var subscription: Subscription?

        public var description: String { return "LimitedAssign \(Root.self)." }

        public var customMirror: Mirror {
            let children: [Mirror.Child] = [
                ("object", object as Any),
                ("keyPath", keyPath),
                ("status", status as Any)
            ]
            return Mirror(self, children: children)
        }

        public var playgroundDescription: Any { return description }

        public init(object: Root, keyPath: ReferenceWritableKeyPath<Root, Input>) {
            self.object = object
            self.keyPath = keyPath
        }

        public func receive(subscription: Subscription) {
            
            self.subscription = subscription
            switch status {
            case .subscribed, .terminal:
                subscription.cancel()
            case .awaitingSubscription:
                status = .subscribed(subscription)
                subscription.request(.max(1))
            }
        }

        public func receive(_ value: Input) -> Subscribers.Demand {
            switch status {
            case .subscribed:
                object?[keyPath: keyPath] = value
            case .awaitingSubscription, .terminal:
                break
            }
            return .none
        }

        public func receive(completion _: Subscribers.Completion<Never>) {
            cancel()
        }

        public func resume() {
            subscription?.request(.max(1))
        }
        
        public func cancel() {
            guard case let .subscribed(subscription) = status else {
                return
            }
            subscription.cancel()
            status = .terminal
            object = nil
        }
    }
}


public extension Publisher where Failure == Never {
    /// Assigns each element from a Publisher to a property on an object.
    ///
    /// - Parameters:
    ///   - keyPath: The key path of the property to assign.
    ///   - object: The object on which to assign the value.
    /// - Returns: A cancellable instance; used when you end assignment
    ///   of the received value. Deallocation of the result will tear down
    ///   the subscription stream.
    func limitedAssign<Root>(to keyPath: ReferenceWritableKeyPath<Root, Output>, on object: Root) -> Cancellable & Resumable {
        let subscriber = Subscribers.LimitiedAssign(object: object, keyPath: keyPath)
        subscribe(subscriber)
        return subscriber
    }
}


class SomeObject {
    var value: Int = -1 {
        didSet {
            print(value)
        }
    }
}

let object = SomeObject()

let publisher = (42 ..< Int.max).publisher

resumableSubscription = publisher.limitedAssign(to: \.value, on: object)

resumableSubscription?.resume()

resumableSubscription?.resume()


