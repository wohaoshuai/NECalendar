//
//  ViewController.swift
//  NECalendar
//
//  Created by Kelong Wu on 2017/7/18.
//  Copyright © 2017年 Kelong Wu. All rights reserved.
//

import UIKit

class ViewController: UIViewController, NEElasticBarViewDelegate {
    @IBOutlet weak var topBar: NEElasticBarView!
    @IBOutlet weak var barView: NEElasticBarView!
    @IBOutlet weak var month: UILabel!
    
    @IBOutlet weak var calendarView: NCElasticBarView!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        barView.delegate = self
        let date = barView.currentDate!
        updateDate(date: date)
        
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
        
    }
    

    
    func newDateSelected(barView: NEElasticBarView, date: Date) {
        updateDate(date: date)
    }
    
    
    var monthMap = ["= =|", "January", "February", "March", "April", "May", "June", "July", "August", "September", "October", "November", "December"]
    func updateDate(date: Date){
        let calendar = Calendar.current
        let monthNum = calendar.component(.month, from: date)
        let yearNum = calendar.component(.year, from: date)
        self.month.text = "\(self.monthMap[monthNum]), \(yearNum)"
    }
}

