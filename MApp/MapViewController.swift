//
//  ViewController.swift
//  MApp
//
//  Created by Baran on 20.04.2023.
//

import UIKit
import MapKit
import CoreLocation
import CoreData

class MapViewController: UIViewController, MKMapViewDelegate, CLLocationManagerDelegate  {
    
    @IBOutlet weak var saveButton: UIButton!
    @IBOutlet weak var nameText: UITextField!
    @IBOutlet weak var descriptionText: UITextField!
    @IBOutlet weak var mapView: MKMapView!
    
    var locationManager = CLLocationManager();
    var selectedLatitude = Double();
    var selectedLongitutde = Double();
    var selectedName = "";
    var selectedId : UUID?;
    
    var annotationTitle = "";
    var annotationSubtitle = "";
    var annotationLatitude = Double();
    var annotationLongitutde = Double();
    
    var userLatitude = Double();
    var userLongitude = Double();
    
    override func viewDidLoad() {
        super.viewDidLoad();
        // MARK: Keyboard saklanması.
        let tap = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        view.addGestureRecognizer(tap)
        
        mapView.delegate = self;
        setLocationManagerSettings(locationManager: self.locationManager);
        
        let gestureRecognizerForMap = UILongPressGestureRecognizer(target: self, action: #selector(selectLocation(gestureRecognizer:)));
        gestureRecognizerForMap.minimumPressDuration = 1;
        mapView.addGestureRecognizer(gestureRecognizerForMap);
        
        if selectedName != ""{
            // core datadan veriler gelsin
            saveButton.isHidden = true;
            if let idString = selectedId?.uuidString{
                let appDelegate = UIApplication.shared.delegate as! AppDelegate;
                let context = appDelegate.persistentContainer.viewContext;
                
                let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "LocationEntity");
                fetchRequest.predicate = NSPredicate(format: "id = %@", idString);
                fetchRequest.returnsObjectsAsFaults = false;
                
                do {
                    let result = try context.fetch(fetchRequest);
                    if result.count > 0 {
                        for data in result as! [NSManagedObject]{
                            if let name = data.value(forKey: "locationName") as? String{
                                annotationTitle = name;
                                
                                if let description = data.value(forKey: "locationDescription") as? String {
                                    annotationSubtitle = description;
                                    
                                    if let latitude = data.value(forKey: "locationLatitude") as? Double{
                                        annotationLatitude = latitude;
                                        
                                        if let longitude = data.value(forKey: "locationLongitude") as? Double {
                                            annotationLongitutde = longitude;
                                            
                                            let annotation = MKPointAnnotation();
                                            annotation.title = annotationTitle;
                                            annotation.subtitle = annotationSubtitle;
                                            let coordinate = CLLocationCoordinate2D(latitude: annotationLatitude, longitude: annotationLongitutde);
                                            annotation.coordinate = coordinate;
                                            
                                            mapView.addAnnotation(annotation);
                                            nameText.text = annotationTitle;
                                            descriptionText.text = annotationSubtitle;
                                            
                                            locationManager.stopUpdatingLocation();
                                            
                                            let span = MKCoordinateSpan(latitudeDelta: 0.005, longitudeDelta: 0.005);
                                            let region = MKCoordinateRegion(center: coordinate, span: span);
                                            mapView.setRegion(region, animated: true);
                                        }
                                    }
                                }
                            }
                        }
                    }
                }catch {
                    print("predicate edilmiş data gelirken hata");
                }
            }
            
        }
        else {
            // yeni veri eklenecek.
        }
    }
    
    
    
