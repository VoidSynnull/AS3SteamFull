package game.data.motion.spring
{
	import flash.geom.Point;

	public class SpringData
	{	
		public var joint:String;
		public var leader:String;
		public var spring:Number;
		public var damp:Number;
		public var rotateRatio:Number;
		public var rotateByVelocity:Boolean;
		public var rotateByLeader:Boolean;	// only one ratio should be set
		public var offsetX:int;
		public var offsetY:int;	
	}
}