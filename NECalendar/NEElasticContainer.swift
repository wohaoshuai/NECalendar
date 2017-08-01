//
//  NEElasticContainer.swift
//  NECalendar
//
//  Created by Kelong Wu on 2017/7/21.
//  Copyright © 2017年 Kelong Wu. All rights reserved.
//

import UIKit

// constants controlling layout of cell in the container
struct NEElasticContainerLayout{
    var leftMargin = CGFloat(5)
    var rightMargin = CGFloat(5)
    var topMargin = CGFloat(5)
    var bottomMargin = CGFloat(5)
    var space = CGFloat(5)
}

class NEElasticContainer: UIView {

    /*
    // Only override draw() if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func draw(_ rect: CGRect) {
        // Drawing code
    }
    */
    
    /**
        
     to record which cell is expanded internally
     */
    var expanded: Int?
    var cells = [NEElasticBarCell]()
    var layout = NEElasticContainerLayout()
    
    // reload cells' frame without animation
    func reloadCells(){
        subviews.forEach({$0.removeFromSuperview()})
        for (i, cell) in cells.enumerated(){
            addSubview(cell)
            
            print("self.frame.height")
            print(self.frame.height)
            
            cell.frame = CGRect(x: calculateX(at: i), y: layout.topMargin, width: cell.frame.width, height: cell.frame.height)
        }
    }
    
    // set cell, reload cell and update contaienr frame
    func setCells(of cells: [NEElasticBarCell]){
        self.cells = cells
        reloadCells()
        setWidth()
    }
    
    // helper function to calculate the x offset of a cell
    func calculateX(at row: Int) -> CGFloat{
        var currentX = layout.leftMargin
        for (i, cell) in cells.enumerated(){
            if i == row {break}
            currentX += cell.frame.width
            currentX += layout.space
        }
        return currentX
    }
    
    // set width of the container according to cells width
    func setWidth(){
        
        var currentX = layout.leftMargin
        for (_, cell) in cells.enumerated(){
            currentX += cell.frame.width
            currentX += layout.space
        }
        if cells.count > 0 {
            currentX = currentX - layout.space + layout.rightMargin
        }
        
        let size = CGSize(width: currentX, height: self.frame.height)
        self.frame = CGRect(origin: self.frame.origin, size: size)
        
    }
    
    // origin of change - origin change right / left - each (too much) block size / changed block size
    // i - origin , (x, y) - leftPressure / rightPressure
    // direction is decided by center pressure
    // process each of them with given animatin with configurable speed
    // we have to understand the bound ay be changed
    //   ---|-|--|---
    // 1 move the offset for center left - with or without animation - v-layer
    // 2 expand the content size as well as the fram of container - v-layer
    // 3 change the frame throw animation --> hard to know what's going to happen
    
