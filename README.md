# SwiftOpenPose

This project was developed by transplanting [tf-openpose](https://github.com/ildoonet/tf-openpose) to Swift.  
Help improve performance of SwiftOpenPose.

![swiftopenpose_result](images/swiftopenpose_result.png)

## Environment
* iOS11
* Xcode9

## Performance Problem.

BenchMark Hardware
  * iPad 2017

```
coreml elapsed for 2.37669098377228 seconds
init elapsed for 0.240312993526459 seconds
estimate_pose_pair: elapsed for 0.0315470099449158 seconds
others elapsed for 0.0973029732704163 seconds
human_roop Time elapsed for roop: 0.575976967811584 seconds
estimate_pose Elapsed time is 0.913830041885376 seconds.
Total time is 3.32556003332138 seconds.
```
* coreml elapsed for 2.37669098377228 seconds  
CoreML processing is slow..  
And speed up the whole process is necessary.  
The total processing time is 3.32556003332138 seconds.  

## MLModel Create

Caffe-model to mlmodel convert.

### Get Caffe-model and prototxt.

* [Get Caffe-model](https://github.com/CMU-Perceptual-Computing-Lab/openpose/blob/master/doc/installation.md)
  * Download of COCO Model
* [Get pose_deploy_linevec.prototxt](https://github.com/CMU-Perceptual-Computing-Lab/openpose/tree/master/models/pose/coco)

#### Edit pose_deploy_linevec.prototxt

edit input_dim of pose_deploy_linevec.prototxt.    
input_dim: 368

``` 
input: "image"
input_dim: 1
input_dim: 3
input_dim: 368 # This value will be defined at runtime
input_dim: 368 # This value will be defined at runtime
```

### Caffe-model to mlmodel convert.
* [install coremltools](https://pypi.python.org/pypi/coremltools)
* Run python here
```
import coremltools

#proto_file = 'pose_deploy.prototxt'
proto_file = 'pose_deploy_linevec.prototxt'
caffe_model = 'pose_iter_440000.caffemodel'

coreml_model = coremltools.converters.caffe.convert((caffe_model, proto_file)
, image_input_names='image'
, image_scale=1/255.
)

coreml_model.save('coco_pose_368.mlmodel')
```

## Dependencies Library

* [UpSurge](https://github.com/aleph7/Upsurge)
* [CoreMLHelpers](https://github.com/hollance/CoreMLHelpers)
* [IteratorTools](https://github.com/mpangburn/IteratorTools)
* [OpenCV](https://opencv.org/releases.html)
  * Download of iOS Pack

## Refarence

* [OpenPose](https://github.com/CMU-Perceptual-Computing-Lab/openpose)
* [tf-openpose](https://github.com/ildoonet/tf-openpose)
* [OpenPose Caffe Model Convert to CoreML Model](https://gist.github.com/otmb/7b2e1caf3330b97c82dc217af5844ad5)
* [エネルギー波を繰り出す女子高生](https://www.pakutaso.com/20151016274post-6129.html)

## Development By Infocom TPO

[Infocom TPO](https://lab.infocom.co.jp/)

## License

SwiftOpenPose is available under the MIT license. See the LICENSE file for more info.
