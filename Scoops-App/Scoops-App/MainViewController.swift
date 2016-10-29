//
//  MainViewController.swift
//  Scoops
//
//  Created by Alberto Marín García on 24/10/16.
//  Copyright © 2016 Alberto Marín García. All rights reserved.
//

import UIKit

class MainViewController: UIViewController {
    
    var mobileServiceClient: MSClient?
    var storageClient: AZSCloudBlobClient?
    var container: AZSCloudBlobContainer?
    
    @IBAction func authorView(_ sender: AnyObject) {
        setupAzure()
        mobileServiceClient?.login(withProvider: "facebook", parameters: nil, controller: self, animated: true) { (user, error) in
            if let _ = error {
                print(error)
                return
            }
            
            if let _ = user {
                let storyBoard = UIStoryboard(name: "Authors", bundle: Bundle.main)
                let vc = storyBoard.instantiateViewController(withIdentifier: "authorsScene") as? AuthorsViewController
                vc?.mobileServiceClient = self.mobileServiceClient
                vc?.storageClient = self.storageClient
                vc?.container = self.container
                self.navigationController?.pushViewController(vc!, animated: true)
            }
        }
    }
    
    @IBAction func readerView(_ sender: AnyObject) {
        setupAzure()
        let storyBoard = UIStoryboard(name: "Readers", bundle: Bundle.main)
        let vc = storyBoard.instantiateViewController(withIdentifier: "readersScene") as? ReadersViewController
        vc?.mobileServiceClient = self.mobileServiceClient
        vc?.storageClient = self.storageClient
        vc?.container = self.container
        self.navigationController?.pushViewController(vc!, animated: true)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "SC👀PS"
    }
    
    //MARK:- Azure
    func setupAzure() {
        do {
            mobileServiceClient = MSClient(applicationURL: URL(string: "https://amarin-scoops.azurewebsites.net")!)

            let credentials = AZSStorageCredentials(accountName: "amarinscoops",
                                                    accountKey: "JwpQ9E/BKrKbV9Um5T1U4z6Nvm+ajhvtgrk+NT4j0zNa4nxbwWpuHpWvOnK2Rcd+8BUqMqV3rVd0BYLLU8Nlww==")
            let account = try AZSCloudStorageAccount(credentials: credentials, useHttps: true)
            storageClient = account.getBlobClient()
            container = storageClient?.containerReference(fromName: "amarin-scoops")
        } catch {
            print(error)
        }
    }

}
