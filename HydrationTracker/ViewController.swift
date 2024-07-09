//
//  ViewController.swift
//  HydrationTracker
//
//  Created by Md Tabish on 08/07/24.
//

import UIKit
import CoreData
import UserNotifications

class MainViewController: UIViewController {
    @IBOutlet weak var tableView: UITableView!
    
    var waterLogs: [WaterLog] = []
    let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.dataSource = self
        tableView.delegate = self
        loadLogs()
        requestNotificationPermission()
        scheduleNotifications()
        registerTableViewCell()
    }
    
    private func registerTableViewCell(){
        tableView.register(UINib(nibName: "WaterLogTableViewCell", bundle: nil), forCellReuseIdentifier: "WaterLogTableViewCell")
        tableView.register(UINib(nibName: "EmptyWaterRecordTableViewCell", bundle: nil), forCellReuseIdentifier: "EmptyWaterRecordTableViewCell")
    }
    
    @IBAction func addLog() {
        let alert = UIAlertController(title: "Add Water Intake", message: "Enter the amount of water (ml)", preferredStyle: .alert)
        alert.addTextField { (textField) in
            textField.keyboardType = .numberPad
        }
        let addAction = UIAlertAction(title: "Add", style: .default) { [weak self] _ in
            guard let amountText = alert.textFields?.first?.text, let amount = Double(amountText) else { return }
            self?.saveLog(amount: amount)
        }
        alert.addAction(addAction)
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(alert, animated: true)
    }
    
    func saveLog(amount: Double) {
        if let existingLog = waterLogs.first(where: { Calendar.current.isDate($0.date!, inSameDayAs: Date()) }) {
            existingLog.amount += amount
            do {
                try context.save()
                tableView.reloadData()
            } catch {
                print("Failed to update log: \(error)")
            }
        } else {
            let newLog = WaterLog(context: context)
            newLog.date = Date()
            newLog.amount = amount
            do {
                try context.save()
                waterLogs.append(newLog)
                tableView.reloadData()
            } catch {
                print("Failed to save log: \(error)")
            }
        }
    }
}

extension MainViewController {
    func loadLogs() {
        let request: NSFetchRequest<WaterLog> = WaterLog.fetchRequest()
        do {
            waterLogs = try context.fetch(request)
            tableView.reloadData()
        } catch {
            print("Failed to load logs: \(error)")
        }
    }
    
    func deleteLog(at indexPath: IndexPath) {
        context.delete(waterLogs[indexPath.row])
        waterLogs.remove(at: indexPath.row)
        do {
            try context.save()
            tableView.reloadData()
        } catch {
            print("Failed to delete log: \(error)")
        }
    }
    
    func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if let error = error {
                print("Error requesting notifications permission: \(error)")
            }
        }
    }
    
    func scheduleNotifications() {
        let content = UNMutableNotificationContent()
        content.title = "Time to Hydrate!"
        content.body = "Don't forget to drink water and stay hydrated."
        content.sound = UNNotificationSound.default
        
        // Create a trigger to fire every minutes
//         let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 60, repeats: true)
        
        var dateComponents = DateComponents()
        dateComponents.hour = 9
        dateComponents.minute = 0
        
//         Create a calendar trigger that repeats daily at 9 AM
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        
        let request = UNNotificationRequest(identifier: "hydrationReminder", content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Failed to add notification request: \(error)")
            } else {
                print("Hydration reminder scheduled successfully")
            }
        }
    }
}

extension MainViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return waterLogs.isEmpty ? 1 : waterLogs.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if waterLogs.isEmpty {
            let cell = tableView.dequeueReusableCell(withIdentifier: "EmptyWaterRecordTableViewCell", for: indexPath) as! EmptyWaterRecordTableViewCell
            tableView.separatorColor = .white
            return cell
        } else {
            let cell = tableView.dequeueReusableCell(withIdentifier: "WaterLogTableViewCell", for: indexPath) as! WaterLogTableViewCell
            let log = waterLogs[indexPath.row]
            cell.dateLabel.text = DateFormatter.localizedString(from: log.date!, dateStyle: .short, timeStyle: .short)
            cell.amountLabel.text = "\(log.amount) ml"
            tableView.separatorColor = .gray
            return cell
        }
    }
}

extension MainViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            deleteLog(at: indexPath)
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        if waterLogs.isEmpty {
            return
        }
        
        let selectedLog = waterLogs[indexPath.row]
        
        let alert = UIAlertController(title: "Update Water Intake", message: "Enter the new amount of water (ml)", preferredStyle: .alert)
        alert.addTextField { (textField) in
            textField.text = "\(selectedLog.amount)"
            textField.keyboardType = .numberPad
        }
        let updateAction = UIAlertAction(title: "Update", style: .default) { [weak self] _ in
            guard let amountText = alert.textFields?.first?.text, let amount = Double(amountText) else { return }
            
            selectedLog.amount = amount
            do {
                try self?.context.save()
                tableView.reloadData()
            } catch {
                print("Failed to update log: \(error)")
            }
        }
        alert.addAction(updateAction)
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(alert, animated: true)
    }
}


