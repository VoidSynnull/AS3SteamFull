package game.scenes.virusHunter.day2Heart.components 
{
	import ash.core.Component;
	
	public class WormTentacle extends Component
	{
		public var boss:WormBoss;
		
		public function WormTentacle(boss:WormBoss)
		{
			this.boss = boss;
		}
	}
}