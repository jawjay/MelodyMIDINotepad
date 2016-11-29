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
    
    var autoscroller : Timer?
    
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
            self.play_button.setTitle("Play", for: UIControlState())
            self.autoscroller?.invalidate()
            self.button_activation(true)
            self.stopMetronome()
        }
        
        loadMelodies()
        openMelody(melodies.first!)
        
        loadDefaults()
        refreshView()
        
        // Remove navigation bar
        self.navigationController?.isNavigationBarHidden = true
        
        // Setup table view
        recording_table.dataSource = self
        recording_table.delegate = self
        recording_table.register(UITableViewCell.self, forCellReuseIdentifier: "cell")

//        recording_table.selectRow(at: IndexPath.init(row: 0, section: 0), animated: false, scrollPosition: .top)
        
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        saveMelodies()
    }
    
    func loadDefaults() {
        let defaults = UserDefaults.standard
        
        var amp = SettingsController.ampDefault
        var dur = SettingsController.durDefault
        var width = SettingsController.beatwidthDefault
        var height = SettingsController.noteHeightDefault
        
        if defaults.bool(forKey: "switchState") {     // check switch state
            amp = defaults.float(forKey: "ampVal")
            dur = defaults.float(forKey: "durVal")
            width = defaults.float(forKey: "domVal")
            height = defaults.float(forKey: "rangeVal")
        }
        
        audioProcessor.transcriber.thresholdDur = Double(dur)
        audioProcessor.transcriber.thresholdAmp = Double(amp)
        midiView?.beatWidth = CGFloat(width)
        midiView?.noteHeight = CGFloat(height)
        
        
        
    }
    
    // Synchronizes ViewController, AudioProcessor, and MIDIView melody selection
    func openMelody(_ melody : Melody) {
        self.melody = melody
        scrollView.openMelody(melody)
        audioProcessor.melody = melody
        self.tempo_text.text = String(melody.tempo)
    }
    
    func refreshView() {
        scrollView.refresh()
    }

    
    @IBAction func recordClicked(_ sender: AnyObject) {
        switch audioProcessor.status {
        case .idle:
            audioProcessor.startRecording()
            record_button.setTitle("Stop", for: UIControlState())
            button_activation(false)
            if metro_switch.isOn {
                startMetronome()
            }
        default:
            audioProcessor.stopRecording()
            refreshView()
            record_button.setTitle("Record", for: UIControlState())
            button_activation(true)
            stopMetronome()
        }
    }
    
    @IBAction func playClicked(_ sender: UIButton) {
        if audioProcessor.status != .playback {
            audioProcessor.startPlayback()
            autoscroller = Timer.scheduledTimer(
                timeInterval: 0.1,
                target: self,
                selector: #selector(autoscroll),
                userInfo: nil,
                repeats: true)
            play_button.setTitle("Stop", for: UIControlState())
            button_activation(false)
            if metro_switch.isOn {
                startMetronome()
            }
        } else {
            audioProcessor.stopPlayback()
            stopMetronome()
        }
    }
    
    // Interface Actions
    
    @IBAction func newClicked(_ sender: AnyObject) {
        let alert = UIAlertController(title: "New Melody", message: "What would you like to call this melody?", preferredStyle: UIAlertControllerStyle.alert)
        // add the actions (buttons)
        
        let defaultName = Melody.generateDateString()
        
        alert.addTextField { (textField) in
            textField.placeholder = defaultName
        }
        
        alert.addAction(UIAlertAction(title: "Create", style: .default, handler: { (UIAlertAction) in
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
            self.recording_table.selectRow(
                at: IndexPath(row: self.melodies.count-1, section: 0),
                animated: true,
                scrollPosition: .bottom)
            
        }))
        
        alert.addAction(UIAlertAction(title: "Cancel", style: UIAlertActionStyle.cancel, handler: nil))
        // show the alert
        self.present(alert, animated: true, completion: nil)

        
    }
    
    @IBAction func deleteMelodyClicked(_ sender: AnyObject) {
        if let melodyIndex = melodies.index(where: {$0 === self.melody}){
            
            // create the alert
            let alert = UIAlertController(
                title: "Delete Melody",
                message: "Would you like to delete this melody?",
                preferredStyle: .alert)
            // add the actions (buttons)
            alert.addAction(UIAlertAction(title: "Yes", style: .default, handler: { (UIAlertAction) in
                self.melodies.remove(at: melodyIndex)
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
            alert.addAction(UIAlertAction(title: "Cancel", style: UIAlertActionStyle.cancel, handler: nil))
            // show the alert
            self.present(alert, animated: true, completion: nil)

        } else {
            let alert = UIAlertController(
                title: "No Melody Selected",
                message: "Please select a melody to delete",
                preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Close", style: .default, handler: nil))
            self.present(alert, animated: true, completion: nil)
        }
        
    }
  
    @IBAction func deleteNoteClicked(_ sender: AnyObject) {
        midiView?.deleteSelected()
    }
    
    func button_activation(_ active:Bool){
        save_button.isEnabled = active
        delete_button.isEnabled = active
        metro_switch.isEnabled = active
        tempo_text.isEnabled = active

    }
    
    fileprivate func startMetronome() {
        metronome.tempo = melody.tempo
        metronome.switchOn()
    }
    
    fileprivate func stopMetronome() {
        if metronome.running {
            metronome.switchOff()
        }
    }
    
    
    //// SETTINGS DELEGATION
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showSettings" {
            let settingsController = segue.destination as? SettingsController
            if let viewController = settingsController {
                viewController.delegate = self
            }
        }
    }
    
    
    func settingsDidChange(_ ampVal:Float,durVal:Float,widthVal:Float,heightVal:Float) {
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
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.navigationController?.isNavigationBarHidden = false
    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.isNavigationBarHidden = true
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: NSCoding
    
    func saveMelodies() { // save all objects in melodies array
        let isSuccessfulSave = NSKeyedArchiver.archiveRootObject(melodies, toFile: Melody.ArchiveURL.path)
        if !isSuccessfulSave {
            print("Failed to save melodies...")
        }
        else{
            print("Saved melodies")
        }
    }
    
    func loadMelodies() { //load melodies at standard melody path into melodies
        if let melodies = NSKeyedUnarchiver.unarchiveObject(withFile: Melody.ArchiveURL.path) as? [Melody] {
            if melodies.count > 0 {
                self.melodies = melodies
                return
            }
        }
        
        self.melodies = [Melody()]
    }
}



extension ViewController : UITableViewDataSource, UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return melodies.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell:UITableViewCell?
        cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        
        //cell!.textLabel!.text = sample_recordings[indexPath.row]
        cell!.textLabel!.text = melodies[indexPath.row].name
        return cell!
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        openMelody(melodies[indexPath.row])
    }
}


extension ViewController : UIScrollViewDelegate {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        guard audioProcessor.status != .playback else { return }
        
        let x = scrollView.contentOffset.x
        audioProcessor.playhead = AKDuration(beats: midiView!.beatsFromX(x), tempo: melody.tempo)
        
        self.scrollView.playheadIndicator.x = x
        self.scrollView.playheadIndicator.setNeedsDisplay()
        
    }
}

extension ViewController : UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        var updated = false
        
        if audioProcessor.status == .idle {
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
