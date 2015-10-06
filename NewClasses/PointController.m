//
//  PointController.m
//

#import "PointController.h"
#import "TSMessage+Alert.h"
#import "PointAnnotationView.h"
#import "MapUtils.h"

@interface PointController()

@property (strong, nonatomic) AreaManagementMapData* data;
@property (assign, nonatomic) BOOL isPendingOperationsCanceled;

@end

@implementation PointController

-(instancetype)initWithAreaManagementData:(AreaManagementMapData *)data{
    self = [super init];
    
    if (self) {
        self.data = data;
        self.pointOperations = [[NSMutableArray alloc] init];
    }
    
    return self;
}

#pragma mark PointAnnotationDelegate
-(void)deletePoint:(PointAnnotation *)point fromMap:(MKMapView *)mapView{
    [point deletePointWithCompletionBlock:^(NSError *error) {
        if (!error) {
            [self removePoint:point fromMap:mapView];
        } else {
            [TSMessage displayError:NSLocalizedString(@"Unable to delete point", nil)];
        }
    }];
}

-(void)changeTypeForPoint:(PointAnnotation *)point inMap:(MKMapView *)mapView{
    [point changePointTypeWithCompletionBlock:^(NSError *error) {
        if (!error) {
            [self changePointType:point inMap:mapView];
        } else {
            [TSMessage displayError:NSLocalizedString(@"Unable to change point type", nil)];
        }
    }];
}

#pragma mark Main Functions
-(void)addPoint:(PointAnnotation *)point toMap:(MKMapView *)mapView{
    point.isLast = YES;
    [mapView addAnnotation:point];
    
    if (point.prevAnnotation) {
        point.prevAnnotation.isLast = NO;
        PointAnnotationView* viewForPrevAnnotation = (PointAnnotationView*)[mapView viewForAnnotation:point.prevAnnotation];
        [viewForPrevAnnotation updateViewFromAnnotation];
        
        for (MKPolygon* polygon in [self.data getComparePolygons]) {
            point.prevAnnotation.isPolylineIntersectWithParentPolygon = [MapUtils isPolyline:point.prevAnnotation.polylineToNextPoint
                                                                           intersectWithSecondPolygon:polygon
                                                                                            inMapView:mapView];
            
            point.isPolylineIntersectWithParentPolygon = [MapUtils isPolyline:point.polylineToNextPoint
                                                            intersectWithSecondPolygon:polygon
                                                                             inMapView:mapView];
            
            if (point.prevAnnotation.isPolylineIntersectWithParentPolygon || point.isPolylineIntersectWithParentPolygon) {
                break;
            }
        }
        
    }
    
    [self constructTemporaryPolygonInMap:mapView];
    
    if (self.delegate && [self.delegate respondsToSelector:@selector(pointController:didAddPoint:)]) {
        [self.delegate pointController:self didAddPoint:point];
    }
}

-(void)removePoint:(PointAnnotation *)point fromMap:(MKMapView *)mapView{
    [mapView removeAnnotation:point];
    if (point.prevAnnotation && point.isLast) {
        point.prevAnnotation.isLast = YES;
        PointAnnotationView* viewforPrevPoint = (PointAnnotationView*)[mapView viewForAnnotation:point.prevAnnotation];
        [viewforPrevPoint updateViewFromAnnotation];
    }
    [self.data.pinsForEditedArea removeObject:point];
    if (self.data.pinsForEditedArea && self.data.pinsForEditedArea.count == 0) {
        self.data.currentParentPolygonForEditedArea = nil;
    }
    
    NSArray* polygonsToCompare = [self.data getComparePolygons];
    
    for (PDAAreaPolygon* polygon in polygonsToCompare) {
        point.prevAnnotation.isPolylineIntersectWithParentPolygon = [MapUtils isPolyline:point.prevAnnotation.polylineToNextPoint
                                                              intersectWithSecondPolygon:polygon
                                                                               inMapView:mapView];
        if (point.prevAnnotation.isPolylineIntersectWithParentPolygon) {
            break;
        }
    }
    
    if (self.data.state == AreaManagmentEditArea || self.data.state == AreaManagmentEditSubArea) {
        self.data.isNeedUpdateArea = YES;
    }
    
    [self constructTemporaryPolygonInMap:mapView];
    
    if (self.delegate && [self.delegate respondsToSelector:@selector(pointController:didRemovePoint:)]) {
        [self.delegate pointController:self didRemovePoint:point];
    }
}

