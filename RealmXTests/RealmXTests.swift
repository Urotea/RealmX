//
//  RealmXTests.swift
//  RealmXTests
//
//  Created by 柿森隆生 on 2019/01/27.
//  Copyright © 2019 Urotea. All rights reserved.
//

import Quick
import Nimble
import RealmSwift
import Realm
import RxSwift
import RxBlocking
@testable import RealmX

class RealmXTests: QuickSpec {
    override func spec() {
        describe("toObservable emits when data changed") {
            context("no records") {
                beforeEach {
                    self.deleteAll()
                }
                afterEach {
                    self.deleteAll()
                }
                it("emits no records") {
                    let realm = try! Realm()
                    let blook = realm.objects(Dog.self).toObservable().toBlocking()
                    let results = try! blook.first()!
                    expect(results).to(haveCount(0))  // no records
                }
                it("emits a record when a data is inserted to realm.") {
                    let realm = try! Realm()
                    let resultsDog = realm.objects(Dog.self)
                        .toObservable()
                        .skip(1) // first, realm emits no records.
                    
                    // insert a dog 0.1 second after subscribing.(use toBlooking())
                    DispatchQueue.global(qos: .background).asyncAfter(deadline: .now() + 0.1) {
                        let dog = Dog()
                        dog.age = 1
                        dog.name = "pochi"
                        
                        let realm = try! Realm()
                        try! realm.write {
                            realm.add(dog)
                        }
                    }
                    
                    let results = try! resultsDog.toBlocking().first()! // realm emits a records because a dog added.
                    expect(results).to(haveCount(1))
                    expect(results.first!.age) == 1
                    expect(results.first!.name) == "pochi"
                }
            }
        }
    }
    
    private func deleteAll() {
        let realm = try! Realm()
        try! realm.write {
            realm.deleteAll()
        }
    }
}

class Dog: Object {
    @objc dynamic var name = ""
    @objc dynamic var age = 0
}
