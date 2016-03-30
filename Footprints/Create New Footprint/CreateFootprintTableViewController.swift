//
//  CreateFootprintTableViewController.swift
//  Footprints
//
//  Created by Jorge Tapia on 3/28/16.
//  Copyright © 2016 Jorge Tapia. All rights reserved.
//

import UIKit
import Photos
import MobileCoreServices

class CreateFootprintTableViewController: UITableViewController {

    @IBOutlet weak var dismissButton: UIBarButtonItem!
    @IBOutlet weak var saveButton: UIBarButtonItem!
    @IBOutlet weak var addTitleLabel: UILabel!
    @IBOutlet weak var addTextNoteLabel: UILabel!
    @IBOutlet weak var addPlaceLabel: UILabel!
    @IBOutlet weak var addDateLabel: UILabel!
    @IBOutlet weak var pictureImageView: UIImageView!
    
    var footprint = Footprint()
    
    var userPicture: UIImage?
    var audioSession: AVAudioSession!
    var audioPlayer: AVAudioPlayer!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        saveButton.enabled = footprint.title != nil
        // TODO: implement
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    // MARK: - Actions
    
    @IBAction func dismissAction(sender: AnyObject) {
        dismissViewControllerAnimated(true, completion: nil)
    }
    
    @IBAction func saveAction(sender: AnyObject) {
        UIApplication.sharedApplication().networkActivityIndicatorVisible = true
        tableView.setContentOffset(CGPointZero, animated: true)
        
        // TODO: set selected date
        footprint.date = NSDate()
        
        // Process photo
        var imageFilePath: NSURL?
        
        if userPicture != nil {
            imageFilePath = NSURL(fileURLWithPath: NSTemporaryDirectory()).URLByAppendingPathComponent("\(NSUUID().UUIDString).igo")
            UIImageJPEGRepresentation(userPicture!, 1.0)?.writeToFile(imageFilePath!.relativePath!, atomically: true)
            footprint.picture = imageFilePath
        }
        
        let activityIndicator = UIActivityIndicatorView(activityIndicatorStyle: .WhiteLarge)
        activityIndicator.frame = CGRect(x: (UIScreen.mainScreen().bounds.width / 2.0) - (activityIndicator.frame.width / 2.0), y: (UIScreen.mainScreen().bounds.height / 2.0) - activityIndicator.frame.height - 64.0, width: activityIndicator.frame.width, height: activityIndicator.frame.height)
        activityIndicator.color = AppTheme.lightPinkColor
        activityIndicator.startAnimating()
        view.addSubview(activityIndicator)
        
        view.userInteractionEnabled = false
        saveButton.enabled = false
        dismissButton.enabled = false
        
        CloudKitHelper.saveFootprint(footprint) { record, error in
            UIApplication.sharedApplication().networkActivityIndicatorVisible = false
            
            if error == nil {
                self.footprint.recordID = record?.recordID
                self.footprint.picture = nil
                
                CloudKitHelper.allFootprints.insert(self.footprint, atIndex: 0)
                AppUtils.deleteFile(imageFilePath)
                
                dispatch_async(dispatch_get_main_queue()) {
                    self.saveButton.enabled = true
                    self.dismissButton.enabled = true
                    self.view.userInteractionEnabled = true
                    activityIndicator.removeFromSuperview()
                    
                    self.dismissViewControllerAnimated(true, completion: nil)
                }
            } else {
                dispatch_async(dispatch_get_main_queue()) {
                    self.saveButton.enabled = true
                    self.dismissButton.enabled = true
                    self.view.userInteractionEnabled = true
                    activityIndicator.removeFromSuperview()
                    
                    AppError.handleAsAlert("Ooops!", message: error?.localizedDescription, presentingViewController: self, completion: nil)
                }
            }
        }
    }
    
    // MARK: - UI methods
    private func setupUI() {
        clearsSelectionOnViewWillAppear = true
        saveButton.enabled = false
        
        let selectedBackgroundView = UIView()
        selectedBackgroundView.backgroundColor = AppTheme.tableVieCellSelectionColor
        
        for section in 0...tableView.numberOfSections - 1 {
            for row in 0...tableView.numberOfRowsInSection(section) - 1 {
                let indexPath = NSIndexPath(forRow: row, inSection: section)
                
                let cell = tableView.cellForRowAtIndexPath(indexPath)
                cell?.selectedBackgroundView = selectedBackgroundView
            }
        }
        
        // Change this navigation controller only
        navigationController?.navigationBar.barTintColor = AppTheme.darkGrayColor
        navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .Plain, target: nil, action: nil)
        
