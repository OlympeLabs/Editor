import 'dart:async';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;
import 'package:tflite_flutter_helper/tflite_flutter_helper.dart';

///this is the class which aplly the style transpher in your picture
///Pre-process the inputs
/* The content image and the style image must be RGB images with pixel values being float32 numbers between [0..1].
The style image size must be (1, 256, 256, 3). We central crop the image and resize it.
The content image must be (1, 384, 384, 3). We central crop the image and resize it. */
class Transfer {
  //final _styleModelFile = 'magenta_arbitrary-image-stylization-v1-256_fp16_prediction_1.tflite';
  //final _transformModelFile = 'magenta_arbitrary-image-stylization-v1-256_fp16_transfer_1.tflite';

  final _styleModelFile = 'magenta_arbitrary-image-stylization-v1-256_int8_prediction_1.tflite';
  final _transformModelFile = 'magenta_arbitrary-image-stylization-v1-256_int8_transfer_1.tflite';

  static const int MODEL_TRANSFER_IMAGE_SIZE = 384;
  static const int MODEL_STYLE_IMAGE_SIZE = 256;

  Interpreter interpreterStyle;
  Interpreter interpreterTransform;
  ImageProcessor imageStyleProcessor;
  ImageProcessor imageTransferProcessor;

//style part
  String styleLoaded = "";
  Uint8List styleData;
  bool isStyleLoaded = false;
  List<List<List<List<double>>>> styleBottleneck;

//image part
  img.Image originImage;
  List<List<List<List<double>>>> styleOriginBottleneck;
  Uint8List modelTransferInput;
  bool originImageLoaded = false;

  Future<void> loadModel() async {
    try {
      interpreterStyle = await Interpreter.fromAsset(_styleModelFile);
      interpreterTransform = await Interpreter.fromAsset(_transformModelFile);
      imageStyleProcessor = ImageProcessorBuilder().add(ResizeOp(MODEL_STYLE_IMAGE_SIZE, MODEL_STYLE_IMAGE_SIZE, ResizeMethod.NEAREST_NEIGHBOUR)).add(CastOp(TfLiteType.float32)).build();
      imageTransferProcessor = ImageProcessorBuilder().add(ResizeOp(MODEL_TRANSFER_IMAGE_SIZE, MODEL_TRANSFER_IMAGE_SIZE, ResizeMethod.NEAREST_NEIGHBOUR)).add(CastOp(TfLiteType.float32)).build();
    } catch (e) {
      print("error at load :\n$e");
    }
  }

  Future<Uint8List> loadStyleImage(String styleImagePath) async {
    if (styleImagePath == this.styleLoaded) {
      return this.styleData;
    }
    isStyleLoaded = false;
    var styleImageByteData = await rootBundle.load(styleImagePath);

    this.styleData = styleImageByteData.buffer.asUint8List();

    this.styleLoaded = styleImagePath;
    return this.styleData;
  }

  void loadStyleImages(List<Uint8List> multistyles) {
    List<List<List<List<double>>>> multiStyleBottleneck= [
      [
        [List.generate(100, (index) => 0.0)]
      ]
    ];
    for (int i = 0 ; i < multistyles.length; i ++){
      this.styleData = multistyles[i];
      loadStyleImageData();
      for (int i = 0; i < 100; i++) {
        multiStyleBottleneck[0][0][0][i] += this.styleBottleneck[0][0][0][i];
      }
    }
    for (int i = 0; i < 100; i++) {
      this.styleBottleneck[0][0][0][i] = multiStyleBottleneck[0][0][0][i] / multistyles.length;
    }

  }

  void loadStyleImageData() {
    var styleImage = img.decodeImage(this.styleData);
    var modelStyleImage = img.copyResize(styleImage, width: MODEL_STYLE_IMAGE_SIZE, height: MODEL_STYLE_IMAGE_SIZE);
    // content_image 384 384 3
    var modelStyleInput = _imageToByteListUInt8(modelStyleImage, MODEL_STYLE_IMAGE_SIZE, 0, 255);

    // style_image 1 256 256 3
    var inputsForStyle = [modelStyleInput];
    var outputsForStyle = Map<int, Object>();

    // style_bottleneck 1 1 1 100
    this.styleBottleneck = [
      [
        [List.generate(100, (index) => 0.0)]
      ]
    ];
    outputsForStyle[0] = styleBottleneck;

    // style predict model
    interpreterStyle.runForMultipleInputs(inputsForStyle, outputsForStyle);
    isStyleLoaded = true;
  }

