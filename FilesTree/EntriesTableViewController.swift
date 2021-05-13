//
//  EntriesTableViewController.swift
//  FilesTree
//
//  Created by Dmitry Reshetnik on 13.05.2021.
//

import UIKit

class EntriesTableViewController: UITableViewController {
    var entries: [Entry] = []
    var entriesTree: [UUID: Entry] = [:]

    override func viewDidLoad() {
        super.viewDidLoad()

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem
        
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "Entry")

        if entriesTree.isEmpty && entries.isEmpty {
            fetchData()
        } else {
            updateUI()
        }
    }
    
    func fetchData() {
        var componetns = URLComponents(string: "https://sheets.googleapis.com/v4/spreadsheets/1e8gLI6Ft1qlawb7DWHUGPUQlkpDaV5wxkuJvNkWGGHE/values/Sheet1")!
        componetns.queryItems = [URLQueryItem(name: "key", value: "AIzaSyBPybXkT_7v-Fjzg9xDnCpEglBRM1QtiV4")]
        let request = URLRequest(url: componetns.url!)
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let data = data {
                do {
                    let values = try JSONDecoder().decode(Response.self, from: data).values
                    
                    self.constructEntriesTree(from: values)
                    
                    DispatchQueue.main.async {
                        self.updateUI()
                    }
                } catch DecodingError.keyNotFound(let key, let context) {
                    Swift.print("could not find key \(key) in JSON: \(context.debugDescription)")
                } catch DecodingError.valueNotFound(let type, let context) {
                    Swift.print("could not find type \(type) in JSON: \(context.debugDescription)")
                } catch DecodingError.typeMismatch(let type, let context) {
                    Swift.print("type mismatch for type \(type) in JSON: \(context.debugDescription)")
                } catch DecodingError.dataCorrupted(let context) {
                    Swift.print("data found to be corrupted in JSON: \(context.debugDescription)")
                } catch let error as NSError {
                    NSLog("Error in read(from:ofType:) domain= \(error.domain), description= \(error.localizedDescription)")
                }
            }
        }.resume()
    }
    
    func updateUI() {
        tableView.reloadData()
    }
    
    func constructEntriesTree(from values: [[String]]) {
        for value in values {
            let entry = Entry(itemID: UUID(uuidString: value[0])!, parentItemID: UUID(uuidString: value[1]), itemType: value[2] == "f" ? .file : .directory, itemName: value[3])
            entries.append(entry)
        }
        
        for entry in entries {
            if entry.parentItemID == nil {
                entriesTree[entry.itemID] = entry
            }
        }
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return entriesTree.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Entry", for: indexPath)
        
        if !entriesTree.values.sorted().isEmpty {
            cell.textLabel?.text = entriesTree.values.sorted()[indexPath.row].itemName
            if entriesTree.values.sorted()[indexPath.row].itemType == .directory {
                cell.accessoryType = .disclosureIndicator
            }
        }

        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard entriesTree.values.sorted()[indexPath.row].itemType != .file else {
            return
        }
        
        var nextEntriesTree: [UUID: Entry] = [:]
        
        for entry in entries {
            if entry.parentItemID == entriesTree.values.sorted()[indexPath.row].itemID {
                nextEntriesTree[entry.itemID] = entry
            }
        }
        
        let nextViewController: EntriesTableViewController = EntriesTableViewController()
        nextViewController.entriesTree = nextEntriesTree
        nextViewController.entries = entries
        nextViewController.navigationItem.title = entriesTree.values.sorted()[indexPath.row].itemName
        
        self.navigationController?.pushViewController(nextViewController, animated: true)
    }

    /*
    // Override to support conditional editing of the table view.
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    */

    /*
    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // Delete the row from the data source
            tableView.deleteRows(at: [indexPath], with: .fade)
        } else if editingStyle == .insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }    
    }
    */

    /*
    // Override to support rearranging the table view.
    override func tableView(_ tableView: UITableView, moveRowAt fromIndexPath: IndexPath, to: IndexPath) {

    }
    */

    /*
    // Override to support conditional rearranging of the table view.
    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the item to be re-orderable.
        return true
    }
    */

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
