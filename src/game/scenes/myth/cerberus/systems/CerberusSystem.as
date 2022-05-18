package game.scenes.myth.cerberus.systems
{	
	import ash.core.Engine;
	import ash.core.Entity;
	
	import engine.components.Audio;
	import engine.components.Display;
	import engine.components.Id;
	import engine.components.Spatial;
	import engine.components.Tween;
	import engine.managers.SoundManager;
	
	import game.components.timeline.Timeline;
	import game.scenes.myth.MythEvents;
	import game.data.sound.SoundModifier;
	import game.scenes.myth.cerberus.components.CerberusControlComponent;
	import game.scenes.myth.cerberus.components.CerberusHeadComponent;
	import game.scenes.myth.cerberus.nodes.CerberusNode;
	import game.systems.GameSystem;
	import game.util.DataUtils;
	
	public class CerberusSystem extends GameSystem
	{
		public function CerberusSystem( cerberusControl:CerberusControlComponent )
		{
			_cerberusControl = cerberusControl;
			super( CerberusNode, updateNode );
		}
		
		private function updateNode( node:CerberusNode, time:Number ):void
		{
			var head:CerberusHeadComponent = node.head;
			var spatial:Spatial = node.spatial;
			var timeline:Timeline;
			var zeeDisplay:Display;
			var zeeSpatial:Spatial;
			var id:Id = node.id;
			var headNumber:Number = DataUtils.getNumber( id.id.slice( 4 ));
			
			var randomX:Number;
			var randomY:Number;
			
			var tween:Tween;
			var zee:Entity;
			
			var neckSpatial:Spatial = head.neckSpatial;
			var faceSpatial:Spatial = head.faceSpatial;
			
			var hitDisplay:Display = head.hitDisplay;
			
			/*******************************
			 * 		  BEFORE MELODY
			 * *****************************/
			if( !_cerberusControl.teleporting )
			{
				if( !_cerberusControl.isSoothed )
				{
					moveHead( node );
					
					switch( head.state )
					{
						case IDLE:
							if( !head.isBlinking )
							{
								if( Math.random() * 120 < 1 )	
								{
									blink( node );
								}
							}
							else 
							{
								head.blinkCounter ++;
								if( head.blinkCounter > 5 )
								{
									blink( node, false );
								}
							}
							
							if( !_cerberusControl.isAttacking )
							{
								if( _cerberusControl.playerDisplay != null )
								{
									if( hitDisplay.displayObject.hitTestObject( _cerberusControl.playerDisplay.displayObject ))
									{
										shakeFace( node );
										group.shellApi.triggerEvent( "chomp" + headNumber );
									}	
								}
							}
							break;
					
						case HIT:
							head.hitCounter ++;
							if( head.hitCounter < 16 )
							{
								faceSpatial.x = head.faceNeutral + Math.random()*4 - 2;
							}
							else
							{
								faceSpatial.x = head.faceNeutral;
								timeline = head.faceTimeline;
								timeline.gotoAndStop( 0 );
								head.state = IDLE;
								_cerberusControl.isAttacking = false;
							}
							break;
						
						default:
							break;
					}
				} 
				else 
				{
				
				/*******************************
				 * 		  AFTER MELODY
				 * *****************************/
					timeline = head.faceTimeline;
					var audio:Audio = node.audio;
					
					switch( head.state )
					{
						case SNORE:
							break;
						
						case IDLE:
							head.state = HIT;
							break;
						
						case HIT:
							timeline.gotoAndStop( 2 );
							group.removeEntity( head.hit );
							head.state = SOOTH_START; 
							blink( node, false );
							audio.play( SoundManager.EFFECTS_PATH + FALLING_ASLEEP, false, SoundModifier.POSITION );
							
							break
						
						case SOOTH_START:
							spatial.rotation -= 1;
							neckSpatial.rotation += -neckSpatial.rotation / 4;
							faceSpatial.rotation = -spatial.rotation;
							
							if( spatial.rotation < -90 )
							{
								timeline.gotoAndStop( 3 );
								
								head.state = SOOTHED;		
							}
							break;
						
						case SOOTHED:
							if( spatial.rotation > -115 )
							{
								spatial.rotation -= 1;
							}
							else
							{
								head.snoreCounter = 0;
								head.timer = Math.random() * 6;
								timeline.gotoAndStop( 4 );
								
								audio.play( SoundManager.EFFECTS_PATH + ASLEEP, true, SoundModifier.POSITION );
								
								head.state = SLEEP;
							}
							
							neckSpatial.rotation += -neckSpatial.rotation / 4;
							faceSpatial.rotation = -spatial.rotation;
							break;
						
						case SLEEP:
							
							if( !group.shellApi.checkEvent( _events.SLEEPING_CERBERUS ))
							{
								group.shellApi.triggerEvent( _events.SLEEPING_CERBERUS );
								_cerberusControl.isSnoring = true;
								head.state = SNORE;
							}
							break;	
					}
				}
			}
		}
			

		/*******************************
		 * 		IDLE HEAD MOVEMENT
		 * *****************************/
		private function moveHead( node:CerberusNode ):void
		{
			var id:Id = node.id;
			var audio:Audio = node.audio;
			
			var head:CerberusHeadComponent = node.head;
			var spatial:Spatial = node.spatial;
			
			var neckSpatial:Spatial = head.neckSpatial;
			var faceSpatial:Spatial = head.faceSpatial;
			var blinkSpatial:Spatial = head.blinkSpatial;
						
			head.timer += DELTA_T;
			spatial.rotation = head.rotation + 20 * Math.sin( head.timer );
			spatial.rotation = 20 * Math.sin( head.timer - 2 );
			
			spatial.rotation = head.rotation + 20 * Math.sin( head.timer );
			neckSpatial.rotation = 20 * Math.sin( head.timer - 2 );
			faceSpatial.rotation = -spatial.rotation - neckSpatial.rotation;
			blinkSpatial.rotation = faceSpatial.rotation;
			
			if( Math.random() * 1000 > 999 )
			{
				if( !audio.isPlaying( SoundManager.EFFECTS_PATH + IDLE_MOTION ))
				{
					audio.play( SoundManager.EFFECTS_PATH + IDLE_MOTION, false, SoundModifier.POSITION, 20 );
				}
			}
		}
		
		/*******************************
		 * 		   RANDOM BLINK
		 * *****************************/
		private function blink( node:CerberusNode, on:Boolean = true ):void
		{
			var head:CerberusHeadComponent = node.head;
			var timeline:Timeline = head.blinkTimeline;
			var frame:int = 0;
			
			head.isBlinking = on;
			head.blinkCounter = 0;
			
			if( on )
			{
				frame = 1;
			}
			
			timeline.gotoAndStop( frame );
		}
				
		/*******************************
		 * 		     ATTACK
		 * *****************************/
		private function shakeFace( node:CerberusNode ):void
		{
			var head:CerberusHeadComponent = node.head;
			var timeline:Timeline = head.faceTimeline;
			
			timeline.gotoAndStop( 1 );
			
			head.state = HIT;
			head.faceNeutral = head.faceSpatial.x;
			head.hitCounter = 0;
			
			_cerberusControl.isAttacking = true;
		}
		
		override public function addToEngine( systemManager:Engine ):void
		{		
			_events = group.shellApi.islandEvents as MythEvents;
			
			super.addToEngine(systemManager);
		}
		
		private static const DELTA_T:Number = 	.05;
		private static const BOUNCE_Y:int = -400;
		
		private var _events:MythEvents;
		private var _cerberusControl:CerberusControlComponent;
	
		private static const ASLEEP:String = 			"myth_cerb_asleep_01_loop.mp3";
		private static const FALLING_ASLEEP:String = 	"myth_cerb_falling_asleep_01.mp3";
		private static const IDLE_MOTION:String =		"myth_cerb_idle_01_loop.mp3";
		
		private static const IDLE:String = 				"idle";
		private static const HIT:String = 				"hit";
		private static const SOOTH_START:String = 		"sooth_start";
		private static const SOOTHED:String = 			"soothed";
		private static const SLEEP:String =				"sleep";
		private static const SNORE:String = 			"snore";
	}
}