  void loadOriginImage(Uint8List originData) {
    this.originImage = img.decodeImage(originData);
    var modelTransferImage = img.copyResize(originImage, width: MODEL_TRANSFER_IMAGE_SIZE, height: MODEL_TRANSFER_IMAGE_SIZE, interpolation: img.Interpolation.nearest);
    this.modelTransferInput = _imageToByteListUInt8(modelTransferImage, MODEL_TRANSFER_IMAGE_SIZE, 0, 255);

    var modelStyleOriginImage = img.copyResize(originImage, width: MODEL_STYLE_IMAGE_SIZE, height: MODEL_STYLE_IMAGE_SIZE);
    // content_image 384 384 3
    var modelStyleOriginInput = _imageToByteListUInt8(modelStyleOriginImage, MODEL_STYLE_IMAGE_SIZE, 0, 255);

    // style_image 1 256 256 3
    var inputsForOriginStyle = [modelStyleOriginInput];
    var outputsForOriginStyle = Map<int, Object>();

    // style_bottleneck 1 1 1 100
    this.styleOriginBottleneck = [
      [
        [List.generate(100, (index) => 0.0)]
      ]
    ];
    outputsForOriginStyle[0] = styleOriginBottleneck;

    // style predict model
    interpreterStyle.runForMultipleInputs(inputsForOriginStyle, outputsForOriginStyle);
    this.originImageLoaded = true;
  }

  Uint8List transfer(int sliderValue) {
    if (!isStyleLoaded) {
      this.loadStyleImageData();
    }

    List<List<List<List<double>>>> blendedStyleBottleneck = [
      [
        [List.generate(100, (index) => 0.0)]
      ]
    ];

    double ratio = sliderValue.roundToDouble() / 100.0;
    for (int i = 0; i < 100; i++) {
      blendedStyleBottleneck[0][0][0][i] = this.styleBottleneck[0][0][0][i] * ratio + (1 - ratio) * this.styleOriginBottleneck[0][0][0][i];
    }

    // content_image + blendedStyleBottleneck
    List<Object> inputsForStyleTransfer = [modelTransferInput, blendedStyleBottleneck];
    var outputsForStyleTransfer = Map<int, Object>();

    // stylized_image 1 384 384 3
    var outputImageData = [
      List.generate(
        MODEL_TRANSFER_IMAGE_SIZE,
        (index) => List.generate(
          MODEL_TRANSFER_IMAGE_SIZE,
          (index) => List.generate(3, (index) => 0.0),
        ),
      )
    ];
    outputsForStyleTransfer[0] = outputImageData;

    interpreterTransform.runForMultipleInputs(inputsForStyleTransfer, outputsForStyleTransfer);

    var outputImage = _convertArrayToImage(outputImageData, MODEL_TRANSFER_IMAGE_SIZE);
    var rotateOutputImage = img.copyRotate(outputImage, 90);
    var flipOutputImage = img.flipHorizontal(rotateOutputImage);
    var resultImage = img.copyResize(flipOutputImage, width: originImage.width, height: originImage.height);
    var result = img.encodeJpg(resultImage);

    return result as Uint8List;
  }

  img.Image _convertArrayToImage(List<List<List<List<double>>>> imageArray, int inputSize) {
    img.Image image = img.Image.rgb(inputSize, inputSize);
    for (var x = 0; x < imageArray[0].length; x++) {
      for (var y = 0; y < imageArray[0][0].length; y++) {
        var r = (imageArray[0][x][y][0] * 255).toInt();
        var g = (imageArray[0][x][y][1] * 255).toInt();
        var b = (imageArray[0][x][y][2] * 255).toInt();
        image.setPixelRgba(x, y, r, g, b);
      }
    }
    return image;
  }

  Uint8List _imageToByteListUInt8(
    img.Image image,
    int inputSize,
    double mean,
    double std,
  ) {
    var convertedBytes = Float32List(1 * inputSize * inputSize * 3);
    var buffer = Float32List.view(convertedBytes.buffer);
    int pixelIndex = 0;

    for (var i = 0; i < inputSize; i++) {
      for (var j = 0; j < inputSize; j++) {
        var pixel = image.getPixel(j, i);
        buffer[pixelIndex++] = (img.getRed(pixel) - mean) / std;
        buffer[pixelIndex++] = (img.getGreen(pixel) - mean) / std;
        buffer[pixelIndex++] = (img.getBlue(pixel) - mean) / std;
      }
    }
    return convertedBytes.buffer.asUint8List();
  }
}
