package game.scenes.survival2.trees.Milipede
{
	import flash.geom.Point;
	
	import ash.core.Component;
	import ash.core.Entity;
	
	import org.osflash.signals.Signal;
	
	public class BodySegment extends Component
	{
		public var length:Number;
		public var space:Number;
		public var currentPosition:Point;
		public var lastPosition:Point;
		public var leader:BodySegment;
		public var rotation:Number;
		public var moving:Boolean;
		public var move:Signal;
		
		public var maxBendRight:Number;
		public var maxBendLeft:Number;
		
		public var kinematicType:String;
		
		public static const LEAD:String = "lead";
		public static const FOLLOW:String = "follow";
		
		public function BodySegment(leader:BodySegment = null, length:Number = 1, space:Number = 0, maxBendRight:Number = 180, maxBendLeft:Number = -180, kinematicType:String = FOLLOW)
		{
			this.length = length;
			this.space = space;
			this.maxBendLeft = maxBendLeft;
			this.maxBendRight = maxBendRight;
			this.kinematicType = kinematicType;
			this.leader = leader;
			move = new Signal(Entity, Boolean);
			moving = false;
			rotation = 0;
		}
	}
}