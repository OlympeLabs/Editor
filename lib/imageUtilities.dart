import 'dart:math';
import 'dart:typed_data';
import 'package:image/image.dart' as img;

//use the original image to add the original noise to the computted Image
List<int> noiseUpScaling(Map<String, List<int>> map) {
  assert(map["original"] != null &&
      map["computed"] != null &&
      map["ratio"] != null);
  List<int> original = map["original"]!;
  List<int> computed = map["computed"]!;
  double ratio = (map["ratio"]![0] / 30) + 1;

  img.Image? originalImage = img.decodeImage(original as Uint8List);
  img.Image? computedImage = img.decodeImage(computed as Uint8List);
  if (originalImage == null || computedImage == null) {
    print("Error : original or computed image null");
    return computed;
  }
  if (originalImage.width * originalImage.height !=
      computedImage.width * computedImage.height) {
    print("Error : Original and computed size different returning computed");
    return computed;
  }
  int width = computedImage.width;
  int height = computedImage.height;
  int convolutionradius = 1;
  List<double> convolutionMask = [0, 0.1, 0, 0.1, 0.6, 0.1, 0, 0.1, 0];
  img.Image upscaledImage = img.Image.empty();
  //complexity : O((W*H) * ([convolutionradius]+2)²)
  for (int x = 0; x < width; x++) {
    for (int y = 0; y < height; y++) {
      if (x >= convolutionradius &&
          x < width - convolutionradius &&
          y >= convolutionradius &&
          y < height - convolutionradius) {
        double convolutionFactor = 0;
        int index = 0;
        for (int i = -convolutionradius; i <= convolutionradius; i++) {
          for (int j = -convolutionradius; j <= convolutionradius; j++) {
            //if(convolutionMask[index] != 0){
            if (convolutionMask[index] > 0.0) {
              int pixelX = max(min(x + i, width), 0);
              int pixelY = max(min(y + j, height), 0);
              img.Pixel rgb = originalImage.getPixel(pixelX, pixelY);
              num lum = rgb.luminance;
              convolutionFactor += lum * convolutionMask[index];
            }
            index++;
            //}
          }
        }
        img.Pixel rgb = computedImage.getPixel(x, y);

        num r = rgb.r;
        num g = rgb.g;
        num b = rgb.b;
        num lum = rgb.luminance;
        double factor =
            ((ratio - 1) + (convolutionFactor / max(lum, 1))) / ratio;
        r = (r * factor).round();
        g = (g * factor).round();
        b = (b * factor).round();

        r = max(min(r, 255), 0);
        g = max(min(g, 255), 0);
        b = max(min(b, 255), 0);
        upscaledImage.setPixelRgb(
          x,
          y,
          r,
          g,
          b,
        );
      } else {
        img.Pixel rgb = computedImage.getPixel(x, y);

        num r = rgb.r;
        num g = rgb.g;
        num b = rgb.b;
        upscaledImage.setPixelRgb(
          x,
          y,
          r,
          g,
          b,
        );
      }
    }
  }
  return img.encodeJpg(upscaledImage);
}

List<int> abgrToRGB(int abgr) {
  int b = (abgr >> 16) & 0xFF;
  int g = (abgr >> 8) & 0xFF;
  int r = abgr & 0xFF;
  return [r, g, b];
}

List<int> computeThumbnailsByWidth(Map<String, List<int>> map) {
  assert(map["imgBytes"] != null && map["maxWidth"] != null);
  List<int> imgBytes = map["imgBytes"]!;
  int maxWidth = map["maxWidth"]![0];

  img.Image? originalImage = img.decodeImage(imgBytes as Uint8List);
  if (originalImage == null) {
    print("Error : original image null");
    return imgBytes;
  }
  int originalW = originalImage.width;
  int originalH = originalImage.height;
  double scaleW = originalW / maxWidth;

  if (scaleW > 1) {
    int w = maxWidth;
    int h = ((originalH / originalW) * maxWidth).round();
    return img.encodeJpg(img.copyResize(originalImage, width: w, height: h));
  }
  return imgBytes;
}
