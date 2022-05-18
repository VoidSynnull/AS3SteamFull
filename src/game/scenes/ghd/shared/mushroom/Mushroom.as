package game.scenes.ghd.shared.mushroom
{
	import ash.core.Component;
	import ash.core.Entity;
	
	import game.components.hit.Bounce;
	import game.components.hit.Wall;
	import game.components.timeline.Timeline;
	
	public class Mushroom extends Component
	{
		internal var _invalidate:Boolean = false;
		internal var _facingLeft:Boolean = false;
		internal var _moving:Boolean = false;
		
		public var bounceLeft:Entity;
		public var bounceLeftDelta:Bounce;
		public var wallLeftDelta:Wall;
		
		public var bounceRight:Entity;
		public var bounceRightDelta:Bounce;
		public var wallRightDelta:Wall;
		
		public var stemTimeline:Timeline = null;
		
		public function Mushroom()
		{
			super();
		}
		
		public function get isFacingLeft():Boolean
		{
			return this._facingLeft;
		}
		
		public function set isFacingLeft( isFacingLeft:Boolean ):void
		{
			this._facingLeft = isFacingLeft;
			this._invalidate = true;
		}
		
		public function get isInvalid():Boolean
		{
			return this._invalidate;
		}
		
		public function get isMoving():Boolean
		{
			return this._moving;
		}
		
		public function set isMoving( isMoving:Boolean ):void
		{
			this._moving = isMoving;
		}
	}
}