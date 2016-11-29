//
//  SettingsController.swift
//  MelodyNotepad
//
//  Created by Mark Jajeh on 7/26/16.
//  Copyright © 2016 John Dunagan. All rights reserved.
//


import UIKit
import AudioKit


protocol SettingsDelegate {
    func settingsDidChange(_ ampVal: Float, durVal: Float,widthVal:Float,heightVal:Float)
}
private extension Selector {
    static let popToRoot = #selector(SettingsController.popToRoot(_:))
}

class SettingsController: UIViewController{
//    weak var mydelegate: ViewControllerDelegate?
    
    // Setting Defaults
    
    static let ampDefault:Float = 0.2
    static let durDefault:Float = 0.06
    static let beatwidthDefault:Float = 80
    static let noteHeightDefault:Float = 16
    
    
    
    @IBOutlet weak var ampSlider: UISlider!
    @IBOutlet weak var ampValLabel: UILabel!
    @IBAction func ampValChanged(_ sender: UISlider) {
        
        ampValLabel.text = String(Double(round(1000*ampSlider.value)/1000))
    }
    
    
    @IBOutlet weak var customSwitch: UISwitch!
    
    
    @IBOutlet weak var durSlider: UISlider!
    @IBOutlet weak var durValLabel: UILabel!
    @IBAction func durValChanged(_ sender: UISlider) {
        durValLabel.text =  String(Double(round(1000*durSlider.value)/1000))
    }
    
    @IBAction func customSwitchFlip(_ sender: AnyObject) {
        defaults.set(customSwitch.isOn, forKey: "switchState")
        setSliders()
    }
    
    
    @IBOutlet weak var widthSlider: UISlider!

    @IBOutlet weak var domValLabel: UILabel!
    
    @IBAction func widthValChanged(_ sender: UISlider) {
        domValLabel.text =  String(Int(widthSlider.value))
    }
    
    @IBOutlet weak var heightSlider: UISlider!
    
    @IBOutlet weak var rangeValLabel: UILabel!
    
    @IBAction func heightValChanged(_ sender: UISlider) {
        rangeValLabel.text = String(Int(heightSlider.value))
    }

    
    let defaults = UserDefaults.standard
    
    
    var delegate: SettingsDelegate?
    
    func popToRoot(_ sender:UIBarButtonItem){
        self.navigationController!.popToRootViewController(animated: true)
        if let mydelegate = self.delegate {
            mydelegate.settingsDidChange(ampSlider.value,durVal: durSlider.value,widthVal: widthSlider.value,heightVal: heightSlider.value)
        }
    }
    
    func setCustomBackButton(_ title: String){
        let myBackButton:UIButton = UIButton(type: .custom)
        myBackButton.addTarget(self, action: .popToRoot, for: UIControlEvents.touchUpInside)
        myBackButton.setTitle(title, for: UIControlState())
        myBackButton.setTitleColor(UIColor.blue, for: UIControlState())
        myBackButton.sizeToFit()
        let myCustomBackButtonItem:UIBarButtonItem = UIBarButtonItem(customView: myBackButton)
        self.navigationItem.leftBarButtonItem  = myCustomBackButtonItem
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setCustomBackButton("Back")
        
        
    }
    
    func setSwitch(){
        customSwitch.isOn = defaults.bool(forKey: "switchState")
    }
    
    func setSliders(){
        var ampVal = SettingsController.ampDefault
        var durVal = SettingsController.durDefault
        var domVal = SettingsController.beatwidthDefault
        var rangeVal = SettingsController.noteHeightDefault
        
        if defaults.bool(forKey: "switchState") {     // check switch state
             ampVal = defaults.float(forKey: "ampVal")
             durVal = defaults.float(forKey: "durVal")
             domVal = defaults.float(forKey: "domVal")
             rangeVal = defaults.float(forKey: "rangeVal")

        }
        ampSlider.value = ampVal
        ampValLabel.text = String(Double(round(1000*ampSlider.value)/1000))
        durSlider.value = durVal
        durValLabel.text =  String(Double(round(1000*durSlider.value)/1000))
        heightSlider.value = rangeVal
        rangeValLabel.text = String(Int(heightSlider.value))
        widthSlider.value = domVal
        domValLabel.text =  String(Int(widthSlider.value))
        
    }
    override func viewWillAppear(_ animated: Bool) {
        setSwitch()
        setSliders()
        
        
        
    }
    override func viewWillDisappear(_ animated: Bool) {
        defaults.set(ampSlider.value, forKey: "ampVal")
        defaults.set(durSlider.value, forKey: "durVal")
        defaults.set(widthSlider.value, forKey: "domVal")
        defaults.set(heightSlider.value, forKey: "rangeVal")
    }
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
  

    
}
