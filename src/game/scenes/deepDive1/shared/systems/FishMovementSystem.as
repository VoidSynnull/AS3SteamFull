package game.scenes.deepDive1.shared.systems
{
	import ash.tools.ListIteratingSystem;
	
	import game.scenes.deepDive1.shared.creators.SpawnFishCreator;
	import game.scenes.deepDive1.shared.nodes.FishNode;
	
	public class FishMovementSystem extends ListIteratingSystem
	{
		public function FishMovementSystem(creator:SpawnFishCreator)
		{
			_creator = creator;
			super(FishNode, updateNode);
		}
		
		public function updateNode(node:FishNode, time:Number):void
		{
			if(node.sleep.sleeping)
			{
				_creator.releaseEntity(node.entity);
			}
		}
		
		private var _creator:SpawnFishCreator;
	}
}