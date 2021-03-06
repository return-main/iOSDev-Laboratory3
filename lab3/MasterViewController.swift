//
//  MasterViewController.swift
//  lab3
//
//  Created by Marc PEREZ on 7/4/2020.
//  Copyright © 2020 Marc PEREZ. All rights reserved.
//

import UIKit
import CoreData

class MasterViewController: UITableViewController, NSFetchedResultsControllerDelegate {

    var detailViewController: DetailViewController? = nil
    var managedObjectContext: NSManagedObjectContext? = nil


    override func viewDidLoad() {
        super.viewDidLoad()

        navigationItem.leftBarButtonItem = editButtonItem
        let sortButton = UIBarButtonItem(barButtonSystemItem: .bookmarks, target: self, action: #selector(sortTable(_:)))
        let addButton = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(insertNewObject(_:)))
        navigationItem.rightBarButtonItems = [addButton, sortButton]

        if let split = splitViewController {
            let controllers = split.viewControllers
            detailViewController = (controllers[controllers.count-1] as! UINavigationController).topViewController as? DetailViewController
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        clearsSelectionOnViewWillAppear = splitViewController!.isCollapsed
        super.viewWillAppear(animated)
    }

    @objc
    func insertNewObject(_ sender: UIBarButtonItem) {
        // Go to the editing page
        performSegue(withIdentifier: "showDetail", sender: sender)
    }
    
    var ascending = false
    @objc
    func sortTable(_ sender: UIBarButtonItem) {
        NSFetchedResultsController<FilmMO>.deleteCache(withName: _fetchedResultsController?.cacheName)
        let sortDescriptor = NSSortDescriptor(key: "rating", ascending: ascending)
        sortFetchRequest.sortDescriptors = [sortDescriptor]
        do {
            try _fetchedResultsController!.performFetch()
            tableView.reloadData()
            ascending = !ascending
        } catch {
             // Replace this implementation with code to handle the error appropriately.
             // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
             let nserror = error as NSError
             fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
        }
    }

    // MARK: - Segues

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
          if segue.identifier == "showDetail" {
            let controller = (segue.destination as! UINavigationController).topViewController as! DetailViewController
            controller.managedObjectContext = self.fetchedResultsController.managedObjectContext
            controller.navigationItem.leftBarButtonItem = splitViewController?.displayModeButtonItem
            controller.navigationItem.leftItemsSupplementBackButton = true
            
            // Get the film from the current selected table row if there is one currently selected
            if let indexPath = tableView.indexPathForSelectedRow {
                controller.film = fetchedResultsController.object(at: indexPath)
            }

            detailViewController = controller
        }
    }

    // MARK: - Table View

