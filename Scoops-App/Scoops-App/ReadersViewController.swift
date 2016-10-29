//
//  ReaderViewController.swift
//  Scoops
//
//  Created by Alberto Marín García on 24/10/16.
//  Copyright © 2016 Alberto Marín García. All rights reserved.
//

import UIKit

class ReadersViewController: UITableViewController {
    
    var mobileServiceClient: MSClient?
    var storageClient: AZSCloudBlobClient?
    var container: AZSCloudBlobContainer?
    
    var model: [NoteRecord]? = []
    
    //MARK:- Lifecyle
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        title = "Lectores"
        readAllNotes()
    }
    
    //MARK:- Actions
    func readAllNotes() {
        mobileServiceClient!.invokeAPI("readAllNotes", body: nil, httpMethod: "GET", parameters: nil, headers: nil) { (result, response, error) in
            if let _ = error {
                print(error)
                return
            }
            
            if !((self.model?.isEmpty)!) {
                self.model?.removeAll()
            }
            
            if let _ = result {
                let json = result as! [NoteRecord]
                
                for item in json {
                    self.model?.append(item)
                }
                
                DispatchQueue.main.async {
                    self.tableView.reloadData()
                }
            }
        }
    }
    
    // MARK: - Table view data source
    override func numberOfSections(in tableView: UITableView) -> Int {
        if (model?.isEmpty)! {
            return 0
        }
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if (model?.isEmpty)! {
            return 0
        }
        return (model?.count)!
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "NOTE", for: indexPath)
        
        let item = model?[indexPath.row]
        
        cell.textLabel?.text = item?["titulo"] as! String?
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let note = model?[indexPath.row]
        
        let storyBoard = UIStoryboard(name: "NoteDetail", bundle: Bundle.main)
        let vc = storyBoard.instantiateViewController(withIdentifier: "noteDetailScene") as? NoteDetailViewController
        vc?.model = note
        vc?.mobileServiceClient = mobileServiceClient
        vc?.container = container
        self.navigationController?.pushViewController(vc!, animated: true)
    }
}
