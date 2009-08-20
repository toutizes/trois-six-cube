package toutizes {
  import flash.events.MouseEvent;
  import flash.filters.GlowFilter;
  import mx.binding.utils.BindingUtils;
  import mx.containers.Canvas;
  import mx.controls.Alert;
  import mx.controls.Label;
  import mx.core.DragSource;
  import mx.core.IUIComponent;
  import mx.effects.Fade;
  import mx.events.DragEvent;
  import mx.managers.DragManager;
  import toutizes.Cube;
  import toutizes.TowerData;

  public class Tower extends Canvas {
    private var _cube:Cube;
    private var _towerData:TowerData;

    private var _possibles:int;
    private var _bits:Array;
    private var _dropArea:Canvas;
    private var _trick:Canvas;
    private var _glowing:Boolean;

    private var _inBits:Fade;
    private var _outBits:Fade;
    private var _glowFilter:GlowFilter;

    private static var _xs:Array =
      [ 2 * Cube.SIZE, 5 * Cube.SIZE, 8 * Cube.SIZE,
	2 * Cube.SIZE, 5 * Cube.SIZE, 8 * Cube.SIZE];
    private static var _ys:Array =
      [ 2 * Cube.SIZE, 2 * Cube.SIZE, 2 * Cube.SIZE,
	8 * Cube.SIZE, 8 * Cube.SIZE, 8 * Cube.SIZE, ];

    public function Tower(cube:Cube, towerData:TowerData):void {
      _cube = cube;
      _towerData = towerData;
      _glowing = false;
      this.width = 12 * Cube.SIZE;
      this.height = 12 * Cube.SIZE;
      this.x = _towerData.col * 12 * Cube.SIZE;
      this.y = _towerData.row * 12 * Cube.SIZE;

      createEffects();
      createDropArea();
      createTrick();
      createBits();

      addEventListener(MouseEvent.MOUSE_OVER, towerOver);
      addEventListener(MouseEvent.MOUSE_OUT, towerOut);

      addEventListener(DragEvent.DRAG_ENTER, dragEnter);
      addEventListener(DragEvent.DRAG_OVER, dragOver);
      addEventListener(DragEvent.DRAG_EXIT, dragExit);
      addEventListener(DragEvent.DRAG_DROP, dragDrop);

      BindingUtils.bindProperty(this, "possibles", _towerData, "possibles");
    }

    public function get towerData():TowerData {
      return _towerData;
    }

    public function set possibles(possibles:int):void {
      var inBits:Array = [];
      var outBits:Array = [];
      for (var color:int = 0; color < 6; color++) {
	var mask:int = 1 << color;
	if ((_possibles & mask) != (possibles & mask)) {
	  if (possibles & mask) {
	    inBits.push(_bits[color]);
	  } else {
	    outBits.push(_bits[color]);
	  }
	}
      }

      _inBits.end();
      _outBits.end();
      _inBits.play(inBits);
      _outBits.play(outBits);

      _possibles = possibles;
    }

    public function set glowing(glowing:Boolean):void {
      if (glowing == _glowing) {
	return;
      }
      if (glowing) {
	if (_trick != null) {
	  _trick.alpha = 0;
	}
	filters = [_glowFilter];
      } else {
	if (_trick != null) {
	  _trick.alpha = 0.7;
	}
	filters = [];
      }
      _glowing = glowing;
    }

    private function createDropArea():void {
      var canvas:Canvas = new Canvas();
      canvas.setStyle("backgroundColor", 0xfefefe);
      canvas.setStyle("borderStyle", "solid");
      canvas.setStyle("borderColor", 0x707070);
      canvas.setStyle("borderThickness", 2);
      canvas.alpha = 0.1;
      canvas.x = Cube.SIZE
      canvas.y = Cube.SIZE;
      canvas.width = 10 * Cube.SIZE;
      canvas.height = 10 * Cube.SIZE;
      addChild(canvas);
      _dropArea = canvas;
    }

    private function createTrick():void {
      if (_towerData.tricky()) {
	_trick = new Canvas();
	_trick.width = _dropArea.width;
	_trick.height = 1;
	_trick.x = _dropArea.x;
	_trick.y = _dropArea.y + _dropArea.height - 1;
	_trick.alpha = 0.7;
	_trick.setStyle("backgroundColor", 0xffffff);
	addChild(_trick);
      }
    }

    private function createBits():void {
      var label:Label = new Label();
      label.x = (this.width - label.measuredWidth) / 2.7;
      label.y = (this.height - label.measuredHeight) / 4;
      label.styleName = "large";
      label.text = Cube.towerLabel(_towerData);
      this.addChild(label);

      _bits = [];
      for (var color:int = 0; color < 6; color++) {
	var bit:Canvas = colorBit(color);
	this.addChild(bit);
	_bits.push(bit);
      }
    }

    private function colorBit(color:int):Canvas {
      var canvas:Canvas = new Canvas();
      canvas.setStyle("backgroundColor", Cube.COLORS[color]);
      canvas.alpha = 0.3;
      canvas.x = _xs[color];
      canvas.y = _ys[color];
      canvas.width = 2 * Cube.SIZE;
      canvas.height = 2 * Cube.SIZE;
      canvas.buttonMode = true;
      canvas.data = _towerData.colorPiece(color);
      canvas.addEventListener(MouseEvent.CLICK, bitClick);
      canvas.toolTip = "Clickez moi pour installer une piece de la bonne taille.";
      return canvas;
    }

    private function bitClick(event:MouseEvent):void {
      _towerData.putPiece(PieceData(event.currentTarget.data));
    }

    private function createEffects():void {
      _inBits = new Fade();
      _inBits.alphaFrom = 0.0;
      _inBits.alphaTo = 0.3;

      _outBits = new Fade();
      _outBits.alphaFrom = 0.3;
      _outBits.alphaTo = 0.0;

      _glowFilter = new GlowFilter(0xc0c0c0, 1.0, 2.0, 2.0);
    }

    private function towerOver(event:MouseEvent):void {
      if (!_cube.dragging) {
	_cube.glowTowers(_towerData.height, true);
      }
    }

    private function towerOut(event:MouseEvent):void {
      if (!_cube.dragging) {
	_cube.glowTowers(_towerData.height, false);
      }
    }

    private function dragEnter(event:DragEvent):void {
      var piece:PieceData = PieceData(event.dragSource.dataForFormat('piece'));
      if (piece != null && _towerData.canPut(piece)) {
	DragManager.acceptDragDrop(this);
      }
    }
                
    internal function dragOver(event:DragEvent):void {
      var piece:PieceData = PieceData(event.dragSource.dataForFormat('piece'));
      // Highlight less for trick pieces.
      if (piece.height == _towerData.height) {
	_dropArea.setStyle("borderColor", 0x202020);
	_dropArea.setStyle("borderThickness", 5);
      } else {
	_dropArea.setStyle("borderColor", 0x707070);
	_dropArea.setStyle("borderThickness", 3);
      }
    }

    internal function dragExit(event:DragEvent):void {
      _dropArea.setStyle("borderColor", 0x707070);
      _dropArea.setStyle("borderThickness", 2);
    }

    internal function dragDrop(event:DragEvent):void {
      var piece:PieceData = PieceData(event.dragSource.dataForFormat('piece'));
      _towerData.putPiece(piece);
      _dropArea.setStyle("borderColor", 0x707070);
      _dropArea.setStyle("borderThickness", 2);
    }
  }
}

