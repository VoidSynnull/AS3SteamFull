package game.scenes.virusHunter.shared.systems
{
	import flash.display.MovieClip;
	
	import ash.core.Engine;
	import ash.core.NodeList;
	import ash.tools.ListIteratingSystem;
	
	import engine.util.Command;
	
	import game.components.entity.Sleep;
	import game.components.timeline.Timeline;
	import game.components.hit.MovieClipHit;
	import game.scenes.virusHunter.brain.virus.Virus;
	import game.scenes.virusHunter.shared.components.WhiteBloodCell;
	import game.scenes.virusHunter.shared.creators.EnemyCreator;
	import game.scenes.virusHunter.shared.nodes.BacteriaMotionNode;
	import game.scenes.virusHunter.shared.nodes.KillCountNode;
	import game.scenes.virusHunter.shared.nodes.WhiteBloodCellMotionNode;
	import game.systems.GameSystem;
	import game.util.EntityUtils;
	import game.util.GeomUtils;
	import game.util.TimelineUtils;


	public class WhiteBloodCellSystem extends ListIteratingSystem
	{
		public function WhiteBloodCellSystem( creator:EnemyCreator )
		{
			super( WhiteBloodCellMotionNode, updateNode );
			_creator = creator;
		}
		
		private function updateNode( node:WhiteBloodCellMotionNode, time:Number ):void
		{
			var bacteriaNode:BacteriaMotionNode;

			if (EntityUtils.sleeping(node.entity))
			{
				node.entity.remove(WhiteBloodCell);
				_creator.releaseEntity(node.entity);
				return;
			}
			
			if( !node.whiteBloodCell.init )
			{
				initWhiteBloodCell( node );
			}
			else
			{
				if(node.whiteBloodCell.state == node.whiteBloodCell.DIE)
				{
					node.entity.remove(WhiteBloodCell);
					_creator.releaseEntity(node.entity);
					return;
				}
				else if( node.whiteBloodCell.state != node.whiteBloodCell.EXPLODE )// && node.whiteBloodCell.state != node.whiteBloodCell.SEEK )
				{
					var timeline:Timeline = node.entity.get( Timeline );
					
					if( node.damageTarget.damage > node.damageTarget.maxDamage )
					{ 
						var killCountNode:KillCountNode = _killCountNodes.head;
						if(killCountNode)
						{
							killCountNode.killCount.count[ "whiteBloodCell" ]++;
						}
						node.whiteBloodCell.state = node.whiteBloodCell.EXPLODE;
						node.entity.remove( MovieClipHit );
						timeline.gotoAndPlay( "explode" );
					}
					else
					{
						var targetDistance:Number;
						var dx:Number;
						var dy:Number;
						var angle:Number;
						
						if( node.whiteBloodCell.state != node.whiteBloodCell.ATTACK )
						{
							// if no Bacteria present, will attack player's ship
							targetDistance = GeomUtils.spatialDistance( node.spatial, node.target.target );
							if( node.whiteBloodCell.alwaysAquire || targetDistance < node.whiteBloodCell.aquireDistance || node.damageTarget.damage > 0 )
							{
								if( targetDistance < node.whiteBloodCell.attackDistance && node.whiteBloodCell.state != node.whiteBloodCell.EXIT)
								{
								
									node.whiteBloodCell.state = node.whiteBloodCell.ATTACK;
									timeline.gotoAndPlay( "attack" );	
								}
								else
								{
									if(node.whiteBloodCell.state != node.whiteBloodCell.EXIT) { node.whiteBloodCell.state = node.whiteBloodCell.AQUIRE; }
									
									dx = node.target.target.x - node.spatial.x;
									dy = node.target.target.y - node.spatial.y;
									
									updateAngle(node, Math.atan2(dy, dx));
								}
							}	
							// prioritize Bacteria
							for( bacteriaNode = _bacteria.head; bacteriaNode; bacteriaNode = bacteriaNode.next )
							{
								if( bacteriaNode.bacteria.state == bacteriaNode.bacteria.FLOAT )
								{
									targetDistance = GeomUtils.spatialDistance( node.spatial, bacteriaNode.spatial );
									if( node.whiteBloodCell.alwaysAquire || targetDistance < node.whiteBloodCell.aquireDistance )
									{
										// WBC stops motion and deals damage to Bacteria
										if( targetDistance < node.whiteBloodCell.attackDistance )
										{
											node.whiteBloodCell.state = node.whiteBloodCell.ATTACK;
											timeline.gotoAndPlay( "attack" );	
											bacteriaNode.damageTarget.damage += .2;
											
											node.motion.velocity.x = 0;
											node.motion.velocity.y = 0;
											
											continue;
										}
											
										else
										{
											node.whiteBloodCell.state = node.whiteBloodCell.AQUIRE;
											
											dx = bacteriaNode.spatial.x - node.spatial.x;
											dy = bacteriaNode.spatial.y - node.spatial.y;
											
											updateAngle(node, Math.atan2( dy, dx ));
											continue;
										}
									}
								}
							}
						}	
					}
				}
			}
		}
		
		private function updateAngle(node:WhiteBloodCellMotionNode, angle:Number):void
		{
			node.motion.velocity.x = Math.cos( angle ) * node.whiteBloodCell.aquireVelocity;
			node.motion.velocity.y = Math.sin( angle ) * node.whiteBloodCell.aquireVelocity;
			
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
		
		private function initWhiteBloodCell( node:WhiteBloodCellMotionNode ):void
		{
			var timeline:Timeline;
			var clip:MovieClip = MovieClip( EntityUtils.getDisplayObject( node.entity ));
			var sleep:Sleep;
			
			if( clip )
			{
				sleep = node.entity.get( Sleep );
				sleep.ignoreOffscreenSleep = true;
				sleep.useEdgeForBounds = false;
				
				TimelineUtils.convertClip( clip.content, EntityUtils.getOwningGroup( node.entity ), node.entity );
				timeline = node.entity.get( Timeline );
				timeline.labelReached.add( Command.create( labelHandeler, node ));
				
				node.whiteBloodCell.state = node.whiteBloodCell.AQUIRE;
				node.whiteBloodCell.init = true;
			}				
		}
		
		private function labelHandeler( label:String, node:WhiteBloodCellMotionNode ):void
		{
			
			if(node.entity)
			{
				var timeline:Timeline = node.entity.get( Timeline );
				// cheap trick to get rid of the constant errors
				
				if( timeline )
				{
					switch( label )
					{
						case "endSwimloop":
							timeline.gotoAndPlay( "swimloop" );
					//		node.whiteBloodCell.state = node.whiteBloodCell.AQUIRE;
							break;
						case "endReturnToIdle":
							timeline.gotoAndPlay( "idle" );
							//node.whiteBloodCell.state = node.whiteBloodCell.IDLE;
							break;
						case "endAttack":
							timeline.gotoAndPlay( "returnToIdle" );
							if(node.whiteBloodCell.state != node.whiteBloodCell.EXIT) { node.whiteBloodCell.state = node.whiteBloodCell.IDLE; }
							break;
						case "endSwimStart":
							timeline.gotoAndPlay( "swimloop" );
					//		node.whiteBloodCell.state = node.whiteBloodCell.AQUIRE;
							break;
						case "endIdle":
							timeline.gotoAndPlay( "swimStart" );
					//		node.whiteBloodCell.state = node.whiteBloodCell.AQUIRE;
							break;
						case "endExplode":
							timeline.paused = true;
							node.whiteBloodCell.state = node.whiteBloodCell.DIE;
							break;
					}
				}
			}
		}
		
		override public function addToEngine( systemManager:Engine ):void
		{
			_killCountNodes = systemManager.getNodeList( KillCountNode );
	//		_cells = systemManager.getNodeList( WhiteBloodCellMotionNode );
			_bacteria = systemManager.getNodeList( BacteriaMotionNode );
			super.addToEngine(systemManager);
		}
		
		override public function removeFromEngine( systemManager:Engine ):void
		{
			systemManager.releaseNodeList( WhiteBloodCellMotionNode );
			systemManager.releaseNodeList( BacteriaMotionNode );
			super.removeFromEngine(systemManager);
		}
		
		private var _creator:EnemyCreator;
		private var _killCountNodes:NodeList;
		
	//	private var _cells:NodeList;
		private var _bacteria:NodeList;
	}
}
