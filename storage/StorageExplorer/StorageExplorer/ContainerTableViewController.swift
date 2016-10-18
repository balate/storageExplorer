//
//  ContainerTableViewController.swift
//  StorageExplorer
//
//  Created by Javier Contreras on 15/10/16.
//  Copyright © 2016 Ocon. All rights reserved.
//

import UIKit

class ContainerTableViewController: UITableViewController {
    
    var client : AZSCloudBlobClient?
    var container : AZSCloudBlobContainer?
    
    //model para la tabla
    var model : [AZSCloudBlockBlob] = []

    override func viewDidLoad() {
        super.viewDidLoad()

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem()
        
        title = container?.name
        
        //cargar los objetos
        readAllBlobs()
        //uploadBlob()
        uploadBlobWithSAS()
    }
    
    
    @IBAction func addBlobToStorage(_ sender: AnyObject) {
        
        uploadBlob()
    }
    
    func uploadBlob (){
    
        //crear refer blob local
        let myBlob = container?.blockBlobReference(fromName: UUID().uuidString)
        
        //tomamos una foto o la cogemos de los recursos
        let image = UIImage(named: "bookStar.jpg")
        
        //subir (pasando la imagen en binario)
        
        myBlob?.upload(from: UIImageJPEGRepresentation(image!, 0.5)!, completionHandler: {(error) in
        
        
            if error != nil {
                print(error)
                return
            }
            
            self.readAllBlobs()
        })
    }
    
    
    func uploadBlobWithSAS() {
    
    do {
            
        //sas de Azure
        let sas = "sv=2dates=bfqt&srt=s&sp=rwdlacup&se=2date21:11:00Z&st=2date5:16&spr=https&sig=GjsdH·%2GbhfgXxXXXXXxxxxXXEEEEU%3D"
        
        let credentials = AZSStorageCredentials(sasToken: sas, accountName: "storagetest") //nombre del storage
        
        let account = try AZSCloudStorageAccount(credentials: credentials, useHttps: true)
        
        let client = account.getBlobClient()
        
        let conti = client?.containerReference(fromName: (self.container?.name)!)
        
        let theBlob = conti?.blockBlobReference(fromName: UUID().uuidString)
        
        //tomamos una foto o la cogemos de los recursos
        let image = UIImage(named: "bookStar.jpg")
        
        //subir (pasando la imagen en binario)
        
        theBlob?.upload(from: UIImageJPEGRepresentation(image!, 0.5)!, completionHandler: {(error) in
            
            
            if error != nil {
                print(error)
                return
            }
            
            self.readAllBlobs()
        })
    
        
    }catch let ex {
        print(ex)
     }
        
    }
    
    
    
    func eraseBlobBlock(_ theBlob: AZSCloudBlockBlob){
        
        theBlob.delete{ (error) in
            
            if let _ = error {
                
                print(error)
                return
            }
            
            self.readAllBlobs()
        }
        
    }
    
    //Download element of Blob
    func downloadBlobBlock(_ theBlob: AZSCloudBlockBlob){
    
        theBlob.downloadToData {(error, data) in
        if let _ = error {
            print(error)
            return
        }
        if let _ = data {
            var img = UIImage(data: data!)
            print("Image OK")
            
            }
        
        }
    
   
    }
    
    // leer todos los elemento de la tabla
    func readAllBlobs(){
    
        //al tener la referencia del container le pasamos el metodo listBlobsSeegmented.
        container?.listBlobsSegmented(with: nil,
                                      prefix: nil,
                                      useFlatBlobListing: true,
                                      blobListingDetails: AZSBlobListingDetails.all,
                                      maxResults: -1,
                                      completionHandler: { (error, results) in
                                        if let _ = error {
                                            print(error)
                                            return
                                        }
                                        
                                        //delete model if exists.
                                        if self.model.isEmpty{
                                        
                                            self.model.removeAll()
                                        }
                                        
                                        // show elements
                                        for items in (results?.blobs)!{
                                        
                                            self.model.append(items as! AZSCloudBlockBlob)
                                        }
                                        
                                        //syncronize with table
                                        DispatchQueue.main.async {
                                            self.tableView.reloadData()
                                        }
        })
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        if model.isEmpty{
        return 0
        }
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        if model.isEmpty{
            return 0
        }
        return model.count
    }

    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "CELDABLOB", for: indexPath)

        let item = model[indexPath.row]
        cell.textLabel?.text = item.blobName

        return cell
    }
    

    /*
    // Override to support conditional editing of the table view.
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    */


    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // Delete the row from the data source
            
            tableView.beginUpdates()
            
            tableView.deleteRows(at: [indexPath], with: .fade)
            
            let item = self.model[indexPath.row]
            model.remove(at: indexPath.row)
            self.eraseBlobBlock(item)
            
            tableView.endUpdates()
            
        } else if editingStyle == .insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }    
    }


 
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let item = self.model[indexPath.row]
        
        downloadBlobBlock(item)
    }

   
}
