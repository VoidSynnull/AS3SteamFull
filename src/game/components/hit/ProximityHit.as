package game.components.hit
{
	import ash.core.Entity;
	
	import ash.core.Component;
	
	public class ProximityHit extends Component
	{
		public function ProximityHit(hitWidth:Number = -1, hitHeight:Number = -1, hitRange:Number = -1)
		{
			this.hitWidth = hitWidth;
			this.hitHeight = hitHeight;
			this.hitRange = hitRange;
		}
		
		public var hitRange:Number;
		public var hitWidth:Number;
		public var hitHeight:Number;
		public var isHit:Boolean = false;
		public var colliderX:Number;
		public var colliderY:Number;
		public var colliderId:String;
		public var colliderWidth:Number;
		public var colliderHeight:Number;
		public var colliderEntity:Entity;
		
	}
}