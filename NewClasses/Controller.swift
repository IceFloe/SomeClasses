//
//  NewChallengeDescrController.swift
//  Runch
//
//  Created by Alex Gurin on 8/16/16.
//  Copyright © 2016 Alex Gurin. All rights reserved.
//

import UIKit
import SDCAlertView

class NewChallengeDescrController: UIViewController, BaseViewController {
    
    fileprivate var viewModel = NewChallengeViewModel()
    var delegate: NewChallengeDelegate? {
        didSet{
            viewModel.delegate = delegate
        }
    }
    
    var challenge: Challenge! {
        set {
            viewModel.update(newValue)
        }
        get {
            return viewModel.challenge.value
        }
    }
    
    @IBOutlet weak var closeBtn: UIButton!
    @IBOutlet weak var forwardBtn: UIButton!
    
    @IBOutlet weak var titleLbl: UILabel!
    @IBOutlet weak var subtitleLbl: UILabel!
    @IBOutlet weak var nameLbl: UILabel!
    @IBOutlet weak var descriptionLbl: UILabel!
    @IBOutlet weak var challengeLbl: UILabel!
    @IBOutlet weak var nameCountLbl: UILabel!
    @IBOutlet weak var descriptionCountLbl: UILabel!
    
    @IBOutlet weak var nameFld: InsetTextField!
    @IBOutlet weak var descriptionFld: UITextView!
    @IBOutlet weak var challengeImg: UIImageView!
    
    @IBOutlet weak var scrollView: UIScrollView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.titleLbl.configure(UIFont.runchSmallHead(), color: UIColor.runchLightBlack())
        self.subtitleLbl.configure(UIFont.runchNormal(), color: UIColor.runchLightBlack())
        self.nameLbl.configure(UIFont.runchNormal(), color: UIColor.runchLightBlack())
        self.descriptionLbl.configure(UIFont.runchNormal(), color: UIColor.runchLightBlack())
        self.challengeLbl.configure(UIFont.runchNormal(), color: UIColor.runchLightBlack())
        self.nameCountLbl.configure(UIFont.runchNormal(), color: UIColor.runchLightBlack())
        self.descriptionCountLbl.configure(UIFont.runchNormal(), color: UIColor.runchLightBlack())
        self.nameFld.configure(UIFont.runchBigHead(), color: UIColor.runchLightBlack())
        self.descriptionFld.configure(UIFont.runchMedium(), color: UIColor.runchLightBlack())
        self.descriptionFld.textContainerInset = UIEdgeInsetsMake(20, 8, 20, 8)
        
        self.challengeImg.layer.cornerRadius = RunchConstants.CornerRadius
        self.challengeImg.layer.masksToBounds = true
        self.challengeImg.clipsToBounds = true
        self.challengeImg.backgroundColor = UIColor.runchLightGray()
        
        self.nameFld.delegate = self
        self.descriptionFld.delegate = self
        
        self.bindModel()
        self.baseBinding(from: viewModel)
        
        self.scrollView.handleKeyboard()
    }
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        if self.viewModel.challengeImg.value == nil {
            self.challengeImg.addDashedBorder()
        }
    }
    
    func bindModel() {
        viewModel.title.bind(to: self.titleLbl.reactive.text)
        viewModel.descrSubTitle.bind(to: self.subtitleLbl.reactive.text)
        viewModel.nameLbl.bind(to: self.nameLbl.reactive.text)
        viewModel.descrLbl.bind(to: self.descriptionLbl.reactive.text)
        viewModel.challengeImageDescr.bind(to: self.challengeLbl.reactive.text)
        viewModel.rightButtonImage.bind(to: self.forwardBtn.reactive.image)
        viewModel.challengeImg.map { (image) -> UIImage in
            if let image = image {
                self.challengeImg.clearSublayers()
                self.challengeImg.contentMode = .scaleAspectFill
                return image
            } else {
                return R.image.no_photo()!
            }
        }.bind(to: self.challengeImg.reactive.image)
        
        _ = self.forwardBtn.reactive.tap.observe { (event) in
            if let challenge = self.viewModel.challenge.value, challenge.enabled! {
                self.save(self.forwardBtn)
            } else {
                self.nextStep(self.forwardBtn)
            }
        }
        
        self.nameFld.reactive.text.map {
            self.viewModel.charactersLeft($0, startedValue: self.viewModel.titleRestriction)
        }.bind(to: self.nameCountLbl.reactive.text)
        viewModel.challengeName.bidirectionalBind(to: self.nameFld.reactive.text)
        
        self.descriptionFld.reactive.text.map {
            self.viewModel.charactersLeft($0, startedValue: self.viewModel.descrRestriction)
        }.bind(to: self.descriptionCountLbl.reactive.text)
        viewModel.challengeDescr.bidirectionalBind(to: self.descriptionFld.reactive.text)
    }
    
    @IBAction func close(_ sender: UIButton) {
        AlertController.cancelCreateChallengeAlert { (action) in
            self.dismiss(animated: true, completion: nil)
        }
    }
    
    @IBAction func save(_ sender: UIButton) {
        viewModel.saveChallenge { (challenge) in
            self.dismiss(animated: true, completion: {
                self.viewModel.delegate?.didCreate(newChallenge: challenge)
            })
        }
    }

    @IBAction func nextStep(_ sender: UIButton) {
        if !self.viewModel.validateRequiredDescrVars() {
            return
        }
        
        self.performSegue(withIdentifier: R.segue.newChallengeDescrController.next_step.identifier, sender: self)
    }
    
    @IBAction func chooseImageForChallenge(_ sender: AnyObject) {
        self.performSegue(withIdentifier: R.segue.newChallengeDescrController.choose_image.identifier, sender: self)
    }
    
    deinit {
        self.scrollView.removeKeyboardHandling()
    }
}

extension NewChallengeDescrController {
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let typedInfo = R.segue.newChallengeDescrController.choose_image(segue: segue) {
            if let vc = typedInfo.destination.topViewController as? ImagePickerViewController {
                vc.nav_title = R.string.localizable.challenge_image_caps()
                vc.delegate = self
            }
        }
        if let typedInfo = R.segue.newChallengeDescrController.next_step(segue: segue) {
            typedInfo.destination.viewModel = self.viewModel
        }
    }
}

extension NewChallengeDescrController: ImagePickerViewControllerDelegate {
    func imagePicker(_ picker: ImagePickerViewController, didPickImage image: UIImage) {
        self.viewModel.updateChallengeImage(image)
    }
}

extension NewChallengeDescrController: UITextFieldDelegate {
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        return textField.restrictLength(range, replacementString: string, numberOfSymbols: viewModel.titleRestriction)
    }
}

extension NewChallengeDescrController: UITextViewDelegate {
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        return textView.restrictLength(range, replacementString: text, numberOfSymbols: viewModel.descrRestriction)
    }
}
