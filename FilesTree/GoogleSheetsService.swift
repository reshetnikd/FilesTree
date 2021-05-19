//
//  GoogleSheetsService.swift
//  FilesTree
//
//  Created by Dmitry Reshetnik on 17.05.2021.
//

import Foundation
import GoogleSignIn
import GTMSessionFetcher
import GoogleAPIClientForREST

struct GoogleSheetsService {
    static let sharedInstance = GoogleSheetsService()
    
    private let sheetID = "1e8gLI6Ft1qlawb7DWHUGPUQlkpDaV5wxkuJvNkWGGHE"
    private let range = "Sheet1"
    private let apiKey = "AIzaSyBPybXkT_7v-Fjzg9xDnCpEglBRM1QtiV4"
    private let scopes = [kGTLRAuthScopeSheetsSpreadsheets]
    private var service = GTLRSheetsService()
    
    func getValues(completion: @escaping (Result<[[String]], Error>) -> Void) {
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
    
    func updateValues(with updateValues: [[String]]) {
        let query = GTLRSheetsQuery_SpreadsheetsValuesClear.query(withObject: GTLRSheets_ClearValuesRequest(), spreadsheetId: sheetID, range: range)
        service.authorizer = GIDSignIn.sharedInstance().currentUser.authentication.fetcherAuthorizer()
        service.executeQuery(query) { ticket, object, error in
            print(ticket.statusCode)
            let valueRange = GTLRSheets_ValueRange()
            valueRange.range = range
            valueRange.values = updateValues
            
            let query = GTLRSheetsQuery_SpreadsheetsValuesUpdate.query(withObject: valueRange, spreadsheetId: sheetID, range: range)
            query.valueInputOption = "USER_ENTERED"
            
            GIDSignIn.sharedInstance().scopes = scopes
            service.authorizer = GIDSignIn.sharedInstance().currentUser.authentication.fetcherAuthorizer()
            service.executeQuery(query) { ticket, object, error in
                print(ticket.statusCode)
            }
        }
    }
}
