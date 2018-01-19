# Opencv lightweight version 

## Package
```
$ git clone https://github.com/opencv/opencv.git
$ cd opencv/
$ git checkout -b 3.3.1 refs/tags/3.3.1

$ vi platforms/ios/build_framework.py 

diff --git a/platforms/ios/build_framework.py b/platforms/ios/build_framework.py
index 78d9ec644..bb312de2d 100644
--- a/platforms/ios/build_framework.py
+++ b/platforms/ios/build_framework.py
@@ -281,7 +281,9 @@ if __name__ == "__main__":
             (["armv7", "arm64"], "iPhoneOS"),
         ] if os.environ.get('BUILD_PRECOMMIT', None) else
         [
-            (["armv7", "armv7s", "arm64"], "iPhoneOS"),
-            (["i386", "x86_64"], "iPhoneSimulator"),
+            # (["armv7", "armv7s", "arm64"], "iPhoneOS"),
+            (["arm64"], "iPhoneOS"),
+            # (["i386", "x86_64"], "iPhoneSimulator"),
+            (["x86_64"], "iPhoneSimulator"),
         ])
     b.build(args.out)


$ python platforms/ios/build_framework.py ios \
--without video --without videoio --without videostab \
--without features2d --without objdetect --without flann --without ml \
--without cudaarithm --without cudabgsegm --without cudacodec --without cudafeatures2d  \
--without cudafilters --without cudaimgproc --without cudalegacy --without cudaobjdetect  \
--without cudaoptflow --without cudastereo --without cudawarping --without cudev \
--without highgui --without viz --without superres --without photo \
--without calib3d --without shape --without stitching \
--without dnn --without aruco \
--without bgsegm --without bioinspired --without ccalib \
--without cnn_3dobj --without cvv --without datasets \
--without dnn_modern --without dpm --without face \
--without freetype --without fuzzy --without hdf --without img_hash \
--without line_descriptor --without matlab --without optflow --without phase_unwrapping \
--without plot --without reg --without rgbd --without saliency --without sfm --without stereo \
--without structured_light --without surface_matching --without text --without tracking \
--without xfeatures2d --without ximgproc --without xobjdetect --without xphoto 
```

## Result
```
$ cat ios/build/build-arm64-iphoneos/opencv2/opencv_modules.hpp
#define HAVE_OPENCV_CORE
#define HAVE_OPENCV_IMGCODECS
#define HAVE_OPENCV_IMGPROC
```
## Install

install to ios/opencv2.framework
