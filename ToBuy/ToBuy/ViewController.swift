//
//  ViewController.swift
//  ToBuy
//
//  Created by Hung Ricky on 2018/5/16.
//
//

import UIKit

class ViewController: BaseViewController, UIGestureRecognizerDelegate {
    var myTextField :UITextField!
    var addBtn :UIButton!
    var tap : UIGestureRecognizer!

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        self.title = "待購清單"
        checkStatus = false
        
        tap = UITapGestureRecognizer(target: self, action: #selector(ViewController.hideKeyBoard(tapG:)))
        tap.delegate = self
        
        // 建立 UITableView F8BBD0
        myTableView = UITableView(frame: CGRect(x: 0, y: 44, width: fullsize.width, height: fullsize.height - 108), style: .plain) // 108 = 20 + 44 + 44
        myTableView.backgroundColor = myBgColor
        myTableView.register(UITableViewCell.self, forCellReuseIdentifier: "Cell")
        myTableView.delegate = self
        myTableView.dataSource = self
        myTableView.allowsSelection = true
        self.view.addSubview(myTableView)
        
        // 導覽列右邊更多按鈕
//        self.navigationItem.rightBarButtonItem = UIBarButtonItem(image: UIImage(named: "more")!, style: .plain, target: self, action: #selector(ViewController.moreBtnAction))
        
        // 新增輸入框
        myTextField = UITextField(frame: CGRect(x: 9, y: 5, width: fullsize.width - 54, height: 34))
        myTextField.backgroundColor = UIColor.init(red: 0.95, green: 0.95, blue: 0.95, alpha: 1)
        myTextField.delegate = self
        myTextField.placeholder = "新進事項"
        myTextField.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 8, height: 34))
        myTextField.leftViewMode = .always
        myTextField.returnKeyType = .done
        myTextField.keyboardType = .default
        self.view.addSubview(myTextField)
        
        // 新增按鈕
        addBtn = UIButton(type: .contactAdd)
        addBtn.center = CGPoint(x: fullsize.width - 22, y: 22)
        addBtn.addTarget(self, action: #selector(ViewController.addBtnAction), for: .touchUpInside)
        self.view.addSubview(addBtn)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
        
        // 進入 非 編輯模式
        myTableView.setEditing(true, animated: false)
        self.editBtnAction()
        
        myTableView.removeGestureRecognizer(tap)
        myTableView.addGestureRecognizer(tap)
    }
    
    @objc func hideKeyBoard(tapG: UITapGestureRecognizer) {
        print(#function)
        self.view.endEditing(true)
    }
    
    // MARK: UIGestureRecognizerDelegate
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        //避免tableView's didSelect造成手勢無法縮鍵盤
        if myTextField.isEditing {
            return true
        }
        return false
    }
    
    // MARK: Button actions
    
