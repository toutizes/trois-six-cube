package toutizes {
  [Bindable]
  public class TowerData {
    private var _cube:CubeData;	// The cube that contains this tower.
    private var _row:int;	// Row in the cube.
    private var _col:int;	// Column in the cube.
    private var _height:int;	// Height of the tower.

    private var _possibles:int;	  // Bitmask of possible colors.
    private var _piece:PieceData; // Piece installed on the tower.

    public function TowerData(cube:CubeData, row:int, col:int, height:int) {
      _cube = cube;
      _row = row;
      _col = col;
      _height = height;
      _possibles = 0x3f;
      _piece = null;
    }

    public function toString():String {
      return "Tower { row: " + _row + ", col:" + _col + ", height:" + _height +
	", piece: " + piece + "}";
	
    }
    public function get row():int {
      return _row;
    }

    public function get col():int {
      return _col;
    }

    public function get height():int {
      return _height;
    }

    public function get possibles():int {
      return _possibles;
    }

    public function set possibles(value:int):void {
     _possibles = value;
    }

    public function get piece():PieceData {
      return _piece;
    }

    public function set piece(value:PieceData):void {
      _piece = value;
    }

    public function canPut(piece:PieceData):Boolean {
      var can:Boolean = _cube.canPut(piece, this);
      return can;
    }

    public function putPiece(piece:PieceData):Boolean {
      return _cube.putPiece(piece, this);
    }

    public function colorPiece(color:int):PieceData {
      return _cube.pieceData(color, _height);
    }

    public function tricky():Boolean {
      return (_row == 1 && _col == 4) || (_row == 3 && _col == 4);
    }
  }
}