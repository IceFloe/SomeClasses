//
//  SMLoadView.m
//

#import "SMLoadView.h"
#import "UIImage+ImageEffects.h"
#import "SMApiClient.h"

@interface SMLoadView()

@property (strong, nonatomic) UIImageView* blurView;
@property (strong, nonatomic) UIActivityIndicatorView* progressView;
@property (strong, nonatomic) NSMutableArray* observers;

@property (strong, nonatomic) UIButton* refreshButton;
@property (strong, nonatomic) UILabel* errorLabel;
@property (strong, nonatomic) UIView* errorView;

@end

@implementation SMLoadView

-(instancetype)init{
    self = [super init];
    
    if(self){
        
    }
    
    return self;
}

-(instancetype)initWithFrame:(CGRect)frame{
    self = [super initWithFrame:frame];
    if(self){
        [self addSubviews];
        [self defaultInit];
    }
    
    return self;
}

-(id)initWithCoder:(NSCoder *)aDecoder{
    self = [super initWithCoder:aDecoder];
    
    if(self){
        [self addSubviews];
        [self defaultInit];
    }
    
    return self;
}

-(void)setStyle:(SMLoadViewStyle)style{
    if (style == SMLoadViewLightStyle) {
        self.progressView.color = [UIColor blackColor];
    }
    
    if (style == SMLoadViewDarkStyle) {
        self.progressView.color = [UIColor whiteColor];
    }
}

-(void)defaultInit{
    self.hidden = YES;
    self.alpha = 0;
    self.isShowAlertView = YES;
    self.isShowErrorView = NO;
    self.translatesAutoresizingMaskIntoConstraints = NO;
    self.observers = [[NSMutableArray alloc] init];
}


-(void)addToView:(UIView *)superView{
    [superView addSubview:self];
    

    UIView* view = self;

    NSDictionary *views = NSDictionaryOfVariableBindings(view);
    [superView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"|-0-[view]-0-|" options:0 metrics:nil views:views]];
    [superView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-0-[view]-0-|" options:0 metrics:nil views:views]];
}

-(void)setTask:(NSURLSessionDataTask *)task animated:(BOOL)animated{
    
    if (!self.superview) {
        NSLog(@"Pls add view to superview");
        return;
    }
    
    NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
    
    [self clearObservers];
    
    if (task) {
        if (task.state != NSURLSessionTaskStateCompleted) {
            if (task.state == NSURLSessionTaskStateRunning) {
                [self startAnimating:animated];
            } else {
                [self stopAnimating:animated];
            }
            
            [self.observers addObject:[notificationCenter addObserverForName:AFNetworkingTaskDidResumeNotification object:task
                                                                       queue:[NSOperationQueue mainQueue]
                                                                  usingBlock:^(NSNotification *note) {
                                                                      [self startAnimating:animated];
                                                                  }]];
            [self.observers addObject:[notificationCenter addObserverForName:AFNetworkingTaskDidCompleteNotification object:task
                                                             queue:[NSOperationQueue mainQueue]
                                                        usingBlock:^(NSNotification *note) {
                                                            [self processTaskComplete:note animated:animated task:task];
                                                        }]];
            [self.observers addObject:[notificationCenter addObserverForName:AFNetworkingTaskDidSuspendNotification object:task
                                                             queue:[NSOperationQueue mainQueue]
                                                        usingBlock:^(NSNotification *note) {
                                                            [self stopAnimating:animated];
                                                        }]];
        } else {
            [self stopAnimating:animated];
        }
    } else {
        [self stopAnimating:animated];
    }
}

-(void)processTaskComplete:(NSNotification*)note animated:(BOOL)animated task:(NSURLSessionDataTask*)task{
    NSError* error;
    if (note.userInfo[AFNetworkingTaskDidCompleteErrorKey]) {
        error = [[SMApiClient apiClient] checkError:nil serviceName:nil isSendToGA:NO];
    }
    if (note.userInfo[AFNetworkingTaskDidCompleteSerializedResponseKey]) {
        error = [[SMApiClient apiClient] checkError:note.userInfo[AFNetworkingTaskDidCompleteSerializedResponseKey] serviceName:nil isSendToGA:NO];
    }
    
    if (self.isShowAlertView) {
        if (error) {
            [[SMApiClient apiClient] showHttpErrorAlert:error];
        }
    }
    
    if (self.isShowErrorView){
        if (error) {
            [self showErrorView:animated];
        } else {
            [self stopAnimating:animated];
        }
    } else{
        if(![task.taskDescription isEqualToString:@"isLongTask"] || error) [self stopAnimating:animated];
    }
}

