package game.scenes.backlot.cityDestroy.systems
{
	import ash.core.Engine;
	import ash.core.NodeList;
	
	import game.components.animation.FSMControl;
	import game.scenes.backlot.cityDestroy.nodes.CannonShotHitNode;
	import game.scenes.backlot.cityDestroy.nodes.CannonShotNode;
	import game.systems.GameSystem;
	import game.systems.entity.character.states.CharacterState;
	
	public class CannonShotHitSystem extends GameSystem
	{
		public function CannonShotHitSystem()
		{
			super(CannonShotHitNode, updateNode);
		}
		
		public function updateNode(node:CannonShotHitNode, time:Number):void
		{
			var shot:CannonShotNode;
			for( shot = cannonShots.head; shot; shot = shot.next )
			{
				if(shot.shot.state != shot.shot.ACTIVE)
					continue;
				if(node.display.displayObject.getBounds(node.display.displayObject).contains(shot.spatial.x - node.spatial.x, shot.spatial.y - node.spatial.y))
				{
					shot.shot.state = shot.shot.HIT;
					if(node.entity.get(FSMControl) != null)
						FSMControl(node.entity.get(FSMControl)).setState( CharacterState.HURT );
					node.health.health -= shot.shot.power;
				}
			}
		}
		
		override public function addToEngine(systemManager:Engine) : void
		{
			cannonShots = systemManager.getNodeList( CannonShotNode );
			
			super.addToEngine(systemManager);
		}
		
		override public function removeFromEngine(systemManager:Engine) : void
		{
			systemManager.releaseNodeList(CannonShotNode);
			super.removeFromEngine(systemManager);
		}
		
		private var cannonShots:NodeList;
	}
}