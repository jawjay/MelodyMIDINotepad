//
//  ViewController.swift
//  MelodyNotepad
//
//  Created by John Dunagan on 7/20/16.
//  Copyright © 2016 John Dunagan. All rights reserved.
//

import UIKit
import AudioKit


class ViewController: UIViewController, SettingsDelegate{

    @IBOutlet weak var play_button: UIButton!
    @IBOutlet weak var record_button: UIButton!
    
    @IBOutlet weak var save_button: UIButton!
    @IBOutlet weak var delete_button: UIButton!
    
    @IBOutlet weak var tempo_text: UITextField!

    
    @IBOutlet weak var metro_switch: UISwitch!
    
    @IBOutlet weak var metronome: MetronomeView!
    
    
    @IBOutlet weak var recording_table: UITableView!
    @IBOutlet weak var scrollView: MIDIScrollView!
    
    let audioProcessor = AudioProcessor.sharedInstance
    
    var melody = Melody.yankeeDoodle()
    var midiView : MIDIView? = nil
    
    var autoscroller : NSTimer?
    
    var melodies = [Melody]()  // use this to hold melodies to load/save
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        tempo_text.delegate = self
        
        // Setup MIDIView
        midiView = scrollView.midiView
        
        scrollView.setOffset(200)
        scrollView.delegate = self
        
        // Swift is cool
        audioProcessor.stopPlaybackCallback = {
            self.play_button.setTitle("Play", forState: .Normal)
            self.autoscroller?.invalidate()
            self.button_activation(true)
            self.stopMetronome()
        }
        
        loadMelodies()
        openMelody(melodies.first!)
        
        loadDefaults()
        refreshView()
        
        // Remove navigation bar
        self.navigationController?.navigationBarHidden = true
        
        // Setup table view
        recording_table.dataSource = self
        recording_table.delegate = self
        recording_table.registerClass(UITableViewCell.self, forCellReuseIdentifier: "cell")

