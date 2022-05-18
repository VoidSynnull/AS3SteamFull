package game.scenes.myth.labyrinth.systems
{
	import flash.display.DisplayObject;
	
	import ash.core.Engine;
	
	import engine.components.Display;
	import engine.components.Motion;
	import engine.components.Spatial;
	
	import game.components.timeline.Timeline;
	import game.data.motion.time.FixedTimestep;
	import game.scenes.myth.labyrinth.components.ScorpionComponent;
	import game.scenes.myth.labyrinth.nodes.ScorpionNode;
	import game.systems.GameSystem;
	
	public class ScorpionSystem extends GameSystem
	{
		public function ScorpionSystem()
		{
			super( ScorpionNode, updateNode );
		}
		
		override public function addToEngine(systemManager:Engine):void
		{
			super.addToEngine( systemManager );
			
			_playerMotion = group.shellApi.player.get( Motion );
			_playerDisplay = group.shellApi.player.get( Display ).displayObject;
			
			super.fixedTimestep = FixedTimestep.MOTION_TIME;
			super.linkedUpdate = FixedTimestep.MOTION_LINK;
		}
		
		public function updateNode( node:ScorpionNode, time:Number ):void
		{
			var scorpion:ScorpionComponent = node.scorpion;	
			var motion:Motion = node.motion;
			var scorpionSpatial:Spatial = scorpion.spatial;
			var timeline:Timeline = node.timeline;
			
			if( _playerMotion.y > MIN_Y && _playerMotion.x > MIN_X && _playerMotion.x < MAX_X && !scorpion.isHit )
			{
				if( Math.abs( _playerMotion.x - motion.x ) < ATTACK_RANGE )
				{
					timeline.paused = false;
				}
				
				if( _playerMotion.x < motion.x - CHARGE_X )
				{
					scorpion.accel = -SCORPION_ACCEL;
					if( scorpionSpatial.scaleX < 0 )
					{
						scorpionSpatial.scaleX *= -1;
					}
				}
				else if( _playerMotion.x > motion.x + CHARGE_X )
				{
					scorpion.accel = SCORPION_ACCEL;
					if( scorpionSpatial.scaleX > 0 )
					{
						scorpionSpatial.scaleX *= -1;
					}
				}
				else
				{
					scorpion.accel = 0;
				}
				
				if( time % TIME_CONSTANT )
				{
					moveLegs( node );
				}
			}
			else
			{
				if( scorpion.startX < motion.x - IDLE_X )
				{
					scorpion.accel = -SCORPION_ACCEL;
					
					if( scorpionSpatial.scaleX < 0 )
					{
						scorpionSpatial.scaleX *= -1;
					}
					
					if( time % TIME_CONSTANT )
					{
						moveLegs( node );
					}
				}
				
				else if( scorpion.startX > motion.x + IDLE_X )
				{
					scorpion.accel = SCORPION_ACCEL;
					if( scorpionSpatial.scaleX > 0 )
					{
						scorpionSpatial.scaleX *= -1;
					}
					
					if( time % TIME_CONSTANT )
					{
						moveLegs( node );
					}
				}
				
				else
				{
					scorpion.accel = 0;
				}
			}
		
			motion.velocity.x += scorpion.accel;
			motion.velocity.x *= VELOCITY_MODIFIED;
			
			if( _playerMotion.x - node.motion.x )
		
			var hitDisplay:Display = node.display;
			if ( hitDisplay.displayObject.hitTestObject( _playerDisplay ))
			{
				if( !scorpion.isHit )
				{
					group.shellApi.triggerEvent( "scorpion_sting" );
					scorpion.isHit = true;
				}
			}
			
			scorpion.timer ++;
			if( scorpion.timer >= COOLDOWN )
			{
				scorpion.isHit = false;
				scorpion.timer = 0;
			}
		}
		
		private function moveLegs( node:ScorpionNode ):void
		{
			var clip:DisplayObject;
			var scorpion:ScorpionComponent = node.scorpion;
			var timeline:Timeline;
			var number:int;
			
			for( number = 0; number < 8; number ++ )
			{
				clip = scorpion.leg[ number ];
				
				if(( Math.random() * 10 ) > 7 )
				{
					group.shellApi.triggerEvent( "scorpion_skitter" );
					clip.scaleX *= -1;
				}
			}
		}
		
		override public function removeFromEngine( engine:Engine ):void
		{
			engine.releaseNodeList( ScorpionNode );
			
			super.removeFromEngine( systemManager );
		}
		
		private const CHARGE_X:int = 20;
		private const ATTACK_RANGE:int = 125;
		private const IDLE_X:int = 50;
		private const SCORPION_ACCEL:int = 60;
		private const MIN_Y:int = 1930;
		private const MIN_X:int = 2078;
		private const MAX_X:int = 3128;
		private const VELOCITY_MODIFIED:Number = .8;
		private const COOLDOWN:int = 30;
		private const TIME_CONSTANT:int = 25;
		
		private var _playerMotion:Motion;
		private var _playerDisplay:DisplayObject;
	}
}