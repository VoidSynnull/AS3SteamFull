package game.scenes.myth.mountOlympus3.systems
{	
	import flash.display.Sprite;
	import flash.geom.Rectangle;
	
	import ash.core.Engine;
	import ash.core.NodeList;
	
	import engine.components.Audio;
	import engine.components.Motion;
	
	import game.components.motion.Edge;
	import game.data.motion.time.FixedTimestep;
	import game.scenes.myth.mountOlympus3.bossStates.ZeusState;
	import game.scenes.myth.mountOlympus3.components.Bolt;
	import game.scenes.myth.mountOlympus3.nodes.BoltNode;
	import game.scenes.myth.mountOlympus3.nodes.CloudCharacterStateNode;
	import game.scenes.myth.mountOlympus3.nodes.ZeusStateNode;
	import game.scenes.myth.mountOlympus3.playerStates.CloudHurt;
	import game.systems.GameSystem;
	import game.systems.SystemPriorities;
	import game.util.GeomUtils;
	
	public class BoltSystem extends GameSystem
	{		
		// audio actions
		private static const EFFECTS:String =	"effects";
		private static const HIT:String = 		"hit";
		private static const REFLECT:String =	"reflect";
		private static const SPAWN:String = 	"spawn";
		
		// labels
		private static const STOP:String =		"stop";
		
		// global nodes
		private var _playerNode:CloudCharacterStateNode;
		private var _zeusNode:ZeusStateNode;
		private var _rotationUnit:Number;
		
		public function BoltSystem()
		{
			super( BoltNode, updateNode );
			super._defaultPriority = SystemPriorities.move;
			super.fixedTimestep = FixedTimestep.MOTION_TIME;
			super.linkedUpdate = FixedTimestep.MOTION_LINK;
		}
		
		override public function addToEngine( systemManager:Engine ):void
		{
			var playerNode:NodeList = systemManager.getNodeList( CloudCharacterStateNode );
			var zeusNode:NodeList = systemManager.getNodeList( ZeusStateNode );
			
			_playerNode = playerNode.head as CloudCharacterStateNode;
			_zeusNode = zeusNode.head as ZeusStateNode;
			_rotationUnit = 360 / _zeusNode.boss.maxBolts;
			
			super.addToEngine( systemManager );
		}
		
		private function updateNode( node:BoltNode, time:Number ):void
		{
			var bolt:Bolt = node.bolt;
			var motion:Motion = node.motion;
			var audio:Audio = node.audio;
			
			switch( bolt.state )
			{
				case Bolt.OFF:					
					break;
				
				case Bolt.SPAWN:
					
					node.audio.stopAll( EFFECTS );
					audio.playCurrentAction( SPAWN );
					node.display.visible = true;
					motion.zeroMotion();	// slate all motion prior ot setting any (need to allow this to happen?)
					
					var startX:int;
					var startY:int;
					if( bolt.isEnemy )
					{
						bolt.rotation = bolt.index * _rotationUnit;
						startX = _zeusNode.motion.x;
						startY = _zeusNode.motion.y;
					}
					else
					{
						startX = _playerNode.motion.x;
						startY = _playerNode.motion.y;
					}
					
					var radians:Number = GeomUtils.degreeToRadian( bolt.rotation );
					node.spatial.rotation = bolt.rotation;
					node.spatial.x = startX + Math.cos( radians ) * bolt.radiusFromSource;
					node.spatial.y = startY + Math.sin( radians ) * bolt.radiusFromSource;
					motion.velocity.x = Math.cos( radians ) * bolt.speed;
					motion.velocity.y = Math.sin( radians ) * bolt.speed;
					
					bolt.timer = 0;
					bolt.state = Bolt.FLYING;

					break;
				
				case Bolt.FLYING:
					
					if( bolt.isEnemy )	// if enemy bolt
					{
						if( _playerNode.fsmControl.state.type != CloudHurt.TYPE && checkForCollision( node, _playerNode.motion, _playerNode.edge ) )
						{
							// if( _playerNode.clouds && !_playerNode.clouds.hit )	// Not sure why this is necessary? - bard
							node.audio.stopAll( EFFECTS );
							node.audio.playCurrentAction( HIT );					// could add this to Hazard audio
							// signal to player that they have been hit
							bolt.state = Bolt.END;
							_playerNode.hazardCollider.isHit = true;
							_playerNode.hazardCollider.coolDown = .2;
							_playerNode.hazardCollider.interval = .1;
							_playerNode.motion.acceleration.x = motion.velocity.x * 10; 
							_playerNode.motion.acceleration.y = motion.velocity.y * 10;
							_playerNode.fsmControl.setState( CloudHurt.TYPE );
							break;
						}
					}
					else if( checkForCollision( node, _zeusNode.motion, _zeusNode.edge ) )	// if player bolt
					{
						_zeusNode.audio.stopAll( EFFECTS );
						
						if( !_zeusNode.boss.invincible )
						{
							_zeusNode.audio.playCurrentAction( HIT );
							
							// signal to zeus that he has been hit
							if( _zeusNode.boss.health <= 0 )
							{
								super.group.shellApi.triggerEvent( "zeus_downed" );
								_zeusNode.fsmControl.setState( ZeusState.DEFEAT );
							}
							else 
							{
								// run health responses
								ZeusState( _zeusNode.fsmControl.state ).hurt( bolt.damage );
								/*
								_zeusNode.boss.checkSequenceAdvance( _zeusNode.fsmControl.state.type );
								_zeusNode.boss.showHealthBar();
								*/
							}
								
							
							bolt.state = Bolt.END;
						}	
						else	// if invincible bolt is reflected
						{
							node.audio.playCurrentAction( REFLECT );
							motion.velocity.x *= -1;
							motion.velocity.y *= -1;
							bolt.zeusReflected = true;
							bolt.isEnemy = true;
						}	
						break;
					}
					
					bolt.timer += time;
					if( ( motion.x < -30 || motion.x > 2740  || motion.y > 1640 || motion.y < -30 ) )
					{		
						bolt.state = Bolt.END;
					}
					else if ( bolt.timer > bolt.duration )
					{
						bolt.state = Bolt.END;
					}
					break;
				
				case Bolt.END:
					
					node.display.visible = false;
					bolt.timer = 0;
					motion.zeroMotion();
					bolt.state = Bolt.OFF;
					node.sleep.sleeping = true;
					
					if( bolt.isEnemy )
					{
						if( bolt.zeusReflected )	// was originally a player bolt
						{
							bolt.zeusReflected = false;
							bolt.isEnemy = false;
							_playerNode.bolts.pool.release( node.entity, Bolt.PLAYER_BOLT );
						}
						else
						{
							_zeusNode.boss.activeBolts--;	
							_zeusNode.entityPool.pool.release( node.entity, Bolt.BOSS_BOLT );
						}
					}
					else
					{
						_playerNode.bolts.pool.release( node.entity, Bolt.PLAYER_BOLT );
					}
					break;
			}
		}
		
		private function checkForCollision( node:BoltNode, targetMotion:Motion, targetEdge:Edge ):Boolean
		{
			var motion:Motion = node.motion;
			var sprite:Sprite = node.display.displayObject as Sprite;
			var boltBounds:Rectangle = sprite.getBounds(sprite.parent); 
			boltBounds.x = motion.x - boltBounds.width/2;
			boltBounds.y = motion.y - boltBounds.height/2;
			var topLeftToBotRight:Boolean = (motion.x < 0 && motion.y < 0) ||  (motion.x > 0 && motion.y > 0)
			
			var targetBounds:Rectangle = new Rectangle( targetMotion.x + targetEdge.rectangle.left, targetMotion.y + targetEdge.rectangle.top, targetEdge.rectangle.width, targetEdge.rectangle.height );
			return GeomUtils.lineRectCollision( targetBounds, boltBounds, topLeftToBotRight );
		}
	}
}

