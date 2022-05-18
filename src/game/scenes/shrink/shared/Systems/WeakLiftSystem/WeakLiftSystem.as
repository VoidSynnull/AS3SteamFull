package game.scenes.shrink.shared.Systems.WeakLiftSystem
{
	import game.systems.GameSystem;
	
	public class WeakLiftSystem extends GameSystem
	{
		public function WeakLiftSystem()
		{
			super(WeakLiftNode, updateNode);
		}
		
		public function updateNode(node:WeakLiftNode, time:Number):void
		{
			if(node.entityIdList.entities.length == 0)
				node.moveData.velocity = node.weakLift.defaultVelocity;
			else
				node.moveData.velocity = node.weakLift.defaultVelocity / node.entityIdList.entities.length * node.weakLift.liftEfficiency;
		}
	}
}