    /**
    
     Reload frame live (without remove previous subviews, bur instead modify the frames of the old view) Animated.
     NOTICE: origin and style is not used currently.
     */
    func reloadFrames(origin: NEElasticBarCellExpandChange, style: NEElasticBarCellExpandStyle, changes: [NEElasticBarCellExpandChange], animated: Bool = true){
        
        
        // origin may not change at all
        // changes has no order
        if let row = origin.row {
            guard row >= 0 && row < cells.count else {
                print("invalid origin")
                return
            }
        }
        
        // we must calculate the frame first from left to right
        // how ?
        // if we need to replace the sub // we might have to move the offset in repalcable view // which we have of course
        
        // that is we calculate two version of frame and place them different 
        // however how can we copy the setting 
        
        // right most 
        var maps = transformChange(changes: changes)
        var itemMaps = transformItemChange(changes: changes)
        var frames = [CGRect]()
        var offset = CGFloat(0)
        for (i, cell) in subviews.enumerated(){
            let frame = CGRect(x: cell.frame.origin.x + offset, y: cell.frame.origin.y, width: maps[i] ?? cell.frame.width, height: cell.frame.height)
            frames.append(frame)
            offset += (maps[i] ?? cell.frame.width) - cell.frame.width
            print(offset)
        }
        
        if animated{
            UIView.animate(withDuration: NEElasticBarAnimationDuration.fast, animations: {
                for (i, subview) in self.subviews.enumerated(){
                    subview.frame = frames[i]
                    subview.layoutIfNeeded()
                    
                    if let e = itemMaps[i]?.expanding{
                        if e == true{
                            subview.subviews.forEach({
                                if let l = ($0 as? UILabel){
                                    l.textColor = UIColor.white
                                }
                            })
                            subview.backgroundColor = NEColor.blue
                        }
                    }
                    
                    if let e = itemMaps[i]?.shrinking{
                        if e == true{
                            subview.subviews.forEach({
                                if let l = ($0 as? UILabel){
                                    l.textColor = NEColor.blue
                                }
                            })
                            subview.backgroundColor = UIColor.white
                        }
                    }
                    
                }
                self.barViewShouldUpdate(offset: offset)
            })
        } else{
            
            for (i, subview) in self.subviews.enumerated(){
                subview.frame = frames[i]
                subview.layoutIfNeeded()
                
                if let e = itemMaps[i]?.expanding{
                    if e == true{
                        subview.subviews.forEach({
                            if let l = ($0 as? UILabel){
                                l.textColor = UIColor.white
                            }
                        })
                        subview.backgroundColor = NEColor.blue
                    }
                }
                
                if let e = itemMaps[i]?.shrinking{
                    if e == true{
                        subview.subviews.forEach({
                            if let l = ($0 as? UILabel){
                                l.textColor = NEColor.blue
                            }
                        })
                        subview.backgroundColor = UIColor.white
                    }
                }
                
            }
            self.barViewShouldUpdate(offset: offset)
            
        }
        
        // the end offset is the offset of content view and frame
        // possible to have bug situation
//        self.frame = CGRect(x: frame.origin.x, y: frame.origin.y, width: frame.width + offset, height: frame.height)
        // update content view size
    }
    
    /**
        
    Helper funciton to transform from one layer to another. 
     This simplify the internal code while keeping the API well-defined for other programmer
     */
    func transformChange(changes: [NEElasticBarCellExpandChange])->[Int:CGFloat]{
        var res = [Int:CGFloat]()
        for change in changes{
            if let row = change.row {
                if let width = change.width{
                    res[row] = width
                }
            }
        }
        return res
    }
    
    func transformItemChange(changes: [NEElasticBarCellExpandChange])->[Int:NEElasticBarCellExpandChange]{
        var res = [Int:NEElasticBarCellExpandChange]()
        for change in changes{
            if let row = change.row{
                res[row] = change
            }
        }
        return res
    }
    
    /**
        Helper function for reloading the frame. Update the container's frame. [animation supported]
     */
    func barViewShouldUpdate(offset: CGFloat){
        print("offset: \(offset)")
        if let barView = (self.superview?.superview as? NEElasticBarView){
            let offsetNext = offset
            print("offset: \(offset)")

            if let prev = barView.prevContainer{
                if self === prev {
                    prev.frame = CGRect(x: prev.frame.origin.x - offset, y: prev.frame.origin.y, width: prev.frame.width, height: prev.frame.height)
                }
            }
            
            if let main = barView.mainContainer{
                if self === main{
                    main.frame = CGRect(x: main.frame.origin.x, y: main.frame.origin.y, width: main.frame.width + offset, height: main.frame.height)
                    barView.scrollView.contentSize = main.frame.size
                }
                
                if let next = barView.nextContainer {
                    let origin = next.frame.origin
                    next.frame = CGRect(x: origin.x + offsetNext, y: origin.y, width: next.frame.width, height: next.frame.height)
                }
            }
            
            if let next = barView.nextContainer{
                if self === next{
                    let origin = next.frame.origin
                    next.frame = CGRect(x: origin.x, y: origin.y, width: next.frame.width + offset, height: next.frame.height)
                }
            }
        }
    }
    
}

enum NEElasticBarCellExpandStyle {
    case center
    case right
    case left
}

/**
    
 Define how the cell in container will expand 
 1.row -  new row
 2.width - new width
 if any of them is nil, nothing will be done.
 */
struct NEElasticBarCellExpandChange {
    var row: Int?
    var width: CGFloat?
    var expanding: Bool = false
    var shrinking: Bool = false
}


