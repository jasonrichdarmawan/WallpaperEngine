//
//  WallpaperEngine.swift
//  Wallpaper
//
//  Created by Jason Rich Darmawan Onggo Putra on 29/06/23.
//

import AppKit

class WallpaperEngine: ObservableObject {
    @Published private(set) var isRunning = false
    
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
                    
                    let frame = frameList[index]
                    
                    // gets URL through index key from {frameList}
                    try workspace.setDesktopImageURL(frame.0, for: screen!, options: options!)
                    // pause distance
                    usleep(frame.1)
                    
                    // increments index (key)
                    index += 1
                    index %= frameList.count - 1
                    
                } catch { }
                
            }
            
            print("\(type(of: self)) \(#function) stop")
        }
        
        print("\(type(of: self)) \(#function)")
    }
    
    /**
     - Returns: in microseconds
     */
    private func getFrameDuration(from imageSource: CGImageSource, at index: Int) -> UInt32 {
        guard let properties = CGImageSourceCopyPropertiesAtIndex(imageSource, index, nil) as? [String: Any],
              let gifProperties = properties[kCGImagePropertyGIFDictionary as String] as? [String: Any],
              
              /// - Returns: in seconds
              let unclampedDelayTime = gifProperties[kCGImagePropertyGIFUnclampedDelayTime as String] as? Double
        else {
            return UInt32()
        }
        
        return UInt32(unclampedDelayTime * 1_000_000)
    }
    
    private func getSequence(forResource: String) -> [(URL, UInt32)] {
        guard let bundleURL = Bundle.main.url(forResource: forResource, withExtension: "gif")
        else {
            print("\(type(of: self)) \(#function) This resource file \"\(forResource)\" does not exist!")
            return []
        }
        
        guard let gifData = try? Data(contentsOf: bundleURL) else {
            print("\(type(of: self)) \(#function) Cannot turn resource file \"\(forResource)\" into NSData")
            return []
        }
        
        guard let imageSource = CGImageSourceCreateWithData(gifData as CFData, nil)
        else {
            print("\(type(of: self)) \(#function) Cannot create image source with the data!")
            return []
        }
        
        var framesURL: [(URL, UInt32)] = []
        
        // create temporary directory to store images
        let tempURL = URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
        
        // convert CGImage to TIFF arguements
        let ctx = CIContext.init()
        
        // number of frames
        let frameCount = CGImageSourceGetCount(imageSource)
        print("\(type(of: self)) \(#function) Number of frames \(frameCount)")
        
        // through each frame of gif
        for index in 0...(frameCount - 1) {
            
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
                
                let frameDuration = getFrameDuration(from: imageSource, at: index)
                
                // write into dictionary
                framesURL.append((tempFileURL, frameDuration))
                
            } catch {}
            
        }
        return framesURL
    }
}
