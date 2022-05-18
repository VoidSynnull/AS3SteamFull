package game.components.entity.collider
{
	import flash.utils.Dictionary;
	import ash.core.Component;
	
	public class ZoneCollider extends Component
	{
		public var isHit:Boolean = false;
		public var zones:Dictionary = new Dictionary(true);
		
		override public function destroy():void
		{
			zones = null;
			isHit = false;
		}
	}
}