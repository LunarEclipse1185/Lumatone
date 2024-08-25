//
//  ViewController.swift
//  Lumatone
//
//  Created by SH BU on 2024/6/15.
//

import UIKit
import UniformTypeIdentifiers

class ViewController: UIViewController, UIDocumentPickerDelegate {
    
    private var audioEngine: AudioEngine!
    private var controlPanel: ControlPanel!
    private var keyboard: Keyboard!
    
    private var folded = false
    
    override func viewDidLoad() {
        print("viewDidLoad")
        audioEngine = AudioEngine()
        keyboard = Keyboard(audioEngine) // TODO: SLOW
        controlPanel = ControlPanel() // all init value sent here
        print("subviews created")
        
        DispatchQueue.global().async {
            self.audioEngine.setupEngine()
            print("audio setup")
        }
        // setup engine is costly. parallelized.
        
        super.viewDidLoad()
        
        let sframe = view.safeAreaLayoutGuide.layoutFrame
        controlPanel.frame = CGRectMake(sframe.minX, sframe.minY, sframe.width, 0.25 * sframe.height)
        keyboard.frame = CGRectMake(sframe.minX, sframe.minY + 0.25 * sframe.height, sframe.width, 0.75 * sframe.height)
        controlPanel.linkDocumentPicker(showDocumentPicker)
        
        view.addSubview(keyboard)
        view.addSubview(controlPanel)
        
        // notification
        NotificationCenter.default.addObserver(forName: .panelHandleSwitched, object: nil, queue: nil, using: switchLayout(_:))
        
        // read stored value
        if UserDefaults.standard.bool(forKey: "controlPanelFolded_Bool") {
            NotificationCenter.default.post(name: .panelHandleSwitched, object: self)
        }
        
        // make document folder visible
        DispatchQueue.global().async {
//            let data = try! Data(contentsOf: Bundle.main.url(forResource: "YanahaGrand", withExtension: "sf2")!)
//            let success = (try? data.write(to: URL.documentsDirectory.appending(component: "YamahaGrand.sf2"))) == nil
//            print("copying default sf2 \(success ? "succeeded" : "failed")")
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
    
    private func switchLayout(_: Notification) {
        let sframe = view.safeAreaLayoutGuide.layoutFrame
        folded = !folded
        controlPanel.frame.origin.y = folded ? -controlPanel.frame.height : 0
        
        keyboard.frame.origin.y = folded ? 0 : controlPanel.frame.height
        keyboard.frame.size.height = folded ? sframe.height : sframe.height - controlPanel.frame.height
        keyboard.padding = folded ? 0.7 : 0.0
    }
    
    // file chooser impl
    
    let doxy = UIDocumentPickerViewController(forOpeningContentTypes:
        UTType.types(tag: "sf2", tagClass: UTTagClass.filenameExtension, conformingTo: nil))
    private func showDocumentPicker() {
        doxy.delegate = self
        present(doxy, animated: true, completion: nil)
    }
    
    public func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        guard let url = urls.first else { return }
        print("user selected file: \(url)")
        controlPanel.recievedFileUrl(url)
    }
    
    func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
        print("file selection cancelled")
        dismiss(animated: true, completion: nil)
    }
}
