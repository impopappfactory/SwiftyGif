//
//  SwiftyGifManager.swift
//
//
import ImageIO
import UIKit
import Foundation

public class SwiftyGifManager {
    
    // A convenient default manager if we only have one gif to display here and there
    public static var defaultManager = SwiftyGifManager(memoryLimit: 50)
    
    private var timer: CADisplayLink?
    private var displayViews: [UIImageView] = []
    private var totalGifSize: Int
    private var memoryLimit: Int
    public var  haveCache: Bool

    private let synchronizationContext: (closure: () -> ()) -> () = {
        let queue = dispatch_queue_create("com.kirualex.SwiftyGif.sync\(NSUUID().UUIDString)", DISPATCH_QUEUE_SERIAL)
        return { (closure: () -> ()) in
            dispatch_sync(queue, closure)
        }
    }()

    private let mainContext: (closure: () -> ()) -> () = {
        return { (closure: () -> ()) in
            dispatch_async(dispatch_get_main_queue(), closure)
        }
    }()
    
    /**
     Initialize a manager
     - Parameter memoryLimit: The number of Mb max for this manager
     */
    public init(memoryLimit: Int) {
        self.memoryLimit = memoryLimit
        totalGifSize = 0
        haveCache = true
        timer = CADisplayLink(target: self, selector: #selector(updateImageView))
        timer!.addToRunLoop(NSRunLoop.mainRunLoop(), forMode: NSRunLoopCommonModes)
    }
    
    /**
     Add a new imageView to this manager if it doesn't exist
     - Parameter imageView: The UIImageView we're adding to this manager
     */
    public func addImageView(imageView: UIImageView) -> Bool {
        if containsImageView(imageView) {
            return false
        }
        
        totalGifSize += imageView.gifImage!.imageSize!
        
        if totalGifSize > memoryLimit && haveCache {
            haveCache = false
            for imageView in displayViews{
                synchronizationContext {
                    imageView.updateCache()
                }
            }
        }
        displayViews.append(imageView)
        return true
    }
    
    public func clear() {
        while !displayViews.isEmpty {
            displayViews.removeFirst().clear()
        }
    }
    
    /**
     Delete an imageView from this manager if it exists
     - Parameter imageView: The UIImageView we want to delete
     */
    public func deleteImageView(imageView: UIImageView){
        
        if let index = self.displayViews.indexOf(imageView){
            if index >= 0 && index < self.displayViews.count {
                displayViews.removeAtIndex(index)
                totalGifSize -= imageView.gifImage!.imageSize!
                if totalGifSize < memoryLimit && !haveCache {
                    haveCache = true
                    for imageView in displayViews {
                        synchronizationContext {
                            imageView.updateCache()
                        }
                    }
                }
            }
        }
    }
    
    /**
     Check if an imageView is already managed by this manager
     - Parameter imageView: The UIImageView we're searching
     - Returns : a boolean for wether the imageView was found
     */
    public func containsImageView(imageView: UIImageView) -> Bool{
        return displayViews.contains(imageView)
    }
    
    /**
     Check if this manager has cache for an imageView
     - Parameter imageView: The UIImageView we're searching cache for
     - Returns : a boolean for wether we have cache for the imageView
     */
    public func hasCache(imageView: UIImageView) -> Bool{
        if imageView.displaying == false {
            return false
        }
        
        if imageView.loopCount == -1 || imageView.loopCount >= 5 {
            return haveCache
        }else{
            return false
        }
    }
    
    /**
     Update imageView current image. This method is called by the main loop.
     This is what create the animation.
     */
    @objc func updateImageView(){
        for imageView in displayViews {

            mainContext {
                imageView.image = imageView.currentImage
            }
            if imageView.isAnimatingGif() {
                synchronizationContext {
                    imageView.updateCurrentImage()
                }
            }

        }
    }
    
}