        // Remove navigation bar border
        navigationController?.navigationBar.shadowImage = UIImage()
        navigationController?.navigationBar.setBackgroundImage(UIImage(), forBarMetrics: .Default)
    }
    
    // MARK: - Table view delegate
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        // TODO: implement
        if indexPath.section == 0 && indexPath.row == 0 {
            presentNameFootprintAlertController(indexPath)
        }
        
        if indexPath.section == 1 {
            if indexPath.row == 0 {
                presentTakeOrChoosePictureAlertController(indexPath)
            }
            
            if indexPath.row == 1 {
                presentRecordAudioAlertController(indexPath)
            }
        }
    }
    
    override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        if DeviceModel.iPhone4 || DeviceModel.iPhone5 {
            return 44.0
        } else {
            return 66.0
        }
    }
    
    // MARK: - Navigation
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        let destinationViewController = segue.destinationViewController
        // TODO: implement
//        if destinationViewController is TextNoteViewController {
//            (destinationViewController as! TextNoteViewController).delegate = self
//        }
//        
//        if destinationViewController is SearchPlaceViewController {
//            (destinationViewController as! SearchPlaceViewController).delegate = self
//        }
//        
//        if destinationViewController is SelectDateViewController {
//            (destinationViewController as! SelectDateViewController).delegate = self
//        }
        
        if destinationViewController is RecordAudioViewController {
            (destinationViewController as! RecordAudioViewController).delegate = self
        }
    }
    
    // MARK: - Name footprint methods
    
    private func presentNameFootprintAlertController(indexPath: NSIndexPath) {
        weak var weakSelf = self
        
        let alert = UIAlertController(title: "Name your Footprint", message: nil, preferredStyle: .Alert)
        
        let addAction = UIAlertAction(title: "Name It", style: .Cancel) { action in
            dispatch_async(dispatch_get_main_queue()) {
                weakSelf?.tableView.deselectRowAtIndexPath(indexPath, animated: true)
                weakSelf?.footprint.title = alert.textFields?.first?.text
                weakSelf?.addTitleLabel.text = weakSelf?.footprint.title
                weakSelf?.saveButton.enabled = true
            }
        }
        addAction.enabled = false
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .Default) { action in
            dispatch_async(dispatch_get_main_queue()) {
                weakSelf?.tableView.deselectRowAtIndexPath(indexPath, animated: true)
            }
        }
        
        alert.addTextFieldWithConfigurationHandler { (textField) in
            textField.autocapitalizationType = .Words
            textField.spellCheckingType = .Yes
            textField.autocorrectionType = .Yes
            textField.placeholder = "My Most Amazing Moment"
            textField.keyboardAppearance = .Dark
            textField.clearButtonMode = .WhileEditing
            
            NSNotificationCenter.defaultCenter().addObserverForName(UITextFieldTextDidChangeNotification, object: textField, queue: NSOperationQueue.mainQueue()) { (notification) in
                addAction.enabled = textField.text?.characters.count > 0
            }
        }
        
        alert.addAction(addAction)
        alert.addAction(cancelAction)
        
        presentViewController(alert, animated: true, completion: nil)
    }
    
    // MARK: - Take or choose picture methods
    
    private func presentTakeOrChoosePictureAlertController(indexPath: NSIndexPath) {
        let alert = UIAlertController(title: nil, message: nil, preferredStyle: .ActionSheet)
        alert.view.tintColor = AppTheme.disabledColor
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .Cancel) { action in
            self.tableView.deselectRowAtIndexPath(indexPath, animated: true)
        }
        
        let libraryAction = UIAlertAction(title: "Photo Library", style: .Default) { action in
            let imagePickerController = UIImagePickerController()
            imagePickerController.navigationBar.barTintColor = AppTheme.darkGrayColor
            imagePickerController.delegate = self
            imagePickerController.sourceType = .PhotoLibrary
            imagePickerController.mediaTypes = [String(kUTTypeImage)]
            imagePickerController.allowsEditing = true
            
            self.presentViewController(imagePickerController, animated: true) {
                self.tableView.deselectRowAtIndexPath(indexPath, animated: true)
            }
        }
        
        let takeAction = UIAlertAction(title: "Take Photo", style: .Default) { action in
            let imagePickerController = UIImagePickerController()
            imagePickerController.navigationBar.barTintColor = AppTheme.darkGrayColor
            imagePickerController.delegate = self
            imagePickerController.sourceType = .Camera
            imagePickerController.mediaTypes = [String(kUTTypeImage)]
            imagePickerController.allowsEditing = true
            
            self.presentViewController(imagePickerController, animated: true) {
                self.tableView.deselectRowAtIndexPath(indexPath, animated: true)
            }
        }
        
        let removeAction = UIAlertAction(title: "Remove", style: .Destructive) { action in
            self.userPicture = nil
            self.pictureImageView.image = UIImage(named: "camera")
            self.tableView.deselectRowAtIndexPath(indexPath, animated: true)
        }
        
        if userPicture != nil {
            alert.addAction(removeAction)
        }
        
        alert.addAction(cancelAction)
        
        if PHPhotoLibrary.authorizationStatus() == .Authorized || PHPhotoLibrary.authorizationStatus() == .NotDetermined {
            alert.addAction(libraryAction)
        }
        
        if UIImagePickerController.isSourceTypeAvailable(.Camera) {
            alert.addAction(takeAction)
        }
        
        presentViewController(alert, animated: true, completion: nil)
    }
    
    // MARK: - Record audio methods
    
    private func presentRecordAudioAlertController(indexPath: NSIndexPath) {
        let alert = UIAlertController(title: nil, message: nil, preferredStyle: .ActionSheet)
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .Cancel) { action in
            self.tableView.deselectRowAtIndexPath(indexPath, animated: true)
        }
        
        let recordAction = UIAlertAction(title: "Record", style: .Default) { action in
            self.performSegueWithIdentifier("recordAudioCreateSegue", sender: nil)
        }
        
        let playAction = UIAlertAction(title: "Play", style: .Default) { action in
            dispatch_async(dispatch_get_main_queue()) {
                do {
                    self.audioSession = AVAudioSession.sharedInstance()
                    try self.audioSession.setActive(true)
                    try self.audioSession.setCategory(AVAudioSessionCategoryPlayback, withOptions: .DuckOthers)
                    
                    let audioData = try NSData(contentsOfURL: self.footprint.audio!, options: .MappedRead)
                    
                    self.audioPlayer = try AVAudioPlayer(data: audioData)
                    self.audioPlayer.delegate = self
                    self.audioPlayer.play()
                } catch {
                    NSLog("\(error)")
                }
            }
        }
        
        let removeAction = UIAlertAction(title: "Remove", style: .Destructive) { action in
            self.footprint.audio = nil
        }
        
        alert.addAction(cancelAction)
        
        if self.footprint.audio != nil {
            alert.addAction(removeAction)
            alert.addAction(playAction)
        }
        
        alert.addAction(recordAction)
        
        presentViewController(alert, animated: true, completion: nil)
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
    }
}

