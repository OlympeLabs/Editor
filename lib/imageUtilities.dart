import 'dart:math';
import 'package:image/image.dart' as img;


List<int> noiseUpScaling(Map<String, List<int>> map) {
  List<int> original = map["original"];
  List<int> computed = map["computed"];
  double ratio = (map["ratio"][0] / 30);

  img.Image originalImage = img.decodeImage(original);
  img.Image computedImage = img.decodeImage(computed);
  if (originalImage.width * originalImage.height != computedImage.width * computedImage.height) {
    print("Error : Original and computed size different returning computed");
    return computed;
  }
  int width = computedImage.width;
  int height = computedImage.height;
  int convolutionradius = 1;
  List<double> convolutionMask = [0, 0.1, 0, 0.1, 0.6, 0.1, 0, 0.1, 0];
  img.Image upscaledImage = img.Image.rgb(width, height);
  for (var x = 0; x < width; x++) {
    for (var y = 0; y < height; y++) {
      if (x >= convolutionradius && x < width - convolutionradius && y >= convolutionradius && y < height - convolutionradius) {
        double convolutionFactor = 0;
        int index = 0;
        for (int i = -convolutionradius; i <= convolutionradius; i++) {
          for (int j = -convolutionradius; j <= convolutionradius; j++) {
            //if(convolutionMask[index] != 0){
            int pixelX = max(min(x + i, width), 0);
            int pixelY = max(min(y + j, height), 0);
            List<int> rgb = abgrToRGB(originalImage.getPixel(pixelX, pixelY));
            double lum = (rgb[0] + rgb[1] + rgb[2]) / 3;
            convolutionFactor += lum * convolutionMask[index];
            index++;
            //}
          }
        }
        List<int> rgb = abgrToRGB(computedImage.getPixel(x, y));

        int r = rgb[0];
        int g = rgb[1];
        int b = rgb[2];
        double lum = (r + g + b) / 3;
        double factor = ((ratio - 1) + (convolutionFactor / max(lum, 1))) / ratio;
        r = (r * factor).round();
        g = (g * factor).round();
        b = (b * factor).round();

        r = max(min(r, 255), 0);
        g = max(min(g, 255), 0);
        b = max(min(b, 255), 0);
        upscaledImage.setPixelSafe(x, y, img.getColor(r, g, b));
      } else {
        upscaledImage.setPixelSafe(x, y, computedImage.getPixel(x, y));
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
