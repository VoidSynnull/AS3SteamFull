package game.scenes.survival1.shared.components
{
	import ash.core.Component;
	import ash.core.Entity;
	
	import org.osflash.signals.Signal;
	
	public class BitmapClean extends Component
	{
		public var locked:Boolean = false;
		
		public var checked:Boolean 	= true;
		public var clean:Boolean 	= false;
		public var percent:Number = 0;
		
		public var radius:int;
		public var minPercent:Number;
		
		public var startCleaning:Signal = new Signal(Entity);
		public var stopCleaning:Signal 	= new Signal(Entity);
		public var cleaned:Signal 		= new Signal(Entity);
		
		public var elapsedTime:Number 	= 0;
		public var waitTime:Number 		= 0.1;
		
		public var cleaning:Boolean = false;
		
		public function BitmapClean(radius:int = 50, minPercent:Number = 1, locked:Boolean = false)
		{
			this.radius = radius;
			this.minPercent = minPercent;
			this.locked = locked;
		}
		
		override public function destroy():void
		{
			this.startCleaning.removeAll();
			this.stopCleaning.removeAll();
			this.cleaned.removeAll();
			
			super.destroy()
		}
		
		public function onDown(entity:Entity):void
		{
			this.cleaning = true;
		}
		
		public function onUp(entity:Entity):void
		{
			this.cleaning = false;
		}
	}
}