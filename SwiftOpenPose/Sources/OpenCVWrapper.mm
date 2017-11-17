//
//  OpenCVWrapper.m
//  openposeTest5
//
//  Created by tpomac2017 on 2017/10/31.
//  Copyright © 2017年 tpomac2017. All rights reserved.
//

#import <opencv2/opencv.hpp>
//#import <opencv2/imgcodecs/ios.h>
//#import <Accelerate/Accelerate.h>

#import "OpenCVWrapper.h"
//#include <numeric>

using namespace cv;
using namespace std;
//
//@interface OpenCVWrapper() <CvVideoCameraDelegate>{
//    CvVideoCamera *cvCamera;
//}
//@end

@implementation OpenCVWrapper

-(void) maximum_filter: (double *) data
             data_size:(int)data_size
             data_rows:(int)data_rows
             mask_size:(int)mask_size
             threshold:(double)threshold {
    
    std::vector<double> vec(&data[0], data + data_size);
    cv::Mat m1(vec);
    m1 = m1.reshape(0, data_rows);
    
    cv::Mat bg;
    
    cv::Mat kernel = cv::getStructuringElement(cv::MORPH_RECT,
                                               cv::Size(mask_size,mask_size),
                                               cv::Point(-1,-1));
    cv::Mat m2;
    m1.copyTo(m2,m1 > threshold);
    
    dilate(m2, bg, kernel);
    
    cv::Mat bg2;
    m2.copyTo(bg2,m2 == bg);
    
//    cout << "bg = "<< endl << " "  << bg  << endl << endl;
//    cout << "bg2 = "<< endl << " "  << bg2  << endl << endl;
    
    size_t size2 = data_size*sizeof(double);
    std::memcpy(&data[0],bg2.data,size2);
    
    vector<double>().swap(vec);
    m1.release();
    m2.release();
    bg.release();
    bg2.release();
    kernel.release();
    
}

@end



