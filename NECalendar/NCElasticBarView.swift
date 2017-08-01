//
//  NCElasticBarView.swift
//  cheer
//
//  Created by Kelong Wu on 2017/7/18.
//  Copyright © 2017年 Evolvement Apps. All rights reserved.
//

import UIKit

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
    
    func cellForRowAt(_ barView: NCElasticBarCell, at row: Int, at block: Int)->NCElasticBarCell?{
    
    }
}

protocol NCElasticBarViewDelegate {
    func newDateSelected(barView: NCElasticBarView, date: Date)
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

class NCElasticBarView: UIView, UIScrollViewDelegate, NCElasticBarViewDatasource {
    
    var delegate: NCElasticBarViewDelegate?
    var linkers = [NCElasticBarView]()
    
    var mainContainer: NCElasticContainer?
    var prevContainer: NCElasticContainer?
    var nextContainer: NCElasticContainer?
    
    // the delegate should manage the persistency with the call instead
    // any change is temp - hence a pacakage is required
    
    func cellForRowAt(_ barView: NCElasticBarCell, at row: Int, at block: Int)->NCElasticBarCell?{
        
    }
    
    
    // load the start date -> which should not be part of the task, but it is a back end 
    // method
    func loadStartDate(){
        let calendar = Calendar.current
        let date = Date()
        
        let today = calendar.component(Calendar.Component.day, from: date)
        var weekday = calendar.component(Calendar.Component.weekday, from: date)
        if weekday == 1{
            weekday = 8
        }
        
        let newDate = calendar.date(byAdding: .day, value: 2 - weekday, to: date)
        let newToday = calendar.component(Calendar.Component.day, from: newDate!)
        
        
        overallStartDate = newDate
    }
    
    // this is not universal at all, hence shoudn't be here at all
    // the expansion rule is different as well
    // expand and cell touched should be seperated
    func cellIsTouched(_ sender: UIButton){
        
        
        // this defines the expandsion behavior, that is to expand which
        // by define a expanded tag
        // in the next case, the cell expansion are complicated as we must expand the subview manually -> maybe rewrite some method
        // width sync
        let expand = sender.tag
        var changes = [NCElasticBarCellExpandChange]()
        var change1 = NCElasticBarCellExpandChange()
        change1.row = expand
        change1.width = NCElasticBarCellSize.large
        change1.expanding = true
        changes.append(change1)
        
        
        // calculate the date
        if let d = delegate{
            let newDate = Calendar.current.date(byAdding: .day, value: expand, to: currentStartDate)
            currentDate = newDate
            d.newDateSelected(barView: self, date: newDate!)
        }
        
        // just change the main 
        // however all should be update
        // even prev - prev does not influence any frame and content view though

        if let main = getMainContainer(){
            if let shrink = main.expanded{
                
                if shrink == expand{
                    return
                }
                var change2 = NCElasticBarCellExpandChange()
                change2.row = shrink
                change2.width = NCElasticBarCellSize.normal
                change2.shrinking = true
                changes.append(change2)
            }
            
            print(main.transformChange(changes: changes))
            main.expanded = expand
            overallExpand = expand
            main.reloadFrames(origin: change1, style: .center, changes: changes)
            prevContainer?.reloadFrames(origin: change1, style: .center, changes: changes, animated: false)
            nextContainer?.reloadFrames(origin: change1, style: .center, changes: changes, animated: false)
        }
        
        // next action: 
        // manage the config api
        // manage config userinterface
        
    }
    
    func toExpandCel(){
        
    }
    
    // this manage the persistent - as all the view is reload
    var overallExpand: Int = 3
    var weekStr = ["Mon", "Tue", "Wed", "Thur", "Fri", "Sat", "Sun"]
    var overallStartDate: Date! // careful
    var currentStartDate: Date!
    var currentDate: Date!
    
