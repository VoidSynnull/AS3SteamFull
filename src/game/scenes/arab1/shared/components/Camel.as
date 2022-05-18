package game.scenes.arab1.shared.components
{
	import ash.core.Component;
	import ash.core.Entity;
	
	public class Camel extends Component
	{
		public var leashLength:Number;
		public var walkDistance:Number;
		public var walkSpeed:Number;
		public var walkPullPadding:Number;
		
		public var handler:Entity;
		
		public var harnes:Entity;
		public var lead:Entity;
		public var leash:Entity;
		
		public function Camel(leashLength:Number = 400, walkSpeed:Number = 400, handler:Entity = null, walkPullPadding:Number = 50)
		{
			this.leashLength = leashLength;
			walkDistance = leashLength / 2;
			this.walkSpeed = walkSpeed;
			this.handler = handler;
			this.walkPullPadding = walkPullPadding;
		}
		
		public static const PULL:String	= "pull";
	}
}