package game.components.motion
{
	import ash.core.Component;
	import ash.core.Entity;
	
	import org.osflash.signals.Signal;
	
	public class Draggable extends Component
	{
		public var dragging:Signal 	= new Signal(Entity);
		public var drag:Signal 		= new Signal(Entity);
		public var drop:Signal 		= new Signal(Entity);
		
		public var axis:String;
		
		public var offsetX:Number = NaN;
		public var offsetY:Number = NaN;
		
		public var _active:Boolean 		= false;
		public var _invalidate:Boolean 	= false;
		public var disable:Boolean 		= false;
		public var forceOffset:Boolean = false;
		
		public var forward:Boolean = true;
		
		public function Draggable(axis:String = null)
		{
			this.axis = axis;
		}
		
		override public function destroy():void
		{
			this.dragging.removeAll();
			this.dragging = null;
			this.drag.removeAll();
			this.drag = null;
			this.drop.removeAll();
			this.drop = null;
			super.destroy();
		}
		
		public function onDrag(entity:Entity = null):void
		{
			this._active 		= true;
			this._invalidate 	= true;
		}
		
		public function onDrop(entity:Entity = null):void
		{
			this._active 		= false;
			this._invalidate 	= true;
		}
	}
}