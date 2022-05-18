package game.scenes.shrink.shared.Systems.WalkToTurnDialSystem
{
	import ash.core.Engine;
	
	import game.data.motion.time.FixedTimestep;
	import game.nodes.entity.character.PlayerNode;
	import game.systems.GameSystem;
	import game.systems.SystemPriorities;
	
	public class WalkToTurnDialSystem extends GameSystem
	{
		private var _playerNode:PlayerNode;
		
		public function WalkToTurnDialSystem()
		{
			super(WalkToTurnDialNode, updateNode);
			super._defaultPriority = SystemPriorities.moveComplete;
			
			super.fixedTimestep = FixedTimestep.MOTION_TIME;
			super.linkedUpdate = FixedTimestep.MOTION_LINK;
		}

		override public function addToEngine(systemManager:Engine):void
		{
			_playerNode = systemManager.getNodeList(PlayerNode).head;
			super.addToEngine(systemManager);
		}
		
		public function updateNode(node:WalkToTurnDialNode, time:Number):void
		{
			if( _playerNode == null )
			{
				_playerNode = systemManager.getNodeList(PlayerNode).head;
			}
			
			if(node.walk.entityIdList.entities.length > 0)
			{
				var velX:Number = _playerNode.motion.velocity.x;
				_playerNode.spatial.x = node.walk.platformSpatial.x;
				//playerMotion.x = node.walk.platformSpatial.x - (velX * time);
				
				if(velX == 0)
					return;
				
				var valueIncreasing:Boolean = false;
				
				if(velX > 0 && node.walk.valueScale > 0 || velX < 0 && node.walk.valueScale < 0)
					valueIncreasing = true;
				
				if(node.walk.value > node.walk.offValue && !node.walk.on)
				{
					node.walk.dialOn.dispatch();
					node.walk.on = true;
				}
				
				if(node.walk.value <= node.walk.offValue && node.walk.on)
				{
					node.walk.dialOff.dispatch();
					node.walk.on = false;
				}
				
				if(node.walk.value >= node.walk.maxValue && valueIncreasing)
				{
					if(node.walk.loop)
						node.walk.value = node.walk.minValue;
					else
					{
						node.walk.value = node.walk.maxValue;
						return;
					}
				}
				
				if(node.walk.value <= node.walk.minValue && !valueIncreasing)
				{
					if(node.walk.loop)
						node.walk.value = node.walk.maxValue;
					else
					{
						node.walk.value = node.walk.minValue;
						return;
					}
				}
				
				if(node.walk.rotate)
					node.spatial.rotation -= velX * time / 5;
				
				node.walk.value += velX * time * node.walk.valueScale / 5;
			}
		}
	}
}