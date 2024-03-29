//
//  VolumeInfo.swift
//  Dashboard
//
//  Created by Timothy Barnard on 22/01/2017.
//  Copyright © 2017 Timothy Barnard. All rights reserved.
//

import Cocoa

enum FileType {
    
    case apps(bytes: Int64, percent: Double)
    case photos(bytes: Int64, percent: Double)
    case audio(bytes: Int64, percent: Double)
    case movies(bytes: Int64, percent: Double)
    case other(bytes: Int64, percent: Double)
    
    var fileTypeInfo: (bytes: Int64, percent: Double) {
        switch self {
        case .apps(let bytes, let percent):
            return (bytes: bytes, percent: percent)
            
        case .photos(let bytes, let percent):
            return (bytes: bytes, percent: percent)
            
        case .audio(let bytes, let percent):
            return (bytes: bytes, percent: percent)
            
        case .movies(let bytes, let percent):
            return (bytes: bytes, percent: percent)
            
        case .other(let bytes, let percent):
            return (bytes: bytes, percent: percent)
        }
    }
    
    var name: String {
        switch self {
        case .apps(_, _):
            return "Apps"
        case .audio(_, _):
            return "Audio"
        case .movies(_, _):
            return "Movies"
        case .photos(_, _):
            return "Photos"
        case .other(_, _):
            return "Other"
        }
    }
}

struct FilesDistribution {
    let capacity: Int64
    let available: Int64
    var distribution = [FileType]()
}

struct VolumeInfo {
    let name: String
    let volumeType: String
    let image: NSImage?
    let capacity: Int64
    let available: Int64
    let removable: Bool
    let fileDistribution: FilesDistribution
}

extension FilesDistribution {
    static fileprivate func randomPercentage() -> Double {
        // random percentage between 15->20
        let rand = arc4random_uniform(15) + 5
        return Double(rand) / 100.0
    }
    
    static func randomDistributionWithCapacity(_ capacity: Int64, available: Int64) -> FilesDistribution? {
        guard capacity > 0 else {
            return nil
        }
        let used = Double(capacity - available)
        let apps = Int64(randomPercentage() * used)
        let appsPercent = Double(apps) / Double(capacity)
        let photos = Int64(randomPercentage() * used)
        let photosPercent = Double(photos) / Double(capacity)
        let audio = Int64(randomPercentage() * used)
        let audioPercent = Double(audio) / Double(capacity)
        let movies = Int64(randomPercentage() * used)
        let moviesPercent = Double(movies) / Double(capacity)
        let other = Int64(used) - (apps + photos + audio + movies)
        let otherPercent = Double(other) / Double(capacity)
        
        let distribution: [FileType] = [
            .apps(bytes: apps, percent: appsPercent),
            .photos(bytes: photos, percent: photosPercent),
            .audio(bytes: audio, percent: audioPercent),
            .movies(bytes: movies, percent: moviesPercent),
            .other(bytes: other, percent: otherPercent)
        ]
        
        let fileDistribution = FilesDistribution(capacity: capacity, available: available, distribution: distribution)
        
        return fileDistribution
    }
}

extension VolumeInfo {
    static func volumeInfo(_ volumeURL: URL) -> VolumeInfo? {
        var nameResource: AnyObject?, removableResource: AnyObject?, capacityResource: AnyObject?,
        availableSpaceResource: AnyObject?, localDiskResource: AnyObject?
        
        do {
            try (volumeURL as NSURL).getResourceValue(&nameResource, forKey: URLResourceKey.volumeNameKey)
            try (volumeURL as NSURL).getResourceValue(&capacityResource, forKey: URLResourceKey.volumeTotalCapacityKey)
            try (volumeURL as NSURL).getResourceValue(&removableResource, forKey: URLResourceKey.volumeIsRemovableKey)
            try (volumeURL as NSURL).getResourceValue(&availableSpaceResource, forKey: URLResourceKey.volumeAvailableCapacityKey)
            try (volumeURL as NSURL).getResourceValue(&localDiskResource, forKey: URLResourceKey.volumeIsLocalKey)
        } catch {
            return nil
        }
        
        guard let name = nameResource as? String,
            let capacity = capacityResource?.int64Value as Int64?,
            let removable = removableResource as? Bool,
            let available = availableSpaceResource?.int64Value as Int64?,
            let isLocal = localDiskResource as? Bool,
            let fileDistribution = FilesDistribution.randomDistributionWithCapacity(capacity, available: available) , isLocal else {
                return nil
        }
        
        let image = NSWorkspace.shared().icon(forFile: volumeURL.path)
        let volumeInfo = VolumeInfo(name: name, volumeType: "", image: image,
                                    capacity: capacity, available: available,
                                    removable: removable, fileDistribution: fileDistribution)
        
        return volumeInfo
    }
    
    static func mountedVolumes() -> [VolumeInfo] {
        let keysToRead = [
            URLResourceKey.volumeIsRemovableKey,
            URLResourceKey.volumeLocalizedNameKey,
            URLResourceKey.volumeIsLocalKey,
            URLResourceKey.volumeTotalCapacityKey,
            URLResourceKey.volumeUUIDStringKey,
            URLResourceKey.volumeAvailableCapacityKey
        ]
        
        guard let volumes = FileManager.default
            .mountedVolumeURLs(includingResourceValuesForKeys: keysToRead,
                               options: [.skipHiddenVolumes]) else {
                                return []
        }
        
        var volumesInfo = [VolumeInfo]()
        
        for volumeURL in volumes {
            if let info = volumeInfo(volumeURL) {
                volumesInfo.append(info)
            }
        }
        return volumesInfo
    }
}

