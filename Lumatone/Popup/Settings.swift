//
//  Settings.swift
//  Lumatone
//
//  Created by SH BU on 2024/8/26.
//

import UIKit

class SettingsNavigationController: UINavigationController {
    var settings = SettingsViewController()
    
    override func viewDidLoad() {
        navigationBar.prefersLargeTitles = true
        viewControllers.append(settings)
    }
}

// a view controller containing settings toggle buttons
class SettingsViewController: UIViewController, UITableViewDataSource {
    
    private var settings = UITableView(frame: .zero, style: .insetGrouped)
    
    override func viewDidLoad() {
        // set up the menu title and cancel button
        navigationItem.title = "Settings"
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Done", style: .done, target: self, action: #selector(done))
        
        settings.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        settings.dataSource = self
        settings.frame = view.frame
        settings.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        settings.allowsSelection = false
//        settings.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        view.addSubview(settings)
    }
    @objc func done() {
        dismiss(animated: true, completion: nil)
    }
    
    // impl data source
    func numberOfSections(in tableView: UITableView) -> Int {
        return settingsData.count
    }
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return settingsData[section].content.count
    }
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return settingsData[section].title
    }
    // creation of cells
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        let cellData = settingsData[indexPath.section].content[indexPath.row]
        cell.textLabel!.text = cellData.title
        cell.accessoryView = cellData.control
        return cell
    }
    
    
    // data
    
    typealias SectionData = (title: String, content: [CellData])
    typealias CellData = (title: String, control: UIControl)
    
    lazy var settingsData: [SectionData] = [
        SectionData("Keyboard", [
            
            CellData("Use lock button", {
                let control = UISwitch(frame: .zero, primaryAction: UIAction { action in
                    let on = (action.sender as! UISwitch).isOn
                    UserDefaults.standard.set(!on, forKey: "lockButtonDisabled_Bool")
                    Keyboard.lockButtonChangedNotif.post(value: !on)
                })
                control.isOn = !UserDefaults.standard.bool(forKey: "lockButtonDisabled_Bool") // default enabled
                return control
            }()),
            
            CellData("Layout", {
                let control = UISegmentedControl(frame: CGRectMake(0, 0, 200, 35), actions: [
                    UIAction(title: "Lumatone") { _ in
                        // todo
                        UserDefaults.standard.set(0, forKey: "layoutIndex_Int")
                    },
                    UIAction(title: "InfHex") { _ in
                        // todo
                        UserDefaults.standard.set(1, forKey: "layoutIndex_Int")
                    }
                ])
                control.selectedSegmentIndex = UserDefaults.standard.integer(forKey: "layoutIndex_Int") // default 0
                return control
            }()),
            
            CellData("Key label", {
                let control = UISegmentedControl(frame: CGRectMake(0, 0, 200, 35), actions: ["Symbol", "Numeral", "None"].enumerated().map { (i, title) in
                    UIAction(title: title) { _ in
                        Keyboard.keyLabelStyleChangedNotif.post(value: i)
                        UserDefaults.standard.set(i, forKey: "keyLabelStyle_Int")
                    }
                })
                control.selectedSegmentIndex = UserDefaults.standard.integer(forKey: "keyLabelStyle_Int") // default 0
                return control
            }())
            
        ]),
        
        SectionData("Playing", [
            
            CellData("Multi-press", {
                let control = UISwitch(frame: .zero, primaryAction: UIAction { action in
                    let on = (action.sender as! UISwitch).isOn
                    UserDefaults.standard.set(on, forKey: "multiPress_Bool")
                    Keyboard.multiPressChangedNotif.post(value: on)
                })
                control.isOn = UserDefaults.standard.bool(forKey: "multiPress_Bool") // default disabled
                return control
            }()),
            
            CellData("Dragging play", {
                let control = UISwitch(frame: .zero, primaryAction: UIAction { action in
                    let on = (action.sender as! UISwitch).isOn
                    UserDefaults.standard.set(on, forKey: "draggingEnabled_Bool")
                    Keyboard.draggingChangedNotif.post(value: on)
                })
                control.isOn = UserDefaults.standard.bool(forKey: "draggingEnabled_Bool") // default disabled
                return control
            }())
            
        ])
    ]
    
    
    
}
