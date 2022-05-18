package game.scenes.arab2.entrance.enforcer
{
	import ash.core.Engine;
	import ash.core.NodeList;
	import ash.core.System;
	
	import game.nodes.entity.character.PlayerNode;
	import game.util.EntityUtils;
	
	public class EnforcerSystem extends System
	{
		private var _enforcers:NodeList;
		private var _players:NodeList;
		
		public function EnforcerSystem()
		{
			super();
		}
		
		override public function update(time:Number):void
		{
			for(var enforcer:EnforcerNode = this._enforcers.head; enforcer; enforcer = enforcer.next)
			{
				if(EntityUtils.sleeping(enforcer.entity)) continue;
				
				for(var player:PlayerNode = this._players.head; player; player = player.next)
				{
					if(EntityUtils.sleeping(player.entity)) continue;
					
					if(enforcer.enforcer.pathIndex != enforcer.navigation.index)
					{
						enforcer.enforcer.pathIndex = enforcer.navigation.index;
						enforcer.enforcer.pathTime = 0;
					}
					
					//trace(enforcer.enforcer.pathIndex
					
					if(!isNaN(enforcer.enforcer.pathIndex))
					{
						enforcer.enforcer.pathTime += time;
						if(enforcer.enforcer.pathTime > 10)
						{
							enforcer.enforcer.pathTime = 0;
							enforcer.spatial.x = enforcer.target.targetX;
							enforcer.spatial.y = enforcer.target.targetY;
						}
					}
					
					if(!enforcer.enforcer.hasCaptured && enforcer.fsm.state.type == "walk")
					{
						if(enforcer.spatial.y + enforcer.enforcer.captureOffsetY < player.spatial.y)
						{
							enforcer.enforcer.hasCaptured = true;
							enforcer.enforcer.captured.dispatch(enforcer.entity, player.entity);
						}
					}
				}
			}
		}
		
		override public function addToEngine(systemManager:Engine):void
		{
			this._enforcers = systemManager.getNodeList(EnforcerNode);
			this._players = systemManager.getNodeList(PlayerNode);
		}
		
		override public function removeFromEngine(systemManager:Engine):void
		{
			systemManager.releaseNodeList(EnforcerNode);
		}
	}
}