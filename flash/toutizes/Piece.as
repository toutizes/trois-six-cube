package toutizes {
  import flash.events.MouseEvent;
  import flash.filters.GlowFilter;
  import flash.geom.Point;
  import mx.binding.utils.BindingUtils;
  import mx.containers.Canvas;
  import mx.core.DragSource;
  import mx.controls.Label;
  import mx.effects.Move;
  import mx.effects.Parallel;
  import mx.effects.Resize;
  import mx.effects.Rotate;
  import mx.events.DragEvent;
  import mx.events.EffectEvent;

  import mx.managers.DragManager;
  import toutizes.Tower;

  public class Piece extends Canvas {
    private var _cube:Cube;
    private var _pieceData:PieceData;
    private var _xOffset:int;
    private var _label:Label;
    private var _trick:Canvas;

    private var _tower:Tower;
    private var _glowing:Boolean;
    private var _dragging:Boolean;

    private var _movePiece:Move;
    private var _resizePiece:Resize;
    private var _installEffect:Parallel;
    private var _glowFilter:GlowFilter;

    public function Piece(cube:Cube, pieceData:PieceData, xOffset:int):void {
      _cube = cube;
      _pieceData = pieceData;
      _xOffset = xOffset;
      _trick = null;
      _tower = null;
      _glowing = false;
      _dragging = false;

      _movePiece = new Move(this);
      _resizePiece = new Resize(this);
      _installEffect = new Parallel(this);
      _installEffect.addChild(_movePiece);
      _installEffect.addChild(_resizePiece);
      _installEffect.addChild(new Rotate(this));
      _installEffect.addEventListener(EffectEvent.EFFECT_END, pieceInstalled);

      _glowFilter = new GlowFilter(0xc0c0c0, 1.0, 2.0, 2.0);

      createGraphics();

      BindingUtils.bindProperty(this, "tower", pieceData, "tower");

      addEventListener(MouseEvent.CLICK, pieceClick);
      addEventListener(MouseEvent.MOUSE_DOWN, mouseDown);
      addEventListener(MouseEvent.MOUSE_UP, mouseUp);

      addEventListener(MouseEvent.ROLL_OVER, rollOver);
      addEventListener(MouseEvent.ROLL_OUT, rollOut);

      addEventListener(DragEvent.DRAG_ENTER, dragEnter);
      addEventListener(DragEvent.DRAG_COMPLETE, dragComplete);

      addEventListener(DragEvent.DRAG_OVER, dragOver);
      addEventListener(DragEvent.DRAG_EXIT, dragExit);
      addEventListener(DragEvent.DRAG_DROP, dragDrop);
    }

    public function set tower(towerData:TowerData):void {
      if ((towerData == null && _tower == null) ||
	  (towerData != null && _tower == _cube.tower(towerData))) {
	return;
      }

      _installEffect.end();
      if (towerData == null) {
	showLabel(false);
	_movePiece.xTo = parkedX();
	_movePiece.yTo = parkedY();
	_resizePiece.widthTo = parkedWidth();
	_resizePiece.heightTo = parkedHeight();
      } else {
	_movePiece.xTo = towerData.col * 12 * Cube.SIZE + 2 * Cube.SIZE;
	_movePiece.yTo = towerData.row * 12 * Cube.SIZE + 2 * Cube.SIZE;;
	_resizePiece.widthTo = 8 * Cube.SIZE;
	_resizePiece.heightTo = 8 * Cube.SIZE;
      }
      _tower = _cube.tower(towerData);
      setToolTip();
      setTrick();
      _installEffect.play();
    }

    public function set glowing(glowing:Boolean):void {
      if (glowing == _glowing) {
	return;
      }
      if (glowing) {
	filters = [_glowFilter];
      } else {
	filters = [];
      }
      _glowing = glowing;
    }

    private function pieceClick(event:MouseEvent):void {
      if (_tower != null) {
	_pieceData.remove();
      }
    }

    private function pieceInstalled(event:EffectEvent):void {
      showLabel(_tower != null);
    }

    // Initiate drag and drop;
    private function mouseDown(event:MouseEvent):void {
      addEventListener(MouseEvent.MOUSE_MOVE, mouseMove);
    }

    private function mouseMove(event:MouseEvent):void {

      var dragInitiator:Canvas = Canvas(event.currentTarget);
      var dragSource:DragSource = new DragSource();
      dragSource.addData(_pieceData, 'piece');
      var proxy:Canvas = new Canvas();
      proxy.width = width;
      proxy.height = height;
      proxy.setStyle("backgroundColor", Cube.COLORS[_pieceData.color]);
      var label:Label = new Label();
      if (_tower != null) {
	label.x = 5 * Cube.SIZE;
	label.y = 5 * Cube.SIZE;
      } else {
	label.x = 2;
	label.y = 0;
      }
      label.text = Cube.pieceLabel(_pieceData);
      label.styleName = "small";
      proxy.addChild(label);
      _cube.dragging = true;
      DragManager.doDrag(dragInitiator, dragSource, event, proxy);
    }

    private function mouseUp(event:MouseEvent):void {
      removeEventListener(MouseEvent.MOUSE_MOVE, mouseMove);
    }

    private function dragComplete(event:DragEvent):void {
      removeEventListener(MouseEvent.MOUSE_MOVE, mouseMove);
      doGlow(false);
      _cube.dragging = false;
    }

    private function rollOver(event:MouseEvent):void {
      if (!_cube.dragging) {
	doGlow(true);
      }
    }

    private function rollOut(event:MouseEvent):void {
      if (!_cube.dragging) {
	doGlow(false);
      }
    }


    // Delegate drop reception to installation tower.
    private function dragEnter(event:DragEvent):void {
      var piece:PieceData = PieceData(event.dragSource.dataForFormat('piece'));
      if (piece != null && _tower != null && _tower.towerData.canPut(piece)) {
	DragManager.acceptDragDrop(this);
      }
    }
                
    private function dragOver(event:DragEvent):void {
      _tower.dragOver(event);
    }

    private function dragExit(event:DragEvent):void {
      _tower.dragExit(event);
    }

    private function dragDrop(event:DragEvent):void {
      _tower.dragDrop(event);
    }

    private function doGlow(glow:Boolean):void {
      glowing = glow;
      _cube.glowTowers(_pieceData.height, glow);
    }

    private function createGraphics():void { 
      setStyle("backgroundColor", Cube.COLORS[_pieceData.color]);
      this.buttonMode = true;
      this.x = parkedX();
      this.y = parkedY();
      this.width = parkedWidth();
      this.height = parkedHeight();
      if (_pieceData.tricky()) {
	_trick = new Canvas();
	_trick.width = 2 * Cube.SIZE;
	_trick.height = 1;
	_trick.x = this.width - _trick.width;
	_trick.y = this.height - _trick.height;
	_trick.alpha = 0.6;
	_trick.setStyle("backgroundColor", 0xffffff);
      }
      setToolTip();
      setTrick();

      _label = new Label();
      _label.x = 4.4 * Cube.SIZE;
      _label.y = 5.5 * Cube.SIZE;
      _label.styleName = "small";
    }

    private function setTrick():void {
      if (_trick == null) {
	return;
      }
      if (_tower == null && _trick.parent == null) {
	addChild(_trick);
      } else if (_tower != null && _trick.parent != null) {
	removeChild(_trick);
      }
    }

    private function setToolTip():void {
      if (_tower == null) {
	this.toolTip = "Glissez moi sur une des tours.";
      } else {
	this.toolTip =
	  "Glissez moi sur une des tours.\nClickez moi pour m'enlever.";
      }
    }

    private function showLabel(show:Boolean):void {
      if (show && _label.parent == null) {
	_label.text =
	  Cube.pieceLabel(_pieceData) + " [" +
	  Cube.towerLabel(_tower.towerData) + "]";
	addChild(_label);
      } else if (!show && _label.parent != null) {
	removeChild(_label);
      }
    }

    private function parkedX():int {
      return Cube.SIZE + _pieceData.height * 3 * Cube.SIZE + _xOffset;
    }

    private function parkedY():int {
      return (_pieceData.color * 12 * Cube.SIZE + 
	      (9 - _pieceData.height) * Cube.SIZE);
    }

    private function parkedWidth():int {
      return 2 * Cube.SIZE;
    }

    private function parkedHeight():int {
      return (_pieceData.height + 2) * Cube.SIZE;
    }
  }
}