import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;
import 'dart:math';

///this is the class which aplly the style transpher in your picture
///Pre-process the inputs
/* The content image and the style image must be RGB images with pixel values being float32 numbers between [0..1].
The style image size must be (1, 256, 256, 3). We central crop the image and resize it.
The content image must be (1, 384, 384, 3). We central crop the image and resize it. */
class Transfer {
  //final _styleModelFile = 'magenta_arbitrary-image-stylization-v1-256_fp16_prediction_1.tflite';
  //final _transformModelFile = 'magenta_arbitrary-image-stylization-v1-256_fp16_transfer_1.tflite';

  static final String _styleModelFile =
      'magenta_arbitrary-image-stylization-v1-256_int8_prediction_1.tflite';
  static final String _transformModelFile =
      'magenta_arbitrary-image-stylization-v1-256_int8_transfer_1.tflite';

  static final int MODEL_TRANSFER_IMAGE_SIZE = 384;
  static final int MODEL_STYLE_IMAGE_SIZE = 256;

  late Interpreter interpreterStyle;
  late Interpreter interpreterTransform;

//style part
  String styleLoaded = "";
  late Uint8List styleData;
  bool isStyleLoaded = false;
  late List<List<List<List<double>>>> styleBottleneck;

//image part
  late img.Image originImage;
  late List<List<List<List<double>>>> styleOriginBottleneck;
  late List<int> modelTransferInput;
  bool originImageLoaded = false;

  Future<void> loadModel() async {
    try {
      interpreterStyle = await Interpreter.fromAsset(_styleModelFile,
          options: InterpreterOptions()..threads = 4);
      interpreterTransform = await Interpreter.fromAsset(_transformModelFile,
          options: InterpreterOptions()..threads = 4);
    } catch (e) {
      print("error at load :\n$e");
    }
  }

  Future<Uint8List> loadStyleImage(String styleImagePath) async {
    if (styleImagePath == this.styleLoaded) {
      return this.styleData;
    }
    isStyleLoaded = false;
    ByteData styleImageByteData = await rootBundle.load(styleImagePath);

    this.styleData = styleImageByteData.buffer.asUint8List();

    this.styleLoaded = styleImagePath;
    return this.styleData;
  }

  void loadStyleImages(List<Uint8List> multistyles) {
    List<List<List<List<double>>>> multiStyleBottleneck = [
      [
        [List.generate(100, (int index) => 0.0)]
      ]
    ];
    for (int i = 0; i < multistyles.length; i++) {
      this.styleData = multistyles[i];
      loadStyleImageData();
      for (int i = 0; i < 100; i++) {
        multiStyleBottleneck[0][0][0][i] += this.styleBottleneck[0][0][0][i];
      }
    }
    for (int i = 0; i < 100; i++) {
      this.styleBottleneck[0][0][0][i] =
          multiStyleBottleneck[0][0][0][i] / multistyles.length;
    }
  }

  void loadStyleImageData() {
    img.Image? styleImage = img.decodeImage(this.styleData);
    if (styleImage == null) {
      Exception("Error : style image null");
    }
    img.Image? modelStyleImage = img.copyResize(styleImage!,
        width: MODEL_STYLE_IMAGE_SIZE, height: MODEL_STYLE_IMAGE_SIZE);
    // content_image 384 384 3
    List<int> modelStyleInput =
        _imageToByteListUInt8(modelStyleImage, MODEL_STYLE_IMAGE_SIZE, 0, 255);

    // style_image 1 256 256 3
    List<List<int>> inputsForStyle = [modelStyleInput];
    Map<int, Object> outputsForStyle = Map<int, Object>();

    // style_bottleneck 1 1 1 100
    this.styleBottleneck = [
      [
        [List.generate(100, (int index) => 0.0)]
      ]
    ];
    outputsForStyle[0] = styleBottleneck;

    // style predict model
    interpreterStyle.runForMultipleInputs(inputsForStyle, outputsForStyle);
    isStyleLoaded = true;
  }

