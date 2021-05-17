//
//  GoogleSheetsService.swift
//  FilesTree
//
//  Created by Dmitry Reshetnik on 17.05.2021.
//

import Foundation
import GoogleSignIn
import GoogleAPIClientForREST

struct GoogleSheetsService {
    private let scopes = [kGTLRAuthScopeSheetsSpreadsheets]
    private var service = GTLRSheetsService()
    
    func getValues(completion: @escaping (Result<[[String]], Error>) -> Void) {
        let apiKey = "AIzaSyBPybXkT_7v-Fjzg9xDnCpEglBRM1QtiV4"
        let sheetID = "1e8gLI6Ft1qlawb7DWHUGPUQlkpDaV5wxkuJvNkWGGHE"
        let range = "Sheet1"
        let query = GTLRSheetsQuery_SpreadsheetsValuesGet.query(withSpreadsheetId: sheetID, range:range)
        
        service.apiKey = apiKey
        service.executeQuery(query) { ticket, object, error in
            if let object = object as? GTLRSheets_ValueRange {
                if let values = object.values as? [[String]] {
                    completion(.success(values))
                } else {
                    completion(.failure(error!))
                }
            }
        }
    }
}
