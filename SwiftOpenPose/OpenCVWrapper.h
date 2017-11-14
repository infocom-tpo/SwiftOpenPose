//
//  OpenCVWrapper.h
//  openposeTest5
//
//  Created by tpomac2017 on 2017/10/31.
//  Copyright © 2017年 tpomac2017. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface OpenCVWrapper : NSObject

-(void)testFunction;


//-(void)maximum_filter:(cv::Mat&) input
//           output:(cv::Mat&) output
//           threshold:(float) threshold;


-(NSMutableArray*) maximum_filter:(NSMutableArray*) input
                      window_size:(int) window_size
                        threshold:(double) threshold;

-(void) maximum_filter_pointer:
                        (double *) input
                        size:(int) size
                          window_size:(int) window_size
                            threshold:(double) threshold;

@end