    @objc func selectLocation(gestureRecognizer: UILongPressGestureRecognizer){
        if  gestureRecognizer.state == .began {
            let holdingPoint = gestureRecognizer.location(in: mapView);
            let holdingCoordinate = mapView.convert(holdingPoint, toCoordinateFrom: mapView);
            selectedLatitude = holdingCoordinate.latitude;
            selectedLongitutde = holdingCoordinate.longitude;
            let annotation = MKPointAnnotation();
            annotation.coordinate = holdingCoordinate;
            
            // MARK: Konum adı ve açıklamasını annotation'a ekleyen fonksiyon.
            setNameAndDescription(nameText: nameText, descriptionText: descriptionText, annotation: annotation);
            
            mapView.addAnnotation(annotation);
        }
    }
    
    
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if selectedName == "" {
            let location = CLLocationCoordinate2D(latitude: locations[0].coordinate.latitude, longitude: locations[0].coordinate.longitude);
            
            let span = MKCoordinateSpan(latitudeDelta: 0.005, longitudeDelta: 0.005);
            let region = MKCoordinateRegion(center: location, span: span)
            
            mapView.setRegion(region, animated: true);
        }
        
        userLatitude = locations[0].coordinate.latitude;
        userLongitude = locations[0].coordinate.longitude;
    }
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        if annotation is MKUserLocation{
            return nil;
        }
        let reuseId = "myAnnotation";
        var pinView = mapView.dequeueReusableAnnotationView(withIdentifier: reuseId);
        
        if pinView == nil {
            pinView = MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: reuseId);
            pinView?.canShowCallout = true;
            pinView?.tintColor = .purple;
            let button = UIButton(type: .detailDisclosure);
            pinView?.rightCalloutAccessoryView = button;
            
        } else {
            pinView?.annotation = annotation;
        }
        
        return pinView;
    }
    
    func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
        if selectedName != "" {
            let requestLocation = CLLocation(latitude: self.annotationLatitude, longitude: self.annotationLongitutde);
            
            CLGeocoder().reverseGeocodeLocation(requestLocation) { (placeMarkArray, error) in
                if let placeMarks = placeMarkArray {
                    if placeMarks.count > 0 {
                        let newPlaceMark = MKPlacemark(placemark: placeMarks[0]);
                        let item = MKMapItem(placemark: newPlaceMark);
                        
                        item.name = self.annotationTitle;
                        
//                        let launchOptions = [MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving];
//                        item.openInMaps(launchOptions: launchOptions);
                        
                        let url = URL(string: "yandexnavi://build_route_on_map?lat_from=\(self.userLatitude)&lon_from=\(self.userLongitude)&lat_to=\(self.annotationLatitude)&lon_to=\(self.annotationLongitutde)")!;
                        UIApplication.shared.open(url, options: [:], completionHandler: nil);
                    }
                }
            }
        }
    }


    @IBAction func saveButtonClicked(_ sender: Any) {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate;
        let context = appDelegate.persistentContainer.viewContext;
        
        let newLocation = NSEntityDescription.insertNewObject(forEntityName: "LocationEntity", into: context);
        newLocation.setValue(nameText.text, forKey: "locationName");
        newLocation.setValue(descriptionText.text, forKey: "locationDescription");
        newLocation.setValue(selectedLatitude, forKey: "locationLatitude");
        newLocation.setValue(selectedLongitutde, forKey: "locationLongitude");
        newLocation.setValue(UUID(), forKey: "id");
        
        do {
            try context.save();
            print("kaydedildi.");
        }
        catch{
            print("Kaydederken hata oluştu");
        }
        
        NotificationCenter.default.post(name: NSNotification.Name("createdNewLocation"), object: nil);
        navigationController?.popViewController(animated: true);
    }
    
    
    // MARK: Konum adı ve açıklamasını annotation'a ekleyen fonksiyon.
    func setNameAndDescription(nameText: UITextField, descriptionText: UITextField, annotation: MKPointAnnotation){
        if let name = nameText.text {
            annotation.title = name;
        }
        
        if let description = descriptionText.text {
            annotation.subtitle = description;
        }
    }
    
    func setLocationManagerSettings(locationManager: CLLocationManager){
        locationManager.delegate = self;
        locationManager.desiredAccuracy = kCLLocationAccuracyBest;
        locationManager.requestWhenInUseAuthorization();
        locationManager.startUpdatingLocation();
        locationManager.stopUpdatingLocation();
    }
    
    // MARK: Herhangi bir yere clicklendiğinde klavyeyi kapatma metodu.
    @objc func dismissKeyboard() {
        view.endEditing(true)
    }
}