-(void)changePointType:(PointAnnotation *)point inMap:(MKMapView *)mapView{
    NSArray* polygonsToCompare = [self.data getComparePolygons];
    
    if (point.prevAnnotation) {
        for (PDAAreaPolygon* polygon in polygonsToCompare) {
            point.prevAnnotation.isPolylineIntersectWithParentPolygon = [MapUtils isPolyline:point.prevAnnotation.polylineToNextPoint
                                                                  intersectWithSecondPolygon:polygon
                                                                                   inMapView:mapView];
            if (point.prevAnnotation.isPolylineIntersectWithParentPolygon) {
                break;
            }
        }
    }
    
    if (point.polylineToNextPoint.pointCount!=0) {
        for (PDAAreaPolygon* polygon in polygonsToCompare) {
            point.isPolylineIntersectWithParentPolygon = [MapUtils isPolyline:point.polylineToNextPoint
                                                   intersectWithSecondPolygon:polygon
                                                                    inMapView:mapView];
            if (point.isPolylineIntersectWithParentPolygon) {
                break;
            }
        }
    }
    
    if (self.data.state == AreaManagmentEditArea || self.data.state == AreaManagmentEditSubArea) {
        self.data.isNeedUpdateArea = YES;
    }
    
    PointAnnotationView* view = (PointAnnotationView*)[mapView viewForAnnotation:point];
    [view updateViewFromAnnotation];
    
    [self constructTemporaryPolygonInMap:mapView];
}

-(void)changePointPosition:(PointAnnotation *)point inMap:(MKMapView *)mapView{
    NSArray* polygonsToCompare = [self.data getComparePolygons];
    
    CGPoint pointCG = [mapView convertCoordinate:point.coordinate toPointToView:mapView];
    CLLocationCoordinate2D coord = [mapView convertPoint:pointCG toCoordinateFromView:mapView];
    MKMapPoint mapPoint = MKMapPointForCoordinate(coord);
    
    point.coordinate = [MapUtils updateCoordinate:coord atPoint:mapPoint ifItNotInPolygons:polygonsToCompare forAnnotation:point inMapView:mapView withAreaManagementData:self.data];

    [point movePointWithCompletionBlock:^(NSError *error) {
        if (!error) {
            if (point.prevAnnotation) {
                for (PDAAreaPolygon* polygon in polygonsToCompare) {
                    point.prevAnnotation.isPolylineIntersectWithParentPolygon = [MapUtils isPolyline:point.prevAnnotation.polylineToNextPoint
                                                                               intersectWithSecondPolygon:polygon
                                                                                                inMapView:mapView];
                    if (point.prevAnnotation.isPolylineIntersectWithParentPolygon) {
                        break;
                    }
                }
            }
            
            if (point.polylineToNextPoint.pointCount!=0) {
                for (PDAAreaPolygon* polygon in polygonsToCompare) {
                    point.isPolylineIntersectWithParentPolygon = [MapUtils isPolyline:point.polylineToNextPoint
                                                                intersectWithSecondPolygon:polygon
                                                                                 inMapView:mapView];
                    if (point.isPolylineIntersectWithParentPolygon) {
                        break;
                    }
                }
            }
            
            [self constructTemporaryPolygonInMap:mapView];
            self.data.isNeedUpdateArea = YES;
        }else{
            [TSMessage displayError:NSLocalizedString(@"Unable to move point", nil)];
        }
    }];
}

