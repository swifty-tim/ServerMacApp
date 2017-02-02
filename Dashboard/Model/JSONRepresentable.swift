//
//  JSONRepresentable.swift
//  CMS Remote Config
//
//  Created by Timothy Barnard on 30/10/2016.
//  Copyright © 2016 Timothy Barnard. All rights reserved.
//

import Cocoa

protocol JSONRepresentable {
    var JSONRepresentation: AnyObject { get }
}

protocol JSONSerializable: JSONRepresentable {
    init()
    init(dict:[String:Any])
    init(dict: [String])
    init(dict: String)
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
            returnObject = name as AnyObject
        }
        
        if name is Float {
            returnObject = name as AnyObject
        }
        
        if name is Double {
            returnObject = name as AnyObject
        }
        
        if name is CGFloat {
            returnObject = name as AnyObject
        }
        
        return returnObject
    }
    
    /**
    - parameters:
        - objectID: id of the object past in 
        - postCompleted: return value of success state

    */
    
    func getInBackground<T:JSONSerializable>(_ objectID: String, ofType type:T.Type , getCompleted : @escaping (_ succeeded: Bool, _ data: T) -> ()) {
        
        let className = ("\(type(of: self))")
        
        if objectID == "" {
            getCompleted(false, T())
        }
        
        var url: String = ""
        url = url.readPlistString(value: "URL", "http://0.0.0.0:8181")
        
        let apiEndpoint = "/storage/"
        let networkURL = url + apiEndpoint + className + "/"+objectID
        
        guard let endpoint = URL(string: networkURL) else {
            print("Error creating endpoint")
            getCompleted(false, T())
            return
        }
        var request = URLRequest(url: endpoint)
        request.httpMethod = "GET"
        
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
                
                let allObjects = dataObjects["data"] as? NSArray
                guard let object = allObjects?.firstObject else {
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
    
    func getGenericAllInBackground(tableName: String, getCompleted : @escaping (_ succeeded: Bool, _ data: GenericTable? ) -> ()) {
        
        //let className = ("\(type(of: T()))")
        
        var url: String = ""
        url = url.readPlistString(value: "URL", "http://0.0.0.0:8181")
        let apiEndpoint = "/storage/"
        let networkURL = url + apiEndpoint + tableName
        
        guard let endpoint = URL(string: networkURL) else {
            print("Error creating endpoint")
            return
        }
        var request = URLRequest(url: endpoint)
        request.httpMethod = "GET"
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
                
                var columns = [String]()
                var records = [AnyObject]()
                
                let allObjects = dataObjects["data"] as? NSArray
                
//                guard let firstObject = allObjects?.first else {
//                    getCompleted(false, genericTable)
//                    return
//                }
//                
//                if let newObject = firstObject as? [String:Any] {
//                    
//                    for (key, _) in newObject {
//                        columns.append(key)
//                    }
//                }
                
                var firstTime: Bool = true
                
                for object in allObjects! {

                    if let newObject = object as? [String:Any] {
                        
                        if firstTime {
                            for (key, _) in newObject {
                                columns.append(key)
                            }
                            firstTime = false
                        }
                        
                        records.append(newObject as AnyObject)
                        
                    }
                }
                
                genericTable = GenericTable(dict: records, columns: columns)
                
            
                
            } catch let error as NSError {
                print(error)
            }
            
            getCompleted(true, genericTable)
            
            }.resume()
        
    }
    
    func sendInBackground(_ objectID: String, postCompleted : @escaping (_ succeeded: Bool, _ data: NSData) -> ()) {
        
        let className = ("\(type(of: self))")
        
        if let json = self.toJSON() {
            let data = HTTPSConnection.convertStringToDictionary(text: json)
            
            var newData = [String:AnyObject]()
            newData = data!
            
            if objectID != "" {
                newData["_id"] = objectID as AnyObject?
            }
            
            var url: String = ""
            url = url.readPlistString(value: "URL", "http://0.0.0.0:8181")
            
            let apiEndpoint = "/storage/"
            let networkURL = url + apiEndpoint + className
            
            let dic = newData
            
            let request = NSMutableURLRequest(url: NSURL(string: networkURL)! as URL)
            let session = URLSession.shared
            request.httpMethod = "POST"
            
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
     - parameters:
        - type: struct name
        - getCompleted: return value of success state
        - data: return array of objects
     
     */
    
    func getAllInBackground<T:JSONSerializable>(ofType type:T.Type, getCompleted : @escaping (_ succeeded: Bool, _ data: [T]) -> ()) {
        
        let className = ("\(type(of: T()))")
        
        var url: String = ""
        url = url.readPlistString(value: "URL", "http://0.0.0.0:8181")
        let apiEndpoint = "/storage/"
        let networkURL = url + apiEndpoint + className
        
        guard let endpoint = URL(string: networkURL) else {
            print("Error creating endpoint")
            return
        }
        var request = URLRequest(url: endpoint)
        request.httpMethod = "GET"
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
                
                let allObjects = dataObjects["data"] as? NSArray
                
                for object in allObjects! {
                    
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


