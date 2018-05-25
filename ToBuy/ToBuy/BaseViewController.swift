//
//  BaseViewController.swift
//  ToBuy
//
//  Created by Hung Ricky on 2018/5/17.
//
//

import UIKit

class BaseViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UITextFieldDelegate {
    
    let fullsize = UIScreen.main.bounds.size
    let myUserDefaults = UserDefaults.standard
    let moc = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
    let buyListEntity = "BuyList"
    var coreDataConnect :CoreDataConnect!
    var myBuyLists : [BuyList]! = []
    var myDoneLists : [BuyList]! = []
    
    var myTableView :UITableView!
    var checkStatus = false
    let checkTagTemp = 1000
    let myBgColor = UIColor.white

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        // 連接 Core Data
        coreDataConnect = CoreDataConnect(context: self.moc)
        
        // 基本設定
        self.view.backgroundColor = myBgColor
        self.navigationController?.navigationBar.isTranslucent = false
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewWillAppear(_ animated: Bool) {
        // 取得資料
        //let selectResult = coreDataConnect.retrieve(buyListEntity, predicate: "done = \(checkStatus ? "true" : "false")", sort: [["seq":false], ["id":false]], limit:nil)
        var selectResult = coreDataConnect.retrieve(buyListEntity, predicate: "done = false", sort: [["seq":true], ["id":false]], limit:nil)
        if let results = selectResult {
            myBuyLists = results as! [BuyList]
        }
        
        selectResult = coreDataConnect.retrieve(buyListEntity, predicate: "done = true", sort: [["seq":true], ["id":false]], limit:nil)
        if let results = selectResult {
            myDoneLists = results as! [BuyList]
        }
        
        myTableView.reloadData()
    }
    
