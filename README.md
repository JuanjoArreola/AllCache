# AllCache

![Cocoapods](https://img.shields.io/cocoapods/v/AllCache.svg)
![Platform](https://img.shields.io/cocoapods/p/AllCache.svg)
![License](https://img.shields.io/cocoapods/l/AllCache.svg)
[![codebeat badge](https://codebeat.co/badges/edafed3a-62b7-4617-b9fb-556f46efeeef)](https://codebeat.co/projects/github-com-juanjoarreola-allcache-master)

### A generic cache for swift

With AllCache you can store any instance (if you can represent it as `Data`) in a memory and/or disk cache.

#### Generic cache
If your class already conforms to `NSCoding` you can create a cache as follows:

```swift
let cache = try! Cache<IceCream>(identifier: "iceCream")
cache.set(IceCream(id: "1", flavor: "Vanilla"), forKey: "1")
let vanilla = try cache.object(forKey: "1")
```
#### Fetcher
You can also make an asynchronous object request from the cache and send a `fetcher` instance, if the object doesn't exist in the cache the fetcher will provide it, you can subclass `Fetcher` and implement the `fetch(respondIn queue: completion:)` method, from there you can create or fetch the object:

```swift
class IceCreamFetcher: Fetcher<IceCream> {

    override func fetch(respondIn queue: DispatchQueue, completion: @escaping (() throws -> FetcherResult<IceCream>) -> Void) -> Request<FetcherResult<IceCream>> {
        let request = Request<FetcherResult<IceCream>>(completionHandler: completion)
        queue.async {
            request.complete(with: FetcherResult<IceCream>(object: IceCream(id: "1", flavor: "Vanilla"), data: nil))
        }
        return request
    }
}
```
```swift
_ = cache.object(forKey: "1", fetcher: IceCreamFetcher(identifier: "1")) { (getIceCream) in
    do {
        let iceCream = try getIceCream()
    } catch {
        print(error)
    }
}
```
#### Cancel requests
All asynchronous requests return a `Request<T>` object that you can cancel, add success or failure handlers, or simply ignore them:

```swift
import AsyncRequest

let request = cache.object(forKey: "1", fetcher: IceCreamFetcher(identifier: "1")) { _ in }
request.cancel()
```
The `Request<T>` class belongs to the [AsyncRequest](https://github.com/JuanjoArreola/AsyncRequest) framework and needs to be imported separately.

#### Processor
If you need to further process the fetched object you can send a `Processor<T>` to the cache, you need to implement the `process(object:respondIn queue:completion:)` method in your custom `Processor`:
```swift
class ToppingProcessor: Processor<IceCream> {

    override open func process(object: IceCream, respondIn queue: DispatchQueue, completion: @escaping (_ getObject: () throws -> IceCream) -> Void) {
        queue.async {
            object.topping = "Oreo"
            completion({ return object })
        }
    }
}
```
and then send an instance when you request an object from the cache:
```swift
let fetcher = Fetcher<IceCream>(identifier: "2")
let processor = ToppingProcessor(identifier: "Oreo")
_ = cache.object(forKey: "1", fetcher: fetcher, processor: processor, completion: { _ in })
```
Every `Processor` object has a `next` property so you can chain more than one processor:
```swift
let processor = ToppingProcessor(identifier: "Oreo")
processor.next = ToppingProcessor(identifier: "Chocolate syrup")
```
#### Image cache
AllCache has a set of classes and extensions to make easier fetching and caching images, the method `requestImage(with:placeholder:processor:completion:)` was added to `UIImageView`, internally the `imageView` requests an image with it's current size from a shared `Cache<UIImage>` instance using an `URL` as a key, the image returned from the cache is then set to the `UIImageView`'
```swift
let url = URL(string: "https://en.wikipedia.org/wiki/Ice_cream#/media/File:Ice_Cream_dessert_02.jpg")!
_ = imageView.requestImage(with: url)
```
additionally, you can send a placeholder image, a processor or a completion closure to this method.

If the image fetched has a different size from the size requested, the image is resized to be the exact size as the `UIImageView`, the resizer is just a `Processor<T>` subclass, if you send a processor in the parameters, it will be assigned to the `next` property of the resizer and it will be applied after the resize, you can chain multiple processors using the this mechanism.

`UIButton` also has a method to request an image, the difference is that you need to send an `UIControlState` in the parameters.
