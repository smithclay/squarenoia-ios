//
//  MapViewController.swift
//  squareanoia
//
//  Created by Clay Smith  on 6/23/15.
//
//

import UIKit
import CoreLocation
import MapKit
import Alamofire

class MapViewController: UIViewController, CLLocationManagerDelegate, MKMapViewDelegate {

    // MARK: Constants
    let CrimeDataDaysOffset = 100
    let ApiRequestCount = 100
    let DefaultBoundingBox: CLLocationDistance = 1000

    // TODO: Background mode kenny loggins alert (local notification)

    // Block size dimensions: http://planning.sanfranciscocode.org/2.5/270.2/
    let ManagerDistanceFilter: CLLocationDistance = 125.2

    let manager = CLLocationManager()
    var zoomedToInitialLocation = false

    @IBOutlet weak var mapView: MKMapView!

    override func viewDidLoad() {
        super.viewDidLoad()

        mapView.delegate = self

        setupLocationServices()
    }

    func setupLocationServices() {
        if (!CLLocationManager.locationServicesEnabled()) {
            let alert = UIAlertController(title: "Location Services Not Enabled", message: "Sorry, location services are not available.", preferredStyle: .Alert)
            alert.addAction(UIAlertAction(title: "Dismiss", style: .Default, handler: nil))
            presentViewController(alert, animated: true, completion: nil)
            return
        }

        manager.distanceFilter = ManagerDistanceFilter
        manager.desiredAccuracy = kCLLocationAccuracyBest
        manager.delegate = self

        if CLLocationManager.authorizationStatus() == .NotDetermined {
            manager.requestAlwaysAuthorization()
        }

        if CLLocationManager.authorizationStatus() == .AuthorizedAlways {
            manager.startUpdatingLocation()
        }
    }

    func colorForType(type: String) -> UIColor {
        var fillColor = UIColor.whiteColor()

        if type == "MURDER" {
            fillColor = UIColor.blackColor()
        }

        if type == "SIMPLE ASSAULT" || type == "ROBBERY" || type == "AGGRAVATED ASSAULT" {
            fillColor = UIColor.redColor()
        }

        if type == "NARCOTICS" || type == "ALCOHOL" {
            fillColor = UIColor.blueColor()
        }

        if type == "BURGLARY" || type == "SIMPLE_THEFT" || type == "THEFT" || type == "VEHICLE THEFT" {
            fillColor = UIColor.greenColor()
        }

        if type == "ARSON" || type == "PROSTITUION" || type == "VANDALISM" {
            fillColor = UIColor.grayColor()
        }

        return fillColor
    }

    // MARK: Map View Delegate
    func iconForType(type: String) -> UIImage {
        let baseColor = UIColor.blackColor()

        var canvasSize = CGSizeMake(10, 10)
        let scale = UIScreen.mainScreen().scale

        // Resize for retina with the scale factor
        canvasSize.width *= scale;
        canvasSize.height *= scale;

        // Create the context
        UIGraphicsBeginImageContext(canvasSize)
        let ctx = UIGraphicsGetCurrentContext()

        // setup drawing attributes
        CGContextSetLineWidth(ctx, 1.0 * scale);
        CGContextSetStrokeColorWithColor(ctx, baseColor.CGColor);
        CGContextSetFillColorWithColor(ctx, colorForType(type).CGColor);

        // setup the circle size
        var circleRect = CGRectMake(0, 0, canvasSize.width, canvasSize.height)
        circleRect = CGRectInset(circleRect, 5, 5)

        // Draw the Circle
        CGContextFillEllipseInRect(ctx, circleRect)
        CGContextStrokeEllipseInRect(ctx, circleRect)

        return UIGraphicsGetImageFromCurrentImageContext()
    }

    func mapView(mapView: MKMapView!, viewForAnnotation annotation: MKAnnotation!) -> MKAnnotationView! {
        if (annotation is MKUserLocation) {
            return nil
        }

        let reuseId = "crimeAnnotation"
        var anView = mapView.dequeueReusableAnnotationViewWithIdentifier(reuseId)
        if anView == nil {
            anView = MKAnnotationView(annotation: annotation, reuseIdentifier: reuseId)
            anView.canShowCallout = true
        } else {
            anView.annotation = annotation
        }

        if let crime = annotation as? CrimeFeature {
            anView.image = iconForType(crime.type)
        }

        return anView
    }

    func mapView(mapView: MKMapView!, regionDidChangeAnimated animated: Bool) {
        fetchCrime(boundingBoxFromRegion(mapView.region))
    }

    // MARK: Location Manager Delegate

    func locationManager(manager: CLLocationManager!, didUpdateToLocation newLocation: CLLocation!, fromLocation oldLocation: CLLocation!) {

    }

    func locationManager(manager: CLLocationManager!, didChangeAuthorizationStatus status: CLAuthorizationStatus) {
        switch status {
        case .NotDetermined:
            println(".NotDetermined")
        case .AuthorizedAlways:
            mapView.showsUserLocation = true
        case .Denied:
            let alert = UIAlertController(title: "Denied", message: "Sorry, your location could not be determined.", preferredStyle: .Alert)
            alert.addAction(UIAlertAction(title: "Dismiss", style: .Default, handler: nil))
            presentViewController(alert, animated: true, completion: nil)
        default:
            println("Unhandled authorization status")
        }
    }

