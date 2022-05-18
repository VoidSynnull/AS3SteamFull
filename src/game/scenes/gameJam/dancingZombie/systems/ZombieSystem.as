package game.scenes.gameJam.dancingZombie.systems
{
	import ash.core.Entity;
	
	import game.scenes.gameJam.dancingZombie.DanceGamePopup;
	import game.scenes.gameJam.dancingZombie.nodes.ZombieNode;
	import game.systems.GameSystem;
	import game.systems.SystemPriorities;
	import game.util.EntityUtils;
		
	public class ZombieSystem extends GameSystem
	{
		// zombie states
		public static const DEAD:String = "dead"; // healed the by the power of music!
		public static const REACHED:String = "reached"; // reached the band's line 

		public function ZombieSystem()
		{
			super(ZombieNode, updateNode);
			super._defaultPriority = SystemPriorities.postUpdate;
		}
		
		public function updateNode(node:ZombieNode, time:Number):void
		{
			if( node.zombie.active )
			{
				if(node.zombie.health == 0)
				{
					node.zombie.health = -1;
					node.zombie.stateChanged.dispatch(node.entity,DEAD);
					return;
				}
				else if(node.zombie.health < 0){
					return;
				}
				if(node.beat.beatHit)
				{
					// update zombie locations
					if(node.zombie.beatMovements.indexOf(node.beat.measure) >= 0)
					{		
						node.display.visible = true;
						/*
						node.spatial.x += node.zombie.direction.x * node.zombie.tileSize;
						node.spatial.y += node.zombie.direction.y * node.zombie.tileSize;
						node.zombie.coordinates = node.zombie.coordinates.add(node.zombie.direction);
						*/
						node.zombie.coordinates = node.zombie.coordinates.add(node.zombie.direction);
						
						if( node.zombie.coordinates.y < (super.group as DanceGamePopup).ROWS_TOTAL )
						{
							//place zombie in appropriate row
							var nextTile:Entity = (super.group as DanceGamePopup).getTileEntity(node.zombie.coordinates.y - 1, node.zombie.coordinates.x);
							node.display.setContainer( EntityUtils.getDisplayObject(nextTile) );
						}
						else{
							node.zombie.stateChanged.dispatch(node.entity,REACHED);
						}
					}
				}
			}
		}
	}
}