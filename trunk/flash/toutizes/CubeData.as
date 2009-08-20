package toutizes {
  import toutizes.PieceData;
  import toutizes.TowerData;

  [Bindable]
  public class CubeData {
    private static var _heights:Array =
      [[0, 4, 3, 1, 2, 5],
       [1, 2, 5, 0, 4, 3],
       [4, 5, 2, 3, 1, 0],
       [3, 0, 4, 2, 5, 1],
       [5, 3, 1, 4, 0, 2],
       [2, 1, 0, 5, 3, 4]];

    private var _pieces:Array;	// [color][height]
    private var _towers:Array;	// [row][col]

    private var _towersByHeights:Array; // [height]

    private var _heightMasks:Array;
    private var _rowMasks:Array;
    private var _colMasks:Array;

    private var _score:int;

    private var _gridString:String;
    private var _updateGrid:Boolean;

    public function CubeData() {
      _towers = [];
      _towersByHeights = [[], [], [], [], [], []];
      _updateGrid = true;

      for (var row:int = 0; row < 6; row++) {
	var towerRow:Array = [];
	for (var col:int = 0; col < 6; col++) {
	  var height:int = _heights[row][col];
	  var tower:TowerData = new TowerData(this, row, col, height);
	  _towersByHeights[height].push(tower);
	  towerRow.push(tower);
	}
	_towers.push(towerRow);
      }

      _pieces = [];
      for (var color:int = 0; color < 6; color++) {
	var pieceRow:Array = [];
	for (height = 0; height < 6; height++) {
	  pieceRow.push(new PieceData(this, color, height));
	}
	_pieces.push(pieceRow);
      }

      _heightMasks = [];
      _rowMasks = [];
      _colMasks = [];
      for (var i:int = 0; i < 6; i++) {
	_heightMasks.push(0x3f);
	_rowMasks.push(0x3f);
	_colMasks.push(0x3f);
      }

      score = 0;
    }

    public function get score():int {
      return _score;
    }

    public function set score(value:int):void {
      _score = value;
    }

    public function towerData(row:int, col:int):TowerData {
      return _towers[row][col];
    }

    public function pieceData(color:int, height:int):PieceData {
      return _pieces[color][height];
    }

    public function canPut(piece:PieceData, tower:TowerData):Boolean {
      if (piece.tower == tower) {
	return true;
      }

      if (!heightMatches(piece, tower)) {
	return false;
      }

      var mask:int = colorMask(piece.color);

      var rowOk:Boolean;
      if (piece.tower != null && piece.tower.row == tower.row) {
	rowOk = true;
      } else {
	rowOk = ((_rowMasks[tower.row] & mask) != 0);
      }

      if (!rowOk) {
	return false;
      }

      var colOk:Boolean;
      if (piece.tower != null && piece.tower.col == tower.col) {
	colOk = true;
      } else {
	colOk = ((_colMasks[tower.col] & mask) != 0);
      }

      return colOk;
    }

    private function heightMatches(piece:PieceData, tower:TowerData):Boolean {
      // Trick pieces.
      if (tower.row == 1 && tower.col == 4 &&
	  piece.color == 5 && piece.height == 5) {
	return true;
      }

      if (tower.row == 3 && tower.col == 4 &&
	  piece.color == 3 && piece.height == 4) {
	return true;
      }

      // Regular pieces.
      return piece.height == tower.height;
    }

    public function putPiece(piece:PieceData, tower:TowerData):Boolean {
      if (!canPut(piece, tower)) {
	return false;
      }

      if (piece.tower == tower) {
	return true;
      }

      var oldUpdateGrid:Boolean = _updateGrid;
      _updateGrid = false;

      if (piece.tower != null) {
	clearTower(piece.tower, false);
      }

      if (tower.piece != null) {
	clearTower(tower);
      }

      var row:int = tower.row;
      var col:int = tower.col;
      var mask:int = colorMask(piece.color);
      var height:int = piece.height;

      _heightMasks[height] = _heightMasks[height] & ~mask;
      _rowMasks[row] = _rowMasks[row] & ~mask;
      _colMasks[col] = _colMasks[col] & ~mask;

      for (var i:int = 0; i < 6; i++) {
	setPossibles(_towers[i][col]);
	setPossibles(_towers[row][i]);
	setPossibles(_towersByHeights[height][i]);
      }

      tower.piece = piece;
      piece.tower = tower;
      score += 1;

      _updateGrid = oldUpdateGrid;
      if (_updateGrid) {
	this.gridString = buildGridString();
      }

      return true;
    }

    public function removePiece(piece:PieceData):Boolean {
      var tower:TowerData = piece.tower;
      if (tower == null) {
	return false;
      }
      return clearTower(tower);
    }

    public function clearTower(tower:TowerData,
			       setPieceTower:Boolean = true):Boolean {
      var piece:PieceData = tower.piece;
      if (piece == null) {
	return false;
      }

      var row:int = tower.row;
      var col:int = tower.col;
      var mask:int = colorMask(piece.color);
      var height:int = piece.height;

      _heightMasks[height] = _heightMasks[height] | mask;
      _rowMasks[row] = _rowMasks[row] | mask;
      _colMasks[col] = _colMasks[col] | mask;

      for (var i:int = 0; i < 6; i++) {
	setPossibles(_towers[i][col]);
	setPossibles(_towers[row][i]);
	setPossibles(_towersByHeights[height][i]);
      }

      if (setPieceTower) {
	piece.tower = null;
      }
      tower.piece = null;
      score -= 1;

      if (_updateGrid) {
	this.gridString = buildGridString();
      }

      return true;
    }

    private function colorMask(color:int):int {
      return 1 << color;
    }

    private function setPossibles(tower:TowerData):void {
      var possibles:int =
	_rowMasks[tower.row] & _colMasks[tower.col] &
	_heightMasks[tower.height];

      if (possibles != tower.possibles) {
	tower.possibles = possibles;
      }
    }

    public function set gridString(grid:String):void {
      _gridString = grid;
    }

    public function get gridString():String {
      return _gridString;
    }

    public function loadGrid(grid:String):void {
      if (grid.length != 73) {
	return;
      }

      _updateGrid = false;

      var index:int = 1;
      for (var col:int = 0; col < 6; col++) {
	for (var row:int = 0; row < 6; row++) {
	  if (grid.charAt(index) != "_") {
	    var color:int = parseInt(grid.charAt(index));
	    if (grid.charAt(index + 1) != "_") {
	      var height:int = parseInt(grid.charAt(index + 1));
	      var tower:TowerData = _towers[row][col];
	      putPiece(_pieces[color][height], _towers[row][col]);
	    }
	  }
	  index += 2;
	}
      }

      _updateGrid = true;
    }

    public function buildGridString():String {
      var grid:String = "g";

      for (var col:int = 0; col < 6; col++) {
	for (var row:int = 0; row < 6; row++) {
	  var tower:TowerData = _towers[row][col];
	  if (tower.piece == null) {
	    grid += "__";
	  } else {
	    grid += (tower.piece.color.toString() +
		     tower.piece.height.toString());
	  }
	}
      }

      return grid;
    }

    public function clear():void {
      _updateGrid = false;

      for (var col:int = 0; col < 6; col++) {
	for (var row:int = 0; row < 6; row++) {
	  clearTower(_towers[row][col]);
	}
      }

      _updateGrid = true;
    }

  }
}