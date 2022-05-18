package game.scenes.backlot.cityDestroy.systems
{
	import flash.geom.Rectangle;
	
	import ash.core.Engine;
	import ash.core.NodeList;
	
	import engine.components.Audio;
	import engine.components.Motion;
	import engine.components.MotionBounds;
	
	import game.components.entity.character.CharacterMotionControl;
	import game.components.entity.collider.PlatformCollider;
	import game.scenes.backlot.cityDestroy.nodes.SoldierHitNode;
	import game.scenes.backlot.cityDestroy.nodes.SoldierNode;
	import game.systems.GameSystem;
	import game.systems.entity.character.states.CharacterState;
	
	public class SoldierHitSystem extends GameSystem
	{
		public function SoldierHitSystem()
		{
			super(SoldierHitNode, updateNode);
		}
		
		public function updateNode(node:SoldierHitNode, time:Number):void
		{
			if(node.hit.time > 0)
			{
				node.hit.time -= time;
				return;
			}
			
			for( var soldier:SoldierNode = soldiers.head; soldier; soldier = soldier.next )
			{
				if(soldier.soldier.state != soldier.soldier.MARCHING )
					continue;
				var hitCheck:Rectangle = node.display.displayObject.getBounds(node.display.displayObject);
				hitCheck.y += hitCheck.height / 2;
				hitCheck.height *= .666;
				if(hitCheck.contains(soldier.spatial.x - node.spatial.x, soldier.spatial.y - node.spatial.y))
				{
					Audio(soldier.entity.get(Audio)).play("effects/flesh_impact_01.mp3");
					
					if(node.motion.velocity.y > 0)
					{
						trace("SoldierHitSystem :: soldier should die");// needs to be animated but deal with it later
						soldier.soldier.state = soldier.soldier.DEAD;
						soldier.entity.remove(CharacterMotionControl);
						soldier.entity.remove(PlatformCollider);
						soldier.entity.remove(MotionBounds);
						Motion(soldier.entity.get(Motion)).velocity.y = -1000;
						Motion(soldier.entity.get(Motion)).acceleration.y = 2000;
						continue;
					}
					
					var soldierMotion:Motion = soldier.entity.get(Motion);
					
					var difference:Number = node.spatial.x - soldier.spatial.x;
					
					node.motion.acceleration.x = difference / Math.abs(difference) * 2000;
					node.motion.acceleration.y = -10000;
					
					node.health.health -= 1;
					node.state.setState( CharacterState.HURT );
					node.hit.time = node.hit.recoveryTime;
				}
			}
		}
		
		override public function addToEngine(systemManager:Engine) : void
		{
			soldiers = systemManager.getNodeList( SoldierNode );
			
			super.addToEngine(systemManager);
		}
		
		override public function removeFromEngine(systemManager:Engine) : void
		{
			systemManager.releaseNodeList(SoldierNode);
			super.removeFromEngine(systemManager);
		}
		
		private var soldiers:NodeList;
	}
}