    // MARK: UITableView Delegate methods
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch section {
        case 0:
            return "待購"
        case 1:
            return "已購"
        default:
            return ""
        }
    }
    
    // 必須實作的方法：每一組有幾個 cell
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            return myBuyLists.count
        }else {
            return myDoneLists.count
        }
    }
    
    // 必須實作的方法：每個 cell 要顯示的內容
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        // 取得 tableView 目前使用的 cell
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath) as UITableViewCell

        // 移除舊的按鈕
        for view in cell.contentView.subviews {
            if let v = view as? UIButton {
                v.removeFromSuperview()
            }
        }
        
        // 點選完成事項
        let checkBtn = UIButton(frame: CGRect(x: Double(fullsize.width) - 42, y: 2, width: 40, height: 40))
        
        // 顯示的內容
        if indexPath.section == 0 {
            cell.textLabel?.text = "\(myBuyLists[indexPath.row].itemname ?? "")"
            checkBtn.tag = checkTagTemp + (myBuyLists[indexPath.row].id ?? 0).intValue
            checkBtn.setTitle(myBuyLists[indexPath.row].done == true ? "\u{2705}" : "\u{2B1C}", for: .normal)
        } else {
            cell.textLabel?.text = "\(myDoneLists[indexPath.row].itemname ?? "")"
            checkBtn.tag = checkTagTemp + (myDoneLists[indexPath.row].id ?? 0).intValue
            checkBtn.setTitle(myDoneLists[indexPath.row].done == true ? "\u{2705}" : "\u{2B1C}", for: .normal)
        }
        
        cell.backgroundColor = myBgColor
        
        checkBtn.addTarget(self, action: #selector(ViewController.checkBtnAction), for: .touchUpInside)
        
        //checkBtn.setImage(UIImage(named:(checkStatus ? "check" : "checkbox")), for: .normal)
        cell.contentView.addSubview(checkBtn)
        
        return cell
    }
    
    // 點選 cell 後執行的動作
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        self.view.endEditing(true)
        
        // 取消 cell 的選取狀態
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    // 各 cell 是否可以進入編輯狀態 及 左滑刪除
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    // 編輯狀態時 按下刪除 cell 後執行動作的方法 (另外必須實作這個方法才會出現左滑刪除功能)
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        
        if indexPath.section == 0 {
            let id = myBuyLists[indexPath.row].id
            
            if editingStyle == .delete {
                if coreDataConnect.delete(buyListEntity, predicate: "id = \(id!)") {
                    
                    myBuyLists.remove(at: indexPath.row)
                    
                    tableView.beginUpdates()
                    tableView.deleteRows(at: [indexPath], with: .fade)
                    tableView.endUpdates()
                    
                    print("刪除的是 \(id!)")
                }
            }
        } else {
            let id = myDoneLists[indexPath.row].id
            
            if editingStyle == .delete {
                if coreDataConnect.delete(buyListEntity, predicate: "id = \(id!)") {
                    
                    myDoneLists.remove(at: indexPath.row)
                    
                    tableView.beginUpdates()
                    tableView.deleteRows(at: [indexPath], with: .fade)
                    tableView.endUpdates()
                    
                    print("刪除的是 \(id!)")
                }
            }
        }
        
    }
    
    
    // MARK: Button actions
    
    // 按下完成事項按鈕執行動作的方法
    @objc func checkBtnAction(_ sender: UIButton) {
        let id = sender.tag - checkTagTemp
        var gotItState = false
        
        if id != 0 {
            var index = -1
            for (i, buyList) in myBuyLists.enumerated() {
                if (buyList.id as! Int) == id {
                    index = i
                    gotItState = false
                    break
                }
            }
            
            if index == -1 {
                for (i, doneList) in myDoneLists.enumerated() {
                    if (doneList.id as! Int) == id {
                        index = i
                        gotItState = true
                        break
                    }
                }
            }
            
            if index != -1 {
                // 設置 Core Data
                let result = coreDataConnect.update(buyListEntity, predicate: "id = \(id)", attributeInfo: ["done":(gotItState ? "false" : "true")])
                if result {
                    
                    // 打勾
                    //sender.setImage(UIImage(named:(checkStatus ? "checkbox" : "check")), for: .normal)
                    sender.setTitle(gotItState ? "\u{2705}" : "\u{2B1C}", for: .normal)
                    
                    // 從陣列中移除
                    if gotItState {
                        myBuyLists.append(myDoneLists[index])
                        myDoneLists.remove(at: index)
                        for (index, value) in myBuyLists.enumerated() {
                            _ = coreDataConnect.update(buyListEntity, predicate: "id = \(value.id!)", attributeInfo: ["seq":String(index)])
                        }
                    } else {
                        myDoneLists.append(myBuyLists[index])
                        myBuyLists.remove(at: index)
                        for (index, value) in myDoneLists.enumerated() {
                            _ = coreDataConnect.update(buyListEntity, predicate: "id = \(value.id!)", attributeInfo: ["seq":String(index)])
                        }
                    }
                    
                    // 從 UITableView 中移除
                    myTableView.beginUpdates()
                    //myTableView.deleteRows(at: [IndexPath(row: index, section: isBuyState ? 1 : 0)], with: .fade)
//                    print("got it State = \(gotItState)")
//                    print("index = \(index)")
//                    print("DoneList count = \(myDoneLists.count)")
//                    print("BuyList count = \(myBuyLists.count)")
//                    myTableView.moveRow(at: IndexPath(row: index, section: isBuyState ? 1 : 0), to: IndexPath(row: isBuyState ? myDoneLists.count - 1 : myBuyLists.count - 1, section: isBuyState ? 0 : 1))
                    myTableView.deleteRows(at: [IndexPath(row: index, section: gotItState ? 1 : 0)], with: .fade)
                    myTableView.insertRows(at: [IndexPath(row: gotItState ? myBuyLists.count - 1 : myDoneLists.count - 1, section: gotItState ? 0 : 1)], with: .fade)
                    myTableView.endUpdates()
                } else {
                    print("error")
                }
            }
        }
    }


}
