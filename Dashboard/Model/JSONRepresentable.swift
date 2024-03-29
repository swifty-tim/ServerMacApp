//
//  JSONRepresentable.swift
//  CMS Remote Config
//
//  Created by Timothy Barnard on 30/10/2016.
//  Copyright © 2016 Timothy Barnard. All rights reserved.
//

import Cocoa

class UniqueSting {
    
    static func apID()->String {
        return "JKHSDGHFKJGH454645GRRLKJF"
    }
    
    static func myNewUUID() -> String {
        let x = asMyUUID()
        return x.string
    }
    struct asMyUUID {
        let uuid: uuid_t
        
        public init() {
            let u = UnsafeMutablePointer<UInt8>.allocate(capacity:  MemoryLayout<uuid_t>.size)
            defer {
                u.deallocate(capacity: MemoryLayout<uuid_t>.size)
            }
            uuid_generate_random(u)
            self.uuid = asMyUUID.uuidFromPointer(u)
        }
        
        public init(_ string: String) {
            let u = UnsafeMutablePointer<UInt8>.allocate(capacity:  MemoryLayout<uuid_t>.size)
            defer {
                u.deallocate(capacity: MemoryLayout<uuid_t>.size)
            }
            uuid_parse(string, u)
            self.uuid = asMyUUID.uuidFromPointer(u)
        }
        
        init(_ uuid: uuid_t) {
            self.uuid = uuid
        }
        
        private static func uuidFromPointer(_ u: UnsafeMutablePointer<UInt8>) -> uuid_t {
            // is there a better way?
            return uuid_t(u[0], u[1], u[2], u[3], u[4], u[5], u[6], u[7], u[8], u[9], u[10], u[11], u[12], u[13], u[14], u[15])
        }
        
        public var string: String {
            let u = UnsafeMutablePointer<UInt8>.allocate(capacity:  MemoryLayout<uuid_t>.size)
            let unu = UnsafeMutablePointer<Int8>.allocate(capacity:  37) // as per spec. 36 + null
            defer {
                u.deallocate(capacity: MemoryLayout<uuid_t>.size)
                unu.deallocate(capacity: 37)
            }
            var uu = self.uuid
            memcpy(u, &uu, MemoryLayout<uuid_t>.size)
            uuid_unparse_lower(u, unu)
            return String(validatingUTF8: unu)!
        }
    }
}

protocol JSONRepresentable {
    var JSONRepresentation: AnyObject { get }
}

protocol JSONSerializable: JSONRepresentable {
    init()
    init(dict:[String:Any])
    init(dict: [String])
    init(dict: String)
}

extension JSONSerializable {
//    var databaseName: String {
//        get {
//            return self.databaseName
//        }
//        set(newVal) { self.databaseName = newVal }
//    }
}


//: ### Implementing the functionality through protocol extensions
extension JSONSerializable {
    var JSONRepresentation: AnyObject {
        var representation = [String: AnyObject]()
        //print(self)
        for case let (label?, value) in Mirror(reflecting: self).children {
            
            
            switch value {
                
            case let value as Dictionary<String, AnyObject>:
                representation[label] = value as AnyObject?
                
            case let value as Array<CGFloat>:
                representation[label] = value as AnyObject?
                
            case let value as Array<String>:
                representation[label] = value as AnyObject?
                
            case let value as Array<AnyObject>:
                var anyObject = [AnyObject]()
                for ( _, objectVal ) in value.enumerated() {
                    var dict = [String:AnyObject]()
                    
                    if let jsonVal = objectVal as? JSONRepresentable {
                        
                        let jsonTest = jsonVal as! JSONSerializable
                    
                        if let jsonData = jsonTest.toJSON() {
                            
                            for (index, value) in convertStringToDictionary(text: jsonData) ?? [String: AnyObject]() {
                                
                                dict[index] = value
                            }
                            
                            anyObject.append(dict as AnyObject)
                        }
                    }
                }
                representation[label] = anyObject as AnyObject?
                
                
            case let value as AnyObject:
                if let myVal = convertToStr(name: value) {
                    representation[label] = myVal
                } else {
                    if let jsonVal = value as? JSONRepresentable {
                        var dict = [String:AnyObject]()
                    
                        let jsonTest = jsonVal as! JSONSerializable
                        if let jsonData = jsonTest.toJSON() {
                            
                            for (index, value) in convertStringToDictionary(text: jsonData) ?? [String: AnyObject]() {
                                
                                dict[index] = value
                            }
                        }
                        representation[label] = dict as AnyObject
                    }
                }
                
                
            default:
                
                break
            }
        }
        return representation as AnyObject
    }
}

