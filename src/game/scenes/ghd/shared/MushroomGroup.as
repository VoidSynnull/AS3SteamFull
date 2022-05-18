package game.scenes.ghd.shared
{
	import flash.display.BitmapData;
	import flash.display.DisplayObject;
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.geom.Point;
	
	import ash.core.Entity;
	
	import engine.components.Audio;
	import engine.components.Display;
	import engine.components.Id;
	import engine.components.Interaction;
	import engine.components.Motion;
	import engine.components.Spatial;
	import engine.creators.InteractionCreator;
	import engine.group.Group;
	import engine.util.Command;
	
	import game.components.Emitter;
	import game.components.entity.Dialog;
	import game.components.entity.Sleep;
	import game.components.entity.character.part.SkinPart;
	import game.components.hit.Bounce;
	import game.components.hit.EntityIdList;
	import game.components.hit.Wall;
	import game.components.scene.SceneInteraction;
	import game.components.timeline.BitmapSequence;
	import game.components.timeline.Timeline;
	import game.creators.entity.BitmapTimelineCreator;
	import game.creators.entity.EmitterCreator;
	import game.creators.ui.ToolTipCreator;
	import game.data.TimedEvent;
	import game.scene.template.AudioGroup;
	import game.scenes.ghd.shared.mushroom.Mushroom;
	import game.scenes.ghd.shared.mushroom.MushroomSystem;
	import game.scenes.ghd.shared.mushroomBouncer.MushroomBouncerSystem;
	import game.scenes.survival1.shared.components.TriggerHit;
	import game.scenes.survival1.shared.systems.TriggerHitSystem;
	import game.util.BitmapUtils;
	import game.util.CharUtils;
	import game.util.DisplayUtils;
	import game.util.EntityUtils;
	import game.util.PerformanceUtils;
	import game.util.SceneUtil;
	import game.util.SkinUtils;
	import game.util.TimelineUtils;
	
	import org.flintparticles.common.actions.Age;
	import org.flintparticles.common.actions.Fade;
	import org.flintparticles.common.actions.ScaleImage;
	import org.flintparticles.common.counters.Blast;
	import org.flintparticles.common.counters.ZeroCounter;
	import org.flintparticles.common.displayObjects.Blob;
	import org.flintparticles.common.initializers.BitmapImage;
	import org.flintparticles.common.initializers.ColorInit;
	import org.flintparticles.common.initializers.Lifetime;
	import org.flintparticles.twoD.actions.Accelerate;
	import org.flintparticles.twoD.actions.Move;
	import org.flintparticles.twoD.actions.MutualGravity;
	import org.flintparticles.twoD.actions.RandomDrift;
	import org.flintparticles.twoD.emitters.Emitter2D;
	import org.flintparticles.twoD.initializers.Position;
	import org.flintparticles.twoD.initializers.Velocity;
	import org.flintparticles.twoD.zones.DiscZone;
	import org.flintparticles.twoD.zones.PointZone;
	import org.osflash.signals.Signal;
	
	public class MushroomGroup extends Group
	{		
		private var _emitterEntity:Entity;
		private const EYES:String 		= 	"eyes";
		private const MUSHROOM:String	=	"mushroom";
		private const BOUNCE:String		=	"Bounce";
		private const LEFT:String		=	"Left";
		private const RIGHT:String		=	"Right";
		private const STEM:String		=	"Stem";
		private const HEAD:String		=	"Head";
		private const ROOTS:String		=	"roots";
		private const TRIGGER:String 	=	"trigger";
		
		public function MushroomGroup()
		{
			super();
		}
		
		private var player:Entity;
		
		/**
		 * 
		 */
		public function createMushrooms( group:Group, container:DisplayObjectContainer, oneSided:Array, facingLeft:Array ):void
		{			
			group.addSystem(new TriggerHitSystem());
			group.addSystem(new MushroomSystem());
			group.addSystem(new MushroomBouncerSystem());
			
			player = group.shellApi.player;
			var isOneSided:Boolean;
			var isFacingLeft:Boolean;
			var display:Display;
			var mushroomEntity:Entity;
			var mushroomHead:Entity;
			var mushroomStem:Entity;
			var stemTimeline:Timeline;
			var clip:MovieClip;
			var headTimeline:Timeline;
			var interaction:Interaction;
			var mushroom:Mushroom;
			var rollover:Entity;
			var sceneInteraction:SceneInteraction;
			var sleep:Sleep;
			var spatial:Spatial;
			var triggerHit:TriggerHit;
			
			var defaultClip:MovieClip = container[ MUSHROOM + HEAD ];
			defaultClip.gotoAndStop( 1 );
			var headSequence:BitmapSequence = BitmapTimelineCreator.createSequence( defaultClip, true, PerformanceUtils.defaultBitmapQuality );
			
			defaultClip = container[ MUSHROOM + STEM ];
			defaultClip.gotoAndStop( 1 );
			var stemSequence:BitmapSequence = BitmapTimelineCreator.createSequence( defaultClip, true, PerformanceUtils.defaultBitmapQuality );
			
			var audioGroup:AudioGroup = group.getGroupById(AudioGroup.GROUP_ID) as AudioGroup;
			for( var index:int = 1; container[ MUSHROOM + index ]; ++index )
			{
				isOneSided = false;
				isFacingLeft = false;
				
				for( var number:int = 0; number < oneSided.length; number ++ )
				{
					if( oneSided[ number ] == index )
					{
						isOneSided = true;
					}
				}
				
				for( number = 0; number < facingLeft.length; number ++ )
				{
					if( facingLeft[ number ] == index )
					{
						isFacingLeft = true;
					}
				}
				
				clip = container[ MUSHROOM + index ];
				clip.gotoAndStop( 1 );
				
				// HEAD
				mushroomHead = BitmapTimelineCreator.createBitmapTimeline( clip.head, true, false, headSequence, PerformanceUtils.defaultBitmapQuality );
				headTimeline = mushroomHead.get( Timeline );
				group.addEntity( mushroomHead );
				
				mushroom			 		= new Mushroom();
				mushroom.bounceLeft 		= group.getEntityById( MUSHROOM + BOUNCE + index + LEFT );
				mushroom.bounceRight 		= group.getEntityById( MUSHROOM + BOUNCE + index + RIGHT );
				
				if( !isOneSided )
				{
					// STEM
					mushroomStem = BitmapTimelineCreator.createBitmapTimeline( clip.stem, true, false, stemSequence, PerformanceUtils.defaultBitmapQuality );
					group.addEntity( mushroomStem );
					
					stemTimeline = mushroomStem.get( Timeline );
					// REMOVE THEM FROM PARENT CLIP
					clip.stem.visible = false;
					mushroom.stemTimeline = stemTimeline;
				}
				clip.head.visible = false;
				
				// MAKE PARENT ENTITY
				mushroomEntity = EntityUtils.createSpatialEntity( group, clip );
				mushroomEntity.add( new Id( clip.name ));
				TimelineUtils.convertClip( clip, group, mushroomEntity, null, false );
				Timeline( mushroomEntity.get( Timeline )).playing = false;
				sleep = mushroomEntity.get( Sleep );
				sleep.sleeping = false;
				sleep.ignoreOffscreenSleep = true;
				
				if( !isOneSided )
				{
					rollover = EntityUtils.createSpatialEntity( group, container[ clip.name + "Rollover" ]);
					rollover.add( new Id( "rollover" + index ));
					ToolTipCreator.addToEntity( rollover );
					InteractionCreator.addToEntity( rollover, [ InteractionCreator.CLICK ]);
					
					sceneInteraction = new SceneInteraction();
					sceneInteraction.reached.add( inspectMushroom );
					rollover.add( sceneInteraction );
					
					// SETUP THE STEM MOVEMENT TIMELINES
					stemTimeline.handleLabel( RIGHT.toLowerCase(), Command.create( stopTimeline, mushroomEntity ), false );
					stemTimeline.handleLabel( LEFT.toLowerCase(), Command.create( stopTimeline, mushroomEntity ), false );
					stemTimeline.stop();
					
					display = mushroomStem.get( Display );
					display.setContainer( Display( mushroomEntity.get( Display )).displayObject.getChildByName( "stemContainer" ));
				}
				
				// REPOSITION THE MUSHROOM PIECES
				spatial = mushroomHead.get( Spatial );
				spatial.x = spatial.y = 0;
				display = mushroomHead.get( Display );
				display.setContainer( Display( mushroomEntity.get( Display )).displayObject.getChildByName( "headContainer" ));
				
				// SETUP LEFT/RIGHT
				if( mushroom.bounceLeft )
				{
					if( mushroom.bounceLeft.get( Bounce ))
					{
						triggerHit = new TriggerHit( headTimeline );
						triggerHit.triggered = new Signal();
						triggerHit.triggered.add( Command.create( setDefaultVelocity, mushroom.bounceLeft ));
						
						mushroom.bounceLeft.add(new EntityIdList());
						mushroom.bounceLeft.add( triggerHit );
						
						mushroom.bounceLeftDelta = mushroom.bounceLeft.get( Bounce );
					}
					else if( mushroom.bounceLeft.get( Wall ))
					{
						mushroom.wallLeftDelta = mushroom.bounceLeft.get( Wall );
					}
				}
				if( mushroom.bounceRight )
				{
					if( mushroom.bounceRight.get( Bounce ))
					{ 
						triggerHit = new TriggerHit( headTimeline );
						triggerHit.triggered = new Signal();
						triggerHit.triggered.add( Command.create( setDefaultVelocity, mushroom.bounceRight ));
						
						mushroom.bounceRight.add(new EntityIdList());
						mushroom.bounceRight.add( triggerHit );
						
						mushroom.bounceRightDelta = mushroom.bounceRight.get( Bounce );
					}
					else if( mushroom.bounceRight.get( Wall ))
					{
						mushroom.wallRightDelta = mushroom.bounceRight.get( Wall );
					}
				}
				
				mushroom.isFacingLeft = isFacingLeft;
				audioGroup.addAudioToEntity( mushroomEntity );
				mushroomEntity.add( mushroom );
			}
			
			var child:DisplayObject;
			
			for each ( child in container )
			{
				if( child.name.toLowerCase().indexOf( ROOTS ) == 0 )
				{
					DisplayUtils.convertToBitmapSprite( clip, null, PerformanceUtils.defaultBitmapQuality );
				}
			}
			
			var emitter2D:Emitter2D;			
			var bitmapData:BitmapData = BitmapUtils.createBitmapData( new Blob( 12 ));
			
			// DASH LINES PULLING IN	
			emitter2D = new Emitter2D();
			emitter2D.counter = new ZeroCounter();
			emitter2D.addInitializer( new BitmapImage( bitmapData, true, 30 * PerformanceUtils.defaultBitmapQuality ));
			emitter2D.addInitializer( new ColorInit( 0xFCFF36, 0xD6D92E ));
			emitter2D.addInitializer( new Position( new DiscZone( new Point( 10, 10 ), 20, 0 )));
			emitter2D.addInitializer( new Lifetime( 1 ));
			
			var pt:Point = new Point();
			var angle:Number = - .5 * Math.PI;
			pt.x = 150 * Math.cos( angle );
			pt.y = 150 * Math.sin( angle );
			
			emitter2D.addInitializer( new Velocity( new PointZone( pt )));
			
			emitter2D.addAction( new MutualGravity( 1, 10, 1 ));
			emitter2D.addAction( new RandomDrift( 1000, 1500 ));
			emitter2D.addAction( new Fade( .75, 1 ));			
			emitter2D.addAction( new ScaleImage( 1, .5 ));	
			emitter2D.addAction( new Accelerate( 0, 600 ));					
			emitter2D.addAction( new Age());
			emitter2D.addAction( new Move());
			_emitterEntity = EmitterCreator.create( this, container, emitter2D, 0, 0, null, "dustEmitter" );
			
		}
		
		private function inspectMushroom( player:Entity, rollover:Entity ):void
		{
			var itemPart:SkinPart = SkinUtils.getSkinPart( player, SkinUtils.ITEM );
			if( itemPart.value == "ghd_guano" )
			{
				CharUtils.triggerSpecialAbility( player );
			}
			else
			{
				var dialog:Dialog = player.get( Dialog );
				dialog.sayById( "mushy" );
			}
		}
		
		private function stopTimeline( mushroomEntity:Entity ):void
		{
			var mushroom:Mushroom = mushroomEntity.get( Mushroom );
			mushroom.isMoving = false;
			
			var audio:Audio = mushroomEntity.get( Audio );
			audio.stopAll();
		}
		
		private function setDefaultVelocity( mushroom:Entity ):void
		{
			var motion:Motion = player.get( Motion );
			var bounce:Bounce = mushroom.get( Bounce );
			motion.velocity.x = bounce.velocity.x;
			motion.velocity.y = bounce.velocity.y;
			
			var spatial:Spatial = player.get( Spatial );			
			var emitter2D:Emitter2D = _emitterEntity.get( Emitter ).emitter;
			emitter2D.x = spatial.x;
			emitter2D.y = spatial.y - 10;
			emitter2D.counter = new Blast( 25 );
			emitter2D.start();
		}
		
		public function setupEyes( group:Group, container:DisplayObjectContainer ):void
		{
			var child:DisplayObject;
			var clip:MovieClip;
			var entity:Entity;
			var sequence:BitmapSequence;
			var timeline:Timeline;
			
			for each ( child in container )
			{
				if( child.name.indexOf( EYES ) == 0 )
				{
					clip = child as MovieClip;
					clip.gotoAndStop(1);
					entity = EntityUtils.createSpatialEntity( group, clip, container );
					sequence = BitmapTimelineCreator.createSequence( clip, true, 2 );
					
					BitmapTimelineCreator.convertToBitmapTimeline( entity, clip, true, sequence, 2 );
					entity.add( new Id( child.name ));
					timeline = entity.get( Timeline );
					timeline.playing = true;		
					timeline.handleLabel( "pause", Command.create( setWait, timeline ), false );
				}
			}
		}
		
		private function setWait( timeline:Timeline ):void
		{
			timeline.stop();
			SceneUtil.addTimedEvent( this, new TimedEvent( Math.random() * 4, 1, Command.create( replayEyes, timeline )));
		}
		
		private function replayEyes( timeline:Timeline ):void
		{
			timeline.play();
		}
		
	}
}