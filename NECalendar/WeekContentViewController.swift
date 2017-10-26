//
//  WeekContentViewController.swift
//  NECalendar
//
//  Created by Kelong Wu on 2017/8/6.
//  Copyright © 2017年 Kelong Wu. All rights reserved.
//

import UIKit

class WeekContentViewController: UIViewController, NCElasticBarViewDatasource, NCElasticBarViewDelegate {
    
    // MARK: - Controller
    //---------------------------------------------------------------------------------------------------
    @IBOutlet weak var barview: NCElasticBarView!
    
    var main: MainViewController?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        barview.datasource = self
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Datasource
    //----------------------------------------------------------------------------------------------------
    func cellForRowAt(_ barView: NCElasticBarView, at row: Int, at block: Int) -> NCElasticBarCell? {
        let cell = NCElasticBarCell()
        cell.frame = CGRect(x: 0, y: 0, width: NEElasticBarCellSize.large, height: 100)
        cell.backgroundColor = UIColor.brown
        return cell
    }
    
    
    func numOfCellAt(_ barView: NCElasticBarView, at row: Int) -> Int? {
        print(row)
        return 10
    }
    
    // MARK: - Delegate
    //----------------------------------------------------------------------------------------------------
    func containerAtRowWillLoad(_ barView: NCElasticBarView, at row: Int, of config: NCElasticContainerConfig) {
        if config.main {
            barview.mainContainer?.reloadFrames(changes: [])
        }
    }
    
    func frameUpdateAt(_ barView: NCElasticBarView, of cell: NEElasticBarCell, at row: Int, at block: Int, with frame: CGRect) {
        
    }
}
