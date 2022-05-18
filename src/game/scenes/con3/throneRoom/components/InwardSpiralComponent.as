package game.scenes.con3.throneRoom.components
{
	import flash.geom.Point;
	
	import ash.core.Component;
	
	import org.osflash.signals.Signal;
	
	public class InwardSpiralComponent extends Component
	{
		public function InwardSpiralComponent( centerPoint:Point, handler:Function = null )
		{
			this.centerPoint = centerPoint;
			
			if( handler )
			{
				this.reachedCenter = new Signal();
				this.reachedCenter.addOnce( handler );
			}
		}
		
		public var radius:Number;
		public var angle:Number;
		public var centerPoint:Point;
		public var reachedCenter:Signal;
		
		public var rotation:Number = 5;
		public var angleStep:Number = .06;
		public var radiusStep:Number = .8;
	}
}