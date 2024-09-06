//
//  ViewController.swift
//  Lumatone
//
//  Created by SH BU on 2024/6/15.
//

import UIKit
import UniformTypeIdentifiers

class ViewController: UIViewController, UIDocumentPickerDelegate {
    static let paddingChangedNotif = TypedNotification<CGFloat>(name: "paddingChanged")
    
    private var audioEngine: AudioEngine!
    private var controlPanel: ControlPanel!
    private var keyboard: Keyboard!
    
    private var folded = UserDefaults.standard.bool(forKey: "controlPanelFolded_Bool")
    private var keyboardPadding: CGFloat = CGFloat(UserDefaults.standard.object(forKey: "keyboardPadding_Float") as? Float ?? 0.7)
    
    private func switchLayout() {
        folded = !folded // ugly
        controlPanel.frame.origin.y = folded ? -controlPanel.frame.height : 0
        keyboard.frame.origin.y = folded ? 0 : controlPanel.frame.height
        keyboard.frame.size.height = folded ? view.frame.height : view.frame.height - controlPanel.frame.height
        keyboard.padding = folded ? keyboardPadding : 0.0
    }
    
    // impl file picker
    public func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        guard let url = urls.first else { return }
        print("user selected file: \(url)")
        controlPanel.recievedFileUrl(url)
    }
    
    
    override func viewWillAppear(_ animated: Bool) {
        print("initializing")
        audioEngine = AudioEngine()
        audioEngine.setupEngine()
        print("audio setup")
        keyboard = Keyboard(audioEngine) // TODO: SLOW
        controlPanel = ControlPanel() // all init value sent here
        print("subviews created")
        
        let sf = view.frame
        let controlPanelH = max(75, 0.25 * sf.height)
        controlPanel.frame = CGRectMake(sf.minX, sf.minY, sf.width, controlPanelH)
        keyboard.frame = CGRectMake(sf.minX, sf.minY + controlPanelH, sf.width, sf.height - controlPanelH)
        if folded {
            switchLayout()
        }
        
        view.addSubview(keyboard)
        view.addSubview(controlPanel)
        
        // observers
        NotificationCenter.default.addObserver(forName: .panelHandleSwitched, object: nil, queue: nil) { _ in
            self.switchLayout()
        }
        NotificationCenter.default.addObserver(forName: .showDocumentPicker, object: nil, queue: nil) { _ in
            let controller = UIDocumentPickerViewController(forOpeningContentTypes: UTType.types(tag: "sf2", tagClass: UTTagClass.filenameExtension, conformingTo: nil))
            controller.delegate = self
            self.present(controller, animated: true)
        }
        NotificationCenter.default.addObserver(forName: .showSettings, object: nil, queue: nil) { _ in
            let controller = SettingsNavigationController()
            controller.modalPresentationStyle = .formSheet
            // formSheet = small, pageSheet = big
            self.present(controller, animated: true)
        }
        NotificationCenter.default.addObserver(forName: .showHelp, object: nil, queue: nil) { _ in
            let controller = HelpNavigationController()
            controller.modalPresentationStyle = .formSheet
            // formSheet = small, pageSheet = big
            self.present(controller, animated: true)
        }
        Self.paddingChangedNotif.registerOnAny { value in
            self.keyboardPadding = value
        }
        
        // make document folder visible
        DispatchQueue.global().async {
            let src = Bundle.main.url(forResource: "YamahaGrand", withExtension: "sf2")!
            let dst = URL.documentsDirectory.appending(component: "YamahaGrand.sf2")
            do {
                if FileManager.default.fileExists(atPath: dst.path) {
                    try FileManager.default.removeItem(at: dst)
                }
                try FileManager.default.copyItem(at: src, to: dst)
            } catch (let error) {
                print("Cannot copy item at \(src) to \(dst): \(error)")
            }
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        // first run show help
        if !UserDefaults.standard.bool(forKey: "firstRunHelpShown_Bool") {
            let controller = HelpNavigationController()
            controller.modalPresentationStyle = .formSheet
            // formSheet = small, pageSheet = big
            present(controller, animated: true)
        }
    }
    
}
