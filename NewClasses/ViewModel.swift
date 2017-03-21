//
//  NewChallengeViewModel.swift
//  Runch
//
//  Created by Alex Gurin on 8/16/16.
//  Copyright © 2016 Alex Gurin. All rights reserved.
//

import UIKit
import Bond
import Alamofire
import MapKit
import AlamofireImage

protocol NewChallengeDelegate {
    func didCreate(newChallenge: Challenge)
}

class NewChallengeViewModel: BaseDataModel {
    
    var delegate: NewChallengeDelegate?
    
    internal fileprivate(set) var title = Observable(R.string.localizable.new_challenge())
    internal fileprivate(set) var state: Observable<DataModelState> = Observable(.none)
    
    internal fileprivate(set) var challenge: Observable<Challenge?> = Observable(nil)
    internal fileprivate(set) var imageWasUpdated: Bool = false
    
    //MARK: Description Vars
    internal fileprivate(set) var challengeImg: Observable<UIImage?> = Observable(nil)
    internal fileprivate(set) var challengeName: Observable<String?> = Observable(nil)
    internal fileprivate(set) var challengeDescr: Observable<String?> = Observable(nil)
    internal fileprivate(set) var imageRequest: Request?
    
    let rightButtonImage: Observable<UIImage?> = Observable(R.image.forward_button()!)
    let descrSubTitle = Observable(R.string.localizable.description())
    let nameLbl = Observable(R.string.localizable.title())
    let descrLbl = Observable(R.string.localizable.short_description())
    let challengeImageDescr = Observable(R.string.localizable.challenge_image())
    let titleRestriction = RunchConstants.NewChallenge.TitleNumberOfSymbols
    let descrRestriction = RunchConstants.NewChallenge.DescrNumberOfSymbols
    
    //MARK: Goal Vars
    let goalSubTitle = Observable(R.string.localizable.goal())
    let daysMin = RunchConstants.NewChallenge.DaysMin
    let daysMax = RunchConstants.NewChallenge.DaysMax
    let distanceMin = RunchConstants.NewChallenge.DistanceMin
    let distanceMax = RunchConstants.NewChallenge.DistanceMax
    let timesMin = RunchConstants.NewChallenge.TimesMin
    let timesMax = RunchConstants.NewChallenge.TimesMax
    let minDateStart = Date().addingTimeInterval(60*60*24*10)
    
    internal fileprivate(set) var challengeDays: Observable<Int> = Observable(Int(RunchConstants.NewChallenge.DaysMin))
    internal fileprivate(set) var challengeKm: Observable<Int> = Observable(Int(RunchConstants.NewChallenge.DistanceMin))
    internal fileprivate(set) var challengeTimes: Observable<Int> = Observable(Int(RunchConstants.NewChallenge.TimesMin))
    
    //MARK: Detail Vars
    let detailsSubTitle = Observable(R.string.localizable.details())
    let priceTitle = Observable(R.string.localizable.price())
    let locationTitle = Observable(R.string.localizable.your_location())
    let dateAndTimeTitle = Observable(R.string.localizable.date_and_time())
    
    internal fileprivate(set) var challengePrice: Observable<Double?> = Observable(nil)
    internal fileprivate(set) var challengeLocation: Observable<City?> = Observable(nil)
    internal fileprivate(set) var challengeDate: Observable<Date?> = Observable(Date().addingTimeInterval(60*60*24*10))
    
    //MARK: Business logic
    func update(_ challenge: Challenge) {
        self.challenge.next(challenge)
        if challenge.enabled! {
            rightButtonImage.next(R.image.checkmark()!)
        }
        challengeName.next(challenge.name)
        challengeDescr.next(challenge.description)
        challengeDays.next(challenge.days)
        challengeKm.next(challenge.kmPerRun)
        challengeTimes.next(challenge.howManyTimes)
        challengePrice.next(challenge.amount)
        challengeLocation.next(challenge.city)
        challengeDate.next(challenge.startDate)

        if let backgroundImgUrl = challenge.backgroundImg {
            let imageDowloader = UIImageView.af_sharedImageDownloader
            let urlRequest = URLRequest(url: backgroundImgUrl)
            imageRequest = imageDowloader.download(urlRequest, completion: { (response) in
                switch response.result {
                case .success(let image):
                    self.challengeImg.next(image)
                case .failure:()
                }
            })?.request
        }
    }
    