  void loadOriginImage(Uint8List originData) {
    img.Image? originalImage = img.decodeImage(originData);
    if (originalImage == null) {
      Exception("Error : original image null");
    }
    this.originImage = originalImage!;
    img.Image modelTransferImage = img.copyResize(originImage,
        width: MODEL_TRANSFER_IMAGE_SIZE,
        height: MODEL_TRANSFER_IMAGE_SIZE,
        interpolation: img.Interpolation.nearest);
    this.modelTransferInput = _imageToByteListUInt8(
        modelTransferImage, MODEL_TRANSFER_IMAGE_SIZE, 0, 255);

    img.Image modelStyleOriginImage = img.copyResize(originImage,
        width: MODEL_STYLE_IMAGE_SIZE, height: MODEL_STYLE_IMAGE_SIZE);
    // content_image 384 384 3
    List<int> modelStyleOriginInput = _imageToByteListUInt8(
        modelStyleOriginImage, MODEL_STYLE_IMAGE_SIZE, 0, 255);

    // style_image 1 256 256 3
    List<List<int>> inputsForOriginStyle = [modelStyleOriginInput];
    Map<int, Object> outputsForOriginStyle = Map<int, Object>();

    // style_bottleneck 1 1 1 100
    this.styleOriginBottleneck = [
      [
        [List.generate(100, (int index) => 0.0)]
      ]
    ];
    outputsForOriginStyle[0] = styleOriginBottleneck;

    // style predict model
    interpreterStyle.runForMultipleInputs(
        inputsForOriginStyle, outputsForOriginStyle);
    this.originImageLoaded = true;
  }

  Future<void> loadOriginImageAsync(Uint8List originData) async {
    Map<String, dynamic> map = await compute(preprocessImageSource, originData);

    this.originImage = map["originImage"] as img.Image;
    this.modelTransferInput = map["modelTransferInput"];
    this.originImageLoaded = true;
  }

  Future<Uint8List> transferAsync() async {
    if (!isStyleLoaded) {
      this.loadStyleImageData();
    }
    Map<String, dynamic> inputMap = {};
    inputMap["modelTransferInput"] = this.modelTransferInput;
    inputMap["styleBottleneck"] = this.styleBottleneck;
    inputMap["styleOriginBottleneck"] = this.styleOriginBottleneck;
    Map<String, dynamic> outputMap =
        await compute(preprocessTransferIsolated, inputMap);

    List<Object> inputsForStyleTransfer = outputMap["inputsForStyleTransfer"];
    Map<int, Object> outputsForStyleTransfer =
        outputMap["outputsForStyleTransfer"];
    List<List<List<List<double>>>> outputImageData =
        outputMap["outputImageData"];
    interpreterTransform.runForMultipleInputs(
        inputsForStyleTransfer, outputsForStyleTransfer);

    img.Image outputImage =
        _convertArrayToImage(outputImageData, MODEL_TRANSFER_IMAGE_SIZE);
    img.Image rotateOutputImage = img.copyRotate(outputImage, angle: 90);
    img.Image flipOutputImage = img.flipHorizontal(rotateOutputImage);
    img.Image resultImage = img.copyResize(flipOutputImage,
        width: originImage.width, height: originImage.height);
    Uint8List result = img.encodeJpg(resultImage);
    return result;
  }

  Uint8List transfer(int sliderValue) {
    if (!isStyleLoaded) {
      this.loadStyleImageData();
    }

    List<List<List<List<double>>>> blendedStyleBottleneck = [
      [
        [List.generate(100, (int index) => 0.0)]
      ]
    ];

    double ratio = 1; //sliderValue.roundToDouble() / 100.0;
    for (int i = 0; i < 100; i++) {
      blendedStyleBottleneck[0][0][0][i] =
          this.styleBottleneck[0][0][0][i] * ratio +
              (1 - ratio) * this.styleOriginBottleneck[0][0][0][i];
    }

    // content_image + blendedStyleBottleneck
    List<Object> inputsForStyleTransfer = [
      modelTransferInput,
      blendedStyleBottleneck
    ];
    Map<int, Object> outputsForStyleTransfer = Map<int, Object>();

    // stylized_image 1 384 384 3
    List<List<List<List<double>>>> outputImageData = [
      List.generate(
        MODEL_TRANSFER_IMAGE_SIZE,
        (int index) => List.generate(
          MODEL_TRANSFER_IMAGE_SIZE,
          (int index) => List.generate(3, (int index) => 0.0),
        ),
      )
    ];
    outputsForStyleTransfer[0] = outputImageData;

    interpreterTransform.runForMultipleInputs(
        inputsForStyleTransfer, outputsForStyleTransfer);

    img.Image outputImage =
        _convertArrayToImage(outputImageData, MODEL_TRANSFER_IMAGE_SIZE);
    img.Image rotateOutputImage = img.copyRotate(outputImage, angle: 90);
    img.Image flipOutputImage = img.flipHorizontal(rotateOutputImage);
    img.Image resultImage = img.copyResize(flipOutputImage,
        width: originImage.width, height: originImage.height);
    //resultImage = this.saltPeperFilter(resultImage, originImage, sliderValue);
    Uint8List result = img.encodeJpg(resultImage);

    return result;
  }