        recording_table.selectRowAtIndexPath(NSIndexPath.init(forRow: 0, inSection: 0), animated: false, scrollPosition: .Top)
        
    }
    
    override func viewDidDisappear(animated: Bool) {
        saveMelodies()
    }
    
    func loadDefaults() {
        let defaults = NSUserDefaults.standardUserDefaults()
        
        var amp = SettingsController.ampDefault
        var dur = SettingsController.durDefault
        var width = SettingsController.beatwidthDefault
        var height = SettingsController.noteHeightDefault
        
        if defaults.boolForKey("switchState") {     // check switch state
            amp = defaults.floatForKey("ampVal")
            dur = defaults.floatForKey("durVal")
            width = defaults.floatForKey("domVal")
            height = defaults.floatForKey("rangeVal")
        }
        
        audioProcessor.transcriber.thresholdDur = Double(dur)
        audioProcessor.transcriber.thresholdAmp = Double(amp)
        midiView?.beatWidth = CGFloat(width)
        midiView?.noteHeight = CGFloat(height)
        
        
        
    }
    
    // Synchronizes ViewController, AudioProcessor, and MIDIView melody selection
    func openMelody(melody : Melody) {
        self.melody = melody
        scrollView.openMelody(melody)
        audioProcessor.melody = melody
        self.tempo_text.text = String(melody.tempo)
    }
    
    func refreshView() {
        scrollView.refresh()
    }

    
    @IBAction func recordClicked(sender: AnyObject) {
        switch audioProcessor.status {
        case .Idle:
            audioProcessor.startRecording()
            record_button.setTitle("Stop", forState: .Normal)
            button_activation(false)
            if metro_switch.on {
                startMetronome()
            }
        default:
            audioProcessor.stopRecording()
            refreshView()
            record_button.setTitle("Record", forState: .Normal)
            button_activation(true)
            stopMetronome()
        }
    }
    
    @IBAction func playClicked(sender: UIButton) {
        if audioProcessor.status != .Playback {
            audioProcessor.startPlayback()
            autoscroller = NSTimer.scheduledTimerWithTimeInterval(
                0.1,
                target: self,
                selector: #selector(autoscroll),
                userInfo: nil,
                repeats: true)
            play_button.setTitle("Stop", forState: .Normal)
            button_activation(false)
            if metro_switch.on {
                startMetronome()
            }
        } else {
            audioProcessor.stopPlayback()
            stopMetronome()
        }
    }
    
    // Interface Actions
    
    @IBAction func newClicked(sender: AnyObject) {
        let alert = UIAlertController(title: "New Melody", message: "What would you like to call this melody?", preferredStyle: UIAlertControllerStyle.Alert)
        // add the actions (buttons)
        
        let defaultName = Melody.generateDateString()
        
        alert.addTextFieldWithConfigurationHandler { (textField) in
            textField.placeholder = defaultName
        }
        
        alert.addAction(UIAlertAction(title: "Create", style: .Default, handler: { (UIAlertAction) in
            let melody = Melody(name : defaultName)
            
            if let name = alert.textFields?[0].text {
                if name.characters.count > 0 {
                    melody.name = name
                }
            }
            
            //setup new melody
            self.melodies.append(melody)
            
            self.openMelody(melody)
            
            self.recording_table.reloadData()
            self.recording_table.selectRowAtIndexPath(
                NSIndexPath(forRow: self.melodies.count-1, inSection: 0),
                animated: true,
                scrollPosition: .Bottom)
            
        }))
        
        alert.addAction(UIAlertAction(title: "Cancel", style: UIAlertActionStyle.Cancel, handler: nil))
        // show the alert
        self.presentViewController(alert, animated: true, completion: nil)

        
    }
    
    @IBAction func deleteMelodyClicked(sender: AnyObject) {
        if let melodyIndex = melodies.indexOf({$0 === self.melody}){
            
            // create the alert
            let alert = UIAlertController(
                title: "Delete Melody",
                message: "Would you like to delete this melody?",
                preferredStyle: .Alert)
            // add the actions (buttons)
            alert.addAction(UIAlertAction(title: "Yes", style: .Default, handler: { (UIAlertAction) in
                self.melodies.removeAtIndex(melodyIndex)
                self.saveMelodies()
                self.recording_table.reloadData()
                if self.melodies.count > melodyIndex {
                    self.openMelody(self.melodies[melodyIndex])
                } else {
                    if let first = self.melodies.first {
                        self.openMelody(first)
                    } else {
                        self.openMelody(Melody())
                    }
                    
                }
            }))
            alert.addAction(UIAlertAction(title: "Cancel", style: UIAlertActionStyle.Cancel, handler: nil))
            // show the alert
            self.presentViewController(alert, animated: true, completion: nil)

        } else {
            let alert = UIAlertController(
                title: "No Melody Selected",
                message: "Please select a melody to delete",
                preferredStyle: .Alert)
            alert.addAction(UIAlertAction(title: "Close", style: .Default, handler: nil))
            self.presentViewController(alert, animated: true, completion: nil)
        }
        
    }
  
    @IBAction func deleteNoteClicked(sender: AnyObject) {
        midiView?.deleteSelected()
    }
    
    func button_activation(active:Bool){
        save_button.enabled = active
        delete_button.enabled = active
        metro_switch.enabled = active
        tempo_text.enabled = active

    }
    
    private func startMetronome() {
        metronome.tempo = melody.tempo
        metronome.switchOn()
    }
    
    private func stopMetronome() {
        if metronome.running {
            metronome.switchOff()
        }
    }
    
    
    //// SETTINGS DELEGATION
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "showSettings" {
            let settingsController = segue.destinationViewController as? SettingsController
            if let viewController = settingsController {
                viewController.delegate = self
            }
        }
    }
    
    
    func settingsDidChange(ampVal:Float,durVal:Float,widthVal:Float,heightVal:Float) {
        //print("Amplitude Vale:  \(ampVal) \nDuration Value: \(durVal)")
        audioProcessor.transcriber.thresholdAmp = Double(ampVal)
        audioProcessor.transcriber.thresholdDur = Double(durVal)
        midiView?.beatWidth = CGFloat(widthVal)
        midiView?.noteHeight = CGFloat(heightVal)
        refreshView()
    }
    
    

    
    @objc func autoscroll() {
        scrollView.moveToBeat(audioProcessor.playhead.beats)
    }
    
    // SETTINGS PAGE WITH NAV BAR
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        self.navigationController?.navigationBarHidden = false
    }
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.navigationBarHidden = true
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: NSCoding
    
    func saveMelodies() { // save all objects in melodies array
        let isSuccessfulSave = NSKeyedArchiver.archiveRootObject(melodies, toFile: Melody.ArchiveURL.path!)
        if !isSuccessfulSave {
            print("Failed to save melodies...")
        }
        else{
            print("Saved melodies")
        }
    }
    
    func loadMelodies() { //load melodies at standard melody path into melodies
        if let melodies = NSKeyedUnarchiver.unarchiveObjectWithFile(Melody.ArchiveURL.path!) as? [Melody] {
            if melodies.count > 0 {
                self.melodies = melodies
                return
            }
        }
        
        self.melodies = [Melody()]
    }
}



extension ViewController : UITableViewDataSource, UITableViewDelegate {
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return melodies.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        var cell:UITableViewCell?
        cell = tableView.dequeueReusableCellWithIdentifier("cell", forIndexPath: indexPath)
        
        //cell!.textLabel!.text = sample_recordings[indexPath.row]
        cell!.textLabel!.text = melodies[indexPath.row].name
        return cell!
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        openMelody(melodies[indexPath.row])
    }
}


extension ViewController : UIScrollViewDelegate {
    func scrollViewDidScroll(scrollView: UIScrollView) {
        guard audioProcessor.status != .Playback else { return }
        
        let x = scrollView.contentOffset.x
        audioProcessor.playhead = AKDuration(beats: midiView!.beatsFromX(x), tempo: melody.tempo)
        
        self.scrollView.playheadIndicator.x = x
        self.scrollView.playheadIndicator.setNeedsDisplay()
        
    }
}

extension ViewController : UITextFieldDelegate {
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        var updated = false
        
        if audioProcessor.status == .Idle {
            if let text = textField.text {
                if let tempo = BPM(text)  {
                    if tempo > 0 && tempo < 400 {
                        melody.tempo = tempo
                        updated = true
                    }
                }
            }
        }
        
        if !updated {
            textField.text = String(melody.tempo)
        }
        
        textField.resignFirstResponder()
        return true
    }
}