-(void)addAndRunOperationForPoint:(PointOperation*)operation inMap:(MKMapView *)mapView{
    if (operation) {
        for (PointOperation* checkedOp in self.pointOperations) {
            if (checkedOp.point == operation.point && checkedOp.operationType == operation.operationType) {
                return;
            }
        }
        if (self.delegate && [self.delegate respondsToSelector:@selector(pointController:willAddPointOperation:)]) {
            [self.delegate pointController:self willAddPointOperation:operation];
        }
        self.isPendingOperationsCanceled = NO;
        [self.pointOperations addObject:operation];
    }
    
    if (self.isPointOperationRunning) {
        return;
    } else {
        self.isPointOperationRunning = YES;
        PointOperation* operation = [self.pointOperations firstObject];
        [self.pointOperations removeObject:operation];
        
        PointAnnotation* point = operation.point;
        
        if (operation.operationType == PointOperationAdd) {
            __weak PointAnnotation* weakAnnotation = point;
            
            [point addPointToHierarchy:self.data.pinsForEditedArea withCompletionBlock:^(NSError *error) {
                if (!error) {
                    if (!self.isPendingOperationsCanceled) [self addPoint:weakAnnotation toMap:mapView];
                } else {
                    [self processDirectionsError:error];
                }
                
                [self checkForAnotherOperationsForMap:mapView];
            }];
        }
        
        if (operation.operationType == PointOperationDelete) {
            [point deletePointWithCompletionBlock:^(NSError *error) {
                if (!error) {
                    if (!self.isPendingOperationsCanceled) [self removePoint:point fromMap:mapView];
                } else {
                    [self processDirectionsError:error];
                }
                
                [self checkForAnotherOperationsForMap:mapView];
            }];
        }
    }
}

-(void)checkForAnotherOperationsForMap:(MKMapView*)mapView{
    self.isPointOperationRunning = NO;
    if (self.pointOperations.count>0) {
        [self addAndRunOperationForPoint:nil inMap:mapView];
    } else {
        if (self.delegate && [self.delegate respondsToSelector:@selector(pointControllerDidEndAllOperations:)]) {
            [self.delegate pointControllerDidEndAllOperations:self];
        }
    }
}

-(void)processDirectionsError:(NSError*)error{
    if ([error.domain isEqualToString:MKErrorDomain]) {
        switch (error.code) {
            case MKErrorUnknown:
                [TSMessage displayError:NSLocalizedString(@"Unknown error", nil)];
                break;
            case MKErrorServerFailure:
                [TSMessage displayError:NSLocalizedString(@"Unable to get data", nil)];
                break;
            case MKErrorLoadingThrottled:
                [TSMessage displayError:NSLocalizedString(@"Too much request over a short period of time", nil)];
                break;
            case MKErrorPlacemarkNotFound:
                [TSMessage displayError:NSLocalizedString(@"Placemark could not be found", nil)];
                break;
            case MKErrorDirectionsNotFound:
                [TSMessage displayError:NSLocalizedString(@"Directions could not be found", nil)];
                break;
                
            default:
                break;
        }
    } else {
        [TSMessage displayError:[error localizedDescription]];
    }
}

-(void)constructTemporaryPolygonInMap:(MKMapView *)mapView{
    [mapView removeOverlay:self.data.polygonForEditedArea];
    
    if (self.data.pinsForEditedArea.count <= 1) {
        return;
    } else if (self.data.pinsForEditedArea.count == 2){
        self.data.polygonForEditedArea = [MapUtils constructNewPolygonFromPointAnnotations:self.data.pinsForEditedArea];
    } else if (self.data.pinsForEditedArea.count > 2){
        self.data.polygonForEditedArea = [MapUtils constructNewPolygonFromPointAnnotations:self.data.pinsForEditedArea];
    }
    
    if (!self.data.polygonForEditedArea) {
        [TSMessage displayError:NSLocalizedString(@"Unable to create area", nil)];
        return;
    }
    
    self.data.isEditedAreaIntersectWithParentPolygon = NO;
    for (PointAnnotation* point in self.data.pinsForEditedArea) {
        if (point.isPolylineIntersectWithParentPolygon) {
            self.data.isEditedAreaIntersectWithParentPolygon = YES;
        }
    }
    
    [mapView addOverlay:self.data.polygonForEditedArea];
}

-(void)cancelPendingOperations{
    self.isPendingOperationsCanceled = YES;
    [self.pointOperations removeAllObjects];
}

@end

@implementation PointOperation

@end

