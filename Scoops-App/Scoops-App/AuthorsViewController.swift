//
//  AuthorsTableViewController.swift
//  Scoops
//
//  Created by Alberto Marín García on 24/10/16.
//  Copyright © 2016 Alberto Marín García. All rights reserved.
//

import UIKit

class AuthorsViewController: UITableViewController {
    
    var mobileServiceClient: MSClient?
    var storageClient: AZSCloudBlobClient?
    var container: AZSCloudBlobContainer?

    var model: [NoteRecord]? = []
    
    //MARK:- Lifecyle
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        title = "Autores"
        readMyNotes()
    }
    
    //MARK:- Actions
    @IBAction func addNewNoteAction(_ sender: AnyObject) {
        let alert = UIAlertController(title: "Nueva nota", message: "Exprésate...", preferredStyle: .alert)
        
        let actionOk = UIAlertAction(title: "OK", style: .default) { (alertAction) in
            let titleNote = alert.textFields![0] as UITextField
            let textNote = alert.textFields![1] as UITextField
            self.addNewNote(titleNote.text!, text: textNote.text!)
        }
        let actionCancel = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        alert.addAction(actionOk)
        alert.addAction(actionCancel)
        alert.addTextField { (textField) in
            textField.placeholder = "Introduce un titulo"
        }
        
        alert.addTextField {(textfield2) in
            textfield2.placeholder = "Introduce el contenido"
        }
        present(alert, animated: true, completion: nil)
    }
    
    func addNewNote(_ title: String, text: String) {
        let tableMS = mobileServiceClient!.table(withName: "Notas")
        tableMS.insert(["titulo": title, "texto": text, "votos": 0, "puntos": 0, "estado": 0]) { (results, error) in
            if let _ = error {
                print(error)
                return
            }
            
            self.readMyNotes()
            print(results)
        }
    }
    
    func readMyNotes() {
        mobileServiceClient!.invokeAPI("readNotesByUser", body: nil, httpMethod: "GET", parameters: nil, headers: nil) { (result, response, error) in
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
    
    func deleteNote(_ note: NoteRecord) {
        let table = mobileServiceClient?.table(withName: "Notas")
        
        table?.delete(note) { (reult, error) in
            if let _ = error {
                print(error)
                // refrescar la tabla
                self.readMyNotes()
                return
            }
            
            // refrescar la tabla
            self.readMyNotes()

            // Eliminar el blob del container
            if let fotoName = note["foto"] as? String {
                let theBlob = self.container?.blockBlobReference(fromName: fotoName)
                theBlob?.delete { (error) in
                    if let _ = error {
                        print(error)
                        return
                    }
                }
            }
        }
    }

    //MARK: - Table view data source
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
    
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // Delete the row from Azure
            let note = self.model?[indexPath.row]
            self.deleteNote(note!)
        }
    }
}
