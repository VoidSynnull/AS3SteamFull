package game.scenes.survival5.shared.whistle
{
	import flash.geom.Point;
	import flash.geom.Rectangle;

	public class ListenerData
	{
		public var id:String;
		public var caughtPlayer:Function;
		public var lookDistance:Number;
		public var listenArea:Rectangle;
		public var inspectTime:Number;
		
		// FOR PATROL
		public var patrolTime:Number;
		public var alphaPoint:Point;
		public var betaPoint:Point;
		
		public function ListenerData(id:String, caughtPlayer:Function, lookDistance:Number = 400, listenArea:Rectangle = null, inspectTime:Number = 20, patrolTime:Number = 1, alphaPoint:Point = null, betaPoint:Point = null )
		{
			this.id = id;
			this.caughtPlayer = caughtPlayer;
			this.lookDistance = lookDistance;
			this.listenArea = listenArea;
			this.inspectTime = inspectTime;
			this.patrolTime = patrolTime;
			this.alphaPoint = alphaPoint;
			this.betaPoint = betaPoint;
		}
	}
}