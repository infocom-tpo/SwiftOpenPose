## このプロジェクトは？

[OpenPose](https://github.com/CMU-Perceptual-Computing-Lab/openpose)をiOSで動かすプロジェクトです。  
[tf-openpose](https://github.com/ildoonet/tf-openpose)をベースに作成しています

## ライセンス

OpenPoseのコード利用は有料ですが、tf-openposeはApache2ライセンスになる為、tf-openposeをベースに開発していますので、ライセンスフリーになると考えています。  
公に利用する際は、法務に確認をお願いします。  
  
また、ボーンの取得には、OpenPoseのCaffe-modelを利用しますがモデルは「[BAIR model license](https://github.com/CMU-Perceptual-Computing-Lab/openpose/blob/master/3rdparty/caffe/docs/model_zoo.md)」になるそうで基本的には無料でモデルは利用可能と考えています。  

## 課題

リアルタイムにボーンを取得するには更なる高速化が必要です。
現在のベンチ(2017/11/14)

```
iPad 2017 Benchmark
Double 1 x 1 x 57 x 46 x 46 array

========
Time elapsed for copy: 0.133957028388977 seconds
Time elapsed for init: 1.002081990242 seconds
Time elapsed for estimate_pose_pair: 0.0317380428314209 seconds
Time elapsed for roop: 0.055433988571167 seconds

-SubTotal:
Time elapsed for code: 1.15459597110748 seconds
Time elapsed for coreml: 2.33745795488358 seconds

Total:
Elapsed time is 3.6908860206604 seconds.
```

コードについては、初期処理の10行程度のコードで1秒かかっています。  
coremlについては57x46x46次元のデータを扱っていますので、減らすことで大きく改善が見込めます。  


## モデルのダウンロード

Caffe-modelをmlmodelにコンバートする必要があります。
Caffe-modelをコンバートするには、Caffe-modelと、prototxtを入手します。

* [OpenPoseのインストールページ](https://github.com/CMU-Perceptual-Computing-Lab/openpose/blob/master/doc/installation.md)から「COCO model」をダウンロードします
* [pose_deploy_linevec.prototxt](https://github.com/CMU-Perceptual-Computing-Lab/openpose/tree/master/models/pose/coco)をダウンロードします

下記pythonコードでコンバートします。  
pip等でcoremltoolsのインストールが必要です。
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

## 依存ライブラリ

* [UpSurge](https://github.com/aleph7/Upsurge)
 * import UpSurge.xcodeproj
* [CoreMLHelpers](https://github.com/hollance/CoreMLHelpers)
 * import Demo.xcodeproj
* [IteratorTools](https://github.com/mpangburn/IteratorTools)
 * import UpSurge.xcodeproj
* [OpenCV](https://opencv.org/releases.html)
 * iOS packをダウンロードし、import

OpenCV以外は*.xcodeprojをimportします  

## *.xcodeproj import

* Build Phases -> Target Dependencies
* Build Phases -> [+] -> New Copy File Phase -> New File
 * Destinationのプルダウンを Frameworksに変更
 * [+] でFrameworkを追加

