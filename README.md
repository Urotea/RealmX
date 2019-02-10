# RealmX

[![Codacy Badge](https://api.codacy.com/project/badge/Grade/9b98b4b55ac04eaead8b966abbeab924)](https://app.codacy.com/app/Urotea/RealmX?utm_source=github.com&utm_medium=referral&utm_content=Urotea/RealmX&utm_campaign=Badge_Grade_Dashboard)
[![Reviewed by Hound](https://img.shields.io/badge/Reviewed_by-Hound-8E64B0.svg)](https://houndci.com)
[![Carthage compatible](https://img.shields.io/badge/Carthage-compatible-4BC51D.svg?style=flat)](https://github.com/Carthage/Carthage)

Realm + RxSwift eXtensions  
This is a micro library wrapping aroud RealmSwift and RxSwift.

## What you can do using this

ReamX can observe Realm Mobile DataBase using RxSwift.  
And more, you can write or delete object in reactive stream.  

RealmX provides three APIs.

```swift
Results<Element>.toObservable() -> Observable<Results<Element>>
```

```swift
Realm().doInTransaction<Element: Object>(
        object: [Element],
        inTransaction: @escaping ((Realm, [Element]) -> Void)) -> Completable
```

```swift
doInTransaction<Element: Object>(
        results: Results<Element>,
        inTransaction: @escaping ((Realm, Results<Element>) -> Void)) -> Completable
```

## Installation

### Carthage

- Add github "Urotea/RealmX" to your Cartfile.
- Run `carthage update`

### CocoaPods

- Add pod 'RealmX-rX' to your Podfile.
- Run `pod update`

## samples

### toObservable

This API emits a event when Realm records changed.

```swift
let realm = try! Realm()
realm.objects(Dog.self).toObservable().subscribe{
    // when Dog table changed, this print is called.
    print($0)
}
```

You can make a stream on background thread.

```swift
DispatchQueue.global(qos: .background).async {
    autoreleasepool {
        let realm = try! Realm()
        realm.objects(Dog.self).toObservable().subscribe {
            print($0)
        }
    }
}
```

### doInTransaction

This API provides Realm transaction on any stream.  
In particular, this is useful for getting json from the network and writing it to Realm.

```swift
let realm = try! Realm()
let dog = Dog()
dog.age = 1
dog.name = "pochi"

realm.doInTransaction(object: [dog]) { (realm: Realm, dogList: [Object]) in 
     realm.add(dogList.first!)
}.subscribe(onCompleted: {
    print("insert success.")
})
```

This show the most power when you use WebAPI(e.g. [Moya](https://github.com/Moya/Moya)) in Rx stream.

```swift
let provider = MoyaProvider<Dogs>()
provider
    .rx
    .request(.get)
    .observeOn(ConcurrentDispatchQueueScheduler(qos: .background))
    .map{
        let dog = Dog()
        dog.age = $0.age
        dog.name = $0.name
    }
    .flatMap {
        let realm = try! Realm()
        return realm.doInTransaction(object: [$0]) { realm, dogList in
            realm.add(dogList.first!)
        }
    }
    .subscribe {}
```

## Example App

To run example app, clone this repository and run `carthage bootstrap`.  
And then, you can run exsample app.  
Further, if you look RealmXTests directory, you can more understand how to use.

## Requirements
iOS 12.0 or later

## License

RealmX is available under the MIT license.
