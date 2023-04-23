//
//  ListViewController.swift
//  MApp
//
//  Created by Baran on 20.04.2023.
//

import UIKit
import CoreData

class ListViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    @IBOutlet weak var locationListTableView: UITableView!
    
    var nameArray = [String]();
    var idArray = [UUID]();
    var selectedName = "";
    var selectedId = UUID();
    
    override func viewDidLoad() {
        super.viewDidLoad();
        
        locationListTableView.delegate = self;
        locationListTableView.dataSource = self;
        navigationController?.navigationBar.topItem?.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(addButtonClicked));
        
        getData();

    }
    
    override func viewWillAppear(_ animated: Bool) {
        NotificationCenter.default.addObserver(self, selector: #selector(getData), name: NSNotification.Name("createdNewLocation"), object: nil);
    }
    
    @objc func getData(){
        let appDelegate = UIApplication.shared.delegate as! AppDelegate;
        let context = appDelegate.persistentContainer.viewContext;
        
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: "LocationEntity");
        request.returnsObjectsAsFaults = false;
        
        do{
            let result = try context.fetch(request);
            
            if result.count > 0 {
                
                nameArray.removeAll(keepingCapacity: false);
                idArray.removeAll(keepingCapacity: false);
                for data in result as! [NSManagedObject]{
                    if let name = data.value(forKey: "locationName") as? String {
                        nameArray.append(name);
                    }
                    
                    if let id = data.value(forKey: "id") as? UUID {
                        idArray.append(id);
                    }
                }
                locationListTableView.reloadData();
            }
        } catch {
            print("data çekme hatası");
        }
    }
    
    @objc func addButtonClicked(){
        selectedName = "";
        performSegue(withIdentifier: "toMapVC", sender: nil)
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return nameArray.count;
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell();
        cell.textLabel?.text = nameArray[indexPath.row];
        return cell;
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete{
            let appDelegate = UIApplication.shared.delegate as! AppDelegate;
            let context = appDelegate.persistentContainer.viewContext;
            
            let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "LocationEntity");
            let id = idArray[indexPath.row].uuidString;
            fetchRequest.predicate = NSPredicate(format: "id = %@", id);
            fetchRequest.returnsObjectsAsFaults = false;
            
            do{
                let datas = try context.fetch(fetchRequest);
                
                if datas.count > 0 {
                    for data in datas as! [NSManagedObject] {
                        if let id = data.value(forKey: "id") as? UUID{
                            if id == idArray[indexPath.row]{
                                context.delete(data);
                                nameArray.remove(at: indexPath.row);
                                idArray.remove(at: indexPath.row);
                                self.locationListTableView.reloadData();
                                do{
                                    try context.save();
                                } catch {
                                    print("Silme işlemi tamamlanırken HATA!!!");
                                }
                                break;
                            }
                        }
                    }
                }
            }
            catch {
                print("Silinirken Hata OLUŞTU ALOOO!!!");
            }
//
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        selectedName = nameArray[indexPath.row];
        selectedId  = idArray[indexPath.row];
        performSegue(withIdentifier: "toMapVC", sender: nil);
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "toMapVC"{
            let destinationVC = segue.destination as! MapViewController;
            destinationVC.selectedName = self.selectedName;
            destinationVC.selectedId = self.selectedId;
            
        }
    }

}
