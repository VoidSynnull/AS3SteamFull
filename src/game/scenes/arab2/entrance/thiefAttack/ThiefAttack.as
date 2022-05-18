package game.scenes.arab2.entrance.thiefAttack
{
	import ash.core.Component;
	import ash.core.Entity;
	
	public class ThiefAttack extends Component
	{
		public var startX:Number;
		public var startY:Number;
		internal var _attacking:Boolean = false;
		internal var _distance:Number = 200;
		internal var _target:Entity;
		
		public function ThiefAttack(distance:Number = 200)
		{
			this.distance = distance;
		}

		public function get distance():Number
		{
			return _distance;
		}

		public function set distance(distance:Number):void
		{
			if(isFinite(distance))
			{
				_distance = distance;
			}
		}
	}
}