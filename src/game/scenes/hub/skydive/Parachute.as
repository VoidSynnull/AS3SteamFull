package game.scenes.hub.skydive
{
	import ash.core.Component;
	import ash.core.Entity;
	
	public class Parachute extends Component
	{
		public function Parachute(entity:Entity)
		{
			this.entity = entity;
		}
		
		public var deploy:Boolean = false;
		public var deployed:Boolean = false;  
		public var entity:Entity;
	}
}