-(void)showErrorView:(BOOL)animated{
    self.errorView.hidden = NO;
    self.errorLabel.text = self.errorMessage;
    [self.progressView stopAnimating];
    self.progressView.hidden = YES;
    
    if(animated){
        [UIView animateWithDuration:0.25 animations:^{
            self.errorView.alpha = 1;
        } completion:^(BOOL finished) {
            
        }];
    } else{
        self.errorView.alpha = 1;
    }
}

-(void)refresh:(id)sender{
    if (self.refreshBlock) {
        self.errorView.hidden = YES;
        self.errorView.alpha = 0;
        self.refreshBlock();
    }
}

-(void)show{
    [self startAnimating:YES];
}

-(void)hide{
    [self stopAnimating:YES];
}

- (void)startAnimating:(BOOL)animated {
    if (self.progressView.isAnimating) {
        return;
    }
    self.hidden = NO;
    if (self.progressView.hidden) {
        self.progressView.hidden = NO;
    }
    
    if (!self.blurView.image) {
        UIGraphicsBeginImageContextWithOptions(self.superview.bounds.size, NO, self.window.screen.scale);
        [self.superview drawViewHierarchyInRect:self.superview.frame afterScreenUpdates:YES];
        UIImage *snapshotImage = UIGraphicsGetImageFromCurrentImageContext();
        UIImage *blurredSnapshotImage;
        if (self.style == SMLoadViewLightStyle) {
            blurredSnapshotImage = [snapshotImage applyLightEffect];
        } else {
            blurredSnapshotImage = [snapshotImage applyDarkEffect];
        }
        UIGraphicsEndImageContext();
        
        self.blurView.image = blurredSnapshotImage;
    }
    
    [self.progressView startAnimating];
    
    if (animated) {
        [UIView animateWithDuration:0.25 animations:^{
            self.alpha = 1;
        } completion:^(BOOL finished) {
            
        }];
    }else{
        self.alpha = 1;
    }
}

- (void)stopAnimating:(BOOL)animated {
    if (animated) {
        [UIView animateWithDuration:0.25 animations:^{
            self.alpha = 0;
        } completion:^(BOOL finished) {
            self.hidden = YES;
            self.blurView.image = nil;
        }];
    } else {
        self.alpha = 0;
        self.hidden = YES;
        self.blurView.image = nil;
    }
    [self.progressView stopAnimating];  
}

-(void)clearObservers{
    for (id object in self.observers) {
        [[NSNotificationCenter defaultCenter] removeObserver:object];
    }
}

-(void)dealloc{
    [self clearObservers];
}

