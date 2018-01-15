#import <opencv2/opencv.hpp>
#import "OpenCVWrapper.h"

using namespace cv;
using namespace std;

@implementation OpenCVWrapper

-(void) matrixMin: (double *) data
        data_size:(int)data_size
        data_rows:(int)data_rows
        heat_rows:(int)heat_rows {
    
    std::vector<double> vec(&data[0], data + data_size);
    cv::Mat m1(vec),m2;
    m1 = m1.reshape(0, data_rows);
    cv::reduce(m1, m2, 1, CV_REDUCE_MIN);
    for(int i = 0; i < m1.rows; i++)
    {
        m1.row(i) -= m2.row(i);
    }
    
    m1 = m1.reshape(0,data_rows*heat_rows);
    cv::reduce(m1, m2, 1, CV_REDUCE_MIN);
    for(int i = 0; i < m1.rows; i++)
    {
        m1.row(i) -= m2.row(i);
    }
    
    size_t size2 = data_size*sizeof(double);
    std::memcpy(&data[0],m1.data,size2);
    
    vector<double>().swap(vec);
    m1.release();
    m2.release();
}

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



