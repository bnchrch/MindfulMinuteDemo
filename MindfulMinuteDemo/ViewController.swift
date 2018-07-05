//
//  ViewController.swift
//  MindfulMinuteDemo
//
//  Created by Ben Church on 2018-07-05.
//  Copyright © 2018 Ben Church. All rights reserved.
//

import UIKit
import HealthKit

class ViewController: UIViewController {

    @IBOutlet weak var meditationMinutesLabel: UILabel!

    // Instantiate the HealthKit Store and Mindful Type
    let healthStore = HKHealthStore()
    let mindfulType = HKObjectType.categoryType(forIdentifier: .mindfulSession)

    @IBAction func addMinuteAct(_ sender: Any) {
        // Create a start and end time 1 minute apart
        let startTime = Date()
        let endTime = startTime.addingTimeInterval(1.0 * 60.0)

        self.saveMindfullAnalysis(startTime: startTime, endTime: endTime)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.activateHealthKit()
    }

    func activateHealthKit() {
        // Define what HealthKit data we want to ask to read
        let typestoRead = Set([
            HKObjectType.categoryType(forIdentifier: HKCategoryTypeIdentifier.mindfulSession)!
            ])

        // Define what HealthKit data we want to ask to write
        let typestoShare = Set([
            HKObjectType.categoryType(forIdentifier: HKCategoryTypeIdentifier.mindfulSession)!
            ])

        // Prompt the User for HealthKit Authorization
        self.healthStore.requestAuthorization(toShare: typestoShare, read: typestoRead) { (success, error) -> Void in
            if !success{
                print("HealthKit Auth error\(error)")
            }
            self.retrieveMindFulMinutes()
        }
    }

    func calculateTotalTime(sample: HKSample) -> TimeInterval {
        let totalTime = sample.endDate.timeIntervalSince(sample.startDate)
        let wasUserEntered = sample.metadata?[HKMetadataKeyWasUserEntered] as? Bool ?? false

        print("\nHealthkit mindful entry: \(sample.startDate) \(sample.endDate) - value: \(totalTime) quantity: \(totalTime) user entered: \(wasUserEntered)\n")

        return totalTime
    }

    func updateMeditationTime(query: HKSampleQuery, results: [HKSample]?, error: Error?) {
        if error != nil {return}

        // Sum the meditation time
        let totalMeditationTime = results?.map(calculateTotalTime).reduce(0, { $0 + $1 }) ?? 0

        print("\n Total: \(totalMeditationTime)")

        renderMeditationMinuteText(totalMeditationSeconds: totalMeditationTime)

    }

    func renderMeditationMinuteText(totalMeditationSeconds: Double) {
        let minutes = Int(totalMeditationSeconds / 60)
        let labelText = "\(minutes) Mindful Minutes in the last 24 hours"
        DispatchQueue.main.async {
            self.meditationMinutesLabel.text = labelText
        }
    }

    func retrieveMindFulMinutes() {

        // Use a sortDescriptor to get the recent data first (optional)
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)

        // Get all samples from the last 24 hours
        let endDate = Date()
        let startDate = endDate.addingTimeInterval(-1.0 * 60.0 * 60.0 * 24.0)
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: [])

        // Create the HealthKit Query
        let query = HKSampleQuery(
            sampleType: mindfulType!,
            predicate: predicate,
            limit: 0,
            sortDescriptors: [sortDescriptor],
            resultsHandler: updateMeditationTime
        )
        // Execute our query
        healthStore.execute(query)
    }

    func saveMindfullAnalysis(startTime: Date, endTime: Date) {
        // Create a mindful session with the given start and end time
        let mindfullSample = HKCategorySample(type:mindfulType!, value: 0, start: startTime, end: endTime)

        // Save it to the health store
        healthStore.save(mindfullSample, withCompletion: { (success, error) -> Void in
            if error != nil {return}

            print("New data was saved in HealthKit: \(success)")
            self.retrieveMindFulMinutes()
        })
    }

}

