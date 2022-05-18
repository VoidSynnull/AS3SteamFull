package game.ui.elements
{
	import com.greensock.TweenMax;
	import com.greensock.easing.Sine;
	
	import flash.display.MovieClip;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.events.MouseEvent;
	import flash.geom.Point;
	import flash.text.TextField;
	import flash.text.TextFormat;
	
	public class Dial extends EventDispatcher
	{
		
		public function Dial()
		{
		}
		
		public function init (__asset:MovieClip, __format:TextFormat): void {
			_asset = __asset
			
			_asset.mcCenterLine.cacheAsBitmap = true
			_asset.mcTopShadow.cacheAsBitmap = true
			
			_bg = _asset.bg
			
			_format = __format
			_entries = new Vector.<DialEntry>
			_lineSpacing = _format.size + _format.leading
			_tfContainer = _asset.tfContainer
			
			active = true
		}
		
		public function set active(value:Boolean):void
		{
			_active = value;
			if (_active) {
				_asset.addEventListener(MouseEvent.MOUSE_DOWN,onMouseDown)
			} else {
				_asset.removeEventListener(MouseEvent.MOUSE_DOWN,onMouseDown)
				_asset.stage.removeEventListener(MouseEvent.MOUSE_UP,onMouseUp)
				_asset.removeEventListener(Event.ENTER_FRAME,onEnterFrameDrag)
			}
		}
		
		public function addEntry (e:DialEntry): void {
			var tf:TextField = new TextField()
			tf.text = e.label
			tf.setTextFormat(_format)
			tf.embedFonts = true
			tf.selectable = false
			tf.width = 235
			tf.height = 50
			tf.y = _lineSpacing*_entries.length
			_asset.tfContainer.addChild (tf)
			_entries.push(e)
		}
		
		private function get entryNum (): int {
			var p:int = 0
			if (_currentEntry) {
				p = _entries.indexOf(_currentEntry)
			}
			return p
		}
		
		private function onMouseDown (e:MouseEvent): void {
			if (_entries.length > 0){
				//trace ("[Dial] onMouseDown")
				TweenMax.killTweensOf(_tfContainer)
				_asset.removeEventListener (Event.ENTER_FRAME,onEnterFrameUpdateAfterRelease)
				_asset.addEventListener (Event.ENTER_FRAME,onEnterFrameDrag)
				_asset.stage.addEventListener(MouseEvent.MOUSE_UP,onMouseUp)
				_origX = e.stageX
				_origY = e.stageY
				_offsetX = _tfContainer.x - e.stageX
				_offsetY = _tfContainer.y - e.stageY
			}
		}
		
		private function onEnterFrameDrag (e:Event): void {
			var prevY:Number = _tfContainer.y
			var newY:Number = _asset.stage.mouseY + _offsetY
			if (prevY != newY) {
				_scrollSpeed = newY - prevY
				_tfContainer.y = newY
				draw()
			}
		}
		
		private function draw(): void {
			var dir:int = Math.abs (_scrollSpeed)/_scrollSpeed
				
			var tf:TextField;
			var pt:Point
			var i:int
			
			for (i = 0; i < _entries.length ; i++ ){
				tf = _tfContainer.getChildAt(i) as TextField
				pt = _tfContainer.localToGlobal(new Point (tf.x,tf.y))
				pt = _asset.globalToLocal(pt)
				if (dir>0) {
					if (pt.y > _bg.height + _lineSpacing) {
						//trace ("[Dial] entry " + i + " offscreen")
						tf.y = tf.y - _entries.length * _lineSpacing
					} 
				} else {
					if ( pt.y < -_lineSpacing) {
						if ((pt.y + _entries.length * _lineSpacing) < (_bg.height + 60))  {
							//trace ("i:" + i +":" + (pt.y + _entries.length * _lineSpacing) + "  _bg.height+60:" + (_bg.height+60))
							tf.y = tf.y + _entries.length * _lineSpacing
						}
					}
				}
			}
		}
		
		public function onMouseUp (e:MouseEvent): void {
			_asset.stage.removeEventListener(MouseEvent.MOUSE_UP,onMouseUp)
			_asset.removeEventListener (Event.ENTER_FRAME,onEnterFrameDrag)
			_asset.addEventListener (Event.ENTER_FRAME,onEnterFrameUpdateAfterRelease)
		}
		
		private function onEnterFrameUpdateAfterRelease (e:Event): void 
		{
			draw()
			_tfContainer.y += _scrollSpeed
			_scrollSpeed *= .8
			if (Math.abs(_scrollSpeed) < 4) {
				stop()
			}
			
		}
		
//		if (Math.abs (_scrollSpeed) < SCROLL_SPEED_MIN) {
//				stop()
//			} else {
//				var newY:Number = _tfContainer.y + _scrollSpeed
//				trace ("_scrollSpeed:" + _scrollSpeed + " y:" + _tfContainer.y +  ",newY:" + newY)
//				var t:Number =.3 +  Math.abs (_scrollSpeed) / 100
//				TweenMax.to (_tfContainer,t, {y: newY, ease:Sine.easeOut, onComplete:stop})
//			}
//		}
		
		private function stop ():void{
			_asset.removeEventListener (Event.ENTER_FRAME,onEnterFrameUpdateAfterRelease)
			
			var shortestDist:Number = 99999
			var closestEntryNum:int = 0  
			
			var tf:TextField;
			var pt:Point;
			var diff:Number 
			
			for (var i:int = 0; i < _entries.length ; i++ ){
				tf = _tfContainer.getChildAt(i) as TextField
				pt = _tfContainer.localToGlobal(new Point (tf.x,tf.y))
				pt = _asset.globalToLocal(pt)
				diff = Math.abs (pt.y - _asset.mcCenterLine.y) 
				
				if (diff < shortestDist) {
					shortestDist = diff
					closestEntryNum = i
				}
			}
			setCurrentEntryByNum (closestEntryNum)
		}
		
		public function setCurrentEntryByNum (i:int, animate:Boolean = true): void {
			//trace ("setCurrentEntry to " + i )
			var tf:TextField = _tfContainer.getChildAt(i) as TextField
			var pt:Point = _tfContainer.localToGlobal(new Point (tf.x,tf.y))
			pt = _asset.globalToLocal(pt)
			//trace ("pt.y, line.y:" + pt.y + "," +)
			var newY:Number = _tfContainer.y + (_asset.mcCenterLine.y - pt.y)
			var time:Number = .3 + Math.abs (newY - _tfContainer.y) / 300
			if (animate) TweenMax.to (_tfContainer,time,{y:newY, ease:Sine.easeOut})
			else _tfContainer.y = newY
			//_currentEntry = 
		}
		
		public function setCurrentEntry (e:DialEntry): void {
			//pt = _entryContainer.localToGlobal(new Point (tf.x,tf.y))
			//pt = _asset.globalToLocal(pt)
		}
		
		private var _minY: Number
		private var _maxY: Number
		private var _bg:Sprite
		private var _active:Boolean = false
		private var _asset:MovieClip
		private var _currentEntry:DialEntry
		private var _entries:Vector.<DialEntry>;
		private var _origX:Number
		private var _origY:Number
		private var _offsetX:Number
		private var _offsetY:Number;
		private var _format:TextFormat
		private var _lineSpacing:int
		private var _tfContainer:MovieClip
		private var _scrollSpeed:Number = 0;
		
		private static const SCROLL_SPEED_MIN:int = 20 // How slow you must be scrolling for it to not have velocity, and stop immediately.
		
		private static const MARGIN:int = 10
		
	}
}