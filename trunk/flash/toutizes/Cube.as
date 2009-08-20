package toutizes {
  import mx.binding.utils.BindingUtils;
  import mx.containers.Canvas;
  import mx.controls.Label;
  import mx.core.DragSource;
  import mx.core.IUIComponent;
  import mx.events.DragEvent;
  import mx.managers.DragManager;
  import mx.rpc.http.HTTPService;
  import mx.rpc.events.ResultEvent;

  import toutizes.CubeData;
  import toutizes.PieceData;
  import toutizes.TowerData;

  public class Cube {
    public static var COLORS:Array = [ 0xff000e, 0x00b91e, 0x412ad9,
				       0xf9f500, 0x00ccfe, 0xff9700 ];
    public static const SIZE:int = 8;
    
    private var _canvas:Canvas;
    private var _cubeData:CubeData;
    private var _service:HTTPService;

    private var _towersByHeight:Array;
    private var _piecesByHeight:Array;
    private var _dragging:Boolean;

    public function Cube(canvas:Canvas) {
      _canvas = canvas;
      draw();
    }

    private function draw():void {
      canvas.removeAllChildren();

      _cubeData = new CubeData();
      _dragging = false;

      _towersByHeight = [[], [], [], [], [], []];
      for (var row:int = 0; row < 6; row++) {
	for (var col:int = 0; col < 6; col++) {
	  var tower:Tower = new Tower(this, _cubeData.towerData(row, col));
	  _towersByHeight[tower.towerData.height].push(tower);
	  canvas.addChild(tower);
	}
      }

      _piecesByHeight = [[], [], [], [], [], []];
      for (var color:int = 0; color < 6; color++) {
	for (var height:int = 0; height < 6; height++) {
	  var pieceData:PieceData = _cubeData.pieceData(color, height);
	  canvas.addChild(new PieceHolder(this, pieceData, 580));
	  var piece:Piece = new Piece(this, pieceData, 580);
	  _piecesByHeight[height].push(piece);
	  canvas.addChild(piece);
	}
      }

      canvas.addEventListener(DragEvent.DRAG_ENTER, dragEnter);
      canvas.addEventListener(DragEvent.DRAG_DROP, dragDrop);

      _service = new HTTPService();
    }

    public function get canvas():Canvas {
      return _canvas;
    }

    public function get cubeData():CubeData {
      return _cubeData;
    }

    public function get dragging():Boolean {
      return _dragging;
    }

    public function set dragging(value:Boolean):void {
      _dragging = value;
    }

    public function tower(towerData:TowerData):Tower {
      if (towerData == null) {
	return null;
      }
      for (var i:int = 0; i < 36; i++) {
	var tower:Tower = Tower(_canvas.getChildAt(i));
	if (tower.towerData == towerData) {
	  return tower;
	}
      }
      return null;
    }

    public function glowTowers(height:int, glowing:Boolean):void {
      for (var i:int = 0; i < 6; i++) {
	_towersByHeight[height][i].glowing = glowing;
      }
    }

    public function glowPieces(height:int, glowing:Boolean):void {
      for (var i:int = 0; i < 6; i++) {
	_piecesByHeight[height][i].glowing = glowing;
      }
    }

    public static function pieceLabel(pieceData:PieceData):String {
      return (pieceData.height + 1).toString();
    }

    public static function towerLabel(towerData:TowerData):String {
      return (towerData.height + 1).toString();
    }

    private function dragEnter(event:DragEvent):void {
      if (event.dragSource.hasFormat('piece')) {
	DragManager.acceptDragDrop(IUIComponent(event.currentTarget));
      }
    }

    private function dragDrop(event:DragEvent):void {
      var piece:PieceData = PieceData(event.dragSource.dataForFormat('piece'));
      if (piece.tower != null) {
	piece.remove();
      }
    }

    public function loadGrid():void {
      _service.url = "play/grid";
      _service.method = "GET";
      _service.addEventListener(ResultEvent.RESULT, gridLoaded);
      _service.send();
    }

    private function gridLoaded(event:ResultEvent):void {
      _service.removeEventListener(ResultEvent.RESULT, gridLoaded);
      _cubeData.loadGrid(String(event.result));
      BindingUtils.bindProperty(this, "gridString", _cubeData, "gridString");
    }

    public function set gridString(value:String):void {
      if (value == null || value.length != 73) {
	return;
      }
      _service.url = "play/move";
      _service.method = "GET";
      _service.addEventListener(ResultEvent.RESULT, gridSent);
      _service.send({grid:value, score:_cubeData.score});
    }

    private function gridSent(event:ResultEvent):void {
      _service.removeEventListener(ResultEvent.RESULT, gridSent);
    }
 
    public function reset():void {
      trace("reset");
      _service.url = "play/restart";
      _service.method = "GET";
      _service.addEventListener(ResultEvent.RESULT, gameRestarted);
      _service.send();
    }

    private function gameRestarted(event:ResultEvent):void {
      trace("restarted: " + event.result);
      _service.removeEventListener(ResultEvent.RESULT, gameRestarted);
      draw();
    }
  }
}