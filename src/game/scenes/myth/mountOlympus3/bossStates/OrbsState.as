package game.scenes.myth.mountOlympus3.bossStates
{
	import ash.core.Entity;
	
	import game.components.entity.Sleep;
	import game.scenes.myth.mountOlympus3.components.Orb;
	
	public class OrbsState extends ZeusState
	{
		public function OrbsState()
		{
			type = "orbs";
		}
		
		override public function start():void
		{
			setInvincible();

			var firstOrb:Entity = node.boss.orbEntity;
			Sleep(firstOrb.get(Sleep)).sleeping = false;
			var orb:Orb = firstOrb.get(Orb);
			orb.state = Orb.SPAWN;
			node.boss.activeOrbs = 0;

			super.start();
		}
	}
}