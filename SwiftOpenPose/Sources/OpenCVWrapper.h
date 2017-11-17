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

-(void) maximum_filter: (double *) data
             data_size:(int)data_size
             data_rows:(int)data_rows
             mask_size:(int)mask_size
             threshold:(double)threshold
;

@end
