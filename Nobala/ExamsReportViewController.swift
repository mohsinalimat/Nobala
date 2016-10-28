//
//  ExamsReportViewController.swift
//  Nobala
//
//  Created by Abdelrahman Mohamed on 10/21/16.
//  Copyright © 2016 Abdelrahman Mohamed. All rights reserved.
//

import UIKit
import ENSwiftSideMenu
import ASProgressHud
import KeychainAccess

class ExamsReportViewController: UIViewController, ENSideMenuDelegate, UITableViewDelegate, UITableViewDataSource, SetTimeViewControllerDelegate {
    
    @IBOutlet weak var userName: UILabel!
    @IBOutlet weak var userType: UIImageView!
    
    @IBOutlet weak var examReportTableView: UITableView!
    
    var fromDate: NSDate?
    var toDate: NSDate?
    
    var startDate: String?
    var endDate: String?
    
    @IBOutlet weak var fromDateLabel: UILabel!
    @IBOutlet weak var toDateLabel: UILabel!
    
    var examReportArrary = []
    var selectedExamReport: ExamStudentReport = ExamStudentReport()

    var sideMenu:ENSideMenu?
    
    var window: UIWindow?
    var setTimeVC: SetTimeViewController?
    
    let keychain = Keychain(service: "Noblaa.app")
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.sideMenuController()?.sideMenu?.delegate = self
        
        let logo = UIImage(named: "LoginTitle.png")
        let imageView = UIImageView(image:logo)
        self.navigationItem.titleView = imageView
        
        window = UIWindow(frame: UIScreen.mainScreen().bounds)
        
        userName.text = keychain["userFName"]
        
        if keychain["user_type"]! == "1" {
            userType.image = UIImage(named: "MLParant.png")
        } else if keychain["user_type"]! == "2" {
            userType.image = UIImage(named: "MLStudend.png")
        } else {
            userType.image = UIImage(named: "MLTeacher.png")
        }
        
        
    }
    
    func fetchExamReport() {
        
        // Do NOT call webservice if either of dates has no value
        if nil == endDate || nil == startDate {return}
        
        ASProgressHud.showHUDAddedTo(self.view, animated: true, type: .Default)
        
        if let Userauth_token : String = keychain["auth_token"] {
            
            NobalaClient.sharedInstance().getExamsStudentReport(Userauth_token, startDate: startDate!, endDate: endDate!,completionHandler: { (success, errorMessage, myResult) in
                
                if !success {
                    
                    var message = "Unknown error, please try again"
                    
                    if errorMessage == "invalid_Data" {
                        
                        message = "Pleas Make Sure  is correct"
                    }
                    
                    let alertController = UIAlertController(title: "Oops", message: message, preferredStyle: .Alert)
                    alertController.addAction(UIAlertAction(title: "OK", style: .Default, handler: nil))
                    
                    self.presentViewController(alertController, animated: true, completion: nil)
                    
                    return
                }
                
                self.examReportArrary = myResult
                
                ASProgressHud.hideHUDForView(self.view, animated: true)
                
                self.examReportTableView.reloadData()
                
                }, fail: { (error, errorMessage) in
                    let alertController = UIAlertController(title: "Oops", message: "Connection error, please try again", preferredStyle: .Alert)
                    alertController.addAction(UIAlertAction(title: "OK", style: .Default, handler: nil))
                    
                    self.presentViewController(alertController, animated: true, completion: nil)
            })
        }
        
        ASProgressHud.hideHUDForView(self.view, animated: true)
    }
    
    override func viewWillAppear(animated: Bool) {
        
        NSThread.sleepForTimeInterval(0.05)
        
        let leftView = storyboard?.instantiateViewControllerWithIdentifier("LeftMenuController") as!leftViewController
        sideMenu = ENSideMenu(sourceView: self.view, menuViewController: leftView, menuPosition: .Left)
        
        let screenSize: CGRect = UIScreen.mainScreen().bounds
        let screenWidth = screenSize.width
        
        //        sideMenu?.menuWidth = screenWidth - 100
        sideMenu?.menuWidth = screenWidth * 0.75
        
        self.sideMenu!.delegate = self
    }
    
    // MARK: - SideMenuButton
    func sideMenuWillOpen() {
        print("ExamsReportViewControllerSideMenuWillOpen")
    }
    
    @IBAction func toggle(sender: AnyObject)
    {
        if ((self.sideMenu?.isMenuOpen) == false)
        {
            self.sideMenu?.showSideMenu()
            
        }
        else
        {
            self.sideMenu?.hideSideMenu()
        }
    }
    
    @IBAction func goToHome(sender: AnyObject) {
        
        let secondViewController = self.storyboard!.instantiateViewControllerWithIdentifier("NobalaStory") as! NobalaViewController
        self.navigationController!.pushViewController(secondViewController, animated: true)
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.examReportArrary.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        let row = indexPath.row
        let tableViewCell = self.examReportTableView.dequeueReusableCellWithIdentifier("ExamReportCell", forIndexPath: indexPath) as! ExamsReportTableViewCell
        
        tableViewCell.ExamTitle.text = examReportArrary[row].valueForKey("ScheduleName") as? String
        tableViewCell.ExamText.text = examReportArrary[row].valueForKey("ScheduleEndDate") as? String
        tableViewCell.ExamDegree.text = String((examReportArrary[row].valueForKey("ExamSheetScore") as? Int)!)
        
        tableViewCell.contentView.viewWithTag(11)!.backgroundColor = Float(indexPath.row) % 2.0 == 0 ? UIColor(red:0.94, green:0.95, blue:0.95, alpha:1.0) : UIColor(red:0.99, green:0.96, blue:0.86, alpha:1.0)
        

        
        return tableViewCell
    }
    
    @IBAction func chooseTime(sender: UIButton) {
        //        setTimeVC = self.storyboard?.instantiateViewControllerWithIdentifier("SetTimeViewController") as? SetTimeViewController
        
        setTimeVC = SetTimeViewController(nibName: "SetTimeView", bundle: NSBundle.mainBundle())
        if sender.tag == 13 {
            setTimeVC?.type = .To
        }
        setTimeVC!.containerController = self
        
        // Create the dialog
        let popup = PopupDialog(viewController: setTimeVC!, transitionStyle: .BounceDown, buttonAlignment: .Horizontal, gestureDismissal: true)
        
        setTimeVC!.dialog = popup
        
        // Present dialog
        self.presentViewController(popup, animated: true, completion: nil)
    }
    
    func updateChosenTimes(date: NSDate, type: ChooseTimeViewType) {
        
        let formatter = NSDateFormatter()
        formatter.dateFormat = "yyyy/MM/dd"
        formatter.locale = NSLocale(localeIdentifier: "ar")
        switch type {
        case .To:
            toDate = date
            toDateLabel.text = formatter.stringFromDate(date)
            
            formatter.locale = NSLocale(localeIdentifier: "en")
            formatter.dateFormat = "dd/MM/yyyy"
            endDate = formatter.stringFromDate(date)
        case .From:
            fromDate = date
            fromDateLabel.text = formatter.stringFromDate(date)
            
            formatter.locale = NSLocale(localeIdentifier: "en")
            formatter.dateFormat = "dd/MM/yyyy"
            startDate = formatter.stringFromDate(date)
        }
    }
    
    func refreshPresentedData() {
        fetchExamReport()
    }


    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