    func containerAtRow(_ scrollView: UIScrollView, at row: Int, main: Bool = false) -> NCElasticContainer? {
        
        // this limits the row / but should we? no, not at all
        guard row > -50 && row < 50 else {
            return nil
        }
        
        let container = NCElasticContainer()
        var cells = [NCElasticBarCell]()
        
        
        
        // start of calendar
        let calendar = Calendar.current
        
        var dateNum = [Int]()
        let startDate = calendar.date(byAdding: .day, value: 7 * row, to: overallStartDate)
        
        
        for i in 0...6{
            let thisDate = calendar.date(byAdding: .day, value: i, to: startDate!)
            dateNum.append(calendar.component(.day, from: thisDate!))
        }
        
        if main == true {
            currentStartDate = startDate!
            let newDate = calendar.date(byAdding: .day, value: overallExpand, to: currentStartDate)
            currentDate = newDate
            if let d = delegate{
                d.newDateSelected(barView: self, date: newDate!)
            }
        }
        // end of calendar data
        
        
        for i in 0...6{
            
            let cell = NCElasticBarCell()
            
            var frameWidth = NCElasticBarCellSize.normal
            if i == overallExpand {
                frameWidth = NCElasticBarCellSize.large
                container.expanded = i
            }
            
            // this is the frame
            cell.frame = CGRect(x: 0, y: 0, width: frameWidth, height: 80) // here // record before leave
            cell.backgroundColor = UIColor.clear
            
            let button = UIButton()
            button.addTarget(self, action: #selector(cellIsTouched(_:)), for: .touchUpInside) // this creates action
            cell.addSubview(button)
            button.translatesAutoresizingMaskIntoConstraints = false
            button.topAnchor.constraint(equalTo: cell.topAnchor).isActive = true
            button.bottomAnchor.constraint(equalTo: cell.bottomAnchor).isActive = true
            button.leftAnchor.constraint(equalTo: cell.leftAnchor).isActive = true
            button.rightAnchor.constraint(equalTo: cell.rightAnchor).isActive = true
            button.tag = i

            cell.layer.borderColor = NCColor.blue.cgColor
            cell.layer.borderWidth = CGFloat(1)
            cell.layer.cornerRadius = CGFloat(3)
            
            // week
            let week = UILabel()
            week.font = week.font.withSize(CGFloat(16))
            week.textColor = NCColor.blue
            week.text = weekStr[i]
            
            cell.addSubview(week)
            week.translatesAutoresizingMaskIntoConstraints = false
            week.centerXAnchor.constraint(equalTo: cell.centerXAnchor).isActive = true
            week.topAnchor.constraint(equalTo: cell.topAnchor, constant: CGFloat(15)).isActive = true
            
            // date
            let date = UILabel()
            date.font = date.font.withSize(CGFloat(24))
            date.textColor = NCColor.blue
            date.text = "\(dateNum[i])"
            
            cell.addSubview(date)
            date.translatesAutoresizingMaskIntoConstraints = false
            date.centerXAnchor.constraint(equalTo: cell.centerXAnchor).isActive = true
            date.topAnchor.constraint(equalTo: week.bottomAnchor, constant: CGFloat(-3)).isActive = true
            
            
            if i == overallExpand{
                cell.backgroundColor = NCColor.blue
                cell.subviews.forEach({
                    if let l = $0 as? UILabel {
                        l.textColor = UIColor.white
                    }
                })
            }

            
            cells.append(cell)
        }
        

        container.setCells(of: cells)
        return container
    }

    /*
    // Only override draw() if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func draw(_ rect: CGRect) {
        // Drawing code
    }
    */
    var currentRow = 0
    var datasource: NCElasticBarViewDatasource?
    var scrollView = UIScrollView()
    var tempView = UIScrollView()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        initView()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        initView()
    }
    
    func initView() {
        loadStartDate()
        
        addScrollView(tempView)
        addScrollView(scrollView)
        tempView.alpha = 0
        scrollView.alpha = 1
        
        datasource = self
        currentRow = 0
        loadRow(of: scrollView, at: 0)
    }
    
    func getMainContainer()->NCElasticContainer?{
        return mainContainer
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
    
     0.clean the scrollview
     1.load main view
     2.load p view
     3.load f view
     
     */
    func loadRow(of currentView: UIScrollView, at row: Int){
        
        currentRow = row
        
        currentView.subviews.forEach({$0.removeFromSuperview()}) // clean the view
        currentView.contentSize = CGSize(width: self.frame.width, height: self.frame.height)
        
        let prev = containerAtRow(scrollView, at: row - 1, main: false)
        let main = containerAtRow(scrollView, at: row, main: true)
        let next = containerAtRow(scrollView, at: row + 1, main: false)
        
        let views = [prev, main, next]
        
        for view in views{
            // we don't actuallt know the setting, and we don't know the position of main view
            if let v = view{
                currentView.addSubview(v)
            }
        }
        
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
        
        print(scrollView.contentOffset)
        print(velocity)
        print(startOffset ?? "nil")
        
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
            print("no next page")
            return
        }
        print("next page")
        for linker in linkers{
            linker.nextPage()
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
            print("no prev page")
            return
        }
        print("prev page")
        for linker in linkers{
            linker.prevPage()
        }
        
        isPaging = true
        print(self.frame.width)
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
            for linker in linkers{
                linker.replaceView()
            }
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
    
    override func layoutSubviews() {
        super.layoutSubviews()
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        for linker in linkers{
            self.synchronizeScrollView(linker.scrollView, toScrollView: self.scrollView)
        }
    }
    
    func synchronizeScrollView(_ scrollViewToScroll: UIScrollView, toScrollView scrolledView: UIScrollView) {
        var offset = scrollViewToScroll.contentOffset
        offset.x = scrolledView.contentOffset.x
        
        scrollViewToScroll.setContentOffset(offset, animated: false)
    }
}
