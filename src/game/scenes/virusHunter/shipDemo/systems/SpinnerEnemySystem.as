package game.scenes.virusHunter.shipDemo.systems
{
	import ash.core.Engine;
	
	import game.scenes.virusHunter.shared.creators.EnemyCreator;
	import game.scenes.virusHunter.shipDemo.nodes.SpinnerEnemyNode;
	import game.systems.GameSystem;
	import game.util.GeomUtils;
	
	public class SpinnerEnemySystem extends GameSystem
	{
		public function SpinnerEnemySystem(creator:EnemyCreator)
		{
			super(SpinnerEnemyNode, updateNode);
			_creator = creator;
		}
		
		private function updateNode(node:SpinnerEnemyNode, time:Number):void
		{			
			if(node.spinner.state == node.spinner.INACTIVE)
			{
				//node.entity.remove(MovieClipHit);
				//node.entity.remove(SpinnerEnemy);
				_creator.releaseEntity(node.entity, false);
				return;
			}
			
			if( node.damageTarget.damage >= node.damageTarget.maxDamage )
			{
				node.spinner.state = node.spinner.DIE;
			}
			
			if(node.spinner.state == node.spinner.DIE)
			{
				_creator.createDelayedEnemyExplosion(node.spatial.x, node.spatial.y, node.entity);
				node.spinner.state = node.spinner.INACTIVE;
				node.pointValue._redeem = true;
			}
			else
			{
				var targetDistance:Number = GeomUtils.spatialDistance(node.spatial, node.target.target);

				if(targetDistance < node.spinner.attackDistance)
				{
					if(node.spinner.state != node.spinner.ATTACK)
					{
						node.spinner.state = node.spinner.ATTACK;
						node.motion.rotationAcceleration = 200;
						node.motion.maxVelocity.x = node.spinner.baseMaxVelocity * 3;
						node.motion.maxVelocity.y = node.spinner.baseMaxVelocity * 3;
						node.motionControlBase.acceleration = node.spinner.baseAcceleration * 3;
					}
				}
				else
				{
					if(node.spinner.state != node.spinner.AQUIRE)
					{
						node.spinner.state = node.spinner.AQUIRE;
						node.motion.rotationAcceleration = 0;
						node.motion.maxVelocity.x = node.spinner.baseMaxVelocity;
						node.motion.maxVelocity.y = node.spinner.baseMaxVelocity;
						node.motionControlBase.acceleration = node.spinner.baseAcceleration;
					}
				}
			}
		}
		
		override public function removeFromEngine(systemManager:Engine) : void
		{
			systemManager.releaseNodeList(SpinnerEnemyNode);
			super.removeFromEngine(systemManager);
		}
		
		private var _creator:EnemyCreator;
	}
}

