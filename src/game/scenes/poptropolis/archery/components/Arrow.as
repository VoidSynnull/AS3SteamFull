package game.scenes.poptropolis.archery.components 
{
	import flash.geom.Point;
	import flash.geom.Rectangle;
	
	import ash.core.Component;
	
	import org.osflash.signals.Signal;
	
	public class Arrow extends Component
	{
		public var mouse:Point;
		public var viewPort:Rectangle;
		
		public var firing:Boolean = false;
		public var fired:Boolean = false;
		public var targetX:Number;
		public var targetY:Number;
		public var finalScale:Number = .15;
		
		public var arrowReady:Signal;
		
		public function Arrow(mouse:Point, viewPort:Rectangle = null)
		{
			this.mouse = mouse;
			if(viewPort == null)
				viewPort = new Rectangle();
			this.viewPort = viewPort;
			arrowReady = new Signal();
		}
	}
}