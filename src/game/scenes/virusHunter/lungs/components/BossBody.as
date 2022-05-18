package game.scenes.virusHunter.lungs.components
{
	import ash.core.Entity;
	
	import ash.core.Component;
	
	import game.util.Utils;
	
	public class BossBody extends Component
	{
		public var boss:Entity;
		public var elapsedTime:Number;
		public var waitTime:Number;
		
		public function BossBody(boss:Entity)
		{
			this.boss = boss;
			this.elapsedTime = 0;
			this.waitTime = Utils.randNumInRange(5, 10);
		}
	}
}