-(void)addSubviews{
    
    ////////Blur
    self.blurView = [[UIImageView alloc] init];
    self.blurView.translatesAutoresizingMaskIntoConstraints = NO;
    [self addSubview:self.blurView];
    
    UIView* blurView = self.blurView;
    NSDictionary *views = NSDictionaryOfVariableBindings(blurView);
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"|-0-[blurView]-0-|" options:0 metrics:nil views:views]];
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-0-[blurView]-0-|" options:0 metrics:nil views:views]];
    
    ////////Progress
    self.progressView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
    self.progressView.translatesAutoresizingMaskIntoConstraints = NO;
    self.progressView.color = [UIColor blackColor];

    [self addSubview:self.progressView];
    
    UIView* progressView = self.progressView;
    UIView *superview = self;
    views = NSDictionaryOfVariableBindings(progressView, superview);
    NSArray *constraints =
    [NSLayoutConstraint constraintsWithVisualFormat:@"V:[superview]-(<=1)-[progressView]"
                                            options: NSLayoutFormatAlignAllCenterX
                                            metrics:nil
                                              views:views];
    [self addConstraints:constraints];
    
    constraints =
    [NSLayoutConstraint constraintsWithVisualFormat:@"H:[superview]-(<=1)-[progressView]"
                                            options: NSLayoutFormatAlignAllCenterY
                                            metrics:nil
                                              views:views];
    [self addConstraints:constraints];
    
    ////////ErrorView
    
    self.errorView = [[UIView alloc] init];
    self.errorView.translatesAutoresizingMaskIntoConstraints = NO;
    [self addSubview:self.errorView];
    
    self.errorLabel = [[UILabel alloc] init];
    self.errorLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [self.errorView addSubview:self.errorLabel];
    
    UIView* errorView = self.errorView;
    self.errorView.hidden = YES;
    self.errorView.alpha = 0;
    
    views = NSDictionaryOfVariableBindings(errorView, superview);
    constraints = [NSLayoutConstraint constraintsWithVisualFormat:@"V:[superview]-(<=1)-[errorView]"
                                                          options: NSLayoutFormatAlignAllCenterX
                                                          metrics:nil
                                                            views:views];
    [self addConstraints:constraints];
    
    constraints = [NSLayoutConstraint constraintsWithVisualFormat:@"H:[superview]-(<=1)-[errorView]"
                                                          options: NSLayoutFormatAlignAllCenterY
                                                          metrics:nil
                                                            views:views];
    [self addConstraints:constraints];
    
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"|-0-[errorView]-0-|" options:0 metrics:nil views:views]];
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:[errorView(>=74)]" options:0 metrics:nil views:views]];
    
    ////////Label
    
    UILabel* errorLabel = self.errorLabel;
    self.errorLabel.textAlignment = NSTextAlignmentCenter;
    self.errorLabel.numberOfLines = 0;
    views = NSDictionaryOfVariableBindings(errorView, errorLabel);
    
    [self.errorView addConstraint:[NSLayoutConstraint constraintWithItem:errorLabel
                                                               attribute:NSLayoutAttributeCenterX
                                                               relatedBy:NSLayoutRelationEqual
                                                                  toItem:errorView
                                                               attribute:NSLayoutAttributeCenterX
                                                              multiplier:1.0 constant:0.0]];
    
    constraints = [NSLayoutConstraint constraintsWithVisualFormat:@"|-5-[errorLabel]-5-|"
                                                          options: 0
                                                          metrics:nil
                                                            views:views];
    [self.errorView addConstraints:constraints];
    
    constraints = [NSLayoutConstraint constraintsWithVisualFormat:@"V:|-8-[errorLabel(>=20)]"
                                                          options: 0
                                                          metrics:nil
                                                            views:views];
    [self.errorView addConstraints:constraints];
    
    ////////Button
    
    self.refreshButton = [UIButton buttonWithType:UIButtonTypeSystem];
    self.refreshButton.translatesAutoresizingMaskIntoConstraints = NO;
    [self.refreshButton setTitle:@"Refresh" forState:UIControlStateNormal];
    [self.refreshButton addTarget:self action:@selector(refresh:) forControlEvents:UIControlEventTouchUpInside];
    [self.errorView addSubview:self.refreshButton];
    
    UIButton* refreshButton = self.refreshButton;
    views = NSDictionaryOfVariableBindings(errorView, refreshButton, errorLabel);
    
    [self.errorView addConstraint:[NSLayoutConstraint constraintWithItem:refreshButton
                                                               attribute:NSLayoutAttributeCenterX
                                                               relatedBy:NSLayoutRelationEqual
                                                                  toItem:errorView
                                                               attribute:NSLayoutAttributeCenterX
                                                              multiplier:1.0 constant:0.0]];
    
    constraints = [NSLayoutConstraint constraintsWithVisualFormat:@"[refreshButton(130)]"
                                                          options: 0
                                                          metrics:nil
                                                            views:views];
    
    [self.errorView addConstraints:constraints];
    
    constraints = [NSLayoutConstraint constraintsWithVisualFormat:@"V:[errorLabel]-8-[refreshButton(30)]-7-|"
                                                          options: 0
                                                          metrics:nil
                                                            views:views];
    
    [self.errorView addConstraints:constraints];
}

@end
