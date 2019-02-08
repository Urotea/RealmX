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
            context("there is a record.") {
                beforeEach {
                    let dog = Dog()
                    dog.age = 1
                    dog.name = "pochi"

                    let realm = try! Realm()
                    try! realm.write {
                        realm.add(dog)
                    }
                }
                afterEach {
                    self.deleteAll()
                }
                it("emits a record when subscribing.") {
                    let realm = try! Realm()
                    let results = try! realm.objects(Dog.self)
                        .toObservable().toBlocking().first()!
                    expect(results).to(haveCount(1))
                    expect(results.first!.age) == 1
                    expect(results.first!.name) == "pochi"
                }
            }
        }
        describe("doInTransaction can write and delete.") {
            context("no records") {
                beforeEach {
                    self.deleteAll()
                }
                afterEach {
                    self.deleteAll()
                }
                it("can add object.") {
                    let dog = Dog()
                    dog.age = 1
                    dog.name = "pochi"
                    let realm = try! Realm()
                    let results = realm.doInTransaction(object: [dog]) { realm, dogList in
                        realm.add(dogList.first!)
                        }.toBlocking().materialize()
                    switch results {
                    case .completed:
                        let realm = try! Realm()
                        let ret = realm.objects(Dog.self)
                        expect(ret).to(haveCount(1))
                        expect(ret.first!.age) == 1
                        expect(ret.first!.name) == "pochi"
                    case .failed:
                        fail()
                    }
                }
                it("can add a object on background reactive stream.") {
                    let results = Observable.just((1, "pochi"))
                        .observeOn(ConcurrentDispatchQueueScheduler(qos: .background))
                        .map { (age: Int, name: String) -> Dog in
                            let dog = Dog()
                            dog.age = age
                            dog.name = name
                            return dog }
                        .flatMap { dog -> Completable in
                            let mRealm = try! Realm()
                            return mRealm
                                .doInTransaction(object: [dog]) { (realm: Realm, dogList: [Dog]) in
                                    realm.add(dogList.first!)
                                }}
                            .toBlocking().materialize()
                    switch results {
                    case .completed:
                        let realm = try! Realm()
                        let ret = realm.objects(Dog.self)
                        expect(ret).to(haveCount(1))
                        expect(ret.first!.age) == 1
                        expect(ret.first!.name) == "pochi"
                    case .failed:
                        fail()
                    }
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
