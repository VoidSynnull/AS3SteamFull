package game.scenes.myth.shared.systems
{
	import flash.geom.Point;
	
	import ash.core.Engine;
	import ash.core.NodeList;
	
	import game.data.animation.entity.character.Stand;
	import game.scenes.myth.mountOlympus3.nodes.CloudCharacterStateNode;
	import game.scenes.myth.mountOlympus3.nodes.ZeusStateNode;
	import game.scenes.myth.shared.components.Cloud;
	import game.scenes.myth.shared.nodes.CloudNode;
	import game.systems.GameSystem;
	import game.systems.SystemPriorities;
	import game.util.GeomUtils;
	
	public class CloudSystem extends GameSystem
	{
		// labels
		private static const END:String =			"end";
		private static const LOSE_ZEUS:String =		"lose_zeus";
		private static const STOP:String =			"stop";
		
		// global variables
		private var _init:Boolean = false;
		private var screenWidth:Number = 2509;
		private var screenHeight:Number = 1334;
		
		// global nodes
		private var _playerNode:CloudCharacterStateNode;
		private var _zeusNode:ZeusStateNode;
		private var _olympus2:Boolean;
		
		public function CloudSystem( olympus2:Boolean = false )
		{			
			_olympus2 = olympus2;
			super( CloudNode, nodeUpdate );
			super._defaultPriority = SystemPriorities.move;
		}
		
		override public function addToEngine( systemManager:Engine ):void
		{
			var playerNode:NodeList = systemManager.getNodeList( CloudCharacterStateNode );
			var zeusNode:NodeList = systemManager.getNodeList( ZeusStateNode );
			
			_playerNode = playerNode.head as CloudCharacterStateNode;
			_zeusNode = zeusNode.head as ZeusStateNode;
			
			super.addToEngine( systemManager );
		}

		private function nodeUpdate( node:CloudNode, time:Number ):void
		{
			var cloud:Cloud = node.cloud;

			if( zeusHasHealth() || _olympus2 )
			{
				if( playerHasClouds() )
				{
					cloud.state = cloud.KILLED;
				}
				
				switch( cloud.state )
				{
					case cloud.GATHERED:
						gathered( node );
						break;
					
					case cloud.GATHER:
						gather( node );
						break;
					
					case cloud.DRIFT:
						drift( node );
						break;
					
					case cloud.ATTRACT:
						attract( node );
						break;
					
					case cloud.SPAWN:
						fadeIn( node );
						break;
					
					case cloud.KILL:
						if( _playerNode.clouds.hit )
						{
							node.followTarget.rate = 0;
							cloud.state = cloud.KILLED;
						}
						break;
					
					case cloud.KILLED:
						fadeOut( node );
						break;
				}
			}
		}	
		
		private function positionCloud( node:CloudNode, addToPlayer:Boolean = false ):void
		{
			var randX:Number = 0;
			var randY:Number = 0;
			
			if( addToPlayer )
			{
				var pos:Point = new Point( _playerNode.spatial.x, _playerNode.spatial.y );
				randX = GeomUtils.randomInRange( pos.x - 30, pos.x + 30 ) - 30;
				randY = GeomUtils.randomInRange( pos.y - 10, pos.y + 10 ) + 10;
			}
				
			else
			{
				randX = GeomUtils.randomInRange( 20, screenWidth );
				randY = GeomUtils.randomInRange( 20, screenHeight );				
			}
			
			node.motion.acceleration.x = node.motion.velocity.x = node.motion.previousAcceleration.x = node.motion.totalVelocity.x = 
				node.motion.acceleration.y = node.motion.velocity.y = node.motion.previousAcceleration.y = node.motion.totalVelocity.y = 0;
			
			node.spatial.x = randX;
			node.spatial.y = randY;
		}
		
		private function playerHasClouds():Boolean
		{
			var result:Boolean = false;
			if( _playerNode )
			{
				if( _playerNode.clouds.dead )
				{
					result = true;
				}
			}
			return result;
		}
		
		private function zeusHasHealth():Boolean
		{
			var result:Boolean = false;
			if( _zeusNode )
			{
				if( _zeusNode.boss.health > 0 )
				{
					result = true;
				}
			}
			return result;
		}
		
		private function gathered( node:CloudNode ):void
		{
			if( node.display.alpha < .9 )
			{
				node.display.alpha = 1;
			}
		}
		
		private function gather( node:CloudNode ):void
		{
			node.followTarget.rate = .5;	
			node.followTarget.offset = new Point( GeomUtils.randomInRange( -40, 40 ) - 25 ,GeomUtils.randomInRange( -10, 10 ) + 25 );
			
			node.display.alpha = .75;
			node.cloud.state = node.cloud.GATHERED;
	
			if( !node.cloud.attached && !_olympus2 )
			{
				_playerNode.clouds.clouds.push( node.cloud );
				node.cloud.attached = true;	
			}
		}
		
		private function drift( node:CloudNode ):void
		{			
			if( node.motion.velocity.x <= 0 && node.motion.velocity.y <= 0 )
			{
				startdrift( node );
			}
			
			if(( node.spatial.x < -20 || node.spatial.x > screenWidth ) || ( node.spatial.y < -20 || node.spatial.y >screenHeight ))
			{
				//kill off clouds that leave the scene, make eligible for respawn
				node.cloud.state = node.cloud.KILLED;
			}
			
			// attract when in range
			if( GeomUtils.spatialDistance( _playerNode.spatial, node.spatial ) < node.cloud.attractRadius )
			{
				node.cloud.state = node.cloud.ATTRACT;
				attract( node );
			}
		}
		
		private function startdrift( node:CloudNode):void
		{
			var x:Number;
			var y:Number;
			
			x = GeomUtils.randomInRange( 50, 80 );
			if( Math.random() * 2 < 1 )
			{
				x *= -1;
			}
			
			y = GeomUtils.randomInRange( 50, 80 );
			if( Math.random() * 2 < 1 )
			{
				y *= -1;
			}
			
			node.motion.velocity = new Point( x, y );
			node.cloud.state = node.cloud.DRIFT;
		}
		
		private function attract( node:CloudNode ):void
		{
			var range:Number;
			
			// remove attract when out of range
			if( GeomUtils.spatialDistance( _playerNode.spatial, node.spatial ) > node.cloud.attractRadius * 1.5 )
			{
				node.followTarget.rate = 0;
				node.cloud.state = node.cloud.DRIFT;
			}
			
			else
			{
				node.followTarget.rate = .015;
				range = _playerNode.clouds.clouds.length;
				
				node.followTarget.offset = new Point( GeomUtils.randomInRange( -3 * range, 3 * range ) - 25, GeomUtils.randomInRange( -range, range ));
			}
			
			// gather when in range
			if( GeomUtils.spatialDistance( _playerNode.spatial, node.spatial ) < node.cloud.gatherRadius )
			{
				gather( node );
			}
		}
		
		private function fadeIn( node:CloudNode ):void
		{
			node.display.alpha += .015;
			
			if( node.display.alpha > .9 )
			{
				node.display.alpha = 1;
				node.cloud.state = node.cloud.DRIFT;
			}
		}
		
		private function fadeOut( node:CloudNode ):void
		{
			node.motion.velocity.x += node.motion.velocity.x * 0.1;
			node.motion.velocity.y += node.motion.velocity.y * 0.1;
			
			node.display.alpha -= 0.015;
			if( node.display.alpha <= 0 )
			{
				respawn( node );
			}
		}
		
		private function respawn( node:CloudNode ):void
		{
			positionCloud( node );
			node.cloud.state = node.cloud.SPAWN;
		}		
	}
}