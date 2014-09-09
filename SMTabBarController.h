//
//  SMTabBarController.h
//  SendMoney
//
//  Created by Алексей on 09.04.14.
//  Copyright (c) 2014 ua.privatbank. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "TransactionViewController.h"
#import "TemplateViewController.h"
#import "ArchiveViewController.h"
#import "SettingsViewController.h"

@interface SMTabBarController : UITabBarController

@property (strong, nonatomic) TransactionViewController* translationVC;
@property (strong, nonatomic) TemplateViewController* templateVC;
@property (strong, nonatomic) ArchiveViewController* archiveVC;
@property (strong, nonatomic) SettingsViewController* settings;
@property (assign, nonatomic) BOOL wasTemplatesLoaded;

@end
