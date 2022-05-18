package game.systems.specialAbility.character
{
	import ash.core.Engine;
	import ash.core.Entity;
	import ash.core.NodeList;
	
	import engine.components.Audio;
	import engine.components.Motion;
	import engine.components.Spatial;
	
	import game.components.Emitter;
	import game.components.specialAbility.ObjectSwarmComponent;
	import game.nodes.entity.character.NpcNode;
	import game.nodes.specialAbility.ObjectSwarmNode;
	import game.systems.GameSystem;
	

	
	public class ObjectSwarmSystem extends GameSystem
	{
		public function ObjectSwarmSystem()
		{
			super( ObjectSwarmNode, updateNode );
		}
		
		override public function addToEngine( systemManager:Engine ):void
		{
		
			super.addToEngine( systemManager );
		}
		
		override public function removeFromEngine( systemManager:Engine ):void
		{
			systemManager.releaseNodeList( NpcNode );
		}
		
		private function updateNode( node:ObjectSwarmNode, time:Number ):void
		{
			var swarmComponent:ObjectSwarmComponent = node.swarmComponent
			var spatial:Spatial = node.spatial;
			spatial.x -= Math.floor(Math.random()*(1+5-3))+5;
			
			if(swarmComponent.isJumper)
			{
				swarmComponent.speedY += Math.floor(Math.random()*2+1);
				spatial.y += swarmComponent.speedY;
				
				if(spatial.y > swarmComponent.startingY + 2)
				{
					swarmComponent.speedY = -Math.floor(Math.random()*20+1);
					//this.canJump = false;
				}
			}
			
		
		}
		
	
		
	}
}