    func charactersLeft(_ string: String?, startedValue: Int) -> String {
        return "\(startedValue - (string?.characters.count ?? 0))"
    }
    
    func updateChallengeImage(_ image: UIImage) {
        imageWasUpdated = true
        challengeImg.next(image)
    }
    
    func validateRequiredDescrVars() -> Bool {
        
        if challengeName.value == nil || challengeName.value?.characters.count == 0
        {
            self.state.next(.error(R.string.localizable.validation_name()))
            return false
        }
        
        if challengeDescr.value == nil || challengeDescr.value?.characters.count == 0
        {
            self.state.next(.error(R.string.localizable.validation_description()))
            return false
        }
        
        if challengeImg.value == nil && imageRequest?.task?.state != .running {
            self.state.next(.error(R.string.localizable.validation_image()))
            return false
        }
        
        return true
    }
    
    func validateRequiredDetailsVars() -> Bool {
        if challengeLocation.value == nil {
            self.state.next(.error(R.string.localizable.validation_location()))
            return false
        }
        
        if challengePrice.value == nil {
            self.state.next(.error(R.string.localizable.validation_price()))
            return false
        }
        
        return true
    }
    
    static func transformDaysIntoString(_ days: Float) -> NSAttributedString {
        let stringValue = R.string.localizable.dDayS(days: Int(days))
        var attributedString = stringValue.attributed(.font(UIFont.runchHead()))
        attributedString = attributedString.add(.font(UIFont.runchHeadBold()), toString: "\(Int(days))")
        return attributedString
    }
    
    func transformDistanceIntoString(_ distance: Float) -> NSAttributedString {
        let stringValue = R.string.localizable.km_per_one_time(Int(distance))
        var attributedString = stringValue.attributed(.font(UIFont.runchHead()))
        attributedString = attributedString.add(.font(UIFont.runchHeadBold()), toString: "\(Int(distance))")
        return attributedString
    }
    
    func transformTimesIntoString(_ times: Float) -> NSAttributedString {
        let stringValue = R.string.localizable.timeS(times: Int(times))
        var attributedString = stringValue.attributed(.font(UIFont.runchHead()))
        attributedString = attributedString.add(.font(UIFont.runchHeadBold()), toString: "\(Int(times))")
        return attributedString
    }
    
    func transformSummaryIntoString(_ days: Float, distance: Int, times: Int) -> NSAttributedString {
        var attributedString = Challenge.summaryAttributedString(Int(days), distance: distance*times, commonFont: UIFont.runchHead())
        attributedString = attributedString
            .add(.foregroundColor(Challenge.сolorForDistance(Double(distance*times))),
                 toString: attributedString.string)
        
        return attributedString
    }
    
    func transformDificultyIntoString(_ distance: Int, times: Int) -> NSAttributedString {
        var attributedString = Challenge.stringForDistance(Double(distance*times)).attributed(.font(UIFont.runchNormal()))
        attributedString = attributedString
            .add(.foregroundColor(Challenge.сolorForDistance(Double(distance*times))),
                 toString: attributedString.string)
        
        return attributedString
    }
    
    func autoCompleteLocationField(_ presenter: UIViewController) {
        if self.challengeLocation.value != nil {
            return;
        }
        
        let locationManager = SessionStore.shared.locationManager
        locationManager.isLocationEnabled { (enabled) in
            if !enabled {
                locationManager.showNeedAccessMessage(presenter, completion: { (enabled) in
                    if enabled {
                       self.getLocationAndReverseIt()
                    } else {
                        self.state.next(.error(R.string.localizable.location_authorize()))
                    }
                })
            } else {
                self.getLocationAndReverseIt()
            }
        }
    }
    
    fileprivate func getLocationAndReverseIt() {
        let locationManager = SessionStore.shared.locationManager
        let sessionManager = SessionStore.shared.sessionManager
        self.state.next(.loading)
        locationManager.requestLocation { (result) in
            switch result {
            case .success(let location):
                var lang = Locale.preferredLanguages[0]
                lang = lang.substring(to: lang.index(lang.startIndex, offsetBy: 2))

                sessionManager.request(ServiceRouter.getCity(lang: lang,
                                                             lat: location.coordinate.latitude,
                                                             lng: location.coordinate.longitude))
                    .validate()
                    .responseArray(keyPath: "cities") { [weak self] (response: DataResponse<[City]>) in
                        guard let strongSelf = self else { return }
                        switch response.result {
                        case .success(let cities):
                            strongSelf.state.next(.none)
                            if cities.count > 0 {
                                strongSelf.challengeLocation.next(cities[0])
                            }
                            break;
                        case .failure(let error):
                            strongSelf.state.next(.error(error.localizedDescription))
                        }
                }
            case .failure(let error):
                self.state.next(.error(error.localizedDescription))
            }
        }
    }
    