extension JSONSerializable {
    
    func toData() -> [ String: AnyObject ]  {
        
        if let jsonObj = self.toJSON() {
            
            return self.convertStringToDictionary(text: jsonObj)!
        }
        return [:]
    }
    
    func toJSON() -> String? {
        let representation = JSONRepresentation
        
        guard JSONSerialization.isValidJSONObject(representation) else {
            return nil
        }
        
        do {
            let data = try JSONSerialization.data(withJSONObject: representation, options: [])
            return String(data: data, encoding: .utf8)
        } catch {
            return nil
        }
    }
    
    func objtToJSON( jsonObj : AnyObject ) -> String? {
        
        guard JSONSerialization.isValidJSONObject(jsonObj) else {
            return nil
        }
        
        do {
            let data = try JSONSerialization.data(withJSONObject: jsonObj, options: [])
            return String(data: data, encoding: .utf8)
        } catch {
            return nil
        }
    }
    
    func toJSONObjects() -> [String : AnyObject]? {
        let representation = JSONRepresentation
        
        guard JSONSerialization.isValidJSONObject(representation) else {
            return nil
        }
        
        return self.convertStringToDictionary(text: objtToJSON(jsonObj: representation)!)
    }
    
    func convertStringToJSONObject(text: String) -> ( String, AnyObject ) {
        if let data = text.data(using: String.Encoding.utf8) {
            do {
                let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String:AnyObject]
                
                return json!.getObjectAtIndex(index: 0)
                
            } catch let error as NSError {
                print(error)
            }
        }
        return ("", "" as AnyObject)
    }
    
    func convertStringToDictionary(text: String) -> [ String: AnyObject ]? {
        if let data = text.data(using: String.Encoding.utf8) {
            do {
                return try JSONSerialization.jsonObject(with: data, options: []) as? [String:AnyObject]
                
            } catch let error as NSError {
                print(error)
            }
        }
        return nil
    }
    
    func convertToStr( name: Any ) -> AnyObject? {
        
        var returnObject: AnyObject?
        
        if name is String {
            returnObject = name as AnyObject
        }
        
        if name is Int {
            returnObject = "\(name)" as AnyObject
        }
        
        if name is Bool {
            
            guard let keyBool = name as? Bool else {
                 return "0"  as AnyObject
            }
            
            returnObject = "0" as AnyObject
            
            if keyBool {
                returnObject = "1"  as AnyObject
            }
        }
        
        if name is Float {
            returnObject = "\(name)" as AnyObject
        }
        
        if name is Double {
            returnObject =  "\(name)" as AnyObject
        }
        
        if name is CGFloat {
            returnObject =  "\(name)" as AnyObject
        }
        
        return returnObject
    }
    
    /**
    - parameters:
        - objectID: id of the object past in 
        - postCompleted: return value of success state

    */
    
    func getInBackground<T:JSONSerializable>(_ objectID: String, ofType type:T.Type , appKey: String = "", getCompleted : @escaping (_ succeeded: Bool, _ data: T) -> ()) {
        
        let className = ("\(type(of: self))")
        
        if objectID == "" {
            getCompleted(false, T())
        }
        
        let url = UserDefaults.standard.string(forKey: "URL") ?? "http://0.0.0.0:8181"
        
        var key = UniqueSting.apID()
        
        if appKey != "" {
            key = appKey
        }
        
        let apiEndpoint = "/api/"+key+"/storage/"
        
        let networkURL = url + apiEndpoint + className + "/"+objectID
        
        guard let endpoint = URL(string: networkURL) else {
            print("Error creating endpoint")
            getCompleted(false, T())
            return
        }
        var request = URLRequest(url: endpoint)
        request.httpMethod = "GET"
        request.setValue("123456", forHTTPHeaderField: "authen_key")
        //if let token = _currentUser?.currentToken {
        //    request.setValue("Bearer \(token)", forHTTPHeaderField: "authorization")
        // }
        
        URLSession.shared.dataTask(with: request) { (data, response, error) in
            
            if ((error) != nil) {
                getCompleted(false, T())
            }
            
            guard let data = data else {
                getCompleted(false, T())
                return
            }
            
            do {
                
                let dataObjects = try JSONSerialization.jsonObject(with: data as Data, options: .allowFragments) as! [String:Any]
                
                guard let allObjects = dataObjects["data"] as? NSArray else {
                    getCompleted(false, T())
                    return
                }

                guard let object = allObjects.firstObject else {
                    getCompleted(false, T())
                    return
                }
                
                getCompleted(true, T(dict: object as! [String:Any]))
                
            } catch let error as NSError {
                print(error)
            }
            
        }.resume()
    }

    /**
     - parameters:
     - type: struct name
     - getCompleted: return value of success state
     - data: return array of objects
     */
    
    func getGenericAllInBackground(tableName: String, appKey: String = "", getCompleted : @escaping (_ succeeded: Bool, _ data: GenericTable? ) -> ()) {
        
        //let className = ("\(type(of: T()))")
        
        let url = UserDefaults.standard.string(forKey: "URL") ?? "http://0.0.0.0:8181"
        
        var key = UniqueSting.apID()
        
        if appKey != "" {
            key = appKey
        }
        
        let apiEndpoint = "/api/"+key+"/storage/"
        
        let networkURL = url + apiEndpoint + tableName
        
        guard let endpoint = URL(string: networkURL) else {
            print("Error creating endpoint")
            return
        }
        var request = URLRequest(url: endpoint)
        request.httpMethod = "GET"
        request.setValue("123456", forHTTPHeaderField: "authen_key")
        //if let token = _currentUser?.currentToken {
        //    request.setValue("Bearer \(token)", forHTTPHeaderField: "authorization")
        // }
        
        var genericTable : GenericTable?
        
        URLSession.shared.dataTask(with: request) { (data, response, error) in
            
            if ((error) != nil) {
                getCompleted(false, genericTable)
            }
            
            guard let data = data else {
                return
            }
            
            do {
                
                let dataObjects = try JSONSerialization.jsonObject(with: data as Data, options: .allowFragments) as! [String:Any]
        
                var records = [Document]()
                
                guard let allObjects = dataObjects["data"] as? NSArray else {
                    getCompleted(false, genericTable)
                    return
                }

                
                for object in allObjects {
                
                    var parentChildren = [Document]()
                    
                    if let parentObjects = object as? [String:Any] {
                        
                        for parentObject in parentObjects {
                    
                            let key = parentObject.key
                            let value = parentObject.value as AnyObject
                    
                            let childrenRecords = self.recursiveFindChildren(object: value)
                        
                            let parentDoc = Document(key: key, value: value, children: childrenRecords, hasChildren: childrenRecords.count)
                        
                            parentChildren.append(parentDoc)
                        }
                    }
                    
                    let parentDoc = Document(key: "", value: "" as AnyObject, children: parentChildren, hasChildren: parentChildren.count)
                    
                    records.append(parentDoc)
                }
                
                genericTable = GenericTable(dict: records )
            
                
            } catch let error as NSError {
                print(error)
            }
            
            getCompleted(true, genericTable)
            
            }.resume()
    }
    
    internal func recursiveFindChildren( object: AnyObject ) -> [Document] {
        
        var children = [Document]()
        
        func tryFindChildren( object: AnyObject ) {
            
            if let parentObjects = object as? [String:Any] {
                
                for childObject in parentObjects {
                    
                    let key = childObject.key
                    let value = childObject.value as AnyObject
                    
                    let childDoc = Document(key: key, value: value, children: [], hasChildren: 0)
                    children.append(childDoc)
                    
                    if self.recursiveChildren( value ) {
                        tryFindChildren(object: value )
                    }
                }
            }
        }
        
        tryFindChildren(object: object)
        
        
        return children

    }
    
    internal func recursiveChildren(_ object: AnyObject  ) -> Bool {
        
        if object is [String:AnyObject] || object is [AnyObject] {
            return true
        }
        return false
    }
    
    func genericRemoveInBackground(_ objectID: String, collectioName: String, appKey: String = "", deleteCompleted : @escaping (_ succeeded: Bool, _ data: String) -> ()) {
        
        let url = UserDefaults.standard.string(forKey: "URL") ?? "http://0.0.0.0:8181"
        
        var key = UniqueSting.apID()
        
        if appKey != "" {
            key = appKey
        }
        
        let apiEndpoint = "/api/"+key+"/storage/"
        
        let networkURL = url + apiEndpoint + collectioName + "/" + objectID
        
        guard let endpoint = URL(string: networkURL) else {
            print("Error creating endpoint")
            return
        }
        var request = URLRequest(url: endpoint)
        request.httpMethod = "DELETE"
        request.setValue("123456", forHTTPHeaderField: "authen_key")
        //if let token = _currentUser?.currentToken {
        //    request.setValue("Bearer \(token)", forHTTPHeaderField: "authorization")
        // }
        
        
        URLSession.shared.dataTask(with: request) { (data, response, error) in
            
            if ((error) != nil) {
                deleteCompleted(false, "Not removed")
            }
            
            guard let _ = data else {
                return
            }
            
            do {
                
                //let dataObjects = try JSONSerialization.jsonObject(with: data as Data, options: .allowFragments) as! [String:Any]
                
                
                
            } catch let error as NSError {
                print(error)
            }
            
            deleteCompleted(true, "Removed")
            
            }.resume()
        
    }

    
    func genericCollectionRemoveInBackground(_ collectioName: String, appKey: String = "", deleteCompleted : @escaping (_ succeeded: Bool, _ data: String) -> ()) {
        
        let url = UserDefaults.standard.string(forKey: "URL") ?? "http://0.0.0.0:8181"
        
        var key = UniqueSting.apID()
        
        if appKey != "" {
            key = appKey
        }
        
        let apiEndpoint = "/api/"+key+"/storage/"
        
        let networkURL = url + apiEndpoint + collectioName + "/"
        
        guard let endpoint = URL(string: networkURL) else {
            print("Error creating endpoint")
            return
        }
        var request = URLRequest(url: endpoint)
        request.httpMethod = "DELETE"
        request.setValue("123456", forHTTPHeaderField: "authen_key")
        //if let token = _currentUser?.currentToken {
        //    request.setValue("Bearer \(token)", forHTTPHeaderField: "authorization")
        // }
        
        
        URLSession.shared.dataTask(with: request) { (data, response, error) in
            
            if ((error) != nil) {
                deleteCompleted(false, "Not removed")
            }
            
            guard let _ = data else {
                return
            }
            
            do {
                
                //let dataObjects = try JSONSerialization.jsonObject(with: data as Data, options: .allowFragments) as! [String:Any]
                
                
                
            } catch let error as NSError {
                print(error)
            }
            
            deleteCompleted(true, "Removed")
            
            }.resume()
        
    }

    
    
    func removeInBackground(_ objectID: String, appKey: String = "", deleteCompleted : @escaping (_ succeeded: Bool, _ data: String) -> ()) {
        
        let className = ("\(type(of: self))")
        
        let url = UserDefaults.standard.string(forKey: "URL") ?? "http://0.0.0.0:8181"
        
        var key = UniqueSting.apID()
        
        if appKey != "" {
            key = appKey
        }
        
        let apiEndpoint = "/api/"+key+"/storage/"
        
        let networkURL = url + apiEndpoint + className + "/" + objectID
        
        guard let endpoint = URL(string: networkURL) else {
            print("Error creating endpoint")
            return
        }
        var request = URLRequest(url: endpoint)
        request.httpMethod = "DELETE"
        request.setValue("123456", forHTTPHeaderField: "authen_key")
        //if let token = _currentUser?.currentToken {
        //    request.setValue("Bearer \(token)", forHTTPHeaderField: "authorization")
        // }
        
        
        URLSession.shared.dataTask(with: request) { (data, response, error) in
            
            if ((error) != nil) {
                deleteCompleted(false, "Not removed")
            }
            
            guard let _ = data else {
                return
            }
            
            do {
                
                //let dataObjects = try JSONSerialization.jsonObject(with: data as Data, options: .allowFragments) as! [String:Any]
                
                
                
            } catch let error as NSError {
                print(error)
            }
            
            deleteCompleted(true, "Removed")
            
            }.resume()
        
    }

    
    func sendInBackground(_ objectID: String, appKey: String = "", postCompleted : @escaping (_ succeeded: Bool, _ data: NSData) -> ()) {
        
        let className = ("\(type(of: self))")
        
        if let json = self.toJSON() {
            let data = HTTPSConnection.convertStringToDictionary(text: json)
            
            var newData = [String:AnyObject]()
            newData = data!
            
            if objectID != "" {
                newData["_id"] = objectID as AnyObject?
            }
            
            let url = UserDefaults.standard.string(forKey: "URL") ?? "http://0.0.0.0:8181"
            
            var key = UniqueSting.apID()
            
            if appKey != "" {
                key = appKey
            }
            
            let apiEndpoint = "/api/"+key+"/storage/"
            
            let networkURL = url + apiEndpoint + className
            
            let dic = newData
            
            let request = NSMutableURLRequest(url: NSURL(string: networkURL)! as URL)
            let session = URLSession.shared
            request.httpMethod = "POST"
            request.setValue("123456", forHTTPHeaderField: "authen_key")
            
            do {
                request.httpBody = try JSONSerialization.data(withJSONObject: dic, options: [])
            } catch {
                //err = error
                request.httpBody = nil
            }
            
            
            request.addValue("application/json", forHTTPHeaderField: "Content-Type")
            request.addValue("application/json", forHTTPHeaderField: "Accept")
            
            let task = session.dataTask(with: request as URLRequest, completionHandler: { data, response, error -> Void in
               
                if ((error) != nil) {
                    print(error!.localizedDescription)
                    postCompleted(false, NSData())
                } else {
                    postCompleted(true, data! as NSData)
                }
            })
            
            task.resume()
        }
    }
}

