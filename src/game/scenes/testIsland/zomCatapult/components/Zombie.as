package game.scenes.testIsland.zomCatapult.components
{
	import ash.core.Component;
	
	import nape.phys.Body;
	
	public class Zombie extends Component
	{
		public var health:int = 3;
		public var body:Body;
		public var ko:Boolean;
	}
}