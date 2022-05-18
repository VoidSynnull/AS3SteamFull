package game.scenes.virusHunter.brain.components
{
	import ash.core.Component;
	
	public class HitPoints extends Component
	{
		public function HitPoints($maxHitpoints:int)
		{
			maxHitpoints = $maxHitpoints;
		}
		
		public var maxHitpoints:int;
		public var hitPoints:int;
	}
}