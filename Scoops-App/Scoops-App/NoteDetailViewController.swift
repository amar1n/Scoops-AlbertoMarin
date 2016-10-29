//
//  NoteViewController.swift
//  Scoops-App
//
//  Created by Alberto Marín García on 28/10/16.
//  Copyright © 2016 Alberto Marín García. All rights reserved.
//

import UIKit

class NoteDetailViewController: UIViewController {
    
    var mobileServiceClient: MSClient?
    var container: AZSCloudBlobContainer?
    
    var model: NoteRecord?
    var puntos: NSNumber?
    
    @IBOutlet weak var tituloView: UILabel! {
        didSet {
            tituloView.text = model?["titulo"] as! String?
        }
    }
    
    @IBOutlet weak var textoView: UITextView! {
        didSet {
            textoView.text = model?["texto"] as! String?
        }
    }
    
    @IBOutlet weak var fotoView: UIImageView!
    
    @IBOutlet weak var pointsView: UITextField! {
        didSet {
            puntos = 0
            pointsView.text = "\(puntos!)"
        }
    }
    
    @IBOutlet weak var scoreView: UILabel!

        //MARK:- Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "Nota"
        getPhotoFromAzure()
        
        textoView.isEditable = (mobileServiceClient?.currentUser) != nil
        pointsView.isUserInteractionEnabled = (mobileServiceClient?.currentUser) == nil
        
        if ((mobileServiceClient?.currentUser) != nil) {
            let camera = UIBarButtonItem(barButtonSystemItem: .camera, target: self, action: #selector(NoteDetailViewController.takePhoto))
            self.navigationItem.rightBarButtonItem = camera
            
            textoView.isEditable = true
            
            pointsView.isUserInteractionEnabled = false
        } else {
            self.navigationItem.rightBarButtonItem = nil
            
            textoView.isEditable = false
            
            pointsView.isUserInteractionEnabled = true
        }
        
        scoreView.text = "La nota es 0"
        if let v = model?["votos"] as? NSNumber,
            let p = model?["puntos"] as? NSNumber {
            if v.intValue != 0 {
                scoreView.text = "La nota es \(p.intValue / v.intValue)"
            }
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        syncModelFromViews()
    }
    
    func syncModelFromViews() {
        if ((mobileServiceClient?.currentUser) != nil) {
            // El texto...
            model?["texto"] = textoView.text as AnyObject?
            let table = mobileServiceClient?.table(withName: "Notas")
            table?.update(model!, completion: { (result, error) in
                if let _ = error {
                    print(error)
                    return
                }
            })
        } else {
            // Los puntos...
            if let pStr = pointsView.text {
                if let pInt = Int(pStr) {
                    let p = NSNumber(value:pInt)
                    if (p != puntos) {
                        mobileServiceClient!.invokeAPI("updatePoints", body: nil, httpMethod: "GET", parameters: ["puntos": p, "id": (self.model?["id"])!], headers: nil) { (result, response, error) in
                            if let _ = error {
                                print(error)
                                return
                            }
                        }
                    }
                }
            }
        }
    }
    
    //MARK:- Actions
    func takePhoto() {
        // Crear una instancia de UIImagePicker
        let picker = UIImagePickerController()
        
        // Configurarla
        if UIImagePickerController.isCameraDeviceAvailable(.rear) {
            picker.sourceType = .camera
        } else {
            // Me conformo con el carrete
            picker.sourceType = .photoLibrary
        }
        picker.delegate = self
        
        // Mostrarlo de forma modal
        self.present(picker, animated: true, completion: {
            // Por si quieres hacer algo nada mas mostrar el picker
        })
    }
    
    //MARK:- Azure
    func getPhotoFromAzure() {
        if let fotoName = model?["foto"] as? String {
            let myBlob = container?.blockBlobReference(fromName: fotoName)
            myBlob?.downloadToData(completionHandler: { (error, data) in
                if let _ = error {
                    print(error)
                    return
                }
                
                if let imgData = data {
                    let img = UIImage(data: imgData)
                    DispatchQueue.main.async {
                        self.fotoView.image = img
                    }
                }
            })
        }
    }
}

//MARK: - Delegates
extension NoteDetailViewController : UIImagePickerControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        // Crear el blob local
        let myBlobName = UUID().uuidString
        let myBlob = container?.blockBlobReference(fromName: myBlobName)
        
        // Tomamos una foto o la agarramos de los recursos
        let img = info[UIImagePickerControllerOriginalImage] as! UIImage?
        
        // Hacemos la subida
        myBlob?.upload(from: UIImagePNGRepresentation(img!)!, completionHandler: { (error) in
            if error != nil {
                print(error)
                return
            }
            
            // Actualizar el nombre del blob en la tabla Notas...
            self.model?["foto"] = myBlobName as AnyObject?
            let table = self.mobileServiceClient?.table(withName: "Notas")
            table?.update(self.model!, completion: { (result, error) in
                if let _ = error {
                    print(error)
                    return
                }
                
                DispatchQueue.main.async {
                    self.fotoView.image = img
                }
            })
            
        })
        
        self.dismiss(animated: true) {
            //
        }
    }
}

extension NoteDetailViewController : UINavigationControllerDelegate {
    
}

