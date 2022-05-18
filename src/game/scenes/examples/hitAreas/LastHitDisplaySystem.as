package game.scenes.examples.hitAreas
{
	import game.systems.GameSystem;
	
	public class LastHitDisplaySystem extends GameSystem
	{
		public function LastHitDisplaySystem()
		{
			super(LastHitDisplayNode, updateNode);
		}
		
		public function updateNode(node:LastHitDisplayNode, time:Number):void
		{
			if(node.entityIdList.entities.length > 0)
			{
				super.group.shellApi.log("last hit id : "+ node.id.id);
			}
		}
	}
}