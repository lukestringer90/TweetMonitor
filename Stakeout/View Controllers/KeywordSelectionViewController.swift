//
//  SearchStringsViewController.swift
//  Stakeout
//
//  Created by Luke Stringer on 31/03/2018.
//  Copyright © 2018 Luke Stringer. All rights reserved.
//

import UIKit

extension KeywordStore {
    var sortedKeywords: [Keyword] {
        get {
            return all().sorted()
        }
    }
    
    func keyword(at index: Int) -> Keyword? {
        return sortedKeywords[index]
    }
}

class KeywordSelectionViewController: UITableViewController {
    var store = KeywordStore.shared
}

// MARK: Actions
extension KeywordSelectionViewController {
    @IBAction func addTapped(_ sender: Any) {
        
        let alert = UIAlertController(title: "New Keyword", message: nil, preferredStyle: .alert)
        alert.addTextField()
        let done = UIAlertAction(title: "Done", style: .default) { action in
            guard
                let text = alert.textFields?.first?.text
                else { return }
            let endIndex = self.store.all().count
            let keyword = Keyword(text: text, index: endIndex)
            self.add(keyword: keyword)
        }
        let cancel = UIAlertAction(title: "Cancel", style: .cancel)
        alert.addAction(cancel)
        alert.addAction(done)
        present(alert, animated: true, completion: nil)
    }
}

// MARK: UITableViewController
extension KeywordSelectionViewController {
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return store.sortedKeywords.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard
            let cell = tableView.dequeueReusableCell(withIdentifier: "KeywordCell"),
            let text = store.keyword(at: indexPath.row)?.text
            else {
                fatalError("Cannot setup keyword cell")
        }
        cell.textLabel?.text = text
        return cell
    }
    
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        guard editingStyle == .delete, let keyword = store.keyword(at: indexPath.row) else { return }
        
        remove(keyword: keyword)
    }
    
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
}

// MARK: Keyword Storage
extension KeywordSelectionViewController {
    
    func add(keyword: Keyword) {
        store.add(keyword)
        self.tableView.reloadSections([0], with: .automatic)
    }
    
    func remove(keyword: Keyword) {
        store.remove(keyword)
        self.tableView.reloadSections([0], with: .automatic)
    }
    
}
