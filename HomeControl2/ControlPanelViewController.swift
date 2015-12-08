//
//  ControlPanelViewController.swift
//  HomeControl2
//
//  Created by Jun Chen on 04/12/15.
//  Copyright © 2015 Jun Chen. All rights reserved.
//

import UIKit
import Foundation
import Just
import SwiftyJSON

class ControlPanelViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    let server = "http://192.168.43.116:3000/"
    var timer = NSTimer()
    var cellDescriptors: NSMutableArray!
    var visibleRowsPerSection = [[Int]]()
    
    @IBOutlet weak var tblExpandable: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        configureTableView()
        loadCellDescriptors("CellDescriptorManual")
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func loadCellDescriptors(fileName: String) {
        if let path = NSBundle.mainBundle().pathForResource(fileName, ofType: "plist") {
            cellDescriptors = NSMutableArray(contentsOfFile: path)
            getIndicesOfVisibleRows()
            tblExpandable.reloadData()
        }
    }
    
    func getIndicesOfVisibleRows() {
        visibleRowsPerSection.removeAll()
        for currentSectionCells in cellDescriptors {
            var visibleRows = [Int]()
            for row in 0...((currentSectionCells as! [[String: AnyObject]]).count - 1) {
                if currentSectionCells[row]["isVisible"] as! Bool == true {
                    visibleRows.append(row)
                }
            }
            visibleRowsPerSection.append(visibleRows)
        }
    }
    
    func getCellDescriptorForIndexPath(indexPath: NSIndexPath) -> [String: AnyObject] {
        let indexOfVisibleRow = visibleRowsPerSection[indexPath.section][indexPath.row]
        let cellDescriptor = cellDescriptors[indexPath.section][indexOfVisibleRow] as! [String: AnyObject]
        return cellDescriptor
    }
    
    func configureTableView() {
        tblExpandable.delegate = self
        tblExpandable.dataSource = self
        tblExpandable.tableFooterView = UIView(frame: CGRectZero)
        
        tblExpandable.registerNib(UINib(nibName: "NormalCell", bundle: nil), forCellReuseIdentifier: "idCellNormal")
        tblExpandable.registerNib(UINib(nibName: "TextfieldCell", bundle: nil), forCellReuseIdentifier: "idCellTextfield")
        tblExpandable.registerNib(UINib(nibName: "DatePickerCell", bundle: nil), forCellReuseIdentifier: "idCellDatePicker")
        tblExpandable.registerNib(UINib(nibName: "SwitchCell", bundle: nil), forCellReuseIdentifier: "idCellSwitch")
        tblExpandable.registerNib(UINib(nibName: "ValuePickerCell", bundle: nil), forCellReuseIdentifier: "idCellValuePicker")
        tblExpandable.registerNib(UINib(nibName: "SliderCell", bundle: nil), forCellReuseIdentifier: "idCellSlider")
    }
    
    
    // Render an custom tableview
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        if cellDescriptors != nil {
            return cellDescriptors.count
        }
        else {
            return 0
        }
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return visibleRowsPerSection[section].count
    }
    
    func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch section {
            case 0:
                return "Basic"
            default:
                return "Device Status"
        }
    }
    
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        let currentCellDescriptor = getCellDescriptorForIndexPath(indexPath)
        
        switch currentCellDescriptor["cellIdentifier"] as! String {
        case "idCellNormal":
            return 60.0
        case "idCellDatePicker":
            return 270.0
        default:
            return 44.0
        }
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let currentCellDescriptor = getCellDescriptorForIndexPath(indexPath)
        let cell = tableView.dequeueReusableCellWithIdentifier(currentCellDescriptor["cellIdentifier"] as! String, forIndexPath: indexPath) as! CustomCell
        
        if currentCellDescriptor["cellIdentifier"] as! String == "idCellNormal" {
            if let primaryTitle = currentCellDescriptor["primaryTitle"] {
                cell.textLabel?.text = primaryTitle as? String
            }
            
            if let secondaryTitle = currentCellDescriptor["secondaryTitle"] {
                cell.detailTextLabel?.text = secondaryTitle as? String
            }
        }
        else if currentCellDescriptor["cellIdentifier"] as! String == "idCellTextfield" {
            cell.textField.placeholder = currentCellDescriptor["primaryTitle"] as? String
        }
        else if currentCellDescriptor["cellIdentifier"] as! String == "idCellSwitch" {
            cell.lblSwitchLabel.text = currentCellDescriptor["primaryTitle"] as? String
            
            let value = currentCellDescriptor["value"] as? String
            cell.swMaritalStatus.on = (value == "true") ? true : false
        }
        else if currentCellDescriptor["cellIdentifier"] as! String == "idCellValuePicker" {
            cell.textLabel?.text = currentCellDescriptor["primaryTitle"] as? String
        }
        else if currentCellDescriptor["cellIdentifier"] as! String == "idCellSlider" {
            let value = currentCellDescriptor["value"] as! String
            cell.slExperienceLevel.value = (value as NSString).floatValue
        }
        
        return cell
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        var isModeChangedToAutomatic = false
        var isModeChangedToManual = false
        let indexOfTappedRow = visibleRowsPerSection[indexPath.section][indexPath.row]
        
        if cellDescriptors[indexPath.section][indexOfTappedRow]["isExpandable"] as! Bool == true {
            var shouldExpandAndShowSubRows = false
            if cellDescriptors[indexPath.section][indexOfTappedRow]["isExpanded"] as! Bool == false {
                shouldExpandAndShowSubRows = true
            }
            
            cellDescriptors[indexPath.section][indexOfTappedRow].setValue(shouldExpandAndShowSubRows, forKey: "isExpanded")
            
            for i in (indexOfTappedRow + 1)...(indexOfTappedRow + (cellDescriptors[indexPath.section][indexOfTappedRow]["additionalRows"] as! Int)) {
                cellDescriptors[indexPath.section][i].setValue(shouldExpandAndShowSubRows, forKey: "isVisible")
            }
        } else {
            if cellDescriptors[indexPath.section][indexOfTappedRow]["cellIdentifier"] as! String == "idCellValuePicker" {
                var indexOfParentCell: Int!
                
                for var i=indexOfTappedRow - 1; i>=0; --i {
                    if cellDescriptors[indexPath.section][i]["isExpandable"] as! Bool == true {
                        indexOfParentCell = i
                        break
                    }
                }
                
                let parentCell = cellDescriptors[indexPath.section][indexOfParentCell]
                let parentSecondaryTitle = parentCell["secondaryTitle"] as! String
                let pickedValue = ((tblExpandable.cellForRowAtIndexPath(indexPath) as! CustomCell).textLabel?.text)!
                
                if parentSecondaryTitle == "Control Mode" && pickedValue == "Auto" {
                    isModeChangedToAutomatic = true
                }
                
                if parentSecondaryTitle == "Control Mode" && pickedValue == "Manual" {
                    isModeChangedToManual = true
                }
                
                parentCell.setValue(pickedValue, forKey: "primaryTitle")
                parentCell.setValue(false, forKey: "isExpanded")
                
                for i in (indexOfParentCell + 1)...(indexOfParentCell + (parentCell["additionalRows"] as! Int)) {
                    cellDescriptors[indexPath.section][i].setValue(false, forKey: "isVisible")
                }
                
                sendCommand(getCommand(parentSecondaryTitle, withParameter: pickedValue))
            }
        }
        
        getIndicesOfVisibleRows()
        tblExpandable.reloadSections(NSIndexSet(index: indexPath.section), withRowAnimation: UITableViewRowAnimation.Fade)
        
        if isModeChangedToAutomatic {
            loadCellDescriptors("CellDescriptorAuto")
            timer = NSTimer.scheduledTimerWithTimeInterval(3, target: self, selector: "updateDevicesStatus", userInfo: nil, repeats: true)
        }
        
        if isModeChangedToManual {
            loadCellDescriptors("CellDescriptorManual")
            timer.invalidate()
        }
    }
    
    func getCommand(keyword: String, withParameter parameter: String) -> String {
        var cmd: String
        
        switch (keyword, parameter) {
        case ("Control Mode", "Auto"):
            cmd = server + "setAutomatic/1"
        case ("Control Mode", "Manual"):
            cmd = server + "setAutomatic/0"
        case ("Alarm", "On"):
            cmd = server + "setAlarm/1"
        case ("Alarm", "Off"):
            cmd = server + "setAlarm/0"
        case ("Lamp", "On"):
            cmd = server + "setRelay/1"
        case ("Lamp", "Off"):
            cmd = server + "setRelay/0"
        default:
            cmd = server
        }
        
        return cmd
    }
        
    
    func sendCommand(url: String) {
        Just.get(url)
    }
    
    func fetchDevicesStatus() -> (String?, String?) {
        let alarmStatus = JSON(Just.get(server + "getAlarm").json!)["data"][0].string
        let relayStatus = JSON(Just.get(server + "getRelay").json!)["data"][0].string
        return (alarmStatus, relayStatus)
    }
    
    func updateDevicesStatus() {
        let status = fetchDevicesStatus()
        
        func updateUI(alarmStatusString alarmStatus: String, relayStatusString relayStatus: String) {
            cellDescriptors[1][0].setValue(alarmStatus, forKey: "primaryTitle")
            cellDescriptors[1][1].setValue(relayStatus, forKey: "primaryTitle")
            getIndicesOfVisibleRows()
            tblExpandable.reloadSections(NSIndexSet(index: 1), withRowAnimation: UITableViewRowAnimation.Fade)
        }
        
        if let alarmStatus = status.0, relayStatus = status.1 {
            switch (alarmStatus, relayStatus) {
            case ("0","0"):
                updateUI(alarmStatusString: "Off", relayStatusString: "Off")
            case ("0","1"):
                updateUI(alarmStatusString: "Off", relayStatusString: "On")
            case ("1","0"):
                updateUI(alarmStatusString: "On", relayStatusString: "Off")
            case ("1","1"):
                updateUI(alarmStatusString: "On", relayStatusString: "On")
            default:
                updateUI(alarmStatusString: "unknown", relayStatusString: "unknown")
            }
        }
    }

}
