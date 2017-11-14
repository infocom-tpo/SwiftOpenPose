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


-(void)testFunction {

}

-(void) maximum_filter_pointer: (double *) input
                size:(int) size
                   window_size:(int) window_size
                     threshold:(double) threshold {
    
    std::vector<double> vec(&input[0], input + size);
    cv::Mat m1(vec, true);
//    cv::Mat m3 = m1.reshape(1,2);
    m1 = m1.reshape(1, 46);
//    cout << "m1 = "<< endl << " "  << m1 << endl << endl;
    
    cv::Mat bg;
    Mat element = getStructuringElement(cv::MORPH_RECT,
                                        cv::Size(5, 5),
                                        cv::Point(-1, -1) );
    cv::Mat m2;
    m1.copyTo(m2,m1 > threshold);
    
//    cout << "m2 = "<< endl << " "  << m2  << endl << endl;
    
    dilate(m2, bg, element);
    
    // m2 と bg で同じ部分を抽出
    // 同じ部分で上書き(Trueの値の場所を上書き)
    cv::Mat bg2;
    m2.copyTo(bg2,m2 == bg);
    
//    cout << "bg = "<< endl << " "  << bg  << endl << endl;
//    cout << "bg2 = "<< endl << " "  << bg2  << endl << endl;
    
    size_t size2 = size*sizeof(double);
    std::memcpy(&input[0],bg2.data,size2);

}

-(NSMutableArray*)maximum_filter:(NSMutableArray*) input
                     window_size:(int) window_size
                       threshold:(double) threshold {
    
    __block std::vector<double> v1;
    [input enumerateObjectsUsingBlock:^(NSNumber * num, NSUInteger idx, BOOL * _Nonnull stop) {
        v1.push_back([num doubleValue]);
    }];
    
    cv::Mat m1(v1, true);
//    cv::Mat m1 = (cv::Mat_<double>(1,3) << 0.03, 5.0, 10.01);
    cv::Mat bg;
    cv::Mat element = cv::Mat::ones(5,5,CV_8UC1);
    cv::Mat m2;

    m1.copyTo(m2,m1 > threshold);
    
    dilate(m2, bg, element);
//    cout << "bg = "<< endl << " "  << bg << endl << endl;
    cv::Mat bg2;
    bg.copyTo(bg2,m2 == bg);
//    cout << "bg2 = "<< endl << " "  << bg2 << endl << endl;
    NSMutableArray *arr = [[NSMutableArray alloc] init];
    cv::Mat_<double>::iterator it = bg2.begin<double>();
    for(; it!=bg2.end<double>(); ++it){
        [arr addObject:@(*it)];
    }
    
    return arr;
    
}


@end



