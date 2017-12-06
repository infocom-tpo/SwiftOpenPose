# SwiftOpenPose

This project was developed by transplanting [tf-openpose](https://github.com/ildoonet/tf-openpose) to Swift.  
Community cooperation is welcome.  

![swiftopenpose_result](images/swiftopenpose_result.png)

## Environment
* iOS11
* Xcode9

## Performance Problem.

* BenchMark Setting
  * **Optimization Level**
    * Fast, Whole Module Optimization

* BenchMark Hardware
  * iPad 2017
```
coreml elapsed for 3.72523802518845 seconds
init elapsed for 0.0884829759597778 seconds
estimate_pose_pair: elapsed for 0.0128589868545532 seconds
others elapsed for 0.0258489847183228 seconds
human_roop Time elapsed for roop: 0.231473982334137 seconds
estimate_pose Elapsed time is 0.346040964126587 seconds.
Elapsed time is 4.09996396303177 seconds.
```
  * iPad Pro 12inch
```
coreml elapsed for 1.7250149846077 seconds
init elapsed for 0.0669110417366028 seconds
estimate_pose_pair: elapsed for 0.0077439546585083 seconds
others elapsed for 0.0165799856185913 seconds
human_roop Time elapsed for roop: 0.10324501991272 seconds
estimate_pose Elapsed time is 0.186879992485046 seconds.
Elapsed time is 1.93221199512482 seconds.
```

## Bench Thinking from results

* coreml elapsed for 2.37669098377228 seconds  
CoreML processing is slow..  
Coreml processing time is 2 - 4 seconds.

So we challenged OpenPose-Model to speed up.  

* [OpenPose Keras Mobilenet-Model](https://github.com/infocom-tpo/tf-openpose/tree/master/convert)
  * Result: However it did not work.


# The following is how to execute this project

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

## Citation

```
@inproceedings{cao2017realtime,
  author = {Zhe Cao and Tomas Simon and Shih-En Wei and Yaser Sheikh},
  booktitle = {CVPR},
  title = {Realtime Multi-Person 2D Pose Estimation using Part Affinity Fields},
  year = {2017}
}
```