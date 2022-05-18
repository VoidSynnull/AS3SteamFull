package game.systems.entity.character
{

	import flash.display.DisplayObjectContainer;
	
	import ash.core.Engine;
	import ash.core.NodeList;
	
	import game.nodes.entity.character.CharacterDepthNode;
	import game.nodes.entity.character.NpcNode;
	import game.systems.GameSystem;
	import game.systems.SystemPriorities;

	public class CharacterDepthSystem extends GameSystem
	{
		public function CharacterDepthSystem()
		{
			super( CharacterDepthNode, updateNode );
			super._defaultPriority = SystemPriorities.moveComplete;
			
		}
		
		override public function addToEngine(systemManager:Engine):void
		{
			super.addToEngine(systemManager);
			_npcs = systemManager.getNodeList(NpcNode);
		}
		
		public function updateNode(node:CharacterDepthNode, time:Number):void
		{
			// only update when player has just landed	
			if( node.collider.isHit )
			{
				if( node.depthChecker.checkForLand )
				{
					if( node.motion.acceleration.y == 0 )
					{
						updateDepth( node );
						node.depthChecker.checkForLand = false;
					}
				}
			}
			else
			{
				node.depthChecker.checkForLand = true;
			}
		}
		
		// check against all of the characetrs/creatures that are not sleeping
		/**
		 * Check against all of the characetrs/creatures that are not sleeping or ignoreDepth.
		 * Figures out appropriate depth and makes change. 
		 */
		public function updateDepth(node:CharacterDepthNode):void
		{
			var npcNode:NpcNode;
			var npcsBehind:Vector.<NpcNode>;
			var npcsFront:Vector.<NpcNode>;
			for ( npcNode = _npcs.head; npcNode; npcNode = npcNode.next )
			{
				if( npcNode.npc.ignoreDepth )	{ continue; }
				
				//If the NPC and character don't have the same parent, don't check it further.
				if( npcNode.display.displayObject.parent != node.display.displayObject.parent) continue;
	
				if( npcNode.spatial.y <= node.motion.y )
				{
					if( !npcsBehind )	{ npcsBehind = new Vector.<NpcNode>(); }
					npcsBehind.push( npcNode );
				}
				else
				{
					if( !npcsFront )	{ npcsFront = new Vector.<NpcNode>(); }
					npcsFront.push( npcNode );
				}
			}
			
			var container:DisplayObjectContainer;
			var nearestZDepth:int;
			var playerDepth:int
			var i:int;
			if( npcsBehind )	// if npcs are behind, find nearest in depth and place player in front 
			{
				container = node.display.container;
				nearestZDepth = container.getChildIndex( npcsBehind[0].display.displayObject );
				for (i = 1; i < npcsBehind.length; i++) 
				{
					nearestZDepth = Math.max( container.getChildIndex( npcsBehind[i].display.displayObject ), nearestZDepth );
				}
				
				playerDepth = container.getChildIndex( node.display.displayObject )
				if( nearestZDepth >= playerDepth )
				{
					container.setChildIndex( node.display.displayObject, nearestZDepth )
				}
				
				npcsBehind = null;
				npcsFront = null;
			}
			else if ( npcsFront )	// if all npcs are in front, find lowest depth and place player behind 
			{
				container = node.display.container;
				nearestZDepth = container.getChildIndex( npcsFront[0].display.displayObject );
				for (i = 1; i < npcsFront.length; i++) 
				{
					nearestZDepth = Math.min( container.getChildIndex( npcsFront[i].display.displayObject ), nearestZDepth );
				}
				
				playerDepth = container.getChildIndex( node.display.displayObject )
				if( nearestZDepth <= playerDepth )
				{
					container.setChildIndex( node.display.displayObject, nearestZDepth )
				}
				npcsBehind = null;
				npcsFront = null;
			}
		}
		
		override public function removeFromEngine(systemManager:Engine) : void
		{
			systemManager.releaseNodeList(CharacterDepthNode);
			systemManager.releaseNodeList(NpcNode);
			_npcs = null;
			super.removeFromEngine(systemManager);
		}
		
		private var _npcs:NodeList;	
	}
}
