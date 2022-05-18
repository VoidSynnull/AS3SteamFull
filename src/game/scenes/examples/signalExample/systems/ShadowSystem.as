package game.scenes.examples.signalExample.systems
{
	import engine.components.Spatial;
	
	import game.scenes.examples.signalExample.components.Shadow;
	import game.scenes.examples.signalExample.nodes.ShadowNode;
	import game.systems.GameSystem;
	
	public class ShadowSystem extends GameSystem
	{
		public function ShadowSystem()
		{
			super(ShadowNode, updateNode);
		}
		
		public function updateNode(node:ShadowNode, time:Number):void
		{
			//Get the Shadow component from the node, as well as the player's spatial
			var shadow:Shadow = node.shadow;
			var spatial:Spatial = node.entity.get(Spatial);
			
			//Check if the player is in the Shadow's zone
			if(spatial.x > shadow.zone.left && spatial.x < shadow.zone.right &&
				spatial.y > shadow.zone.top && spatial.y < shadow.zone.bottom)
			{
				//If you're already in it, no need to dispatch, otherwise...
				if(!shadow.inZone)
				{
					shadow.inZone = true;
					shadow.shadow.dispatch(shadow.inZone);
				}
			}
			//If the player is not in the zone
			else
			{
				//If the last update you were in the zone, set to out
				if(shadow.inZone)
				{
					shadow.inZone = false;
					shadow.shadow.dispatch(shadow.inZone);
				}
			}
		}
	}
}