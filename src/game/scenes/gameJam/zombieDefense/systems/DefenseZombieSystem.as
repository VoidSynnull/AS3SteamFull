package game.scenes.gameJam.zombieDefense.systems
{
	import flash.geom.Point;
	
	import ash.core.Entity;
	
	import engine.components.Motion;
	import engine.components.Spatial;
	import engine.util.Command;
	
	import game.components.entity.character.CharacterMotionControl;
	import game.data.animation.entity.character.Dizzy;
	import game.data.animation.entity.character.Stand;
	import game.scenes.gameJam.zombieDefense.components.DefenseTrap;
	import game.scenes.gameJam.zombieDefense.components.DefenseZombie;
	import game.scenes.gameJam.zombieDefense.nodes.DefenseZombieNode;
	import game.systems.GameSystem;
	import game.systems.SystemPriorities;
	import game.util.CharUtils;
	import game.util.MotionUtils;
	import game.util.TweenUtils;
		
	public class DefenseZombieSystem extends GameSystem
	{
		// zombie states
		public static const DEAD:String = "dead"; 
		public static const REACHED:String = "reached"; 
		public static const HIT:String = "hit"; 
		public static const RECOVER:String = "recover";


		public function DefenseZombieSystem()
		{
			super(DefenseZombieNode, updateNode, addNode);
			super._defaultPriority = SystemPriorities.postUpdate;
		}
		
		public function addNode(node:DefenseZombieNode):void
		{
			//trace("added:"+node.id.id)
		}

		public function updateNode(node:DefenseZombieNode, time:Number):void
		{
			if( node.zombie.active )
			{
				if(node.zombie.health > 0)
				{
					// always tick effect timer
					node.zombie.effectTimer += time;
					if(node.zombie.effectTimer > node.zombie.effectDuration){
						node.zombie.effectTimer = 0;
						// end effect
						if(node.zombie.statusEffect != DefenseTrap.NONE){
							trace("EFFECT: Expired:"+node.zombie.statusEffect);
							if(node.zombie.statusEffect == DefenseTrap.STUN || node.zombie.statusEffect == DefenseTrap.KNOCKBACK){
								// return to path
								var targ:Point = node.zombie.path[node.zombie.pathIndex];
								CharUtils.moveToTarget(node.entity, targ.x, targ.y, false, Command.create(dispatchRecover) );
							}
							node.zombie.statusEffect = DefenseTrap.NONE;
							node.zombie.effectDuration = 0;
						}
					}

					switch(node.zombie.statusEffect)
					{
						case DefenseTrap.KNOCKBACK:
						{
							trace("EFFECT: KNOCKBACK APPLIED:"+node.zombie.effectDuration)
							CharacterMotionControl(node.entity.get(CharacterMotionControl)).maxAirVelocityX = 300;
							CharacterMotionControl(node.entity.get(CharacterMotionControl)).maxVelocityX = 200;
							CharacterMotionControl(node.entity.get(CharacterMotionControl)).maxVelocityY = 300;
							MotionUtils.zeroMotion(node.entity);
							node.motion.velocity = new Point(750,-200);
							break;
						}
						case DefenseTrap.SLOW:
						{
							trace("EFFECT: SLOW APPLIED:"+node.zombie.effectDuration)
							CharacterMotionControl(node.entity.get(CharacterMotionControl)).maxAirVelocityX = 150;
							CharacterMotionControl(node.entity.get(CharacterMotionControl)).maxVelocityX = 150;
							CharacterMotionControl(node.entity.get(CharacterMotionControl)).maxVelocityY = 150;
							break;
						}
						case DefenseTrap.STUN:
						{
							trace("EFFECT: STUN APPLIED:"+node.zombie.effectDuration)
							CharacterMotionControl(node.entity.get(CharacterMotionControl)).maxAirVelocityX = 0;
							CharacterMotionControl(node.entity.get(CharacterMotionControl)).maxVelocityX = 0;
							CharacterMotionControl(node.entity.get(CharacterMotionControl)).maxVelocityY = 0;
							CharUtils.setAnim(node.entity, Dizzy);
							MotionUtils.zeroMotion(node.entity);
							break;
						}
							
						default:
						{
							// NONE, restore settings
							CharacterMotionControl(node.entity.get(CharacterMotionControl)).maxAirVelocityX = 300;
							CharacterMotionControl(node.entity.get(CharacterMotionControl)).maxVelocityX = 200;
							CharacterMotionControl(node.entity.get(CharacterMotionControl)).maxVelocityY = 300;
							break;
						}
					}
				}
				else{
					node.zombie.active = false;
					node.zombie.health = -1;
					node.zombie.stateChanged.dispatch(node.entity,DEAD);
					node.zombie.effectDuration = 0;
					node.zombie.statusEffect = DefenseTrap.NONE;
				}
			}
		}
		
		private function dispatchRecover(zombie:Entity):void
		{
			var zom:DefenseZombie = zombie.get(DefenseZombie);
			zom.stateChanged.dispatch(zombie,DefenseZombieSystem.RECOVER);
		}		
		
		
		
		
		
		
		
		
		
	}
}