package game.systems.entity.character.part
{
	import flash.display.MovieClip;
	
	import ash.core.Engine;
	import ash.core.NodeList;
	
	import engine.components.Spatial;
	
	import game.components.entity.character.part.CreepyEyes;
	import game.nodes.entity.character.NpcNode;
	import game.nodes.entity.character.part.CreepyEyesNode;
	import game.systems.GameSystem;
	
	public class CreepyEyesSystem extends GameSystem
	{
		public function CreepyEyesSystem()
		{
			super( CreepyEyesNode, updateNode );
			super.nodeAddedFunction = ESNodeAddedFunction;
		}
		
		private function ESNodeAddedFunction( node:CreepyEyesNode ):void
		{
			// assign assets
			node.creepyEyes.left = MovieClip(node.display.displayObject)["left"];
			node.creepyEyes.right = MovieClip(node.display.displayObject)["right"];
			node.creepyEyes.npc = MovieClip(node.display.displayObject.parent);
		}

		override public function addToEngine( systemManager:Engine ):void
		{
			playerSpatial = group.shellApi.player.get( Spatial );
			_npcNodes = systemManager.getNodeList( NpcNode );
			super.addToEngine( systemManager );
		}
		
		override public function removeFromEngine( systemManager:Engine ):void
		{
			systemManager.releaseNodeList( NpcNode );
		}
		
		private function updateNode( node:CreepyEyesNode, time:Number ):void
		{
			var eyes:CreepyEyes = node.creepyEyes;
			// set direction depending on which way npc is facing
			var dir:Number = 1;
			if (eyes.npc.scaleX < 0)
				dir = -1;
			var angle:Number = Math.atan2(playerSpatial.y - eyes.npc.y, dir * (playerSpatial.x - eyes.npc.x)) / Math.PI * 180;
			eyes.left.rotation = angle;
			eyes.right.rotation = angle;
		}
		
		private var playerSpatial:Spatial;
		private var _npcNodes:NodeList;
	}
}