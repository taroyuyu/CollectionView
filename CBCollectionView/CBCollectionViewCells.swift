//
//  CBCollectionViewCells.swift
//  Lingo
//
//  Created by Wesley Byrne on 1/29/16.
//  Copyright © 2016 The Noun Project. All rights reserved.
//

import Foundation


open class CBCollectionReusableView : NSView {
    
    open internal(set) var indexPath: IndexPath?
    open internal(set) var reuseIdentifier: String?
    open internal(set) weak var collectionView : CBCollectionView?
    open internal(set) var reused : Bool = false
    
    internal var attributes : CBCollectionViewLayoutAttributes?
    
    open var backgroundColor: NSColor?
    
    override public init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        self.wantsLayer = true
        self.layerContentsRedrawPolicy = NSViewLayerContentsRedrawPolicy.onSetNeedsDisplay
    }
    required public init?(coder: NSCoder) {
        super.init(coder: coder)
        self.wantsLayer = true
        self.layerContentsRedrawPolicy = NSViewLayerContentsRedrawPolicy.onSetNeedsDisplay
    }
    
    override open func prepareForReuse() {
        self.reused = true
        super.prepareForReuse()
    }
    open func viewWillDisplay() { }
    open func viewDidDisplay() { }
    
    open func applyLayoutAttributes(_ layoutAttributes: CBCollectionViewLayoutAttributes, animated: Bool) {

        if animated {
            self.animator().frame = layoutAttributes.frame
            self.animator().alphaValue = layoutAttributes.alpha
            self.layer?.zPosition = layoutAttributes.zIndex
            self.animator().isHidden = layoutAttributes.hidden
        }
        else {
            self.frame = layoutAttributes.frame
            self.alphaValue = layoutAttributes.alpha
            self.layer?.zPosition = layoutAttributes.zIndex
            self.isHidden = layoutAttributes.hidden
        }
        
        self.attributes = layoutAttributes
    }
    
    open override func updateLayer() {
        self.layer?.backgroundColor = self.backgroundColor?.cgColor
        if let c = self.layer?.cornerRadius, c > 0 {
            let l = CALayer()
            l.backgroundColor = NSColor.white.cgColor
            l.frame = self.bounds
            l.cornerRadius = self.layer!.cornerRadius
            self.layer?.mask = l
        }
    }
    
    open override func draw(_ dirtyRect: NSRect) {
        
        if let c = self.backgroundColor {
            NSGraphicsContext.saveGraphicsState()
            c.setFill()
            NSRectFill(dirtyRect)
            NSGraphicsContext.restoreGraphicsState()
        }
        super.draw(dirtyRect)
    }
    
    
    
}

open class CBCollectionViewCell : CBCollectionReusableView {
    
    open override func acceptsFirstMouse(for theEvent: NSEvent?) -> Bool { return true }
    
    fileprivate var wantsTracking = true
    open var trackingOptions = [NSTrackingAreaOptions.mouseEnteredAndExited, NSTrackingAreaOptions.activeInKeyWindow, .inVisibleRect, .enabledDuringMouseDrag]
    
    fileprivate var _selected: Bool = false
    fileprivate var _highlighted : Bool = false
    open var highlighted: Bool {
        get { return _highlighted }
        set { self.setHighlighted(newValue, animated: false) }
    }
    open var selected : Bool {
        set { self.setSelected(newValue, animated: false) }
        get { return self._selected }
    }
    
    override public init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        
    }
    
    required public init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    open func setSelected(_ selected: Bool, animated: Bool = true) {
        self._selected = selected
    }
    
    open func setHighlighted(_ highlighted: Bool, animated: Bool) {
        self._highlighted = highlighted
        if highlighted {
            self.collectionView?.indexPathForHighlightedItem = self.indexPath
        }
    }
    
    open override func prepareForReuse() {
        super.prepareForReuse()
        self.setSelected(false, animated: false)
        self.setHighlighted(false, animated: false)
    }
    
    
    var _trackingArea : NSTrackingArea?
    open var trackMouseMoved : Bool = false {
        didSet {
            if trackMouseMoved == oldValue { return }
            let idx = trackingOptions.index(of: .mouseMoved)
            if trackMouseMoved && idx == nil {
                trackingOptions.append(.mouseMoved)
            }
            else if !trackMouseMoved, let i = idx {
                trackingOptions.remove(at: i)
            }
            self.updateTrackingAreas()
        }
    }
    
    open func disableTracking() {
        self.wantsTracking = false
        self.updateTrackingAreas()
    }
    
    open func enableTracking() {
        self.wantsTracking = true
        self.updateTrackingAreas()
    }
    
    open override func updateTrackingAreas() {
        super.updateTrackingAreas()
        if let ta = self._trackingArea { self.removeTrackingArea(ta) }
        if self.wantsTracking == false { return }
        _trackingArea = NSTrackingArea(rect: self.bounds, options: NSTrackingAreaOptions(trackingOptions), owner: self, userInfo: nil)
        self.addTrackingArea(_trackingArea!)
    }
    
    override open func mouseEntered(with theEvent: NSEvent) {
        
        guard let window = self.window else { return }
        let mLoc = window.convertFromScreen(NSRect(origin: NSEvent.mouseLocation(), size: CGSize.zero)).origin
        if !self.bounds.contains(self.convert(mLoc, from: nil)) { return }
        
        guard let cv = self.collectionView, let ip = self.indexPath else { return }
        guard theEvent.type == NSEventType.mouseEntered && (theEvent.trackingArea?.owner as? CBCollectionViewCell) == self else { return }
        
        if let view = self.window?.contentView?.hitTest(theEvent.locationInWindow) {
            if view.isDescendant(of: self) {
                if let h = cv.delegate?.collectionView?(cv, shouldHighlightItemAtIndexPath: ip) , h == false { return }
                super.mouseEntered(with: theEvent)
                self.setHighlighted(true, animated: true)
            }
        }
    }
    
    override open func mouseExited(with theEvent: NSEvent) {
        super.mouseExited(with: theEvent)
        guard theEvent.type == NSEventType.mouseExited && (theEvent.trackingArea?.owner as? CBCollectionViewCell) == self else { return }
        self.setHighlighted(false, animated: true)
    }
    
}