    override func numberOfSections(in tableView: UITableView) -> Int {
        return fetchedResultsController.sections?.count ?? 0
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let sectionInfo = fetchedResultsController.sections![section]
        return sectionInfo.numberOfObjects
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        let film = fetchedResultsController.object(at: indexPath)
        configureCell(cell, withFilm: film)
        return cell
    }

    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }

    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    override func tableView(_ tableView: UITableView, moveRowAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
        var objects = fetchedResultsController.fetchedObjects!
        let object = objects[sourceIndexPath.row]
        objects.remove(at: sourceIndexPath.row)
        objects.insert(object, at: destinationIndexPath.row)
        
        // Save
        do {
            try fetchedResultsController.managedObjectContext.save()
        } catch {
            // Replace this implementation with code to handle the error appropriately.
            // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
            let nserror = error as NSError
            fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
        }
    }

    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            let film = fetchedResultsController.object(at: indexPath)

            let title = String.localizedStringWithFormat(NSLocalizedString("Delete %@ (directed by %@)?", comment: "Title text in the alert window"), film.title!, film.director!)
            let message = NSLocalizedString("Are you sure you want to delete this film?", comment: "Message text in the alert window")
            //Create the AlertController and add Its action like button in Actionsheet
            let actionSheetControllerIOS8: UIAlertController = UIAlertController(title: title, message: message, preferredStyle: .actionSheet)

            let cancelText = NSLocalizedString("Cancel", comment: "Cancel text in the alert window")
            let cancelActionButton = UIAlertAction(title: cancelText, style: .cancel) { _ in
                print("Cancel")
            }
            actionSheetControllerIOS8.addAction(cancelActionButton)
            let deleteText = NSLocalizedString("Delete", comment: "Delete text in the alert window")
            let deleteActionButton = UIAlertAction(title: deleteText, style: .destructive, handler: { (action) in
                let context = self.fetchedResultsController.managedObjectContext
                context.delete(film)

                do {
                    try context.save()
                } catch {
                    // Replace this implementation with code to handle the error appropriately.
                    // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                    let nserror = error as NSError
                    fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
                }
            })
            actionSheetControllerIOS8.addAction(deleteActionButton)
            self.present(actionSheetControllerIOS8, animated: true, completion: nil)
        }
    }

    func configureCell(_ cell: UITableViewCell, withFilm film: FilmMO) {
        cell.textLabel!.text = film.title
        let localizedString = NSLocalizedString("%@ (rating: %d)", comment: "Subtitle in film tableview cells")
        cell.detailTextLabel!.text = String.localizedStringWithFormat(localizedString, film.director!, film.rating)
    }

    // MARK: - Fetched results controller
    

    lazy var sortFetchRequest: NSFetchRequest<FilmMO> = {
        let fetchRequest: NSFetchRequest<FilmMO> = FilmMO.fetchRequest()
        
        // Set the batch size to a suitable number.
        fetchRequest.fetchBatchSize = 20
        
        // Edit the sort key as appropriate.
        let sortDescriptor = NSSortDescriptor(key: "rating", ascending: ascending)
        
        fetchRequest.sortDescriptors = [sortDescriptor]
        
        return fetchRequest
    }()
    var fetchedResultsController: NSFetchedResultsController<FilmMO> {
        if _fetchedResultsController != nil {
            return _fetchedResultsController!
        }
            // Edit the section name key path and cache name if appropriate.
            // nil for section name key path means "no sections".
            let aFetchedResultsController = NSFetchedResultsController(fetchRequest: sortFetchRequest, managedObjectContext: self.managedObjectContext!, sectionNameKeyPath: nil, cacheName: "Master")
            aFetchedResultsController.delegate = self
            _fetchedResultsController = aFetchedResultsController
            
            do {
                try _fetchedResultsController!.performFetch()
            } catch {
                 // Replace this implementation with code to handle the error appropriately.
                 // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                 let nserror = error as NSError
                 fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
            }
            
            return _fetchedResultsController!
    }
    var _fetchedResultsController: NSFetchedResultsController<FilmMO>? = nil

    func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        tableView.beginUpdates()
    }

    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange sectionInfo: NSFetchedResultsSectionInfo, atSectionIndex sectionIndex: Int, for type: NSFetchedResultsChangeType) {
        switch type {
            case .insert:
                tableView.insertSections(IndexSet(integer: sectionIndex), with: .fade)
            case .delete:
                tableView.deleteSections(IndexSet(integer: sectionIndex), with: .fade)
            default:
                return
        }
    }

    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        switch type {
            case .insert:
                tableView.insertRows(at: [newIndexPath!], with: .fade)
            case .delete:
                tableView.deleteRows(at: [indexPath!], with: .fade)
            case .update:
                configureCell(tableView.cellForRow(at: indexPath!)!, withFilm: anObject as! FilmMO)
            case .move:
                configureCell(tableView.cellForRow(at: indexPath!)!, withFilm: anObject as! FilmMO)
                tableView.moveRow(at: indexPath!, to: newIndexPath!)
            default:
                return
        }
    }

    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        tableView.endUpdates()
    }

    /*
     // Implementing the above methods to update the table view in response to individual changes may have performance implications if a large number of changes are made simultaneously. If this proves to be an issue, you can instead just implement controllerDidChangeContent: which notifies the delegate that all section and object changes have been processed.
     
     func controllerDidChangeContent(controller: NSFetchedResultsController) {
         // In the simplest, most efficient, case, reload the table view.
         tableView.reloadData()
     }
     */

}

