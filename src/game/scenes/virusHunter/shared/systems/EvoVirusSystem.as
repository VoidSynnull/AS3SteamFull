package game.scenes.virusHunter.shared.systems
{	
	import ash.core.Engine;
	import ash.core.NodeList;
	import ash.tools.ListIteratingSystem;
	
	import engine.components.Audio;
	import engine.managers.SoundManager;
	
	import game.components.hit.MovieClipHit;
	import game.data.sound.SoundModifier;
	import game.scenes.virusHunter.foreArm.nodes.CutNode;
	import game.scenes.virusHunter.shared.components.EvoVirus;
	import game.scenes.virusHunter.shared.creators.EnemyCreator;
	import game.scenes.virusHunter.shared.nodes.EvoVirusMotionNode;
	import game.scenes.virusHunter.shared.nodes.KillCountNode;
	import game.util.GeomUtils;
	
	
	
	public class EvoVirusSystem extends ListIteratingSystem
	{
		public function EvoVirusSystem(creator:EnemyCreator)
		{
			super(EvoVirusMotionNode, updateNode);
			_creator = creator;
		}
		
		private function updateNode( node:EvoVirusMotionNode, time:Number ):void
		{
		/*	if (EntityUtils.sleeping(node.entity))
			{
				node.virus.state = node.virus.INACTIVE;
				node.entity.remove(EvoVirus);
				_creator.releaseEntity(node.entity);
				return;
			}
		*/	
			if( node.virus.state != node.virus.EXPLODE )
			{
				if( node.virus.state == node.virus.DIE )
				{
					node.virus.state = node.virus.INACTIVE;
					_creator.releaseEntity(node.entity);
					node.entity.remove(EvoVirus);
					node.virus.init = false;
					return;
				}
				
				else
				{
					if( node.timeline.currentFrameData )
					{
						if( node.timeline.currentFrameData.label == "switchAttackState" || node.timeline.currentFrameData.label == "switchHitState" )
						{
							node.virus.state = node.virus.SEEK;
							node.damageTarget.isHit = false;
						}
					}
					
					if( node.damageTarget.isHit && !node.damageTarget.isTriggered )//.isHit && !node.damageTarget.isTriggered )
					{
						if( node.damageTarget.damage > node.damageTarget.maxDamage )
						{
							var killCountNode:KillCountNode = _killCountNodes.head;
							if( killCountNode )
							{
								killCountNode.killCount.count["evoVirus"]++;
							}
							node.virus.state = node.virus.EXPLODE;
							node.entity.remove( MovieClipHit );
							node.timeline.gotoAndPlay( "explode" );
							_creator.createRandomPickup( node.spatial.x, node.spatial.y, false );
						}
						
						else if( node.virus.state != node.virus.HIT )
						{
							node.virus.state = node.virus.HIT;
							node.timeline.gotoAndPlay( "hit" );
						}
					}
					else
					{
						var targetDistance:Number;
						var dx:Number;
						var dy:Number;
						var angle:Number;
						var cutNode:CutNode;
							
						for( cutNode = _cutNodes.head; cutNode; cutNode = cutNode.next )
						{
							if( cutNode.cut.state == cutNode.cut.SEALED )
							{
								targetDistance = GeomUtils.spatialDistance( node.spatial, cutNode.spatial );
								
								if( targetDistance < node.virus.aquireDistance && node.virus.state != node.virus.ATTACK ) 
								{
									
									if( targetDistance < node.virus.attackDistance )
									{	
										node.timeline.gotoAndPlay( "attack" );
										node.virus.state = node.virus.ATTACK;
										
										cutNode.cut.health -= .5;
										var audio:Audio = cutNode.entity.get(Audio);
										
										if( audio == null )
										{
											audio = new Audio();
											
											cutNode.entity.add(audio);
										}
										
										audio.play( SoundManager.EFFECTS_PATH + CUT_TORN, false, SoundModifier.POSITION );
										
										node.motion.velocity.x = 0;
										node.motion.velocity.y = 0;
										continue;
									}
								
									else
									{
										node.virus.state = node.virus.LOCKED_ON;
										
										dx = cutNode.spatial.x - node.spatial.x;
										dy = cutNode.spatial.y - node.spatial.y;
										angle = Math.atan2(dy, dx);
										
										node.motion.velocity.x = Math.cos(angle) * node.virus.aquireVelocity;
										node.motion.velocity.y = Math.sin(angle) * node.virus.aquireVelocity;
										
										node.spatial.rotation = angle * (180 / Math.PI);
										continue;
									}
								}
							}
						}
						
						
						if( node.virus.state != node.virus.LOCKED_ON )
						{
							targetDistance = GeomUtils.spatialDistance(node.spatial, node.target.target);
							
							if( targetDistance < node.virus.aquireDistance )// || node.damageTarget.damage > 0)
							{
								if( node.virus.state != node.virus.ATTACK )
								{
									if( targetDistance < node.virus.attackDistance  )
									{
										node.timeline.gotoAndPlay( "attack" );
										node.virus.state = node.virus.ATTACK;
									}
									
									else
									{
										node.virus.state = node.virus.AQUIRE;
										
										dx = node.target.target.x - node.spatial.x;
										dy = node.target.target.y - node.spatial.y;
										angle = Math.atan2(dy, dx);
										
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
									//	return;
									}
								}
							}
						}
						else
						{
							node.virus.state = node.virus.SEEK;
						}	
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
			_killCountNodes = systemManager.getNodeList( KillCountNode );
			_cutNodes = systemManager.getNodeList( CutNode );
			super.addToEngine( systemManager );
		}
		
		override public function removeFromEngine(systemManager:Engine):void
		{
			systemManager.releaseNodeList( EvoVirusMotionNode );
			systemManager.releaseNodeList( CutNode );
			super.removeFromEngine( systemManager );
		}
		
		private var _creator:EnemyCreator;
		static private const CUT_TORN:String = "squish_06.mp3";
		
		private var _virusNodes:NodeList;
		private var _sceneDamageNodes:NodeList;
		private var _cutNodes:NodeList;
		private var _killCountNodes:NodeList;
	}
}