    func locationManager(manager: CLLocationManager!, didFailWithError error: NSError!) {
        println(error)
    }

    func locationManager(manager: CLLocationManager!, didUpdateLocations locations: [AnyObject]!) {
        if let location = locations.last as? CLLocation {
            DataModel.sharedInstance.lastKnownLocation = location

            //if !zoomedToInitialLocation {
            setMapLocation(location)
            //    zoomedToInitialLocation = true
            //}

            // Show local notification if there are a large number of crimes nearby.
            let crimeCount = DataModel.sharedInstance.nearbyViolentCrimeCount(location)
            self.setCrimeBadge(crimeCount)

            if crimeCount > 2 {
                let localNotification = UILocalNotification()
                localNotification.fireDate = NSDate()
                localNotification.alertTitle = "Danger Zone!"
                localNotification.alertBody = "There's a high number of violent crimes nearby."
                localNotification.applicationIconBadgeNumber = crimeCount
                UIApplication.sharedApplication().scheduleLocalNotification(localNotification)
            }

            // Bug with user location updating?
            mapView.showsUserLocation = false
            mapView.showsUserLocation = true
        }
    }

    func setMapLocation(location: CLLocation) {
        mapView.region = MKCoordinateRegionMakeWithDistance(location.coordinate, DefaultBoundingBox, DefaultBoundingBox)
        fetchCrime(boundingBoxFromRegion(mapView.region))
    }

    // MARK: API

    let dateFormatter: NSDateFormatter = {
        let dateFormatter = NSDateFormatter()
        let enUSPosixLocale = NSLocale(localeIdentifier: "en_US_POSIX")
        dateFormatter.locale = enUSPosixLocale
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZZZZZ"
        return dateFormatter
    }()

    func boundingBoxFromRegion(region: MKCoordinateRegion) -> (CLLocationCoordinate2D, CLLocationCoordinate2D) {
        var southWestCorner = CLLocationCoordinate2D()
        var northEastCorner = CLLocationCoordinate2D()
        let center = region.center
        northEastCorner.latitude = center.latitude + (region.span.latitudeDelta  / 2.0)
        northEastCorner.longitude = center.longitude + (region.span.longitudeDelta / 2.0)

        southWestCorner.latitude  = center.latitude  - (region.span.latitudeDelta  / 2.0)
        southWestCorner.longitude = center.longitude - (region.span.longitudeDelta / 2.0)
        return (southWestCorner, northEastCorner)
    }

    func parseFeatures(features: [NSDictionary]) -> Set<CrimeFeature> {
        var crimes = Set<CrimeFeature>()
        for feature in features {
            if let idString = feature["id"] as? String, ident = idString.toInt(),
                description = feature["properties"]?["description"] as? String,
                time = feature["properties"]?["date_time"] as? String,
                type = feature["properties"]?["crime_type"] as? String,
                geo = feature["geometry"] as? NSDictionary,
                coords = geo["coordinates"] as? [NSNumber] {
                let lat = (coords[1]).doubleValue
                let long = (coords[0]).doubleValue
                    crimes.insert(CrimeFeature(id: ident, type: type, dateString: time, crimeDescription: description, coordinate: CLLocationCoordinate2D(latitude: lat, longitude: long)))
            }
        }
        return crimes
    }

    func setCrimeBadge(count: Int) {
        if let dangerZoneVC = tabBarController?.viewControllers?[1] as? UIViewController,
            tabItem = dangerZoneVC.tabBarItem {

            if count == 0 {
                tabItem.badgeValue = nil
                return
            }

            tabItem.badgeValue = "\(count)"
        }
    }

    func fetchCrime(boundingBox: (CLLocationCoordinate2D, CLLocationCoordinate2D)) {
        let (southWest, northEast) = boundingBox
        let pastOffset = Double(-1*CrimeDataDaysOffset*24*60*60)
        let startDate = NSDate().dateByAddingTimeInterval(pastOffset)
        let bbox = "\(southWest.longitude),\(southWest.latitude),\(northEast.longitude),\(northEast.latitude)"

        let params: [String: AnyObject] = ["format": "json", "count": ApiRequestCount, "bbox": bbox, "dtstart": dateFormatter.stringFromDate(startDate)]

        Alamofire.request(.GET, "http://sanfrancisco.crimespotting.org/crime-data", parameters: params)
        .responseJSON(options: .allZeros) { (_, _, responseObject, error) -> Void in
            if let response = responseObject as? NSDictionary, features = response["features"] as? [NSDictionary] {

                let parsedCrimes = self.parseFeatures(features)
                for crime in parsedCrimes {
                    if !DataModel.sharedInstance.crimes.contains(crime) {
                        DataModel.sharedInstance.crimes.insert(crime)
                        self.mapView.addAnnotation(crime)
                    }
                }

                let crimeCount = DataModel.sharedInstance.nearbyViolentCrimeCount(DataModel.sharedInstance.lastKnownLocation)
                self.setCrimeBadge(crimeCount)
            }
        }
    }
}
