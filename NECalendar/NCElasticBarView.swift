//
//  NCElasticBarView.swift
//  cheer
//
//  Created by Kelong Wu on 2017/7/18.
//  Copyright © 2017年 Evolvement Apps. All rights reserved.
//

import UIKit

// MARK: -----Configuration-----
// Configuration
//-----------------------------------------------------------------------------------------------------------------

/**
    Configuration of how a container should be load
 */
struct NCElasticContainerConfig {
    
    var main: Bool = false
    var minRow: Int = -500
    var maxRow: Int = 500
}

struct NCElasticBarCellSize {
    static let normal = CGFloat(50)
    static let large = CGFloat(100)
}

struct NCElasticBarAnimationDuration {
    static let slow = 0.25
    static let normal = 0.2
    static let fast = 0.15
}

// MARK: - -----Datasource-----
//Datasource
//-----------------------------------------------------------------------------------------------------------------
protocol NCElasticBarViewDatasource {
    /**
     Ask datasouce the cell in given position, where parameter row determines index of container, block determines index of cell in a given container.
     
     - parameters:
        - barView: the bar-view object requesting this information
        - row: the row of a container/section in the view
        - block: the index of block/cell in a container
     */
    func cellForRowAt(_ barView: NCElasticBarView, at row: Int, at block: Int)->NCElasticBarCell?
    
    /**
     Ask datasource the number of cell in a given position
     
     - parameters:
        - barView: the bar-view object requesting this information
        - row: the row of a container the view
     */
    func numOfCellAt(_ barView: NCElasticBarView, at row: Int)->Int?

}

// MARK: - -----Delegate-----
// Delegate
//-----------------------------------------------------------------------------------------------------------------
protocol NCElasticBarViewDelegate {
    
    /**
     Tell the delegate the container at a given row is about to load.
     */
    func containerAtRowWillLoad(_ barView: NCElasticBarView, at row: Int, of config: NCElasticContainerConfig)
    
    /**
     Ask the delegate to update the cell at a given position with a new frame. Usually used to make custom change to view with animation.
     */
    func frameUpdateAt(_ barView: NCElasticBarView, of cell: NEElasticBarCell, at row: Int, at block: Int, with frame: CGRect)

}

// MARK: - -----View (Main)-----
// View (Main)
//-----------------------------------------------------------------------------------------------------------------
class NCElasticBarView: UIView, UIScrollViewDelegate {
    
    // MARK: - 0. Shared Properties / Helper Functions
    var delegate: NCElasticBarViewDelegate?{
        didSet{
            if NCDeveloper.debug{print("delegate has been set")}
            loadRow(of: scrollView, at: currentRow)
        }
    }
    var datasource: NCElasticBarViewDatasource? {
        didSet{
            if NCDeveloper.debug{print("datasource has been set")}
            loadRow(of: scrollView, at: currentRow)
        }
    }
    
    var scrollView = UIScrollView()
    var tempView = UIScrollView()
    
    var mainContainer: NCElasticContainer?
    var prevContainer: NCElasticContainer?
    var nextContainer: NCElasticContainer?
    
    var currentRow = 0

    // MARK: - 1.Load view
    override init(frame: CGRect) {
        super.init(frame: frame)
        initView()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        initView()
    }
    
    func initView() {
        
        if NCDeveloper.debug{print("initView")}
        
        addScrollView(tempView)
        addScrollView(scrollView)
        tempView.alpha = 0
        scrollView.alpha = 1
        
        currentRow = 0
        loadRow(of: scrollView, at: 0)
    }
    
    func addScrollView(_ scrollView: UIScrollView){
        
        scrollView.delegate = self
        addSubview(scrollView)
        scrollView.showsHorizontalScrollIndicator = false 
        scrollView.showsVerticalScrollIndicator = false
        scrollView.contentSize = CGSize(width: self.frame.width, height: self.frame.height)
        
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.leftAnchor.constraint(equalTo: self.leftAnchor).isActive = true
        scrollView.rightAnchor.constraint(equalTo: self.rightAnchor).isActive = true
        scrollView.topAnchor.constraint(equalTo: self.topAnchor).isActive = true
        scrollView.bottomAnchor.constraint(equalTo: self.bottomAnchor).isActive = true
    }
    
