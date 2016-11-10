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
    func settingsDidChange(ampVal: Float, durVal: Float,widthVal:Float,heightVal:Float)
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
    @IBAction func ampValChanged(sender: UISlider) {
        
        ampValLabel.text = String(Double(round(1000*ampSlider.value)/1000))
    }
    
    
    @IBOutlet weak var customSwitch: UISwitch!
    
    
    @IBOutlet weak var durSlider: UISlider!
    @IBOutlet weak var durValLabel: UILabel!
    @IBAction func durValChanged(sender: UISlider) {
        durValLabel.text =  String(Double(round(1000*durSlider.value)/1000))
    }
    
    @IBAction func customSwitchFlip(sender: AnyObject) {
        defaults.setBool(customSwitch.on, forKey: "switchState")
        setSliders()
    }
    
    
    @IBOutlet weak var widthSlider: UISlider!

    @IBOutlet weak var domValLabel: UILabel!
    
    @IBAction func widthValChanged(sender: UISlider) {
        domValLabel.text =  String(Int(widthSlider.value))
    }
    
    @IBOutlet weak var heightSlider: UISlider!
    
    @IBOutlet weak var rangeValLabel: UILabel!
    
    @IBAction func heightValChanged(sender: UISlider) {
        rangeValLabel.text = String(Int(heightSlider.value))
    }

    
    let defaults = NSUserDefaults.standardUserDefaults()
    
    
    var delegate: SettingsDelegate?
    
    func popToRoot(sender:UIBarButtonItem){
        self.navigationController!.popToRootViewControllerAnimated(true)
        if let mydelegate = self.delegate {
            mydelegate.settingsDidChange(ampSlider.value,durVal: durSlider.value,widthVal: widthSlider.value,heightVal: heightSlider.value)
        }
    }
    
    func setCustomBackButton(title: String){
        let myBackButton:UIButton = UIButton(type: .Custom)
        myBackButton.addTarget(self, action: .popToRoot, forControlEvents: UIControlEvents.TouchUpInside)
        myBackButton.setTitle(title, forState: UIControlState.Normal)
        myBackButton.setTitleColor(UIColor.blueColor(), forState: UIControlState.Normal)
        myBackButton.sizeToFit()
        let myCustomBackButtonItem:UIBarButtonItem = UIBarButtonItem(customView: myBackButton)
        self.navigationItem.leftBarButtonItem  = myCustomBackButtonItem
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setCustomBackButton("Back")
        
        
    }
    
    func setSwitch(){
        customSwitch.on = defaults.boolForKey("switchState")
    }
    
    func setSliders(){
        var ampVal = SettingsController.ampDefault
        var durVal = SettingsController.durDefault
        var domVal = SettingsController.beatwidthDefault
        var rangeVal = SettingsController.noteHeightDefault
        
        if defaults.boolForKey("switchState") {     // check switch state
             ampVal = defaults.floatForKey("ampVal")
             durVal = defaults.floatForKey("durVal")
             domVal = defaults.floatForKey("domVal")
             rangeVal = defaults.floatForKey("rangeVal")

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
    override func viewWillAppear(animated: Bool) {
        setSwitch()
        setSliders()
        
        
        
    }
    override func viewWillDisappear(animated: Bool) {
        defaults.setFloat(ampSlider.value, forKey: "ampVal")
        defaults.setFloat(durSlider.value, forKey: "durVal")
        defaults.setFloat(widthSlider.value, forKey: "domVal")
        defaults.setFloat(heightSlider.value, forKey: "rangeVal")
    }
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
  

    
}