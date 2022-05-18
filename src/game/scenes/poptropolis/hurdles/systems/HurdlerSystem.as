package game.scenes.poptropolis.hurdles.systems
{
	import ash.core.Entity;
	
	import engine.components.Audio;
	import engine.components.Motion;
	import engine.components.Spatial;
	import engine.managers.SoundManager;
	
	import game.components.timeline.Timeline;
	import game.components.entity.character.animation.RigAnimation;
	import game.data.animation.entity.character.Skid;
	import game.data.animation.entity.character.poptropolis.HurdleJump;
	import game.data.animation.entity.character.poptropolis.HurdleRun;
	import game.data.animation.entity.character.poptropolis.HurdleStop;
	import game.scenes.poptropolis.hurdles.Hurdles;
	import game.scenes.poptropolis.hurdles.components.Hurdler;
	import game.scenes.poptropolis.hurdles.nodes.HurdlerNode;
	import game.systems.GameSystem;
	import game.util.CharUtils;
	
	import org.osflash.signals.Signal;
	
	public class HurdlerSystem extends GameSystem
	{
		private const ACCEL_AFTER_PASS_FINISH:int = -450
			
		public var stoppedRunningAfterFinish:Signal;
		public var passedFinishLine:Signal;

		private var _jumpFrequencyX:Number
		private var _lastJumpX:Number;
		private var _finishPosX:Number;
		
		public function HurdlerSystem()
		{
			super( HurdlerNode, updateNode );
			stoppedRunningAfterFinish = new Signal();
			passedFinishLine = new Signal();
		}

		public function init ( jumpFrequencyX:Number, lastJumpX:Number, finishPosX:Number ):void
		{
			_jumpFrequencyX = jumpFrequencyX;
			_lastJumpX = lastJumpX;
			_finishPosX = finishPosX;
		}

		private function updateNode( node:HurdlerNode, time:Number ) : void
		{
			updateCharControl( node );
			checkCollision( node );
		}
		
		private function updateCharControl( node:HurdlerNode ) : void
		{
			var hurdler:Hurdler = node.hurdler;
			var spatial:Spatial = node.spatial;
			var motion:Motion = node.motion;
			var rigAnim:RigAnimation = node.rigAnim;
			var char:Entity = node.entity;
			
			// check for collison with ground
			if ( motion.velocity.y > 0 && spatial.y > hurdler.groundPosY ) 
			{
				spatial.y = hurdler.groundPosY;
				motion.acceleration.y = 0;
				motion.velocity.y = 0;

				if ( hurdler.state == "jumping"  )
				{
					hurdler.state = "running";
					
					if( !hurdler.crossedFinish )
					{
						CharUtils.setAnim( char, HurdleRun );
					}
					else
					{
						CharUtils.setAnim( char, Skid );
					}
				}
			}

			// check for full stop
			if( hurdler.crossedFinish )
			{
				//trace( "crossedFinish: state is: " + hurdler.state + " velocity is: "  + motion.velocity.x );
				if( hurdler.state == "crossedFinish" )
				{
					if( Math.abs(motion.velocity.x) < 380 )
					{
						CharUtils.setAnim( char, Skid);
						hurdler.state = "stopping";
					}
				}
				else if ( motion.velocity.x < 0 && motion.acceleration.x < 0 ) 
				{
					motion.acceleration.x = 0;
					motion.acceleration.y = 0;
					motion.velocity.x = 0;
					motion.velocity.y = 0;
					
					stoppedRunningAfterFinish.dispatch( char );
				} 
			}
			
			if (motion.acceleration.x == 0) 
			{
				motion.velocity.x = 0
			}
			
			// check for jumps
			if( !hurdler.crossedFinish)
			{
				// Check if time to set next jump for npcs
				if ( hurdler.state == "running")
				{
					if( !hurdler.isPlayer )
					{
						if ( spatial.x > hurdler.nextJumpX ) 
						{
							jump( node );
							hurdler.nextHurdleX += _jumpFrequencyX
							var newJumpPtX:Number = hurdler.nextHurdleX + Math.random()*Hurdles.NPC_JUMP_INACCURACY - Hurdles.NPC_JUMP_INACCURACY/2;
							if (newJumpPtX < _lastJumpX) 
							{
								hurdler.nextJumpX = newJumpPtX
							} 
							else 
							{
								hurdler.nextJumpX = 100000
							}
						}
					}
					else if( hurdler.triggerJump )
					{
						jump( node );
					}
				}
			
				// return to false
				hurdler.triggerJump = false;
			}
		}
		
		public function jump ( node:HurdlerNode ):void 
		{
			CharUtils.setAnim( node.entity, HurdleJump );
			node.hurdler.state = "jumping";
			node.motion.velocity.y = Hurdles.JUMP_VEL_Y;// -400
			node.motion.acceleration.y = Hurdles.JUMP_ACCEL_Y;// 650
		}
		
		// check hurdles for collision with players
		private function checkCollision( node:HurdlerNode ) : void
		{
			var hurdler:Hurdler = node.hurdler;

			if( !hurdler.crossedFinish )
			{
				var charSpatial:Spatial = node.spatial;
				var charMotion:Motion = node.motion;
				var trackIndex:int = node.hurdler.trackIndex;
				var children:Vector.<Entity> = node.children.children;
				
				// check against relevant hurdle group
				for each (var hurdle:Entity in children ) 
				{
					var hurdleSpatial:Spatial = Spatial (hurdle.get(Spatial))
					var hurdleTimeline:Timeline = Timeline (hurdle.get(Timeline))
					
					// if character is in range for collision
					if (Math.abs(charSpatial.x - hurdleSpatial.x ) < 100 && charSpatial.x > hurdleSpatial.x ) 
					{
						// i.e if hurdles hasn't been hit yet
						if ( hurdleTimeline.currentIndex == 0 ) 
						{
							if ( charSpatial.y > ( trackIndex * 50 + 250 ) ) 
							{
								charMotion.velocity.x = -200;
								hurdleTimeline.gotoAndPlay ("fall");
								Audio(hurdle.get(Audio)).play( SoundManager.EFFECTS_PATH + "hurdle_knocked_over_01.mp3" );
							}
							else if (charSpatial.y > ( trackIndex * 50 + 220 ) ) 
							{
								charMotion.velocity.x = -70;
								hurdleTimeline.gotoAndPlay ("trip");
								Audio(hurdle.get(Audio)).play( SoundManager.EFFECTS_PATH + "hurdle_bump_01.mp3" );
							}
						}
					}
					
					if( !hurdler.crossedFinish )
					{
						if ( charSpatial.x > _finishPosX + 100 + trackIndex * Hurdles.RUNNER_SPACING_X ) 
						{
							hurdler.crossedFinish = true;	// TODO :: remember to reset at star of race
							hurdler.state = "crossedFinish";
							charMotion.acceleration.x = ACCEL_AFTER_PASS_FINISH;	// slow down
							passedFinishLine.dispatch( node.entity );
						}
					}
				}
			}
		}
	}
}