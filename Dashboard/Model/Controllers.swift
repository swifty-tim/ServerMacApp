//
//  Controllers.swift
//  Dashboard
//
//  Created by Timothy Barnard on 20/01/2017.
//  Copyright © 2017 Timothy Barnard. All rights reserved.
//

//
//  Config.swift
//  CMS Remote Config
//
//  Created by Timothy Barnard on 30/10/2016.
//  Copyright © 2016 Timothy Barnard. All rights reserved.
//

import Foundation

class KeyValuePair {
    
    let key: String
    let value: String
    
    init(key: String, value:String) {
        self.key = key
        self.value = value
    }
}


enum RCObjectType : String {
    
    case Button = "UIButton"
    case Label = "UILabel"
    case ImageView = "UIImageView"
    case TextField = "UITextField"
    case Cell = "UICell"
    case View = "UIView"
    case TableView = "UITableView"
    case Object = "Object"
    case NavigationBar = "UINavigationBar"
}

enum ListType: Int {
    case LanguageType = 0
    case ColorType = 1
    case TextType = 2
    case NumberType = 3
}


struct RCColor: JSONSerializable {
    
    var blue : CGFloat!
    var green : CGFloat!
    var red : CGFloat!
    var alpha : CGFloat!
    var name : String!
    
    init() {}
    init(dict: String){}
    
    init(dict: [String]){}
    
    init(blue: CGFloat, green: CGFloat, red: CGFloat, alpha: CGFloat, name: String) {
        self.blue = blue
        self.green = green
        self.red = red
        self.alpha = alpha
        self.name = name
    }
    
    init(dict : [String:Any]) {
        self.blue = dict.tryConvert(forKey: "blue")
        self.green = dict.tryConvert(forKey: "green")
        self.red = dict.tryConvert(forKey: "red")
        self.alpha = dict.tryConvert(forKey: "alpha")
        self.name = dict.tryConvert(forKey: "name")
    }
}

//struct RCProperty: JSONSerializable {
//    
//    var key: String!
//    var value: String!
//    var type: ListType!
//    
//    init() {}
//    
//    init(dict: String){}
//    
//    init(key: String, value: String, type: ListType) {
//        self.key = key
//        self.value = value
//        self.type = type
//    }
//    
//    init(dict: [String : Any]) {
//        self.key = dict.tryConvert(forKey: "key")
//        self.value = dict.tryConvert(forKey: "value")
//        
//        switch dict["type"] as? Int ?? 0 {
//        case 0:
//            self.type = ListType.LanguageType
//            break
//        case 1:
//            self.type = ListType.ColorType
//            break
//        case 2:
//            self.type = ListType.TextType
//            break
//        case 2:
//            self.type = ListType.NumberType
//            break
//        default:
//            self.type = ListType.TextType
//        }
//
//    }
//    
//    init(dict: [String]){}
//    
//}

enum SettingPart {
    case ClassProperties
    case MainSetting
    case Properties
    case Class
    case Object
    case Color
}


struct RCColorProp {
    
    var color: RCColor!
    var row: Int = 0
    
    init(color: RCColor, row: Int) {
        self.color = color
        self.row = row
    }
}


struct RCProperty {
    
    var key: String = ""
    var valueStr: String = ""
    var valueNo: Int = -1
    var row: Int = -1
    var type: String = ""
    var parent: Int = -1
    var settingPart: SettingPart!
    
    init(key: String, valueStr:String, valueNo: Int, row:Int, type: String, parent: Int, settingPart: SettingPart) {
        self.key = key
        self.valueStr = valueStr
        self.valueNo = valueNo
        self.row = row
        self.type = type
        self.parent = parent
        self.settingPart = settingPart
    }
}

struct RCObject: JSONSerializable {
    
    var objectType : RCObjectType!
    var objectDesc: String!
    var objectName : String!
    var objectProperties : [String: Any]!
    
    init() {
        objectType = RCObjectType.Object
        objectDesc = ""
        objectName = ""
        objectProperties = [:]
    }
    init(dict: String){}
    
    init( objectName: String, objectDescription: String, objectType: RCObjectType) {
        self.objectName = objectName
        self.objectDesc = objectDescription
        self.objectType = objectType
        self.objectProperties = [String:Any]()
        self.objectProperties["type"] = objectType.rawValue
    }
    
    init(dict: [String]){}
    
    init( dict: [String:Any] ) {
        self.objectName = dict["objectName"] as! String
        self.objectDesc = dict.tryConvert(forKey: "objectDesc")
        self.objectProperties = dict["objectProperties"] as! [String: Any]!
        
        switch objectProperties["type"] as! String {
        case "UIButton":
            self.objectType = .Button
            break
        case "UILabel":
            self.objectType = .Label
            break
        case "UIImageView":
            self.objectType = .ImageView
            break
        case "UITextField":
            self.objectType = .TextField
        case "UICell":
            self.objectType = .Cell
        case "UITableView":
            self.objectType = .TableView
        case "UINavigationBar":
            self.objectType = .NavigationBar
        default:
            self.objectType = .Object
        }
    }
}

struct RCController: JSONSerializable {
    
    var objectsList: [RCObject]!
    var name : String!
    var parent: Int = 0
    var classProperties : [String: Any]!
    
    init() {
        objectsList = [RCObject]()
        name = ""
        classProperties = [:]
    }
    init(dict: String){}
    
    init(name: String) {
        self.name = name
        self.objectsList = [RCObject]()
        self.classProperties = [String:Any]()
    }
    
    init(dict: [String]){}
    
    init( dict : [String:Any] ) {
        
        self.name = dict["name"] as! String
        
        self.objectsList = [RCObject]()
        
        self.classProperties = dict.tryConvertObj(forKey: "classProperties")
        
        
        for ( value) in dict["objectsList"] as! NSArray {
            
            let newObject = RCObject( dict: value as! [String: Any])
            self.objectsList.append(newObject)
        }
    }
}

struct Config : JSONSerializable {
    
    var colors : [RCColor]!
    var controllers : [RCController]!
    var mainSettings: [String:String]!
    var languagesList : [String]!
    var version : String = "0"
    var applicationID : String = ""
    var filePath: String = ""
    var appTheme: String = ""
    var appLive: Int = 1
    var configVersion: String = ""
    
    init() {
        colors = [RCColor]()
        controllers = [RCController]()
        mainSettings = [:]
        languagesList = []
    }
    init(dict: String){}
    
    init(dict: [String]){}
    
    init( dict : [String:Any] ) {
        
        self.colors = [RCColor]()
        
        for ( color ) in dict["colors"] as! NSArray {
            let newColor = RCColor(dict: color as! [String:Any])
            self.colors.append(newColor)
        }
        
        self.controllers = [RCController]()
        
        for( value ) in dict["controllers"] as! NSArray {
            
            let newController = RCController(dict: (value as! [String:Any]) )
            self.controllers.append(newController)
        }
        
        self.languagesList = [String]()
        self.languagesList = dict["languagesList"] as! [String]!
        
        self.mainSettings = [String:String]()
        
        guard let settings =  dict["mainSettings"] as? [String:String] else {
            return
        }
        self.mainSettings = settings
        self.version = dict.tryConvert(forKey: "version")
    }
}

struct Translations: JSONSerializable {
    
    var translationList: [String:AnyObject]!
    
    init() {}
    init(dict: String){}
    
    init(dict: [String]){}
    
    init(dict: [String:Any] ) {
        
        guard let translationDict = dict["translationList"] as? [String:AnyObject] else {
            self.translationList = dict as [String : AnyObject]!
            return
        }
        
        self.translationList = translationDict
        
    }
    
}

