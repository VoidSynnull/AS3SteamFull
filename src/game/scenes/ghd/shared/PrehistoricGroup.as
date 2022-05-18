package game.scenes.ghd.shared
{
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.geom.Point;
	
	import ash.core.Entity;
	
	import engine.components.Audio;
	import engine.components.AudioRange;
	import engine.components.Display;
	import engine.components.Id;
	import engine.components.Motion;
	import engine.components.Spatial;
	import engine.components.SpatialAddition;
	import engine.creators.InteractionCreator;
	import engine.group.Group;
	import engine.util.Command;
	
	import game.components.entity.Sleep;
	import game.components.hit.EntityIdList;
	import game.components.motion.FollowTarget;
	import game.components.motion.Threshold;
	import game.components.motion.WaveMotion;
	import game.components.scene.SceneInteraction;
	import game.components.timeline.BitmapSequence;
	import game.components.timeline.Timeline;
	import game.creators.entity.BitmapTimelineCreator;
	import game.creators.scene.HitCreator;
	import game.creators.ui.ToolTipCreator;
	import game.data.WaveMotionData;
	import game.data.scene.hit.MovingHitData;
	import game.scene.template.AudioGroup;
	import game.scenes.survival1.shared.components.TriggerHit;
	import game.scenes.survival1.shared.systems.TriggerHitSystem;
	import game.systems.motion.ThresholdSystem;
	import game.systems.motion.WaveMotionSystem;
	import game.util.DisplayUtils;
	import game.util.EntityUtils;
	import game.util.PerformanceUtils;
	import game.util.TimelineUtils;
	
	import org.osflash.signals.Signal;

	public class PrehistoricGroup extends Group
	{
		private const WASP:String			=		"wasp";
		private const BABY:String			=		"baby";
		private const MOMA:String			=		"moma";
		private const BODY:String			=		"Body";
		private const HEAD:String			=		"Head";
		private const EGG:String			=		"egg";
		private const CRACKED_EGG:String	=		"crackedEgg";
		private const NEST:String			=		"nest";
		private const DACTYL:String 		=		"dactyl";
		private const ART:String			=		"Art";
		private const TRIGGER:String 		=	"trigger";
		
		public function PrehistoricGroup()
		{
			super();
		}
		
		private var player:Entity;
		
		public function createDactyls( group:Group, container:DisplayObjectContainer, nestHandler:Function = null ):void
		{
			group.addSystem( new WaveMotionSystem());
			group.addSystem( new ThresholdSystem());
			group.addSystem(new TriggerHitSystem());
			
			
			var dactylHead:Entity;
			var dactylBody:Entity;
			var headTimeline:Timeline;
			var bodyTimeline:Timeline;
			var sleep:Sleep;
			
			var audio:Audio;
			var clip:MovieClip;
			var creator:HitCreator = new HitCreator();
			var dactyl:Entity;
			var dactylArt:Entity;
			var display:Display;
			var motion:Motion;
			var movingHitData:MovingHitData;
			var number:int;
			var position:Point;
			var spatial:Spatial;
			var threshold:Threshold;
			var timeline:Timeline;
			var wasp:Entity;
			var waveMotion:WaveMotion;
			var waveMotionData:WaveMotionData;
			
			var triggerHit:TriggerHit;

			clip = container[ DACTYL + HEAD ];
			clip.gotoAndStop( 1 );
			var headSequence:BitmapSequence = BitmapTimelineCreator.createSequence( clip, true, PerformanceUtils.defaultBitmapQuality );
			
			clip = container[ DACTYL + BODY ];
			clip.gotoAndStop( 1 );
			var bodySequence:BitmapSequence = BitmapTimelineCreator.createSequence( clip, true, PerformanceUtils.defaultBitmapQuality );
			var dactylSequence:BitmapSequence;
			
			clip = container[ WASP + "1" ];
			clip.gotoAndStop( 1 );
			var waspSequence:BitmapSequence = BitmapTimelineCreator.createSequence( clip, this, PerformanceUtils.defaultBitmapQuality );
			
			var audioGroup:AudioGroup = group.getGroupById(AudioGroup.GROUP_ID) as AudioGroup;
			
			for( number = 1; container[ DACTYL + number + ART ]; number ++ )
			{

				// PLATFORM HIT
				dactyl = group.getEntityById( DACTYL + number );
				
				spatial = dactyl.get( Spatial );
				display = dactyl.get( Display );
				display.alpha = 0;
				motion = dactyl.get( Motion );
				
				// ASSOCIATED DISPLAY
				// CREATE HEAD
				clip = container[ DACTYL + number + ART ];
				dactylHead = BitmapTimelineCreator.createBitmapTimeline( clip.head, true, false, headSequence, PerformanceUtils.defaultBitmapQuality );
				headTimeline = dactylHead.get( Timeline );
				headTimeline.gotoAndStop( "closed" );
				group.addEntity( dactylHead );	
				
				
				dactylBody = BitmapTimelineCreator.createBitmapTimeline( clip.body, true, false, bodySequence, PerformanceUtils.defaultBitmapQuality );
				bodyTimeline = dactylBody.get( Timeline );
				bodyTimeline.playing = true;
				bodyTimeline.handleLabel( "fly", Command.create( flapWing, dactyl ), false );
				
				group.addEntity( dactylBody );
				
				clip.head.visible = false;
				clip.body.visible = false;
				
				// MAKE PARENT DACTYL ART
				dactylArt = EntityUtils.createSpatialEntity( group, clip );
				dactylArt.add( new Id( clip.name ));
				TimelineUtils.convertClip( clip, group, dactylArt, null, false );

				sleep = dactylArt.get( Sleep );
				sleep.sleeping = false;
				sleep.ignoreOffscreenSleep = true;

				dactylArt.add( new FollowTarget( spatial ));
				
				display = dactylHead.get( Display );
				display.moveToFront();
				
				// DACTYLS BEHAVE DIFFERENTLY IN PREHISTORIC 1 AND 2
				if( group.shellApi.sceneName.indexOf( "1" ) > -1 )
				{
					switch( number )
					{
						case 1:
							motion.velocity.x = 300;
							position = new Point( -400, spatial.y );
							
							threshold = new Threshold( "x", ">" );
							threshold.threshold = 3000;
							
							spatial.scaleX *= -1;
							spatial = dactylArt.get( Spatial );
							spatial.scaleX *= -1;
							
							break;
						
						case 2:
							motion.velocity.x = -300;
							position = new Point( 3000, spatial.y );
							
							threshold = new Threshold( "x", "<" );
							threshold.threshold  = -400;
							break;
						
						default:
							break;
					}
				}
				else
				{
					if( number == 5 )
					{
						motion.velocity.x = 250;
						motion.velocity.y = -60;
						
						threshold = new Threshold( "x", ">" );
						threshold.threshold = 2380;
						
						spatial.scaleX *= -1;
						position = new Point( -220, spatial.y );
						
						spatial = dactylArt.get( Spatial );
						spatial.scaleX *= -1;
					}
					else if( number % 2 == 0 )
					{
						motion.velocity.x = 300;
						
						threshold = new Threshold( "x", ">" );
						threshold.threshold = 2380;
						
						spatial.scaleX *= -1;
						position = new Point( -220, spatial.y );
						
						spatial = dactylArt.get( Spatial );
						spatial.scaleX *= -1;
					}
					else
					{
						motion.velocity.x = -300;
						
						threshold = new Threshold( "x", "<" );
						threshold.threshold  = -220;
						
						position = new Point( 2380, spatial.y );
						spatial = dactylArt.get( Spatial );
					}
				}
				
				dactyl.add( threshold );
				threshold.entered.add( Command.create( repositionDactyl, dactyl, position ));
				creator.addHitSoundsToEntity( dactyl, audioGroup.audioData, shellApi );
				audioGroup.addAudioToEntity( dactyl );
				dactyl.add( new AudioRange( 600 ));
				audio = dactyl.get( Audio );
				audio.playCurrentAction( TRIGGER );
				
				triggerHit = new TriggerHit( headTimeline );
				triggerHit.triggered = new Signal();
				
				dactyl.add(new EntityIdList());
				dactyl.add( triggerHit );
			}
		
			// SETUP FOR NEST
			if( nestHandler )
			{
				DisplayUtils.convertToBitmapSprite( container[ EGG ], null, PerformanceUtils.defaultBitmapQuality );
				DisplayUtils.convertToBitmapSprite( container[ CRACKED_EGG ], null, PerformanceUtils.defaultBitmapQuality );
				DisplayUtils.convertToBitmapSprite( container[ NEST ], null, PerformanceUtils.defaultBitmapQuality );
				
				// setup baby dactyl
				clip = container[ BABY ];
				clip.gotoAndStop(1);
				dactyl = EntityUtils.createSpatialEntity( group, clip, container );
				dactylSequence = BitmapTimelineCreator.createSequence( clip, true, PerformanceUtils.defaultBitmapQuality );
				
				BitmapTimelineCreator.convertToBitmapTimeline( dactyl, clip, true, dactylSequence, PerformanceUtils.defaultBitmapQuality );
				dactyl.add( new Id( BABY ));
				Timeline( dactyl.get( Timeline )).playing = true;
				audioGroup.addAudioToEntity( dactyl );
				
				// setup moma dactyl
				clip = container[ MOMA ];
				clip.gotoAndStop(1);
				dactyl = EntityUtils.createSpatialEntity( group, clip, container );
				dactylSequence = BitmapTimelineCreator.createSequence( clip, true, PerformanceUtils.defaultBitmapQuality );
				
				dactyl = BitmapTimelineCreator.convertToBitmapTimeline( dactyl, clip, true, dactylSequence, PerformanceUtils.defaultBitmapQuality );
				
				dactyl.add( new Id( MOMA ));
				Timeline( dactyl.get( Timeline )).playing = true;
				
				// ADD THE SWIP MOTION
				var clickHit:Entity = EntityUtils.createSpatialEntity( group, container[ "actionClip" ]);
				clickHit.add( new Id( "actionClip" ));
				InteractionCreator.addToEntity( clickHit, [ InteractionCreator.CLICK ]);
				ToolTipCreator.addToEntity( clickHit );
				
				var sceneInteraction:SceneInteraction = new SceneInteraction();
				sceneInteraction.reached.add( nestHandler );
				clickHit.add( sceneInteraction );
			}
			
			// SETUP WASPS
			for( number = 1; container[ WASP + number ]; number ++ )
			{
				clip = container[ WASP + number ];
				
				wasp = EntityUtils.createSpatialEntity( group, clip, container );
				BitmapTimelineCreator.convertToBitmapTimeline( wasp, clip, true, waspSequence );
				Timeline( wasp.get( Timeline )).playing = true;
				
				wasp.add( new Id( WASP + number ));
				
				waveMotion = new WaveMotion();
				waveMotionData = new WaveMotionData( "y", 18, .1 );
				waveMotion.data.push( waveMotionData );
				
				waveMotionData = new WaveMotionData( "x", 15, .3 );
				waveMotion.data.push( waveMotionData );
				
				wasp.add( waveMotion ).add( new SpatialAddition());	
				audioGroup.addAudioToEntity( wasp );
				wasp.add( new AudioRange( 600 ));
				audio = wasp.get( Audio );
				audio.playCurrentAction( TRIGGER );
			}
		}
			
		private function flapWing( dactyl:Entity ):void
		{
			var audio:Audio = dactyl.get( Audio );
			audio.playCurrentAction( TRIGGER );
		}
		
		private function repositionDactyl( dactyl:Entity, position:Point ):void
		{
			var spatial:Spatial = dactyl.get( Spatial );
			spatial.x = position.x;
			spatial.y = position.y;
		}
	}
}