    /**
    
     This method reload the cells in a give scrollview.
     [NOT ANIMATED]
     
     */
    func loadRow(of currentView: UIScrollView, at row: Int){
        
        currentRow = row
        
        currentView.subviews.forEach({$0.removeFromSuperview()}) // clean the view
        currentView.contentSize = CGSize(width: self.frame.width, height: self.frame.height)
        
        // should this be a delegate or /
        var falseConfig = NCElasticContainerConfig()
        falseConfig.main = false
        
        var trueConfig = NCElasticContainerConfig()
        trueConfig.main = true
        
        // load the view here
        let prev = containerAtRow(currentView, at: row, of: falseConfig)
        let main = containerAtRow(currentView, at: row, of: trueConfig)
        let next = containerAtRow(currentView, at: row, of: falseConfig)
        let views = [prev, main, next]
        
        for view in views{
            if let v = view{
                currentView.addSubview(v)
            }
        }
        
        // decide the content size here
        // actually we should listen to the content size and try to link it out
        // to listen to the change 
        // so that we can make more precise rule
        var width = self.frame.width
        if let _ = main{
            
            // control the small width case for main
            if main!.frame.width > width {width = main!.frame.width}
            
            main?.frame = CGRect(x: 0, y: 0, width: width, height: self.frame.height)
            
            main?.tag = row
            
            mainContainer = main
            currentView.contentSize = CGSize(width: width, height: self.frame.height)
        } else {
            print("error: out of index")
        }
        
        if let _ = prev{
            prevContainer = prev
            prev?.frame = CGRect(x: -prev!.frame.width, y: 0, width: prev!.frame.width, height: self.frame.height)
            prev?.tag = row - 1
        }
        
        if let _ = next{
            nextContainer = next
            next?.frame = CGRect(x: width, y: 0, width: next!.frame.width, height: self.frame.height)
            next?.tag = row + 1
        }
    }
    
    // MARK: - 2.Switch Between Rows
    var startOffset: CGFloat?
    var isPaging: Bool = false
    var offset: CGFloat = 0
    
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        startOffset = scrollView.contentOffset.x
    }
    
    func scrollViewWillEndDragging(_ scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {
        
        if velocity.x < CGFloat(1) && scrollView.contentOffset.x + scrollView.frame.width > scrollView.contentSize.width + CGFloat(30){
            
            nextPage()
        }
        
        if velocity.x > CGFloat(1) && startOffset! + scrollView.frame.width >= scrollView.contentSize.width {
            nextPage()
        }
        
        if velocity.x > CGFloat(-1) && scrollView.contentOffset.x < CGFloat(-30) {
            prevPage()
        }
        
        if velocity.x < CGFloat(-1) && startOffset! <= CGFloat(0) {
            prevPage()
        }
    }
    
    func nextPage() {
        if containerAtRow(scrollView, at: currentRow + 1) == nil {
            return
        }
        
        isPaging = true
        scrollView.subviews.forEach({
            if $0.tag == (currentRow){
                offset = $0.frame.width
            }
        })
        
        loadRow(of: tempView, at: currentRow + 1)
    }
    
    func prevPage() {
        if containerAtRow(scrollView, at: currentRow - 1) == nil {
            return
        }
        
        isPaging = true
        offset = -self.frame.width

        loadRow(of: tempView, at: currentRow - 1)
        let offsetX = tempView.contentSize.width - self.frame.width
        tempView.setContentOffset(CGPoint(x: offsetX, y: CGFloat(0)), animated: false)
        
    }
    
    func scrollViewWillBeginDecelerating(_ scrollView: UIScrollView) {
        if isPaging{
            scrollView.isUserInteractionEnabled = false
            let p = CGPoint(x: offset, y: 0)
            scrollView.setContentOffset(p, animated: true)
        }
    }
    
    func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
        if isPaging{
            replaceView()
        }
    }
    
    func replaceView(){
        isPaging = false
        
        self.scrollView.alpha = 0
        self.tempView.alpha = 1
        scrollView.isUserInteractionEnabled = true
        
        let temp = self.tempView
        self.tempView = self.scrollView
        self.scrollView = temp
    }
    
    // MARK: - 3.Load Container and Cells
    /**
     Reload container at given row
     */
    func containerAtRow(_ scrollView: UIScrollView, at row: Int, of config: NCElasticContainerConfig = NCElasticContainerConfig()) -> NCElasticContainer? {
        
        guard row > config.minRow && row < config.maxRow else {
            return nil
        }
        
        if let d = delegate{
            d.containerAtRowWillLoad(self, at: row, of: config)
        }
        
        let container = NCElasticContainer()
        var cells = [NCElasticBarCell]()
        
        if NCDeveloper.debug{print("containerAtRow")}
        
        if let datasource = self.datasource{
            
            if NCDeveloper.debug{print("datasource is available")}
            
            if let cellNum = datasource.numOfCellAt(self, at: row){
                // create cells here
                guard cellNum > 0 else {
                    print("invalid cell number")
                    return nil
                }
                
                for blockIndex in 0...cellNum{
                    // there might be empty cell which is okay in this case
                    if let cell = datasource.cellForRowAt(self, at: row, at: blockIndex){
                        cells.append(cell)
                    }
                }
            }
        }
        
        // cells can be an empty array
        container.setCells(of: cells)
        return container
    }

    
//    // synchronization
//    func scrollViewDidScroll(_ scrollView: UIScrollView) {
//        for linker in linkers{
//            self.synchronizeScrollView(linker.scrollView, toScrollView: self.scrollView)
//        }
//    }
//    
//    func synchronizeScrollView(_ scrollViewToScroll: UIScrollView, toScrollView scrolledView: UIScrollView) {
//        var offset = scrollViewToScroll.contentOffset
//        offset.x = scrolledView.contentOffset.x
//        
//        scrollViewToScroll.setContentOffset(offset, animated: false)
//    }
    
}
