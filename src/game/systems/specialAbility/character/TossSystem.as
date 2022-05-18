package game.systems.specialAbility.character
{
	import ash.core.Engine;
	import ash.core.NodeList;
	import ash.core.System;
	
	import engine.components.Spatial;
	
	import game.components.specialAbility.character.Toss;
	import game.nodes.specialAbility.character.TossNode;
	import game.systems.SystemPriorities;
	import game.util.CharUtils;

	
	
	public class TossSystem extends System
	{
		private var _nodes:NodeList;
		
		override public function addToEngine(systemsManager:Engine):void
		{
			_nodes = systemsManager.getNodeList(TossNode);
			super._defaultPriority = SystemPriorities.update;
		}
		
		
		override public function update( time : Number ) : void
		{
			var node:TossNode;
			
			for ( node = _nodes.head; node; node = node.next )
			{
				var toss:Toss = node.toss;
				var spatial:Spatial = node.spatial;
				var handspatial:Spatial = CharUtils.getJoint(toss.player, CharUtils.HAND_FRONT).get(Spatial);
				
				toss.vy += toss.ay;
				if(toss.vy < 0)
				{
					spatial.y += toss.vy;
					spatial.rotation += 7;
				} else {
					if(spatial.y < handspatial.y)
					{
						spatial.y += toss.vy;
						spatial.rotation += 6.8;
					}
				}
				
			}
		}

		
		
		
		override public function removeFromEngine(systemManager:Engine):void
		{
			systemManager.releaseNodeList(TossNode);
			_nodes = null;
		}
	}
}