    func generateRequest() -> [String: Any] {
        if let challenge = challenge.value {
            return generateUpdateChallengeRequest(challenge: challenge)
        } else {
            return generateNewChallengeRequest()
        }
    }
    
    func generateNewChallengeRequest() -> [String: Any] {
        var parameters = [String: Any]()
        
        parameters["title"] = self.challengeName.value!
        parameters["descr"] = self.challengeDescr.value!
        parameters["start_ts"] = self.challengeDate.value!.serviceFormat()
        parameters["days"] = self.challengeDays.value
        parameters["amount"] = self.challengePrice.value!
        parameters["ccy"] = "UAH"
        parameters["city_id"] = self.challengeLocation.value!.identifier
        parameters["km_per_run"] = self.challengeKm.value
        parameters["how_many_times"] = self.challengeTimes.value
        let compressedImage = self.challengeImg.value!.compress(1)
        let imageData: Data = UIImageJPEGRepresentation(compressedImage, 0.8)!
        let strBase64: String = imageData.base64EncodedString()
        parameters["bg_image"] = strBase64
        
        return parameters;
    }
    
    func generateUpdateChallengeRequest(challenge: Challenge) -> [String: Any] {
        var parameters = [String: Any]()
        
        if (challenge.name != self.challengeName.value!) {
            parameters["title"] = self.challengeName.value!
        }
        if (challenge.description != self.challengeDescr.value!) {
            parameters["descr"] = self.challengeDescr.value!
        }
        if (challenge.startDate != self.challengeDate.value!) {
            parameters["start_ts"] = self.challengeDate.value!.serviceFormat()
        }
        if (challenge.days != self.challengeDays.value) {
            parameters["days"] = self.challengeDays.value
        }
        if (challenge.amount != self.challengePrice.value!) {
            parameters["amount"] = self.challengePrice.value!
        }
        
        //We can't update this value for now
        //parameters["ccy"] = "UAH" as AnyObject
        
        if (challenge.city.identifier != self.challengeLocation.value!.identifier) {
            parameters["city_id"] = self.challengeLocation.value!.identifier
        }
        if (challenge.kmPerRun != self.challengeKm.value) {
            parameters["km_per_run"] = self.challengeKm.value
        }
        if (challenge.howManyTimes != self.challengeTimes.value) {
            parameters["how_many_times"] = self.challengeTimes.value as AnyObject
        }
        
        if (imageWasUpdated) {
            let compressedImage = self.challengeImg.value!.compress(1)
            let imageData: Data = UIImageJPEGRepresentation(compressedImage, 0.8)!
            let strBase64: String = imageData.base64EncodedString()
            parameters["bg_image"] = strBase64 as AnyObject
        }
        
        return parameters;
    }
    
    func saveChallenge(_ completion: @escaping (Challenge) -> Void) {
        self.state.next(.loading)
        let sessionManager = SessionStore.shared.sessionManager
        
        if let challenge = self.challenge.value {
            sessionManager.request(ServiceRouter.updateChallenge(challengeId: challenge.identifier, params: generateRequest()))
                .validate().responseObject(mapToObject: challenge) {[weak self] (response: DataResponse<Challenge>) in
                    guard let strongSelf = self else { return }
                    switch response.result {
                    case .success(let challenge):
                        strongSelf.state.next(.success(R.string.localizable.challenge_updated()))
                        completion(challenge)
                        break
                    case .failure (let error):
                        strongSelf.state.next(.error(error.localizedDescription))
                        break
                    }
            }

        } else {
            sessionManager.request(ServiceRouter.createChallenge(params: generateRequest()))
                .validate().responseObject {[weak self] (response: DataResponse<Challenge>) in
                    guard let strongSelf = self else { return }
                    switch response.result {
                    case .success(let challenge):
                        strongSelf.state.next(.success(R.string.localizable.challenge_published()))
                        completion(challenge)
                        break
                    case .failure (let error):
                        strongSelf.state.next(.error(error.localizedDescription))
                        break
                    }
            }
        }
    }
}
