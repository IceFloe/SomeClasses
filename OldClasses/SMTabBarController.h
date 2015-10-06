//
//  SMTabBarController.h
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
