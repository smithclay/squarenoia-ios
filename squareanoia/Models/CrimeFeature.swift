//
//  CrimeFeature.swift
//  squareanoia
//
//  Created by Clay Smith  on 6/23/15.
//
//

import Foundation
import CoreLocation
import MapKit

func == (lhs: CrimeFeature, rhs: CrimeFeature) -> Bool {
    return lhs.identifier == rhs.identifier
}

@objc class CrimeFeature: NSObject, Printable, MKAnnotation, Hashable {
    let identifier: Int
    let type: String
    let crimeDescription: String
    let dateString: String

    @objc var coordinate: CLLocationCoordinate2D

    @objc override var description: String {
        return "\(coordinate.latitude), \(coordinate.longitude): \(type): \(crimeDescription)"
    }

    var title: String! {
        return type
    }

    var subtitle: String! {
        return "\(crimeDescription) - \(dateString)"
    }

    init(id: Int, type: String, dateString: String, crimeDescription: String, coordinate: CLLocationCoordinate2D) {
        self.identifier = id
        self.type = type
        self.crimeDescription = crimeDescription
        self.coordinate = coordinate
        self.dateString = dateString
    }

    override var hashValue: Int {
        return identifier
    }
}
