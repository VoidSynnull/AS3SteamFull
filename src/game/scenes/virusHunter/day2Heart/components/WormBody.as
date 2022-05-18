package game.scenes.virusHunter.day2Heart.components 
{
	import ash.core.Component;
	
	import game.util.Utils;
	
	public class WormBody extends Component
	{
		public var wormBoss:WormBoss;
		public var elapsedTime:Number;
		public var waitTime:Number;
		
		public function WormBody(wormBoss:WormBoss)
		{
			this.wormBoss = wormBoss;
			this.elapsedTime = 0;
			this.waitTime = Utils.randInRange(5, 10);
		}
	}
}