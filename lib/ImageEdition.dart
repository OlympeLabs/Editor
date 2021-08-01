List<Uint8List> splitImage(img.Image originImage, int originWidth, int originHeight, int nbRow, int nbCol) {
  int subWidth = (originWidth / nbRow).ceil();
  int subHeight = (originHeight / nbCol).ceil();

  int offsetX = 0;
  int offsetY = 0;

  List<Uint8List> images = List(nbRow * nbCol);

  for (int j = 0; j < nbCol; j++) {
    offsetY = j * subHeight;
    for (int i = 0; i < nbRow; i++) {
      offsetX = i * subWidth;
      images[nbRow * j + i] = img.encodeJpg(img.copyCrop(originImage, offsetX, offsetY, subWidth, subWidth));
      print(" split  done ${((nbRow * j + i) / (nbRow * nbCol)) * 100}%");
    }
  }
  return images;
}

Uint8List joinImages(List<Uint8List> imageSplited, int originWidth, int originHeight, int nbRow, int nbCol) {
  img.Image finalImg = img.Image(originWidth, originHeight);
  int offsetX = 0;
  int offsetY = 0;
  int subWidth = (originWidth / nbRow).ceil();
  int subHeight = (originHeight / nbCol).ceil();

  for (int j = 0; j < nbCol; j++) {
    offsetY = j * subHeight;
    for (int i = 0; i < nbRow; i++) {
      offsetX = i * subWidth;
      img.copyInto(finalImg, img.decodeImage(imageSplited[nbRow * j + i]), dstX: offsetX, dstY: offsetY, srcX: 0, srcY: 0, srcH: subHeight, srcW: subWidth);
      print(" join done ${((nbRow * j + i) / (nbRow * nbCol)) * 100}%");
    }
  }
  return img.encodeJpg(finalImg);
}
