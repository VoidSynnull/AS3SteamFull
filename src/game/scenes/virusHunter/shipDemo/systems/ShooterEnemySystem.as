package game.scenes.virusHunter.shipDemo.systems
{
	import ash.core.Engine;
	import ash.core.Entity;
	
	import game.components.hit.MovieClipHit;
	import game.scenes.virusHunter.shared.components.WeaponControl;
	import game.scenes.virusHunter.shared.creators.EnemyCreator;
	import game.scenes.virusHunter.shipDemo.components.SeekerEnemy;
	import game.scenes.virusHunter.shipDemo.nodes.ShooterEnemyNode;
	import game.systems.GameSystem;
	import game.util.GeomUtils;
	import game.util.MotionUtils;
	
	public class ShooterEnemySystem extends GameSystem
	{
		public function ShooterEnemySystem(creator:EnemyCreator)
		{
			super(ShooterEnemyNode, updateNode);
			_creator = creator;
		}
		
		private function updateNode(node:ShooterEnemyNode, time:Number):void
		{
			if(node.shooter.state == node.shooter.INACTIVE)
			{
				//node.entity.remove(MovieClipHit);
				//node.entity.remove(ShooterEnemy);
				_creator.releaseEntity(node.entity, false);
				return;
			}
			
			if( node.damageTarget.damage >= node.damageTarget.maxDamage )
			{
				node.shooter.state = node.shooter.DIE;
			}
			
			var weaponEntity:Entity = node.weaponSlots.active;
			var weaponControl:WeaponControl = weaponEntity.get(WeaponControl);
			
			if(node.shooter.state == node.shooter.DIE)
			{
				_creator.createDelayedEnemyExplosion(node.spatial.x, node.spatial.y, node.entity);
				node.shooter.state = node.shooter.INACTIVE;
				weaponControl.fire = false;
				node.pointValue._redeem = true;
			}
			else
			{
				var targetDistance:Number = GeomUtils.spatialDistance(node.spatial, node.target.target);
				
				if(targetDistance < node.shooter.attackDistance)
				{
					node.shooter.state = node.shooter.ATTACK;
					node.motion.maxVelocity.x = node.shooter.baseMaxVelocity;
					node.motion.maxVelocity.y = node.shooter.baseMaxVelocity;
					node.motionControlBase.acceleration = node.shooter.baseAcceleration;
					weaponControl.fire = true;
				}
				else
				{
					node.shooter.state = node.shooter.AQUIRE;
					node.motion.maxVelocity.x = node.shooter.baseMaxVelocity * 2;
					node.motion.maxVelocity.y = node.shooter.baseMaxVelocity * 2;
					node.motionControlBase.acceleration = node.shooter.baseAcceleration * 2;
					weaponControl.fire = false;
				}
			}
		}
		
		override public function removeFromEngine(systemManager:Engine) : void
		{
			systemManager.releaseNodeList(ShooterEnemyNode);
			super.removeFromEngine(systemManager);
		}
		
		private var _creator:EnemyCreator;
	}
}

