package game.scenes.deepDive3.shared.components
{
	import ash.core.Component;
	import ash.core.Entity;
	
	public class Orb extends Component
	{
		public function Orb($player:Entity):void{
			player = $player;
		}
		
		public var player:Entity;
	}
}