import 'dart:io';
import 'dart:math';
import 'package:image/image.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;
import 'package:tflite_flutter_helper/tflite_flutter_helper.dart';
import 'package:path_provider/path_provider.dart' as syspaths;


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

  Future<void> loadModel() async {
    // TODO Exception
    try{
      interpreterStyle = await Interpreter.fromAsset(_styleModelFile);
      interpreterTransform = await Interpreter.fromAsset(_transformModelFile);
      imageStyleProcessor = ImageProcessorBuilder().add(ResizeOp(MODEL_STYLE_IMAGE_SIZE, MODEL_STYLE_IMAGE_SIZE, ResizeMethod.NEAREST_NEIGHBOUR)).add(CastOp(TfLiteType.float32)).build();
      imageTransferProcessor = ImageProcessorBuilder().add(ResizeOp(MODEL_TRANSFER_IMAGE_SIZE, MODEL_TRANSFER_IMAGE_SIZE, ResizeMethod.NEAREST_NEIGHBOUR)).add(CastOp(TfLiteType.float32)).build();

    }catch(e){
      print("error at load :\n$e");
    }
  }


  Future<Uint8List> loadStyleImage(String styleImagePath) async {
    var styleImageByteData = await rootBundle.load(styleImagePath);
    return styleImageByteData.buffer.asUint8List();
  }

  List<Uint8List> splitImage(img.Image originImage, int originWidth, int originHeight, int nbRow, int nbCol){

    int subWidth = (originWidth/nbRow).ceil();
    int subHeight = (originHeight/nbCol).ceil();

    int offsetX = 0;
    int offsetY = 0;

    List<Uint8List> images = List(nbRow * nbCol);

    for(int j = 0 ; j < nbCol ; j++ ){
      offsetY = j * subHeight;
      for( int i = 0 ; i < nbRow ; i++){
        offsetX = i * subWidth;
        images[nbRow*j + i] = img.encodeJpg(img.copyCrop(originImage, offsetX, offsetY, subWidth, subWidth));
        print(" split  done ${((nbRow*j + i)/(nbRow*nbCol)) *100 }%");

      }
    }
    return images;
  }


  Uint8List joinImages(List<Uint8List> imageSplited, int originWidth, int originHeight, int nbRow, int nbCol){
    img.Image finalImg = img.Image(originWidth, originHeight);
    int offsetX = 0;
    int offsetY = 0;
    int subWidth = (originWidth/nbRow).ceil();
    int subHeight = (originHeight/nbCol).ceil();

    for(int j = 0 ; j < nbCol ; j++ ){
      offsetY = j * subHeight;
      for( int i = 0 ; i < nbRow ; i++){
        offsetX = i * subWidth;
        img.copyInto(finalImg, img.decodeImage(imageSplited[nbRow*j + i]), dstX: offsetX, dstY: offsetY, srcX: 0, srcY: 0, srcH: subHeight, srcW: subWidth);
        print(" join done ${((nbRow*j + i)/(nbRow*nbCol)) *100 }%");
      }
    }
    return img.encodeJpg(finalImg);
  }



  Future<Uint8List> fullSplitTransfer(Uint8List originData, Uint8List styleData) async {
    img.Image originImage = img.decodeImage(await transfer(originData, styleData));
    int originWidth = originImage.width;
    int originHeight = originImage.height;
    double subdivider = 3;

    int nbRow = ((originWidth/MODEL_TRANSFER_IMAGE_SIZE)/subdivider).ceil();
    int nbCol = ((originHeight/MODEL_TRANSFER_IMAGE_SIZE)/subdivider).ceil();

    List<Future<Uint8List>> filtredImages = splitImage(originImage, originWidth, originHeight, nbRow, nbCol).map((part) async {
      return await transfer(part, styleData);
    }).toList();
    List<Uint8List> imageParts = await Future.wait(filtredImages);
    return joinImages(imageParts, originWidth, originHeight, nbRow, nbCol);
  }

  Uint8List transfer(Uint8List originData, Uint8List styleData) {
    var originImage = img.decodeImage(originData);
    var modelTransferImage = img.copyResize(originImage, width: MODEL_TRANSFER_IMAGE_SIZE, height: MODEL_TRANSFER_IMAGE_SIZE, interpolation: Interpolation.nearest);
    var modelTransferInput = _imageToByteListUInt8(modelTransferImage, MODEL_TRANSFER_IMAGE_SIZE, 0, 255);

    var styleImage = img.decodeImage(styleData);
    var modelStyleImage = img.copyResize(styleImage, width: MODEL_STYLE_IMAGE_SIZE,height: MODEL_STYLE_IMAGE_SIZE);
    // content_image 384 384 3
    var modelStyleInput = _imageToByteListUInt8(modelStyleImage, MODEL_STYLE_IMAGE_SIZE, 0, 255);

    // style_image 1 256 256 3
    var inputsForStyle = [modelStyleInput];
    var outputsForStyle = Map<int, dynamic>();

    // style_bottleneck 1 1 1 100
    var styleBottleneck = 
      [
      [
      [List.generate(100, (index) => 0.0)]
      ]];
    outputsForStyle[0] = styleBottleneck;

    // style predict model
    interpreterStyle.runForMultipleInputs(
      inputsForStyle, outputsForStyle);

    // content_image + styleBottleneck
    var inputsForStyleTransfer = [modelTransferInput, styleBottleneck];

    var outputsForStyleTransfer = Map<int, dynamic>();
    // stylized_image 1 384 384 3
    var outputImageData = 
      List.generate(
        MODEL_TRANSFER_IMAGE_SIZE,
          (index) =>
          List.generate(
            MODEL_TRANSFER_IMAGE_SIZE,
              (index) => List.generate(3, (index) => 0.0),
          ),
      )
    ;
    outputsForStyleTransfer[0] = [outputImageData];

    interpreterTransform.runForMultipleInputs(
      inputsForStyleTransfer, outputsForStyleTransfer);

    var outputImage = _convertArrayToImage([outputImageData], MODEL_TRANSFER_IMAGE_SIZE);
    var rotateOutputImage = img.copyRotate(outputImage, 90);
    var flipOutputImage = img.flipHorizontal(rotateOutputImage);
    var resultImage = img.copyResize(flipOutputImage, width: originImage.width, height: originImage.height);
    return img.encodeJpg(resultImage);
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

   img.Image _byteListUInt8ToImage(Uint8List outputImageData, int inputSize) {

    var buffer = Float32List.view(outputImageData.buffer);
    img.Image image = img.Image.rgb(inputSize, inputSize);
    int pixelIndex = 0;
    int mini = 255;
    int maxi = 0;
    for (var x = 0; x < inputSize; x++) {
      for (var y = 0; y < inputSize; y++) {
        var r = (buffer[pixelIndex++] * 255).toInt();
        mini = min(r, mini);
        maxi = max(r, maxi);

        var g = (buffer[pixelIndex++] * 255).toInt();
        mini = min(g, mini);
        maxi = max(g, maxi);

        var b = (buffer[pixelIndex++] * 255).toInt();
        mini = min(b, mini);
        maxi = max(b, maxi);


        image.setPixelRgba(x, y, r, g, b);
      }
    }
    print("min = $mini max = $maxi");
    return image;
  }




  Tensor runStylePredict(preprocessedStyleImage){
    //the model is [interpreterStyle]
    
    //Set model input.
    interpreterStyle.allocateTensors();
    interpreterStyle.getInputTensor(0).setTo(preprocessedStyleImage);
    
    
    //Calculate style bottleneck.
    interpreterStyle.invoke();
    Tensor tensor = interpreterStyle.getOutputTensor(0);
    print(tensor);

    var styleBottleneck = tensor;

    return styleBottleneck;
  }


  Uint8List runStyleTransform(styleBottleneck, preprocessedContentImage){
    //the model is [interpreterTransform]
    interpreterTransform.allocateTensors();
    interpreterTransform.getInputTensor(0).setTo(preprocessedContentImage);
    print(interpreterTransform.getInputTensor(1));
    interpreterTransform.getInputTensor(1).setTo(styleBottleneck.data);


    interpreterTransform.invoke();
    Tensor tensor = interpreterTransform.getOutputTensor(0);
    print(tensor);
    
    var stylizedImage = tensor.data;
    return stylizedImage;

  }
  
  Uint8List imagePreprocess(Uint8List imageData, int requiredSize) {
    var image = img.decodeImage(imageData);
    var resizedImage = img.copyResize(image, width: requiredSize, height: requiredSize);
    //var modelStyleInput = _imageToByteListUInt8(resizedImage, requiredSize, 0, 255);
    return resizedImage.getBytes(format: Format.rgb);
  }




   Uint8List cleanTransfer(Uint8List originData, Uint8List styleData) {
    var originImage = img.decodeImage(originData);
    var originStyleImage = img.decodeImage(styleData);

    TensorImage originTensorImage = TensorImage.fromImage(originImage);
    TensorImage styleTensorImage = TensorImage.fromImage(originStyleImage);

    // style_image 1 256 256 3
    var preprocessedStyleImage = imageStyleProcessor.process(styleTensorImage).getBuffer();//imagePreprocess(styleData, MODEL_STYLE_IMAGE_SIZE);


    var styleBottleneck = runStylePredict(preprocessedStyleImage);
    print("style bottleNeck computed");

    // content_image 384 384 3
    var preprocessedContentImage = imageTransferProcessor.process(originTensorImage).getBuffer();//imagePreprocess(originData, MODEL_TRANSFER_IMAGE_SIZE);
    var outputImageData = runStyleTransform(styleBottleneck, preprocessedContentImage);
    print("output Image computed outputImageData = ${outputImageData.lengthInBytes}");

    img.Image image = _byteListUInt8ToImage(outputImageData, MODEL_TRANSFER_IMAGE_SIZE);
    return img.encodeJpg(image);
  }


}
