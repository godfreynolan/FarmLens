//
//  Use this file to import your target's public headers that you would like to expose to Swift.
//

#ifndef CVOpenTemplate_Header_h
#define CVOpenTemplate_Header_h

#include <opencv2/opencv.hpp>

cv::Mat stitch (std::vector <cv::Mat> & images);

#endif
