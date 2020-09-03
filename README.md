# AllCache

![License](https://img.shields.io/github/license/JuanjoArreola/AllCache)
[![codebeat badge](https://codebeat.co/badges/edafed3a-62b7-4617-b9fb-556f46efeeef)](https://codebeat.co/projects/github-com-juanjoarreola-allcache-master)

### A generic cache for swift

With AllCache you can store any instance (if you can represent it as `Data`) in a memory and/or disk.

#### Generic cache
If your class already conforms to `Codable` you can create a cache as follows:

```swift
let cache = try! Cache(identifier: "iceCream", serializer: JSONSerializer<Icecream>())
```

To store or get instances from the cache:

```swift
cache.set(IceCream(id: "1", flavor: "Vanilla"), forKey: "1")
let vanilla = try cache.instance(forKey: "1")
```

#### Fetcher

You can also make an asynchronous instance request from the cache and send a `Fetcher` instance, if the object doesn't exist in the cache the fetcher will fetch it or create it, you can conform to `Fetcher` and implement the `func fetch() -> Promise<FetcherResult<T>>` method, from there you can create or fetch the object:

```swift
struct IcecreamCreator: Fetcher {
    func fetch() -> Promise<FetcherResult<Icecream>> {
        let icecream = Icecream(id: "1", flavor: "Vanilla")
        return Promise().fulfill(with: FetcherResult(instance: icecream))
    }
}
```
You can then send the fetcher to the instance request, if the instance is not cached the `IcecreamCreator` will create it
```swift
cache.instance(forKey: "1", fetcher: IcecreamCreator()).onSuccess { icecream in
    print(icecream.flavor)
}
```

#### Cancel requests
All asynchronous requests return a `Promise<T>` object that you can cancel, add success or error handlers, or simply ignore them:

```swift
import ShallowPromises

let promise = cache.instance(forKey: "1", fetcher: IcecreamCreator()) { _ in }
promise.cancel()

```
The `Promise<T>` class belongs to the [ShallowPromises](https://github.com/JuanjoArreola/ShallowPromises) framework and needs to be imported separately.

#### Processor
If you need to further process the fetched instance you can send a `Processor<T>` to the cache, you need to implement the `process(_ instance: T) throws -> T` method in your custom `Processor`:

```swift
class ToppingProcessor: Processor<Icecream> {
    
    override func process(_ instance: Icecream) throws -> Icecream {
        instance.topping = self.identifier
        return instance
    }
}
```
and then send a processor instance when you request an instance from the cache:
```swift
let fetcher = IcecreamCreator()
let processor = ToppingProcessor(identifier: "Oreo")
let promise = cache.instance(forKey: "1", fetcher: fetcher, processor: processor)
```

Every `Processor` object has a `next` property so you can chain more than one processor:

```swift
let processor = ToppingProcessor(identifier: "Oreo")
processor.next = ToppingProcessor(identifier: "Chocolate syrup")
```

#### Image cache

AllCache has a set of classes and extensions to make easier to fetch and cache images, the method `requestImage(with:placeholder:processor:)` was added to `UIImageView` in an extension, internally the `imageView` requests an image with it's current size from a shared `Cache<UIImage>` instance using an `URL` as a key, the image returned from the cache is then set to the `UIImageView`'

```swift
let url = URL(string: "https://en.wikipedia.org/wiki/Ice_cream#/media/File:Ice_Cream_dessert_02.jpg")!
imageView.requestImage(with: url)
```
additionally, you can send a placeholder image, or a processor

If the image fetched has a different size from the size requested, the image is resized to be the exact size as the `UIImageView`, the resizer is just a `Processor<T>` subclass, if you send a processor in the parameters, it will be assigned to the `next` property of the resizer and it will be applied after the resize, you can chain multiple processors using the this mechanism.

`UIButton` also has a method to request an image, the difference is that you need to send an `UIControlState` in the parameters.
