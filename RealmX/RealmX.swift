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