  img.Image saltPeperFilter(
      img.Image source, img.Image reference, int pourcent) {
    int width = reference.width;
    int height = reference.height;
    Random rng = new Random();
    int SaltPourcentage = 100 - pourcent;
    for (int x = 0; x < width; x++) {
      for (int y = 0; y < height; y++) {
        if (rng.nextInt(100) < SaltPourcentage) {
          img.Pixel color = reference.getPixel(x, y);
          source.setPixelRgb(x, y, color.r, color.g, color.b);
        }
      }
    }
    return source;
  }
}

Map<String, dynamic> preprocessImageSource(List<int> imageByte) {
  const int MODEL_TRANSFER_IMAGE_SIZE = 384;

  img.Image? originImage = img.decodeImage(imageByte as Uint8List);
  if (originImage == null) {
    Exception("Error : original image null");
  }

  List<int> modelTransferInput;

  img.Image modelTransferImage = img.copyResize(originImage!,
      width: MODEL_TRANSFER_IMAGE_SIZE,
      height: MODEL_TRANSFER_IMAGE_SIZE,
      interpolation: img.Interpolation.nearest);
  modelTransferInput = _imageToByteListUInt8(
      modelTransferImage, MODEL_TRANSFER_IMAGE_SIZE, 0, 255);

  Map<String, dynamic> map = {};
  map["originImage"] = originImage;
  map["modelTransferInput"] = modelTransferInput;
  return map;
  // style predict model
}

img.Image _convertArrayToImage(
    List<List<List<List<double>>>> imageArray, int inputSize) {
  img.Image image = img.Image.empty();
  for (int x = 0; x < imageArray[0].length; x++) {
    for (int y = 0; y < imageArray[0][0].length; y++) {
      int r = (imageArray[0][x][y][0] * 255).toInt();
      int g = (imageArray[0][x][y][1] * 255).toInt();
      int b = (imageArray[0][x][y][2] * 255).toInt();
      image.setPixelRgb(x, y, r, g, b);
    }
  }
  return image;
}

List<int> _imageToByteListUInt8(
  img.Image image,
  int inputSize,
  double mean,
  double std,
) {
  Float32List convertedBytes = Float32List(1 * inputSize * inputSize * 3);
  Float32List buffer = Float32List.view(convertedBytes.buffer);
  int pixelIndex = 0;

  for (int i = 0; i < inputSize; i++) {
    for (int j = 0; j < inputSize; j++) {
      img.Pixel pixel = image.getPixel(j, i);
      buffer[pixelIndex++] = (pixel.r - mean) / std;
      buffer[pixelIndex++] = (pixel.g - mean) / std;
      buffer[pixelIndex++] = (pixel.b - mean) / std;
    }
  }
  return convertedBytes.buffer.asUint8List();
}

Map<String, dynamic> preprocessTransferIsolated(Map<String, dynamic> input) {
  const int MODEL_TRANSFER_IMAGE_SIZE = 384;

  Uint8List modelTransferInput = input["modelTransferInput"] as Uint8List;
  List<List<List<List<double>>>> styleBottleneck = input["styleBottleneck"];

  List<Object> inputsForStyleTransfer = [modelTransferInput, styleBottleneck];
  Map<int, Object> outputsForStyleTransfer = Map<int, Object>();

  // stylized_image 1 384 384 3
  List<List<List<List<double>>>> outputImageData = [
    List.generate(
      MODEL_TRANSFER_IMAGE_SIZE,
      (int index) => List.generate(
        MODEL_TRANSFER_IMAGE_SIZE,
        (int index) => List.generate(3, (int index) => 0.0),
      ),
    )
  ];
  outputsForStyleTransfer[0] = outputImageData;

  Map<String, dynamic> output = {};
  output["inputsForStyleTransfer"] = inputsForStyleTransfer;
  output["outputsForStyleTransfer"] = outputsForStyleTransfer;
  output["outputImageData"] = outputImageData;
  return output;
}
