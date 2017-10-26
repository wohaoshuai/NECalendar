//
//  NCElasticContainer.swift
//  NCCalendar
//
//  Created by Kelong Wu on 2017/7/21.
//  Copyright © 2017年 Kelong Wu. All rights reserved.
//

import UIKit

// MARK: - -----Configuration-----
// Configuration
//-----------------------------------------------------------------------------------------------------------------

// constants controlling layout of cell in the container
struct NCElasticContainerLayout{
    var leftMargin = CGFloat(5)
    var rightMargin = CGFloat(5)
    var topMargin = CGFloat(5)
    var bottomMargin = CGFloat(5)
    var space = CGFloat(5)
}

// MARK: - -----Construction Package-----
// Construction Package

/**
 
 Define how the cell in container will expand
 1.row -  new row
 2.width - new width
 if any of them is nil, nothing will be done.
 */
struct NCElasticBarCellExpandChange {
    var row: Int?
    var width: CGFloat?
}

// MARK: - -----Contaienr (Main)-----
// Container (Main)
//-----------------------------------------------------------------------------------------------------------------
class NCElasticContainer: UIView {

    // MARK: - 0. Shared Properties / Helper Functions
    /**
     
     to record which cell is expanded internally
     */
    var cells = [NCElasticBarCell]()
    var layout = NCElasticContainerLayout()
    
    // MARK: - 1.Load Container
    // reload cells' frame
    func reloadCells(){
        subviews.forEach({$0.removeFromSuperview()})
        for (i, cell) in cells.enumerated(){
            addSubview(cell)
            
            cell.frame = CGRect(x: calculateX(at: i), y: layout.topMargin, width: cell.frame.width, height: cell.frame.height)
        }
    }
    
    // set cell, reload cell and update contaienr frame
    func setCells(of cells: [NCElasticBarCell]){
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
    
    // MARK: - 2.Live update the container
    
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
    func reloadFrames(changes: [NCElasticBarCellExpandChange], animated: Bool = true){
        
        var maps = transformChange(changes: changes)
        var frames = [CGRect]()
        
        var offset = CGFloat(0)
        for (i, cell) in subviews.enumerated(){
            let frame = CGRect(x: cell.frame.origin.x + offset, y: cell.frame.origin.y, width: maps[i] ?? cell.frame.width, height: cell.frame.height)
            frames.append(frame)
            offset += (maps[i] ?? cell.frame.width) - cell.frame.width
        }
        
        if animated{
            UIView.animate(withDuration: NCElasticBarAnimationDuration.fast, animations: { // config-point
                self.transformCells(offset: offset, frames: frames)
            })
        } else{
            self.transformCells(offset: offset, frames: frames)
        }

    }
    
    /**
     Transform the cell's frames
     */
    func transformCells(offset: CGFloat, frames: [CGRect]){
        for (i, subview) in self.subviews.enumerated(){  // does the subview means the cell?
            let newFrame = frames[i]
            if let barview = self.superview as? NCElasticBarView{
                if let d = barview.delegate{
                    d.frameUpdateAt(barview, of: subview as! NEElasticBarCell, at: barview.currentRow, at: i, with: newFrame)
                }
            }
            subview.frame = newFrame
            subview.layoutIfNeeded()
        }
        barViewShouldUpdate(offset: offset)
    }
    
    /**
        Helper funciton to transform from one layer to another.
        This simplify the internal code while keeping the API well-defined for other programmer
     */
    func transformChange(changes: [NCElasticBarCellExpandChange])->[Int:CGFloat]{
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
    
    /**
        Helper function for reloading the frame. Update the container's frame. [animation supported]
     */
    func barViewShouldUpdate(offset: CGFloat){
        if let barView = (self.superview?.superview as? NCElasticBarView){
            let offsetNext = offset

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


