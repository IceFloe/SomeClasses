//
//  SMTabBarController.m
//  SendMoney
//
//  Created by Алексей on 09.04.14.
//  Copyright (c) 2014 ua.privatbank. All rights reserved.
//

#import "SMTabBarController.h"
#import "SMDataLoader.h"
#import "AppDelegate.h"
#import "RecommPageViewController.h"
#import "Init.h"
#import "PushLibrary.h"
#import "SSKeychain+PIN.h"
#import "PinViewController.h"
#import "SMLoadView.h"
#import "SMApiClient.h"

@interface SMTabBarController ()

@property (strong, nonatomic) SMDataLoader* dataLoader;
@property (strong, nonatomic) SMLoadView* loadview;
@property (strong, nonatomic) SMApiClient* apiClient;
@property (assign, nonatomic) BOOL isLoadData;

@end

@implementation SMTabBarController
{
    BOOL isPinChecked;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.dataLoader = [SMDataLoader sharedInstance];
    self.loadview = [[SMLoadView alloc] init];
    [self.loadview addToView:self.view];
    
    self.apiClient = [SMApiClient apiClient];
    
    self.translationVC = self.viewControllers[0];
    self.templateVC = self.viewControllers[1];
    self.archiveVC = self.viewControllers[2];
    self.settings = self.viewControllers[3];
    
    self.tabBar.translucent = YES;
        
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(loadUserData) name:SMUserLoginNotification object:nil];
    
}

-(void)loadUserData{
    self.isLoadData = YES;
    if (!DMSsid){
        Init *init = [[Init alloc] init];
        [[SMApiClient dmsApiClient] getDMSSid:[init createJSONwithSid:[SMApiClient getImei]] success:^(NSURLSessionDataTask *task, NSDictionary* responseObject) {
            if ([responseObject objectForKey:@"sid"]){
                
                [[NSUserDefaults standardUserDefaults] setObject:[responseObject objectForKey:@"sid"] forKey:@"DmsSid"];
                [[NSUserDefaults standardUserDefaults] synchronize];
                [PushLibrary sendRegistrationTokenToURL:@"https://link.privatbank.ua/dms/commonSMART/regGCM" withSid:DMSsid];
            }
        } failure:nil];
    } else{
        [PushLibrary sendRegistrationTokenToURL:@"https://link.privatbank.ua/dms/commonSMART/regGCM" withSid:DMSsid];
    }
    
    [self.dataLoader getCardsFromDatabase:YES usingLoadView:nil completionBlock:^(NSArray *cards, NSError* error) {
        if (cards==nil || [cards count]==0) {
            [self.dataLoader refreshAllData:^{
                [self checkTemplates];
                [self checkForNewRecommendations];
            } withLoadView:self.loadview];
        }else{
            [self checkTemplates];
            [self checkForNewRecommendations];
//            [self.dataLoader refreshAllData:nil withLoadView:nil];
        }
    }];
}

-(void)checkTemplates{
    [self.dataLoader getTemplatesFromDatabase:YES usingLoadView:nil completionBlock:^(NSArray *templates, NSError* error) {
        if (!error && templates && templates.count>0) {
            [[NSNotificationCenter defaultCenter] postNotificationName:ReloadTemplateNotification object:nil];
            self.selectedIndex = 1;
        }
    }];
}

-(void)viewDidAppear:(BOOL)animated{
    
    [super viewDidAppear:animated];
    [self showOfferForComment];
    
    if(!isPinChecked) [self checkPin:pinState];
    
    if ([SMApiClient isUserLogin] && !self.isLoadData) {
        [self loadUserData];
    }
}

-(void) checkPin:(NSString*)pinStatus{
    
#ifdef DEBUG
    NSLog(@"Pin Status: %@", pinState);
#endif
    if ([SSKeychain isPinCodeExists] || [pinState isEqualToString:kPinActivated]) {
        PinViewController *pinVC = (PinViewController*)[self.storyboard instantiateViewControllerWithIdentifier:@"pin"];
        UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:pinVC];
        [self presentViewController:nav animated:NO completion:nil];
    }else if (!pinStatus || [pinStatus isEqualToString:kDidntLogIn]) {
        UINavigationController* login = [self.storyboard instantiateViewControllerWithIdentifier:@"login"];
        [self presentViewController:login animated:YES completion:nil];
    } else {
        
    }
    
    isPinChecked = YES;
}

- (void)showOfferForComment {
    AppDelegate* delegate = (AppDelegate*)[[UIApplication sharedApplication] delegate];
    if (!delegate.isShowOfferForComment
        && delegate.countSuccessSending >= 2) {
        UIAlertView* alert = [[UIAlertView alloc] initWithTitle:@"FEEDBACK".loc
                                                        message:@"WRITE_COMMENT".loc
                                                       delegate:self
                                              cancelButtonTitle:@"CANCEL".loc
                                              otherButtonTitles:@"FEEDBACK".loc, nil];
        [alert setDelegate:self];
        [alert setTag:222];
        [alert show];
    }
}

- (void)checkForNewRecommendations{
    if (!isShowRecommendations && [SMApiClient isUserLogin]){
        [self.apiClient getRecommendations:nil success:^(NSURLSessionDataTask *task, NSDictionary* responseObject) {
            NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
            [userDefaults setBool:YES forKey:@"AlreadyBeenLaunchedTemplates"];
            [userDefaults synchronize];
            
            NSArray *recommendationsDicts = [responseObject valueForKeyPath:@"list"];
            NSMutableArray* recommendations = [[NSMutableArray alloc] init];
            if (recommendationsDicts && recommendationsDicts.count>0) {
                
                for (NSDictionary* json in recommendationsDicts) {
                    Recommendation* recomm = [Recommendation initFromJson:json];
                    [recommendations addObject:recomm];
                }
                
//fix RecommPageViewController
//                RecommPageViewController *recom = [[RecommPageViewController alloc] initWithNibName:@"RecommPageViewController" bundle:nil];
//                recom.ownerName = [responseObject valueForKeyPath:@"fio"];
//                recom.recommendations = recommendations;
//                recom.isModal = YES;
//                [self presentViewController:recom.navController animated:YES completion:nil];
            }
        } failure:^(NSURLSessionDataTask *task, NSError *error) {
            
        }];
    }
}


#pragma mark - UIAlertViewDelegate
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    switch (alertView.tag) {
        case 222:
        {
            AppDelegate* delegate = (AppDelegate*)[[UIApplication sharedApplication] delegate];
            
            if (buttonIndex == 1) { //yes
                [[UIApplication sharedApplication] openURL:[NSURL URLWithString:RateLink7]];
            }
            delegate.isShowOfferForComment = YES;
            [delegate saveCountSuccessSending];
            break;
        }
        default:
            break;
    }
}

@end
