//
//  EditHotKeyViewController.swift
//  Thor
//
//  Created by Alvin on 5/12/16.
//  Copyright © 2016 AlvinZhu. All rights reserved.
//

import Cocoa
import MASShortcut

class EditHotKeyViewController: NSViewController {

    @IBOutlet weak var btnApps: NSPopUpButton!
    @IBOutlet weak var shortcutView: MASShortcutView!
    
    var editedApp: AppModel?
    
    private var apps: [AppModel]?
    private var selectedApp: AppModel?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.layer?.backgroundColor = NSColor.whiteColor().CGColor
        
        btnApps.action = #selector(chooseApp(_:))
        btnApps.target = self
    }
    
    override func viewWillAppear() {
        super.viewWillAppear()
        
        if let apps = apps {
            resetSelections(apps)
        } else {
            AppsManager.manager.getAppsInApplicationsDirectiory {
                if self.apps == nil || $0 != self.apps! {
                    self.apps = $0
                    self.resetSelections($0)
                }
            }
        }
    }
    
    override func viewWillDisappear() {
        super.viewWillDisappear()
        
        editedApp = nil
        selectedApp = nil
        shortcutView.shortcutValue = nil
        
        view.window?.close()
        NSApp.stopModal()
    }
    
    @IBAction func save(sender: AnyObject) {
        if let shortcut = shortcutView.shortcutValue, selectedApp = selectedApp {
            selectedApp.shortcut = shortcut
            
            AppsManager.manager.save(selectedApp)
            
            NSNotificationCenter.defaultCenter().postNotificationName(refreshAppsListNotification, object: nil)
        }
        
        view.window?.close()
        NSApp.stopModal()
    }
    
    @objc private func chooseApp(popUpButton: NSPopUpButton) {
        if let selectedItem = popUpButton.selectedItem where selectedItem.tag == 1000 {
            let openPanel = NSOpenPanel()
            openPanel.allowsMultipleSelection = false
            openPanel.canChooseDirectories = true
            openPanel.canChooseFiles = true
            openPanel.allowedFileTypes = ["app"]
            
            openPanel.beginSheetModalForWindow(view.window!, completionHandler: { (result) in
                if result == NSModalResponseOK, let metaDataItem = NSMetadataItem(URL: openPanel.URLs.first!) {
                    
                    self.editedApp = AppModel(item: metaDataItem)
                    
                    self.resetSelections(self.apps)
                }
            })
        } else {
            let idx = popUpButton.indexOfSelectedItem - (editedApp == nil ? 0 : 2)
            
            if let apps = apps {
                selectedApp = apps[idx]
            }
        }
    }
    
    private func resetSelections(apps: [AppModel]?) {
        guard let apps = apps else { return }
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)) {
            let menu = NSMenu()
            
            if let editedApp = self.editedApp {
                let selectedItem = NSMenuItem()
                selectedItem.title = editedApp.appDisplayName
                selectedItem.image = editedApp.icon
                
                menu.addItem(selectedItem)
                
                menu.addItem(NSMenuItem.separatorItem())
                
                self.shortcutView.shortcutValue = editedApp.shortcut
                
                self.selectedApp = editedApp
            }
            
            for app in apps {
                let item = NSMenuItem()
                item.title = app.appDisplayName
                item.image = app.icon
                
                menu.addItem(item)
            }
            
            menu.addItem(NSMenuItem.separatorItem())
            
            let customMenuItem = NSMenuItem()
            customMenuItem.title = "Custom".localized()
            customMenuItem.tag = 1000
            menu.addItem(customMenuItem)
            
            dispatch_async(dispatch_get_main_queue(), {
                self.btnApps.removeAllItems()
                self.btnApps.menu = menu
                self.selectedApp = self.selectedApp ?? apps.first
                self.btnApps.selectItemAtIndex(0)
            })
        }
    }
    
}