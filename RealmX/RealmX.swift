//
//  RealmX.swift
//  RealmX
//
//  Created by 柿森隆生 on 2019/01/27.
//  Copyright © 2019 Urotea. All rights reserved.
//

import Foundation
import RxSwift
import RealmSwift

public extension Results {
    /// realm results to RxSwift Observable
    /// This emits results when results updated.
    ///
    /// - Returns: RxSwift Observable
    public func toObservable() -> Observable<Results<Element>> {
        var token: NotificationToken?
        // RealmSwift oficial reference saies that self.realm will never return nil
        // https://realm.io/docs/swift/3.7.6/api/Classes/Results.html
        let config = self.realm!.configuration
        let threadSafeObject = ThreadSafeReference(to: self)
        return Observable.create { observer in
            DispatchQueue.main.async {
                do {
                    let realm = try Realm(configuration: config)
                    let results = realm.resolve(threadSafeObject)
                    token = results?.observe { (change: RealmCollectionChange) in
                        switch change {
                        case .initial(let obj):
                            observer.onNext(obj)
                        case .update(let obj, _, _, _):
                            observer.onNext(obj)
                        case .error(let error):
                            observer.onError(error)
                        }
                    }
                } catch {
                    observer.onError(error)
                }
            }
            return Disposables.create {
                token?.invalidate()
            }
        }
    }
}

public extension Realm {
    /// do in realm transaction with realm object.
    ///
    /// - Parameters:
    ///   - object: this is handed over to "inTransaction".
    ///   - inTransaction: this callback called in transaction.
    /// - Returns: RxSwift Completable.
    public func doInTransaction(
        object: [Object],
        inTransaction: @escaping ((Realm, [Object]) -> Void)) -> Completable {
        return Completable.create { completable in
            do {
                try self.write {
                    inTransaction(self, object)
                }
                completable(.completed)
            } catch {
                completable(.error(error))
            }
            return Disposables.create()
        }
    }

    /// do in realm transaction with realm results.
    ///
    /// - Parameters:
    ///   - results: this is handed over to "inTransaction".
    ///   - inTransaction: this callback called in transaction.
    /// - Returns: RxSwift Completable.
    public func doInTransaction<Element: Object>(
        results: Results<Element>,
        inTransaction: @escaping ((Realm, Results<Element>) -> Void)) -> Completable {
        return Completable.create { completable in
            do {
                try self.write {
                    inTransaction(self, results)
                }
                completable(.completed)
            } catch {
                completable(.error(error))
            }
            return Disposables.create()
        }
    }
}
