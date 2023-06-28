//
//  WallpaperEngine.swift
//  Wallpaper
//
//  Created by Jason Rich Darmawan Onggo Putra on 29/06/23.
//

import AppKit

class WallpaperEngine: ObservableObject {
    @Published private(set) var isRunning = false
    
    /**
     - ToDo: usleep based on video length and frames
     */
    func toggle() {
        if isRunning {
            isRunning = false
            return
        }
        
        isRunning = true
        
        // list of frames of gif
        let frameList = getSequence(forResource: "koi")
        
        //workspace and screen
        let workspace = NSWorkspace.shared
        let screen = NSScreen.main
        
        // options for each frame
        var options = workspace.desktopImageOptions(for: screen!)
        options![NSWorkspace.DesktopImageOptionKey.allowClipping] = true
        
        var index = 0
        DispatchQueue.global(qos: .background) .async {
            print("\(type(of: self)) \(#function) start")
            
            while self.isRunning {
                do {
                    
                    // gets URL through index key from {frameList}
                    try workspace.setDesktopImageURL(frameList[index]!, for: screen!, options: options!)
                    // pause distance
                    usleep(3333)
                    
                    // increments index (key)
                    index += 1
                    index %= frameList.count - 1
                    
                } catch { }
                
            }
            
            print("\(type(of: self)) \(#function) stop")
        }
        
        print("\(type(of: self)) \(#function)")
    }
    
    private func getSequence(forResource: String) -> [Int: URL] {
        guard let bundleURL = Bundle.main.url(forResource: forResource, withExtension: "gif")
        else {
            print("\(type(of: self)) \(#function) This resource file \"\(forResource)\" does not exist!")
            return [:]
        }
        
        guard let gifData = try? Data(contentsOf: bundleURL) else {
            print("\(type(of: self)) \(#function) Cannot turn resource file \"\(forResource)\" into NSData")
            return [:]
        }
        
        let gifOptions = [
            kCGImageSourceShouldAllowFloat as String : true as NSNumber,
            kCGImageSourceCreateThumbnailWithTransform as String : true as NSNumber,
            kCGImageSourceCreateThumbnailFromImageAlways as String : true as NSNumber
        ] as CFDictionary
        
        guard let imageSource = CGImageSourceCreateWithData(gifData as CFData, gifOptions)
        else {
            print("\(type(of: self)) \(#function) Cannot create image source with the data!")
            return [:]
        }
        
        // dictionary to store URLs
        var framesURL: Dictionary<Int, URL> = [:]
        
        // create temporary directory to store images
        let tempURL = URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
        
        // convert CGImage to TIFF arguements
        let ctx = CIContext.init()
        
        // number of frames
        print("\(type(of: self)) \(#function) Number of frames \(CGImageSourceGetCount(imageSource))")
        
        // through each frame of gif
        for index in 0...(CGImageSourceGetCount(imageSource) - 1) {
            
            // current images random URL within temporary directory
            let tempFileName = ProcessInfo().globallyUniqueString
            let tempFileURL = tempURL.appendingPathComponent(tempFileName)
            
            // CGImage representation of frame
            let tempCGIimage = CGImageSourceCreateImageAtIndex(imageSource, index, nil)
            let imageCI = CIImage(cgImage: tempCGIimage!)
            
            do {
                // convert CGImage to TIFF
                try ctx.writeTIFFRepresentation(
                    of: imageCI,
                    to: tempFileURL,
                    format: CIFormat.RGBA16,
                    colorSpace: CGColorSpaceCreateDeviceRGB(),
                    options: [:]
                )
                
                // write into dictionary
                framesURL[index] = tempFileURL
                
            } catch {}
            
        }
        return framesURL
    }
}