//    // 按下更多按鈕時執行動作的方法
//    @objc func moreBtnAction() {
//        self.navigationController?.pushViewController(MoreViewController(), animated: true)
//    }
    
    // 按下編輯按鈕時執行動作的方法
    @objc func editBtnAction() {
        myTableView.setEditing(!myTableView.isEditing, animated: true)
        let allList = myBuyLists + myDoneLists
        if (!myTableView.isEditing) {
            // 顯示編輯按鈕
            self.navigationItem.leftBarButtonItem = UIBarButtonItem(title: "編輯", style: .plain , target: self, action: #selector(ViewController.editBtnAction))
            self.navigationItem.leftBarButtonItem?.tintColor = UIColor.darkGray
            
            // 可以新增
            myTextField.isUserInteractionEnabled = true
            addBtn.isEnabled = true
            
            // 顯示完成按鈕
            for buyList in allList {
                if let id = buyList.id {
                    let btn = self.view.viewWithTag(checkTagTemp + id.intValue) as? UIButton
                    btn?.isHidden = false
                }
            }
                        
        } else {
            // 顯示編輯完成按鈕
            self.navigationItem.leftBarButtonItem = UIBarButtonItem(title: "完成", style: .plain , target: self, action: #selector(ViewController.editBtnAction))
            
            // 無法新增
            self.view.endEditing(true)
            myTextField.isUserInteractionEnabled = false
            addBtn.isEnabled = false
            
            // 隱藏完成按鈕
            for buyList in allList {
                if let id = buyList.id {
                    let btn = self.view.viewWithTag(checkTagTemp + id.intValue) as? UIButton
                    btn?.isHidden = true
                }
            }
            
        }
    }
    
    // 按下新增按鈕時執行動作的方法
    @objc func addBtnAction() {
        // 結束編輯 把鍵盤隱藏起來
        self.view.endEditing(true)
        
        let itemname = myTextField.text ?? ""
        
        if itemname != "" {
            
            // 取得目前 seq 的最大值
            var seq = 100
            let selectResult = coreDataConnect.retrieve(buyListEntity, predicate: "done = false", sort: [["id":true]], limit: 1)
            if let results = selectResult {
                for result in results {
                    seq = (result.value(forKey: "seq") as! Int) + 1
                }
            }
            
            // auto increment
            var id = 1
            if let idSeq = myUserDefaults.object(forKey: "idSeq") as? Int {
                id = idSeq + 1
            }
            
            // insert
            let insertResult = coreDataConnect.insert(
                buyListEntity, attributeInfo: [
                    "id" : "\(id)",
                    "seq" : "\(seq)",
                    "itemname" : itemname,
                    "remark" : "",
                    "done" : "false"
                ])
            
            if insertResult {
                print("新增資料成功")
                
                // 新增資料至陣列
                let newBuyList = coreDataConnect.retrieve(buyListEntity, predicate: "id = \(id)", sort: nil, limit: 1)
                
                myBuyLists.insert((newBuyList![0] as! BuyList), at: 0)
                
                // 新增 cell 在第一筆 row
                myTableView.beginUpdates()
                myTableView.insertRows(at: [IndexPath(row: 0, section: 0)], with: .fade)
                myTableView.endUpdates()
                
                // 更新 auto increment
                myUserDefaults.set(id, forKey: "idSeq")
                myUserDefaults.synchronize()
                
                // 重設輸入框
                myTextField.text = ""
                
            }
        }
        
    }
    
    // MARK: UITableView Delegate methods
    
    // 點選 cell 後執行的動作
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        super.tableView(tableView, didSelectRowAt: indexPath)
        
        self.updateRecordContent(indexPath)
        
    }
    
    // 編輯狀態時 拖曳切換 cell 位置後執行動作的方法 (必須實作這個方法才會出現排序功能)
    func tableView(_ tableView: UITableView, moveRowAtIndexPath sourceIndexPath: IndexPath, toIndexPath destinationIndexPath: IndexPath) {
        print("\(sourceIndexPath.row) to \(destinationIndexPath.row)")
        
        if sourceIndexPath.section == destinationIndexPath.section &&
            sourceIndexPath.row == destinationIndexPath.row {
            return
        }
        
        var tempBuyArr:[BuyList] = []
        var tempDoneArr:[BuyList] = []
        
        if sourceIndexPath.section == destinationIndexPath.section {
            let tempLists:[BuyList]!
            var tempArr:[BuyList] = []
            if destinationIndexPath.section == 0 {
                tempLists = myBuyLists
                tempArr = tempBuyArr
            } else {
                tempLists = myDoneLists
                tempArr = tempDoneArr
            }
            if(sourceIndexPath.row > destinationIndexPath.row) { // 排在後的往前移動
                for (index, value) in tempLists.enumerated() {
                    if index < destinationIndexPath.row || index > sourceIndexPath.row {
                        tempArr.append(value)
                    } else if index == destinationIndexPath.row {
                        tempArr.append(tempLists[sourceIndexPath.row])
                    } else if index <= sourceIndexPath.row {
                        tempArr.append(tempLists[index - 1])
                    }
                }
                
            } else if (sourceIndexPath.row < destinationIndexPath.row) { // 排在前的往後移動
                for (index, value) in tempLists.enumerated() {
                    if index < sourceIndexPath.row || index > destinationIndexPath.row {
                        tempArr.append(value)
                    } else if index < destinationIndexPath.row {
                        tempArr.append(tempLists[index + 1])
                    } else if index == destinationIndexPath.row {
                        tempArr.append(tempLists[sourceIndexPath.row])
                    }
                }
            } else {
                tempBuyArr = myBuyLists
                tempDoneArr = myDoneLists
            }
            if destinationIndexPath.section == 0 {
                tempBuyArr = tempArr
                tempDoneArr = myDoneLists
            } else {
                tempBuyArr = myBuyLists
                tempDoneArr = tempArr
            }
        }else {
            var sourceArray : [BuyList] = []
            var destinationArray : [BuyList] = []
            let sourceLists : [BuyList]!
            let destinationLists : [BuyList]!
            
            if destinationIndexPath.section == 0 {
                sourceLists = myDoneLists
                destinationLists = myBuyLists
            } else {
                sourceLists = myBuyLists
                destinationLists = myDoneLists
            }
            
            //避免目的section沒有資料不執行
            if destinationLists.count == 0 {
                destinationArray.append(sourceLists[sourceIndexPath.row])
            } else {
                for (index, value) in destinationLists.enumerated() {
//                    print("destination index :\(index) valueItem :\(value.itemname!)")
                    if index + 1 == destinationIndexPath.row && index + 1 == destinationLists.count {
                        destinationArray.append(value)
                        destinationArray.append(sourceLists[sourceIndexPath.row])
                    } else if index == destinationIndexPath.row {
                        destinationArray.append(sourceLists[sourceIndexPath.row])
                        destinationArray.append(value)
                    } else {
                        destinationArray.append(value)
                    }
                }
            }
            for (index, value) in sourceLists.enumerated() {
                if index != sourceIndexPath.row{
                    sourceArray.append(value)
                }
            }
            
            if destinationIndexPath.section == 0 {
                tempBuyArr = destinationArray
                tempDoneArr = sourceArray
            } else {
                tempBuyArr = sourceArray
                tempDoneArr = destinationArray
            }
            
        }
        
        for tempBuy in tempBuyArr {
            tempBuy.done = false
        }
        for tempDone in tempDoneArr {
            tempDone.done = true
        }
        
        myBuyLists = tempBuyArr
        myDoneLists = tempDoneArr
        self.updateRecordsSeq()
        
        tableView.reloadData()
    }
    
    // MARK: UITextFieldDelegate delegate methods
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        self.addBtnAction()
        
        return true
    }
    
    
    // MARK: functional methods
    
    // 更新事項內容
    func updateRecordContent(_ indexPath :IndexPath) {
        
        var updateList :[BuyList] = indexPath.section == 0 ? myBuyLists: myDoneLists
        
        let name = updateList[indexPath.row].itemname!
        let id = updateList[indexPath.row].id!.intValue
        
        // 更新事項
        let updateAlertController = UIAlertController(title: "更新", message: nil, preferredStyle: .alert)
        
        // 建立輸入框
        updateAlertController.addTextField {
            (textField: UITextField!) -> Void in
            textField.text = name
            textField.placeholder = "更新事項"
        }
        
        // 建立[取消]按鈕
        let cancelAction = UIAlertAction(title: "取消", style: .cancel, handler: nil)
        updateAlertController.addAction(cancelAction)
        
        // 建立[更新]按鈕
        let okAction = UIAlertAction(title: "更新", style: UIAlertActionStyle.default) {
            (action: UIAlertAction!) -> Void in
            let content = (updateAlertController.textFields?.first)! as UITextField
            
            let result = self.coreDataConnect.update(self.buyListEntity, predicate: "id = \(id)", attributeInfo: ["itemname":"\(content.text!)"])
            if result {
                let newBuyList = self.coreDataConnect.retrieve(self.buyListEntity, predicate: "id = \(id)", sort: nil, limit: 1)
                
                //self.myBuyLists[indexPath.row] = newBuyList![0] as! BuyList
                updateList[indexPath.row] = newBuyList![0] as! BuyList
                self.myTableView.reloadData()
            } else {
                print("error")
            }
        }
        updateAlertController.addAction(okAction)
        
        // 顯示提示框
        self.present(updateAlertController, animated: true, completion: nil)
    }
    
    // 更新 Core Data 資料的排序
    func updateRecordsSeq() {
        var seq = 1
        
        for buyList in myBuyLists {
            let result = coreDataConnect.update(buyListEntity, predicate: "id = \(buyList.id!)", attributeInfo: ["seq":"\(seq)", "done":"false"])
            if result {
                print("\(buyList.id!) \(buyList.itemname!) : \(seq)")
            } else {
                print("error")
            }
            seq = seq + 1
        }
        
        seq = 1
        
        for doneList in myDoneLists {
            let result = coreDataConnect.update(buyListEntity, predicate: "id = \(doneList.id!)", attributeInfo: ["seq":"\(seq)", "done":"true"])
            if result {
                print("\(doneList.id!) \(doneList.itemname!) : \(seq)")
            } else {
                print("error")
            }
            seq = seq + 1
        }
    }



}

