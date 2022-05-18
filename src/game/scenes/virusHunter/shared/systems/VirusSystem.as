package game.scenes.virusHunter.shared.systems
{
	import ash.core.Engine;
	import ash.core.NodeList;
	import ash.tools.ListIteratingSystem;
	
	import game.components.hit.MovieClipHit;
	import game.scenes.virusHunter.shared.components.Virus;
	import game.scenes.virusHunter.shared.creators.EnemyCreator;
	import game.scenes.virusHunter.shared.nodes.KillCountNode;
	import game.scenes.virusHunter.shared.nodes.VirusMotionNode;
	import game.util.EntityUtils;
	import game.util.GeomUtils;
	
	public class VirusSystem extends ListIteratingSystem
	{
		public function VirusSystem(creator:EnemyCreator)
		{
			super(VirusMotionNode, updateNode);
			_creator = creator;
		}
		
		private function updateNode(node:VirusMotionNode, time:Number):void
		{
			if (EntityUtils.sleeping(node.entity))
			{
				node.virus.state = node.virus.INACTIVE;
				node.entity.remove(Virus);
				node.entity.remove(MovieClipHit);
				_creator.releaseEntity(node.entity, false);
				return;
			}
			
			if( node.virus.state != node.virus.EXPLODE )
			{
				if(node.virus.state == node.virus.DIE)
				{
					node.virus.state = node.virus.INACTIVE;
					_creator.releaseEntity(node.entity, false);
					return;
				}
				else
				{
					if( node.damageTarget.damage >= node.damageTarget.maxDamage )
					{
						var killCountNode:KillCountNode = _killCountNodes.head;
						if( killCountNode )
						{
							killCountNode.killCount.count["virus"]++;
						}
						node.virus.state = node.virus.EXPLODE;
						node.entity.remove(MovieClipHit);
						node.timeline.gotoAndPlay( "explode" );
						_creator.createRandomPickup(node.spatial.x, node.spatial.y, false);
						return;
					}
					
					var targetDistance:Number = GeomUtils.spatialDistance(node.spatial, node.target.target);
					
					if(node.virus.alwaysAquire || targetDistance < node.virus.aquireDistance || node.damageTarget.damage > 0)
					{
						if( targetDistance < node.virus.attackDistance )
						{
							if( node.virus.state != node.virus.ATTACK )
							{
								node.virus.state = node.virus.ATTACK;
								node.timeline.gotoAndPlay( "attack" );	
							}
						}
						else
						{
							node.virus.state = node.virus.AQUIRE;

							var dx:Number = node.target.target.x - node.spatial.x;
							var dy:Number = node.target.target.y - node.spatial.y;
							var angle:Number = Math.atan2(dy, dx);
							
							node.motion.velocity.x = Math.cos(angle) * node.virus.aquireVelocity;
							node.motion.velocity.y = Math.sin(angle) * node.virus.aquireVelocity;
							
							var degrees:Number = angle * (180 / Math.PI);
							var delta:Number = node.spatial.rotation - degrees;
							
							if (delta < -180)
							{
								node.spatial.rotation = node.spatial.rotation + 360;
								delta += 360;
							}
							else if (delta >= 180)
							{
								node.spatial.rotation = node.spatial.rotation - 360;
								delta -= 360;
							}
							
							if(Math.abs(delta) < .2)
							{
								node.spatial.rotation = degrees;
							}
							else
							{
								node.spatial.rotation = node.spatial.rotation - delta * .1;
							}
							
						}
					}
					else
					{
						node.virus.state = node.virus.SEEK;
					}
				}
			}
			else
			{
				if( node.timeline.currentFrameData.label == "endExplode" )
				{
					node.spatial.x = -1000;
					node.spatial.y = -1000;
				}
				if( node.timeline.currentFrameData.label == "endVirus" )
				{
					node.timeline.stop();
					node.virus.state = node.virus.DIE;
				}
			}
		}
				
		override public function addToEngine(systemManager:Engine):void
		{
			_killCountNodes = systemManager.getNodeList(KillCountNode);
			super.addToEngine(systemManager);
		}
		
		override public function removeFromEngine(systemManager:Engine):void
		{
			systemManager.releaseNodeList(VirusMotionNode);
			super.removeFromEngine(systemManager);
		}
		
		private var _creator:EnemyCreator;
		private var _killCountNodes:NodeList;
	}
}