// MARK: - Image picker controller delegate

extension CreateFootprintTableViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    func imagePickerController(picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : AnyObject]) {
        userPicture = info[UIImagePickerControllerEditedImage] as? UIImage
        pictureImageView.image = userPicture
        
        picker.dismissViewControllerAnimated(true) {
            self.view.setNeedsDisplay()
            self.view.setNeedsLayout()
            self.view.layoutIfNeeded()
        }
    }
    
    func imagePickerControllerDidCancel(picker: UIImagePickerController) {
        picker.dismissViewControllerAnimated(true) {
            self.tableView.deselectRowAtIndexPath(NSIndexPath(forRow: 0, inSection: 2), animated: true)
            self.tableView.deselectRowAtIndexPath(NSIndexPath(forRow: 1, inSection: 2), animated: true)
            
            self.view.setNeedsDisplay()
            self.view.setNeedsLayout()
            self.view.layoutIfNeeded()
        }
    }
    
}

// MARK: - Audio player delegate

extension CreateFootprintTableViewController: AVAudioPlayerDelegate {
    
    func audioPlayerBeginInterruption(player: AVAudioPlayer) {
        do {
            try audioSession.setActive(false)
        } catch {
            let error = error as NSError
            NSLog("\(error), \(error.userInfo)")
        }
    }
    
    func audioPlayerEndInterruption(player: AVAudioPlayer, withFlags flags: Int) {
        if flags == AVAudioSessionInterruptionFlags_ShouldResume {
            player.play()
        }
    }
    
    func audioPlayerDidFinishPlaying(player: AVAudioPlayer, successfully flag: Bool) {
        do {
            try audioSession.setActive(false)
            audioSession = nil
            audioPlayer = nil
        } catch {
            let error = error as NSError
            NSLog("\(error), \(error.userInfo)")
        }
    }

}
