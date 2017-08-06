//
//  NCElasticBarView.swift
//  cheer
//
//  Created by Kelong Wu on 2017/7/18.
//  Copyright © 2017年 Evolvement Apps. All rights reserved.
//

import UIKit

struct NCElasticContainerConfig {
    
    var main: Bool = false
    var minRow: Int = -50
    var maxRow: Int = 50
    
}

extension UIColor {
    convenience init(hexString: String) {
        let hex = hexString.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int = UInt32()
        Scanner(string: hex).scanHexInt32(&int)
        let a, r, g, b: UInt32
        switch hex.characters.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(red: CGFloat(r) / 255, green: CGFloat(g) / 255, blue: CGFloat(b) / 255, alpha: CGFloat(a) / 255)
    }
}

struct NCColor {
    static let blue = UIColor(hexString: "0076FF")
}

protocol NCElasticBarViewDatasource {
    /**
     Datasource should prepare each container, a container can contain any UIView subclasses. However, for this application, a NCElasticContainer will be used.
     To further simplify the problem, we might use Indexpath to combine the Container and Cell. However, we use separete methods now to maintain the flexibility.
     */
    func cellForRowAt(_ barView: NCElasticBarView, at row: Int, at block: Int)->NCElasticBarCell?
    
    /**
     we must know the cell
     */
    func numOfCellAt(_ barView: NCElasticBarView, at row: Int)->Int?

}

protocol NCElasticBarViewDelegate {
    
    func containerAtRowWillLoad(_ barView: NCElasticBarView, at row: Int)
    
    func frameUpdateAt(_ barView: NCElasticBarView, of cell: NEElasticBarCell, at row: Int, at block: Int)

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

class NCElasticBarView: UIView, UIScrollViewDelegate {
    
    var delegate: NCElasticBarViewDelegate?
    var datasource: NCElasticBarViewDatasource?
    
    var scrollView = UIScrollView()
    var tempView = UIScrollView()
    
    var mainContainer: NCElasticContainer?
    var prevContainer: NCElasticContainer?
    var nextContainer: NCElasticContainer?
    
    var currentRow = 0

    override init(frame: CGRect) {
        super.init(frame: frame)
        initView()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        initView()
    }
    
    func initView() {
        
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
    
    // MARK: - Switch Between Rows
    var startOffset: CGFloat?
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
    
    var isPaging: Bool = false
    var offset: CGFloat = 0
    
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
    
    func containerAtRow(_ scrollView: UIScrollView, at row: Int, of config: NCElasticContainerConfig = NCElasticContainerConfig()) -> NCElasticContainer? {
        
        guard row > config.minRow && row < config.maxRow else {
            return nil
        }
        
        if let d = delegate{
            d.containerAtRowWillLoad(self, at: row)
        }
        
        let container = NCElasticContainer()
        var cells = [NCElasticBarCell]()
        
        if let datasource = self.datasource{
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
