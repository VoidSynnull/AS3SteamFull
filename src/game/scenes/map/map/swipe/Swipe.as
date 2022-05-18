package game.scenes.map.map.swipe
{
	import flash.geom.Rectangle;
	
	import ash.core.Component;
	import ash.core.Entity;
	
	import org.osflash.signals.Signal;
	
	public class Swipe extends Component
	{
		internal var _invalidate:Boolean 	= false;
		internal var _swiping:Boolean 		= false;
		internal var _active:Boolean		= false;
		
		internal var _startX:int;
		internal var _startY:int;
		
		internal var _stopX:int;
		internal var _stopY:int;
		
		internal var _time:Number = 0;
		
		/**
		 * The maximum amount of time you have to swipe. If a down interaction isn't followed by a
		 * subsequent up interaction within the allotted time, the swipe is cancelled.
		 */
		public var swipeTime:Number = 0.5;
		
		/**
		 * A Vector of Rectangles that define where a DisplayObject can't be swiped
		 * within its local coordinate space.
		 */
		public var rectangles:Vector.<Rectangle> = new Vector.<Rectangle>();
		
		/**
		 * If false, swipes are prevented from being triggered when the mouse moves
		 * out of a DisplayObject after a previous down interaction.
		 */
		public var swipeOnOut:Boolean = false;
		
		public var start:Signal = new Signal(Entity);
		public var stop:Signal 	= new Signal(Entity);
		
		public function Swipe()
		{
			
		}
		
		override public function destroy():void
		{
			this.start.removeAll();
			this.start = null;
			
			this.stop.removeAll();
			this.stop = null;
			
			super.destroy();
		}
		
		public final function get startX():int { return this._startX; }
		public final function get startY():int { return this._startY; }
		
		public final function get stopX():int { return this._stopX; }
		public final function get stopY():int { return this._stopY; }
		
		internal final function onDown(entity:Entity):void
		{
			this._invalidate 	= true;
			this._swiping		= true;
		}
		
		internal final function onUp(entity:Entity):void
		{
			if(this._active)
			{
				this._invalidate 	= true;
				this._swiping		= false;
				this._active		= false;
			}
		}
		
		internal final function onOut(entity:Entity):void
		{
			if(this._active && this.swipeOnOut)
			{
				this._invalidate 	= true;
				this._swiping		= false;
				this._active		= false;
			}
		}
	}
}