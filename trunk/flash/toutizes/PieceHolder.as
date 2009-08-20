package toutizes {
  import mx.containers.Canvas;
  import mx.controls.Label;
  import toutizes.Cube;
  import toutizes.Tower;

  public class PieceHolder extends Canvas {
    private var _cube:Cube;
    private var _pieceData:PieceData;
    private var _xOffset:int;

    public function PieceHolder(cube:Cube, pieceData:PieceData, xOffset:int):void {
      _cube = cube;
      _pieceData = pieceData;
      _xOffset = xOffset;
      draw();
    }

    private function draw():void {
      removeAllChildren();
      this.x = _pieceData.height * 3 * Cube.SIZE + _xOffset;
      this.y = _pieceData.color * 12 * Cube.SIZE;
      this.width = 3 * Cube.SIZE;
      this.height = 12 * Cube.SIZE;

      addChild(colorPiece());

      var label:Label = new Label();
      label.x = Cube.SIZE;
      label.y = Cube.SIZE;
      label.text = Cube.pieceLabel(_pieceData);
      label.styleName = "small";
      addChild(label);
    }

    private function colorPiece():Canvas {
      var canvas:Canvas = new Canvas();
      canvas.setStyle("backgroundColor", Cube.COLORS[_pieceData.color]);
      canvas.alpha = 0.3;
      canvas.x = Cube.SIZE;
      canvas.y = (9 - _pieceData.height) * Cube.SIZE;
      canvas.width = 2 * Cube.SIZE;
      canvas.height = (_pieceData.height + 2) * Cube.SIZE;
      return canvas;
    }
  }
}