//
//  ViewController.swift
//  SS2Specht
//
//  Created by Will on 2018/5/25.
//  Copyright © 2018 gewill.org. All rights reserved.
//

import Cocoa
import SwiftyJSON
import FileKit

class ViewController: NSViewController {

    @IBOutlet weak var titleL: NSTextField!

    @IBOutlet weak var ssFilePathL: NSTextField!
    @IBOutlet weak var openSSConfigFileB: NSButton!

    @IBOutlet weak var spFilePathL: NSTextField!
    @IBOutlet weak var convertB: NSButton!

    let spFileName = "Conf.yaml"

    var selectedFile: URL? {
        didSet {
            ssFilePathL.stringValue = selectedFile?.path ?? ""
        }
    }

    var spFile: URL? {
        didSet {
            spFilePathL.stringValue = spFile?.path ?? ""
        }
    }

    // MARK: - response methods
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    override var representedObject: Any? {
        didSet {
            // Update the view, if already loaded.
        }
    }

    // MARK: - response methods
    @IBAction func openSSConfigFile(_ sender: NSButton) {
        guard let window = view.window else { return }

        let panel = NSOpenPanel()
        panel.canChooseFiles = true
        panel.canChooseDirectories = false
        panel.allowsMultipleSelection = false

        panel.beginSheetModal(for: window) { (result) in
            if result == NSApplication.ModalResponse.OK {
                self.selectedFile = panel.urls[0]
            }
        }
    }

    @IBAction func revealSpechtFileInFinder(_ sender: NSButton) {
        guard let _ = self.spFile else {
            return
        }

        guard let folderPath = getSSFileFolderPath() else {
            return
        }

        NSWorkspace.shared.selectFile(nil, inFileViewerRootedAtPath: folderPath.url.path)
    }

    @IBAction func startConvert(_ sender: NSButton) {
        guard let selectedFile = selectedFile else { return }
        guard let jsonData = NSData(contentsOf: selectedFile) else { return }
        let ssJson: JSON = JSON(jsonData)

        guard let templateFile = Bundle.main.url(forResource: "Conf", withExtension: "yaml") else { return }
        guard var templateText = getFileString(templateFile) else { return }

        var serverStr = ""
        var serverIdStr = ""
       
        ssJson["configs"].arrayValue.forEach {
            let id: String = $0["remarks"].stringValue
            serverStr += """
              - id: \(id)
                type: ss
                host: \($0["server"])
                port: \($0["server_port"])
                method: \($0["method"])
                password: \($0["password"])\n
            """
            serverIdStr += """
                  - id: \(id)
                    delay: 0\n
            """
        }

        templateText = templateText.replacingOccurrences(of: "@server@", with: serverStr)
        templateText = templateText.replacingOccurrences(of: "@server_id@", with: serverIdStr)

        guard let spPath = getDefaultSpechtConfigFilePath() else {
            return
        }
        
        do {
            try templateText |> TextFile(path: spPath)
            self.spFile = spPath.url
        } catch {
            NSAlert(error: error).runModal()
        }

    }

    // MARK: - private methods
    private func getFileString(_ url: URL) -> String? {
        do {
            let text = try String(contentsOf: url)
            return text
        } catch {
            NSAlert(error: error).runModal()
            return nil
        }
    }
    
    private func getDefaultSpechtConfigFilePath() -> Path? {
        guard let folderPath = getSSFileFolderPath() else {
            return nil
        }
        
        return folderPath + spFileName
    }
    
    private func getSSFileFolderPath() -> Path? {
        guard let spFile = self.selectedFile else {
            return nil
        }
        
        guard let path = Path(url: spFile) else {
            return nil
        }
        
        return path.parent
    }
}
