#import <opencv2/opencv.hpp>

#import "OpenCVWrapper.h"

using namespace cv;
using namespace std;

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

