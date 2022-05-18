package game.scenes.survival5.shared.whistle
{
	import flash.geom.Point;
	import flash.geom.Rectangle;
	
	import ash.core.Component;
	
	public class WhistleListener extends Component
	{
		public var listenArea:Rectangle;
		public var inspectTime:Number;
		
			// Parameters for returning to patrol
		public var alphaPoint:Point;
		public var betaPoint:Point;
		
		public var patrolTime:Number;
		public var alphaNext:Boolean = true;
		public var inspecting:Boolean = false;
		
		public function WhistleListener( listenArea:Rectangle = null, inspectTime:Number = 20, patrolTime:Number = 1, alphaPoint:Point = null, betaPoint:Point = null )
		{
			this.listenArea = listenArea;
			this.inspectTime = inspectTime;
			
			this.patrolTime = patrolTime;
			this.alphaPoint = alphaPoint;
			this.betaPoint = betaPoint;
		}
	}
}