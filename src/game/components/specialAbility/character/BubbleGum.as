package game.components.specialAbility.character
{
	import ash.core.Component;
	import ash.core.Entity;
	
	
	public class BubbleGum extends Component
	{
		public var gum:Entity;
		public var maxScale:Number;
		public var ax:Number;
		public var ay:Number;
		public var vx:Number = 0;
		public var vy:Number = 0;
		public var maxHeight:Number;
		public var popped:Boolean;
		public var particleClass:Class;
		public var trailsEmitter:Entity;
		
		public function BubbleGum(_gum:Entity, _particleClass:Class)
		{
			gum = _gum;
			particleClass = _particleClass;
			maxScale = Math.random()/2 + .75;
			ax = Math.random()*5 - 10;
			ay = -Math.random()*50 - 75;
			maxHeight = -Math.random()*50 - 125;
		}
	}
}