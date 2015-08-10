//
//  DataModel.swift
//  squareanoia
//
//  Created by Clay Smith  on 6/24/15.
//
//

import Foundation
import CoreLocation

class DataModel {
    static let sharedInstance = DataModel()

    var crimes = Set<CrimeFeature>()
    var lastKnownLocation: CLLocation?

    func nearbyViolentCrimeCount(location: CLLocation?, threshold: CLLocationDirection = 145) -> Int {
        return nearbyCrimes(location, threshold: threshold,
            typeFilter: ["SIMPLE ASSAULT", "ROBBERY", "AGGRAVATED ASSAULT", "MURDER"]).count
    }

    func nearbyCrimes(location: CLLocation?, threshold: CLLocationDirection, typeFilter: [String]? = nil) -> [CrimeFeature] {
        var features = [CrimeFeature]()

        if location == nil {
            return features
        }

        for crime in crimes {
            let crimeLocation = CLLocation(coordinate: crime.coordinate, altitude: location!.altitude, horizontalAccuracy: location!.horizontalAccuracy, verticalAccuracy: location!.verticalAccuracy, course: location!.course, speed: location!.speed, timestamp: location!.timestamp)

            let distance = location!.distanceFromLocation(crimeLocation)

            if distance < threshold {
                if typeFilter == nil {
                    features.append(crime)
                }

                if let typeFilter = typeFilter where find(typeFilter, crime.type) != nil {
                    features.append(crime)
                }
            }
        }
        return features
    }
}
