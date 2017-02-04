//
//  TranslationViewDelegate.swift
//  Dashboard
//
//  Created by Timothy Barnard on 04/02/2017.
//  Copyright © 2017 Timothy Barnard. All rights reserved.
//

import Cocoa

typealias SelectionTranslations = (_ row: Int, _ key: String ) -> Void

class TranslationViewDelegate: NSObject {
    
    var translations = [String:String]()
    
    var tableView: NSTableView
    var objectSelectionBlock: SelectionTranslations?
    
    init(tableView: NSTableView, selectionBlock: @escaping SelectionTranslations) {
        self.tableView = tableView
        self.objectSelectionBlock = selectionBlock
        super.init()
        self.tableView.delegate = self
    }
    
    func reload( translations: [String:String] ) {
        self.translations = translations
        self.tableView.reloadData()
    }
}

extension TranslationViewDelegate: NSTableViewDelegate {
    
    func tableViewSelectionDidChange(_ notification: Notification) {
        
        guard let tableView = notification.object as? NSTableView else {
            return
        }
        let selectedRow = tableView.selectedRow
        
        if selectedRow < 0 {
            return
        }
        let (_, value) = self.translations.getValueAtIndex(index: selectedRow)
        
        objectSelectionBlock?(selectedRow, value)
    }
    
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        
        let (key, value) = self.translations.getValueAtIndex(index: row)
        
        if let cell = tableView.make(withIdentifier: "KeyCell", owner: nil) as? NSTableCellView {
            cell.textField?.stringValue = key
            return cell
            
        } else if let cell = tableView.make(withIdentifier: "ValueCell", owner: nil) as? NSTableCellView {
            cell.textField?.stringValue = value
            return cell
        }
        
        return nil
    }
}