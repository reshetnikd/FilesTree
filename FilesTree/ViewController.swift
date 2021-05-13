//
//  ViewController.swift
//  FilesTree
//
//  Created by Dmitry Reshetnik on 13.05.2021.
//

import UIKit

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        var componetns = URLComponents(string: "https://sheets.googleapis.com/v4/spreadsheets/1e8gLI6Ft1qlawb7DWHUGPUQlkpDaV5wxkuJvNkWGGHE/values/Sheet1")!
        componetns.queryItems = [URLQueryItem(name: "key", value: "AIzaSyBPybXkT_7v-Fjzg9xDnCpEglBRM1QtiV4")]
        let request = URLRequest(url: componetns.url!)
        
        URLSession.shared.dataTask(with: request) { data, _, error in
            if let data = data {
                do {
                    let response = try JSONDecoder().decode(Response.self, from: data)
                    
                    print(response)
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


}

