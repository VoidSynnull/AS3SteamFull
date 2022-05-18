package game.scenes.examples.dynamicBoatScene
{
	import flash.geom.Rectangle;
	
	import ash.core.Component;
	
	public class EntityGridElement extends Component
	{
		public function EntityGridElement()
		{
			
		}
		
		public var show:Boolean = false;
		public var creator:*;
		public var data:*;
		public var hitArea:Rectangle;
	}
}