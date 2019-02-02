//
//  ViewController.swift
//  Example
//
//  Created by 柿森隆生 on 2019/01/27.
//  Copyright © 2019 Urotea. All rights reserved.
//

import UIKit
import RxSwift
import RealmSwift
import RealmX

// Define your models like regular Swift classes
class Dog: Object {
    @objc dynamic var name = ""
    @objc dynamic var age = 0
}

class ViewController: UIViewController {
    @IBAction func ButtonTouchDown(_ sender: Any) {
        // if button clicked, insert data.
        let realm = try! Realm()
        
        let dog = Dog()
        dog.name = "tama"
        dog.age = 5
        
        try! realm.write {
            realm.add(dog)
        }
    }
    
    let disposeBag = DisposeBag()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // deleteAllData
        self.cleanDataBase()
        // Use them like regular Swift objects
        let myDog = Dog()
        myDog.name = "Rex"
        myDog.age = 1
        print("name of dog: \(myDog.name)")
        // Get the default Realm
        let realm = try! Realm()

        // Query Realm for all dogs less than 2 years old
        let puppies = realm.objects(Dog.self).filter("age < 2")
        print("puppies.count is: \(puppies.count)") // => 0 because no dogs have been added to the Realm yet

        puppies.toObservable().subscribe(onNext: { (result: Results<Dog>) in
            print("count in subscribe: \(result.count)") // => The first time subscribe, next time when a dog who has less than 2 years old is added.
            print("name of dog in subscribe: \(result.first?.name)")
        }).disposed(by: self.disposeBag)

        // Query and update from any thread
        DispatchQueue(label: "background").async {
            autoreleasepool {
                print("is this not main thread?: \(!Thread.isMainThread)")
                let realm = try! Realm()
                let theDog = realm.objects(Dog.self).filter("age < 6")

                theDog
                    .toObservable()
                    .subscribeOn(ConcurrentDispatchQueueScheduler(qos: .background))
                    .subscribe(onNext: { (result: Results<Dog>) in
                        // The first time subscribe, next time when a dog who has less than 6 year old is added.
                        print("is this main thread?: \(Thread.isMainThread)")
                        print("count in complex thread: \(result.count)")
                        print("name in complex thread: \(result.first?.name)")
                    }).disposed(by: self.disposeBag)
            }
        }
    }

    private func cleanDataBase() {
        let realm = try! Realm()
        try! realm.write {
            realm.deleteAll()
        }
    }
}
