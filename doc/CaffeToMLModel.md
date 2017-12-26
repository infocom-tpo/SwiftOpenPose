# Convert from OpenPose Caffe-Model to MLModel

## Get Caffe-model and prototxt.

* [Get Caffe-model](https://github.com/CMU-Perceptual-Computing-Lab/openpose/blob/master/doc/installation.md)
  * Download of COCO Model
* [Get pose_deploy_linevec.prototxt](https://github.com/CMU-Perceptual-Computing-Lab/openpose/tree/master/models/pose/coco)

### Edit pose_deploy_linevec.prototxt

edit input_dim of pose_deploy_linevec.prototxt.    
input_dim: 368

``` 
input: "image"
input_dim: 1
input_dim: 3
input_dim: 368 # This value will be defined at runtime
input_dim: 368 # This value will be defined at runtime
```

## Convert from OpenPose Caffe-Model to MLModel.

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