extension Array where Element: JSONSerializable {
    
    /**
     getFilteredInBackground
     - parameters:
     - type: struct name
     - query: Dictionary of objects to find : ("name":"Timothy")
     - getCompleted: return value of success state
     - data: return array of objects
     
     */
    
    func getFilteredInBackground<T:JSONSerializable>(ofType type:T.Type,  query: [String:AnyObject], appKey: String = "", getCompleted : @escaping (_ succeeded: Bool, _ data: [T]) -> ()) {
        
        let className = ("\(type(of: T()))")
        
        let url = UserDefaults.standard.string(forKey: "URL") ?? "http://0.0.0.0:8181"
        
        var key = UniqueSting.apID()
        
        if appKey != "" {
            key = appKey
        }
        
        let apiEndpoint = "/api/"+key+"/storage/query/"
        
        let networkURL = url + apiEndpoint + className
        
        guard let endpoint = URL(string: networkURL) else {
            print("Error creating endpoint")
            return
        }
        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.setValue("123456", forHTTPHeaderField: "authen_key")
        //if let token = _currentUser?.currentToken {
        //    request.setValue("Bearer \(token)", forHTTPHeaderField: "authorization")
        // }
        
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: query, options: [])
        } catch {
            //err = error
            request.httpBody = nil
        }
        
        
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        
        var allT = [T]()
        
        URLSession.shared.dataTask(with: request) { (data, response, error) in
            
            if ((error) != nil) {
                getCompleted(false, allT)
            }
            
            guard let data = data else {
                return
            }
            
            do {
                
                let dataObjects = try JSONSerialization.jsonObject(with: data as Data, options: .allowFragments) as! [String:Any]
                
                guard let allObjects = dataObjects["data"] as? NSArray else {
                    getCompleted(false, allT)
                    return
                }
                
                for object in allObjects {
                    
                    if let newObject = object as? [String:Any] {
                        allT.append(T(dict: newObject ))
                    }
                    else if let newStringArr = object as? [String] {
                        allT.append(T(dict: newStringArr))
                    }
                    else if let newString = object as? String {
                        allT.append(T(dict: newString))
                    }
                }
                
            } catch let error as NSError {
                print(error)
            }
            
            getCompleted(true, allT)
            
            }.resume()
    }

    
    
    /**
     getAllInBackground
     - parameters:
        - type: struct name
        - getCompleted: return value of success state
        - data: return array of objects
     */
    
    func getAllInBackground<T:JSONSerializable>(ofType type:T.Type, appKey: String = "", getCompleted : @escaping (_ succeeded: Bool, _ data: [T]) -> ()) {
        
        let className = ("\(type(of: T()))")
        
        let url = UserDefaults.standard.string(forKey: "URL") ?? "http://0.0.0.0:8181"
        
        var key = UniqueSting.apID()
        
        if appKey != "" {
            key = appKey
        }
        
        let apiEndpoint = "/api/"+key+"/storage/"
        let networkURL = url + apiEndpoint + className
        
        guard let endpoint = URL(string: networkURL) else {
            print("Error creating endpoint")
            return
        }
        var request = URLRequest(url: endpoint)
        request.httpMethod = "GET"
        request.setValue("123456", forHTTPHeaderField: "authen_key")
        //if let token = _currentUser?.currentToken {
        //    request.setValue("Bearer \(token)", forHTTPHeaderField: "authorization")
        // }
        
        var allT = [T]()
        
        URLSession.shared.dataTask(with: request) { (data, response, error) in
            
            if ((error) != nil) {
                getCompleted(false, allT)
            }
            
            guard let data = data else {
                return
            }
            
            do {
                
                let dataObjects = try JSONSerialization.jsonObject(with: data as Data, options: .allowFragments) as! [String:Any]
                
                guard let allObjects = dataObjects["data"] as? NSArray else {
                    getCompleted(false, allT)
                    return
                }
                
                for object in allObjects {
                    
                    if let newObject = object as? [String:Any] {
                         allT.append(T(dict: newObject ))
                    }
                    else if let newStringArr = object as? [String] {
                         allT.append(T(dict: newStringArr))
                    }
                    else if let newString = object as? String {
                         allT.append(T(dict: newString))
                    }
                }
                
            } catch let error as NSError {
                print(error)
            }
            
            getCompleted(true, allT)
        
        }.resume()
        
    }
}


