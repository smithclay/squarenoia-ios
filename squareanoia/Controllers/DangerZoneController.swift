//
//  DangerZoneController.swift
//  squareanoia
//
//  Created by Clay Smith  on 6/23/15.
//
//

import UIKit
import CoreLocation

class DangerZoneController: UIViewController {
    @IBOutlet weak var crimeCountLabel: UILabel!

    let CloseCrimeDistance: CLLocationDistance = 125

    override func viewDidLoad() {
        super.viewDidLoad()
    }

    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        let closeCrimes = DataModel.sharedInstance.nearbyViolentCrimeCount(DataModel.sharedInstance.lastKnownLocation)
        crimeCountLabel.text = "\(closeCrimes)"
    }
}
