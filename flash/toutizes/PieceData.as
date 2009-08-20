package toutizes {
  [Bindable]
  public class PieceData {
    private var _cube:CubeData;	// The cube that contains this piece.
    private var _height:int;	// Height of the piece.
    private var _color:int;	// Color of the piece.
    private var _tower:TowerData; // null if not installed.

    public function PieceData(cube:CubeData, color:int, height:int) {
      _cube = cube;
      _color = color;
      _height = height;
      _tower = null;
    }

    public function toString():String {
      return "Piece { color:" + _color + ", height:" + _height + "}";
    }

    public function get color():int {
      return _color;
    }

    public function get height():int {
      return _height;
    }

    public function get tower():TowerData {
      return _tower;
    }

    public function set tower(value:TowerData):void {
      _tower = value;
    }

    public function remove():Boolean {
      return _cube.removePiece(this);
    }

    public function tricky():Boolean {
      return (_color == 5 && _height == 5) ||
	(_color == 3 && _height == 4);
    }
  }
}