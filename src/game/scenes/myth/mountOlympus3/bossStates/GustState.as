package game.scenes.myth.mountOlympus3.bossStates
{
	import game.scenes.myth.mountOlympus3.components.Gust;

	public class GustState extends ZeusState
	{
		public function GustState()
		{
			type = "gust";			
		}
		
		override public function start():void
		{
			node.boss.gustSleep.sleeping = false;
			node.boss.gust.state = Gust.SPAWN;
			
			super.start();
		}
	}
}