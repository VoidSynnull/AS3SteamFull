package game.scenes.gameJam.zombieDefense.systems
{
	import flash.display.Sprite;
	
	import ash.core.NodeList;
	
	import game.scenes.gameJam.zombieDefense.components.DefenseTrap;
	import game.scenes.gameJam.zombieDefense.components.DefenseZombie;
	import game.scenes.gameJam.zombieDefense.nodes.DefenseTrapNode;
	import game.scenes.gameJam.zombieDefense.nodes.DefenseZombieNode;
	import game.systems.GameSystem;
	import game.util.MotionUtils;
	
	public class DefenseTrapSystem extends GameSystem
	{
		private var zombieList:NodeList;
		
		public function DefenseTrapSystem()
		{
			super(DefenseTrapNode, updateNode, addNode);
		}
		
		private function addNode(node:DefenseTrapNode):void
		{
			zombieList = systemManager.getNodeList(DefenseZombieNode);
			//trace("newTrap"+node.id.id)
		}
		
		private function updateNode(node:DefenseTrapNode, time:Number):void
		{
			//trace("updateTrap"+node.id.id)
			// collect zombie nodelist, check collisions, apply effects and thier druations, 
			if(node.trap.armed){
				var isHit:Boolean = false;
				for (var zomNode:DefenseZombieNode = zombieList.head; zomNode != null; zomNode = zomNode.next) 
				{
					isHit = MotionUtils.checkOverlap(node, zomNode);
					if(!isHit){
						isHit = Sprite(node.display.displayObject).hitTestObject(zomNode.display.displayObject);
					}
					if(isHit){
						applyeffectToZombie(node, zomNode);
					}
				}
			}
			else{
				// tick re-arm time
				node.trap.rearmTimer += time;
				if(node.trap.rearmTimer >= node.trap.rearmTime){
					node.trap.armed = true;
					node.trap.rearmTimer = 0;
				}
			}
		}
		
		private function applyeffectToZombie(node:DefenseTrapNode,zomNode:DefenseZombieNode):void
		{
			trace("TRAP:"+node.id.id+" HIT:"+zomNode.id.id)
			var zom:DefenseZombie = zomNode.zombie;
			var trap:DefenseTrap = node.trap;
			zom.health -= trap.damage;
			zom.statusEffect = trap.effect;
			zom.effectDuration = trap.effectDuration;
			zom.stateChanged.dispatch(zomNode.entity,DefenseZombieSystem.HIT);
			trap.rearmTimer = 0;
			trap.armed = false;
		}		
		
		
		
		
		
		
		
		
		
		
		
		
		
		
	}
}