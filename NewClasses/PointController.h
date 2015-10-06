//
//  PointController.h
//

#import <Foundation/Foundation.h>
#import "PointAnnotation.h"
#import "AreaManagementMapData.h"

@class PointController;
@class PointOperation;

@protocol PointControllerDelegate <NSObject>
@optional

-(void)pointController:(PointController*)pointController willAddPointOperation:(PointOperation*)operation;
-(void)pointControllerDidEndAllOperations:(PointController*)pointController;
-(void)pointController:(PointController*)pointController didAddPoint:(PointAnnotation*)point;
-(void)pointController:(PointController*)pointController didRemovePoint:(PointAnnotation*)point;

@end

@interface PointController : NSObject <PointAnnotationDelegate>

@property (assign, atomic) BOOL isPointOperationRunning;
@property (strong, atomic) NSMutableArray* pointOperations;
@property (weak, atomic) id<PointControllerDelegate> delegate;

- (instancetype)initWithAreaManagementData:(AreaManagementMapData*)data;

-(void)addAndRunOperationForPoint:(PointOperation*)operation inMap:(MKMapView *)mapView;
-(void)removePoint:(PointAnnotation*)point fromMap:(MKMapView*)mapView;
-(void)changePointType:(PointAnnotation*)point inMap:(MKMapView*)mapView;
-(void)changePointPosition:(PointAnnotation*)point inMap:(MKMapView*)mapView;
-(void)constructTemporaryPolygonInMap:(MKMapView *)mapView;
-(void)cancelPendingOperations;

@end

typedef NS_ENUM(NSInteger, AreaManagmentPointOperationType) {
    PointOperationAdd = 1,
    PointOperationDelete,
};

@interface PointOperation : NSObject

@property (assign, nonatomic) AreaManagmentPointOperationType operationType;
@property (strong, nonatomic) PointAnnotation* point;

@end
