# AllCache

![Cocoapods](https://img.shields.io/cocoapods/v/AllCache.svg)
![Platform](https://img.shields.io/cocoapods/p/AllCache.svg)
![License](https://img.shields.io/cocoapods/l/AllCache.svg)
[![codebeat badge](https://codebeat.co/badges/edafed3a-62b7-4617-b9fb-556f46efeeef)](https://codebeat.co/projects/github-com-juanjoarreola-allcache-master)

### A generic cache for swift

With AllCache you can store any instance (if you can represent it as `Data`) in a memory and/or disk cache, it has a a set of classes on top of `Cache<T>` that makes very easy to work with `UIImage` instances.

#### Generic cache

```swift
let userCache = try! Cache<User>(identifier: "users", serializer: DataSerializer<User>())
let user = User(name: "Me", id: "1")
userCache.set(user, forKey: user.id)
```

#### Image cache

```swift
imageView?.requestImage(with: url, placeholder: UIImage(named: "placeholder"))
```
