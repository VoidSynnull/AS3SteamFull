package game.scenes.shrink.apartmentNormal
{
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.geom.Point;
	
	import ash.core.Entity;
	
	import engine.components.Display;
	import engine.components.Id;
	import engine.components.Interaction;
	import engine.components.Spatial;
	import engine.components.SpatialAddition;
	import engine.components.Tween;
	import engine.creators.InteractionCreator;
	import engine.managers.SoundManager;
	import engine.util.Command;
	
	import game.components.entity.Dialog;
	import game.components.hit.Zone;
	import game.components.motion.Threshold;
	import game.components.motion.WaveMotion;
	import game.components.scene.SceneInteraction;
	import game.components.timeline.Timeline;
	import game.creators.entity.EmitterCreator;
	import game.creators.ui.ToolTipCreator;
	import game.data.TimedEvent;
	import game.data.WaveMotionData;
	import game.data.animation.entity.character.PointPistol;
	import game.data.animation.entity.character.Tremble;
	import game.data.display.BitmapWrapper;
	import game.data.ui.ToolTipType;
	import game.scene.template.PlatformerGameScene;
	import game.scenes.shrink.ShrinkEvents;
	import game.scenes.shrink.bedroomShrunk02.BedroomShrunk02;
	import game.scenes.shrink.mainStreet.StreamerSystem.Streamer;
	import game.scenes.shrink.mainStreet.StreamerSystem.StreamerSystem;
	import game.scenes.shrink.shared.particles.LazerParticle;
	import game.scenes.shrink.shared.popups.MicroscopeMessage;
	import game.systems.SystemPriorities;
	import game.systems.hit.ZoneHitSystem;
	import game.systems.motion.ThresholdSystem;
	import game.systems.motion.WaveMotionSystem;
	import game.util.AudioUtils;
	import game.util.CharUtils;
	import game.util.DisplayUtils;
	import game.util.EntityUtils;
	import game.util.GeomUtils;
	import game.util.SceneUtil;
	import game.util.SkinUtils;
	import game.util.TimelineUtils;
	
	import org.flintparticles.threeD.actions.Move;
	
	public class ApartmentNormal extends PlatformerGameScene
	{
		public function ApartmentNormal()
		{
			super();
		}
		
		// pre load setup
		override public function init(container:DisplayObjectContainer = null):void
		{			
			super.groupPrefix = "scenes/shrink/apartmentNormal/";
			
			super.init(container);
		}
		
		// initiate asset load of scene specific assets.
		override public function load():void
		{
			super.load();
		}
		
		private const CAT_TARGET:Point = new Point( 3320, 520 );
		private const TELESCOPE:Point = new Point( 90, 520 );
		
		private var shrinkRay:ShrinkEvents;
		private var interactions:Array = ["snack", "car", "microscope" ];
		private var microscopeMessage:MicroscopeMessage;
		
		// all assets ready
		override protected function addBaseSystems():void
		{
			addSystem( new ThresholdSystem());
			addSystem( new ZoneHitSystem(), SystemPriorities.checkCollisions);
			addSystem( new StreamerSystem(), SystemPriorities.render);
			
			super.addBaseSystems();
		}
		
		override public function loaded():void
		{
			super.loaded();
			shrinkRay = events as ShrinkEvents;
			
			shellApi.eventTriggered.add(onEventTriggered);
			
			setUpNpcs();
			setUpCatTrigger();
			setUpInteractions();
			setUpBlimp();
		}
		
		private function setUpInteractions():void
		{
			var clip:MovieClip;
			var entity:Entity;
			var name:String;
			var number:int;
			var sceneInteraction:SceneInteraction;
			
			for each( name in interactions )
			{
				clip = _hitContainer[ name ];
				
				entity = EntityUtils.createSpatialEntity( this, clip, _hitContainer );
				entity.add( new Id( name ));
				
				InteractionCreator.addToEntity( entity, [ InteractionCreator.CLICK ]);
				sceneInteraction = new SceneInteraction();
				sceneInteraction.reached.add( clickOnInteraction );
				
				entity.add( sceneInteraction );
				ToolTipCreator.addToEntity( entity );
			}
		}
		
		private function setUpBlimp():void
		{
			var clip:MovieClip = _hitContainer[ "blimp" ];
			var wrapper:BitmapWrapper = DisplayUtils.convertToBitmapSprite( clip, null, 2 );
			var blimp:Entity = EntityUtils.createSpatialEntity( this, wrapper.sprite );
			
			var data:WaveMotionData = new WaveMotionData( "y", 10, .02 );
			var float:WaveMotion = new WaveMotion();
			InteractionCreator.addToEntity( blimp, [ InteractionCreator.CLICK ]);
			var interaction:Interaction = blimp.get( Interaction );
			interaction.click.add( sayBlimp );
			
			ToolTipCreator.addToEntity( blimp );
			
			float.add( data );
			blimp.add(new SpatialAddition( 0, 100 )).add( float );
			addSystem(new WaveMotionSystem());
		}
		
		private function clickOnInteraction( player:Entity, entity:Entity ):void
		{
			var interaction:String = Id( entity.get( Id )).id;
			var clicked:String = "clicked_";
			
			if( shellApi.checkEvent( shrinkRay.CHASED_CAT ) && interaction == "microscope" )
			{
				microscopeMessage = addChildGroup( new MicroscopeMessage( super.overlayContainer )) as MicroscopeMessage;
			}
			else
			{
				Dialog( player.get( Dialog )).sayById( clicked + interaction );
			}
		}
		
		private function sayBlimp( ...args ):void
		{
			Dialog( player.get( Dialog )).sayById( "clicked_blimp" );
		}
		
		private function setUpCatTrigger():void
		{
			if(shellApi.checkEvent(shrinkRay.CAT_IN_BATH) || shellApi.checkEvent(shrinkRay.CHASED_CAT))
				return;
			
			var threshold:Threshold = new Threshold( "x", ">=" );
			threshold.threshold = 2800;
			threshold.entered.addOnce( runToBath );
			player.add( threshold );
		}
		
		private function runToBath( ...args ):void
		{
			var cat:Entity = getEntityById( "cat" );
			SceneUtil.lockInput( this );
			SceneUtil.setCameraTarget( this, cat );
			
			var doorSpatial:Spatial = getEntityById( "doorBathroomNormal" ).get( Spatial );			
			CharUtils.moveToTarget( cat, doorSpatial.x, doorSpatial.y, false, getCat );
		}
		
		private function getCat( cat:Entity ):void
		{
			SceneUtil.setCameraTarget( this, player );
			shellApi.triggerEvent( shrinkRay.GET_CAT );
			shellApi.completeEvent( shrinkRay.CAT_IN_BATH );
			
			removeEntity( cat );
		}
		
		private function setUpNpcs():void
		{
			var cat:Entity = getEntityById( "cat" );
			var villain:Entity = getEntityById( "char1" );
			var dialog:Dialog = player.get( Dialog );
			
			villain.remove( SceneInteraction );
			villain.remove( Interaction );
			ToolTipCreator.removeFromEntity( villain );

			Display( villain.get( Display )).visible = false;
			
			if( !shellApi.checkEvent( shrinkRay.CHASED_CAT ))
			{
				dialog.sayById( "cat_is_inside" );
				if( shellApi.checkEvent( shrinkRay.CAT_IN_BATH ))
				{
					removeEntity(cat);
				}
				else
				{
					SceneUtil.lockInput( this );
					CharUtils.moveToTarget( cat, CAT_TARGET.x, CAT_TARGET.x );
				}
			}
			else
			{
				if( shellApi.checkEvent( shrinkRay.SHRUNK ))
				{
					removeEntity( villain );
				}
				else
				{
					if( !shellApi.checkEvent( shrinkRay.FIND_CJ ))
					{
						SceneUtil.addTimedEvent( this, new TimedEvent( 1, 3, lookAround ));
						dialog.sayById( "cat_is_outside" );
						SceneUtil.lockInput( this );
					}
				}
			}
		}
		
		private function lookAround():void
		{
			Spatial( player.get( Spatial )).scaleX *= -1;
		}
		
		private function onEventTriggered( event:String, makeCurrent:Boolean = true, init:Boolean = false, removeEvent:String = null ):void
		{
			if( event == shrinkRay.GET_CAT || event == shrinkRay.FIND_CJ )
			{
				SceneUtil.lockInput( this, false );
			}
			if( event == shrinkRay.LOOK_AWAY_MICROSCOPE )
			{
				SceneUtil.lockInput( this );
				Dialog( player.get( Dialog )).sayById( "close_microscope" );
			}
			
			if( event == shrinkRay.SNOOPED_TOO_MUCH )
			{
				var villain:Entity = getEntityById( "char1" );
				var gun:Entity = SkinUtils.getSkinPartEntity( villain ,SkinUtils.ITEM );
				var clip:MovieClip = Display( gun.get( Display )).displayObject as MovieClip;
				clip.laser.gotoAndStop( 0 );
				
				var flash:Entity = TimelineUtils.convertClip( clip.flash, this, null, gun );
				flash.add( new Id( "flash" ));
				var timeline:Timeline = flash.get( Timeline );
				timeline.gotoAndStop( 0 );
				
				enterVillain();
			}
			
			if( event == shrinkRay.CHASE_PLAYER )
			{
				giveChase();
			}
		}
		
		private function enterVillain():void
		{
			var villain:Entity = getEntityById( "char1" );
			Display( villain.get( Display )).visible = true;
			
			var playPos:Spatial = player.get( Spatial );
			
			CharUtils.moveToTarget( villain, playPos.x + 200, playPos.y, false, snooping );
			CharUtils.setAnim( player, Tremble );
		}
		
		private function snooping( villain:Entity ):void
		{
			CharUtils.setDirection( player, true );
			Dialog( villain.get( Dialog )).sayById( "snooping" );
		}
		
		private function giveChase():void
		{
			CharUtils.moveToTarget(player, TELESCOPE.x, TELESCOPE.y, true, shakeInFear, new Point( 25, 100 ));
			CharUtils.moveToTarget( getEntityById( "char1" ), TELESCOPE.x + 200, TELESCOPE.y, false, pointLaser );
		}
		
		private function pointLaser( entity:Entity ):void
		{
			CharUtils.setAnim( entity, PointPistol );
			Timeline( entity.get( Timeline )).gotoAndStop( 12 );
			SceneUtil.addTimedEvent( this, new TimedEvent( .5, 1, Command.create( fireLaser, entity )));
			AudioUtils.play( this, SoundManager.EFFECTS_PATH + "shooting_laser_01_loop.mp3", 1, true );
		}
		
		private function fireLaser( entity:Entity ):void
		{
			var spatial:Spatial = player.get( Spatial );
			
			var gun:Entity = SkinUtils.getSkinPartEntity( entity,SkinUtils.ITEM );
			var clip:MovieClip = Display( gun.get( Display )).displayObject as MovieClip;
			
			var laserClip:MovieClip = clip.laser;
			clip = new MovieClip();
			
			var pos:Point = DisplayUtils.localToLocal(laserClip, _hitContainer);
			clip.x = pos.x;
			clip.y = pos.y;
			
			var point:Point =  new Point( spatial.x - 25, TELESCOPE.y - 10 );
			
			var distance:Number = Point.distance( pos, point );
			
			var sections:Number = 8.0;
			
			distance /= sections;
			
			var rotation:Number = GeomUtils.degreesBetween(point.x, point.y , clip.x, clip.y);
			
			var laser:Entity = EntityUtils.createSpatialEntity(this, clip, _hitContainer);
				
			var flash:Entity = getEntityById( "flash" );
			var timeline:Timeline = flash.get( Timeline );
			timeline.play();
			
			Spatial( laser.get( Spatial )).rotation = rotation;
			laser.add( new Streamer( clip, 90, null, true, 2, 2.5, 4, sections, distance, 4, 4, 0x00ff00 )).add( new Tween());
			
			var laserPart:LazerParticle = new LazerParticle();
			laserPart.init();
			EmitterCreator.create( this, _hitContainer, laserPart, 0, 0, laser, "lazerShot", spatial );
			
			SceneUtil.addTimedEvent( this, new TimedEvent( .01, 100, shrinkPlayer ));
			
			AudioUtils.play( this, SoundManager.EFFECTS_PATH + "shrink_01.mp3", 2 );
		}
		
		private function shrinkPlayer():void
		{
			CharUtils.setScale(player, Spatial(player.get(Spatial)).scale - .0025);
			if(Spatial(player.get(Spatial)).scale < .11)
				playerGetsShrunk();
		}
		
		private function playerGetsShrunk():void
		{
			shellApi.removeEvent(shrinkRay.REMOTE_HAS_BATTERY);
			shellApi.completeEvent(shrinkRay.CAR_HAS_BATTERY);
			
			shellApi.setUserField(shrinkRay.CAR_FIELD, "LivingRoomShrunk,2718", shellApi.island, true, enterWonderland );
		}
		
		private function enterWonderland( ...args ):void
		{
			shellApi.completeEvent( shrinkRay.SHRUNK );
			shellApi.loadScene( BedroomShrunk02, 650, 1875, "right" );
		}
		
		private function shakeInFear(entity:Entity):void
		{
			CharUtils.setDirection( player, true );
			CharUtils.setAnim( player, Tremble );
		}
	}
}