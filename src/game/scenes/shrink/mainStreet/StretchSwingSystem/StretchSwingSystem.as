package game.scenes.shrink.mainStreet.StretchSwingSystem
{
	import engine.components.Spatial;
	
	import game.components.hit.EntityIdList;
	import game.data.motion.time.FixedTimestep;
	import game.systems.GameSystem;
	import game.systems.SystemPriorities;
	import game.util.AudioUtils;
	
	public class StretchSwingSystem extends GameSystem
	{
		public function StretchSwingSystem()
		{
			super(StretchSwingNode, updateNode);
			super._defaultPriority = SystemPriorities.checkCollisions;
				
			super.fixedTimestep = FixedTimestep.ANIMATION_TIME;
		}
		
		public function updateNode(node:StretchSwingNode, time:Number):void
		{
			var entityIdList:EntityIdList = node.stretchySwing.hitNode.idList;
			if(entityIdList.entities.length > 0)
			{
				if(!node.stretchySwing.stretching)
				{
					if(node.stretchySwing.soundEffect != "none")
						AudioUtils.play(group, "effects/" + node.stretchySwing.soundEffect);
					stretch(node, node.stretchySwing.stretchScale);
					node.stretchySwing.stretching = true;
				}
			}
			else
			{
				if(node.stretchySwing.stretching)
				{
					stretch(node, 1);
					node.stretchySwing.stretching = false;
				}
			}
			var spatial:Spatial = node.stretchySwing.hitNode.spatial;
			spatial.y = node.spatial.y + node.spatial.height - spatial.height / 2;
		}
		
		private function stretch(node:StretchSwingNode, amount:Number):void
		{
			node.tween.to(node.spatial, 1, {scaleY:amount});
		}
	}
}