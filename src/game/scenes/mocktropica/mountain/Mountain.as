package game.scenes.mocktropica.mountain
{
	import com.greensock.easing.Quad;
	
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	
	import ash.core.Entity;
	
	import engine.components.Audio;
	import engine.components.AudioRange;
	import engine.components.Display;
	import engine.components.Id;
	import engine.components.Motion;
	import engine.components.Spatial;
	import engine.components.Tween;
	import engine.creators.InteractionCreator;
	import engine.managers.SoundManager;
	import engine.util.Command;
	
	import game.components.entity.Dialog;
	import game.components.entity.character.CharacterMotionControl;
	import game.components.hit.Zone;
	import game.components.motion.Edge;
	import game.components.motion.MotionControl;
	import game.components.motion.Threshold;
	import game.components.scene.SceneInteraction;
	import game.components.timeline.Timeline;
	import game.creators.entity.EmitterCreator;
	import game.creators.scene.HitCreator;
	import game.creators.ui.ToolTipCreator;
	import game.data.animation.entity.character.Tossup;
	import game.data.game.GameEvent;
	import game.data.scene.characterDialog.DialogData;
	import game.data.scene.hit.HazardHitData;
	import game.data.sound.SoundModifier;
	import game.particles.emitter.Rain;
	import game.particles.emitter.SwarmingFlies;
	import game.scene.template.AudioGroup;
	import game.scene.template.CollisionGroup;
	import game.scene.template.ItemGroup;
	import game.scenes.mocktropica.MocktropicaEvents;
	import game.scenes.mocktropica.basement.Basement;
	import game.scenes.mocktropica.mountain.components.BoulderComponent;
	import game.scenes.mocktropica.mountain.popups.Mancala;
	import game.scenes.mocktropica.mountain.systems.BoulderSystem;
	import game.scenes.mocktropica.mountain.systems.GustSystem;
	import game.scenes.mocktropica.shared.AchievementGroup;
	import game.scenes.mocktropica.shared.AdvertisementGroup;
	import game.scenes.mocktropica.shared.MocktropicaScene;
	import game.scenes.myth.mountOlympus3.components.Gust;
	import game.systems.SystemPriorities;
	import game.systems.motion.ThresholdSystem;
	import game.ui.showItem.ShowItem;
	import game.util.CharUtils;
	import game.util.DisplayUtils;
	import game.util.EntityUtils;
	import game.util.GeomUtils;
	import game.util.MotionUtils;
	import game.util.SceneUtil;
	import game.util.SkinUtils;
	
	import org.flintparticles.common.counters.Steady;
	import org.flintparticles.twoD.emitters.Emitter2D;
	
	public class Mountain extends MocktropicaScene
	{
		public function Mountain()
		{
			super();
		}
		
		// pre load setup
		override public function init(container:DisplayObjectContainer = null):void
		{			
			super.groupPrefix = "scenes/mocktropica/mountain/";
			
			super.init(container);
		}
		
		// initiate asset load of scene specific assets.
		override public function load():void
		{
			super.load();
		}
		
		// all assets ready
		override public function loaded():void
		{
			super.loaded();
			_events = super.events as MocktropicaEvents;
			
			super.shellApi.eventTriggered.add( eventTriggers );
			var entity:Entity;	
			var display:Display;
			var spatial:Spatial;
			var threshold:Threshold;
			
			if( super.shellApi.checkEvent( _events.MOUNTAIN_UNFINISHED ))
			{
				super.removeEntity( getEntityById( "ungrass" ));
				super.removeEntity( getEntityById( "unrock" ));
				super.removeEntity( getEntityById( "undirt" ));
				super.removeEntity( getEntityById( "tree" ));
			}
			
			if( super.shellApi.checkEvent( _events.SET_RAIN ))
			{ 
				var rain:Rain = new Rain();
				
				rain.init( new Steady( 150 ), new Rectangle( 0, 0, shellApi.viewportWidth, shellApi.viewportHeight ));
				EmitterCreator.create( this, overlayContainer, rain );
				
				entity = EntityUtils.createMovingEntity( this, _hitContainer[ "gust" ]);
				entity.add( new Id( "gust" ));
				
				var rainZone:Entity = super.getEntityById( "rainZone" );
				var zone:Zone = rainZone.get( Zone );
				zone.entered.add( createGust );
				
				super.addSystem( new GustSystem(), SystemPriorities.update );
			}
			else
			{
				super.removeEntity( super.getEntityById( "wallHit" ));
			}
			
			entity = EntityUtils.createSpatialEntity( this, _hitContainer[ "liftShadow" ]);
			entity.add( new Id( "liftShadow" ));
			
			entity = EntityUtils.createSpatialEntity( this, _hitContainer[ "chairLift" ]);
			entity.add( new Id( "chairLift" ));
			
			entity = EntityUtils.createSpatialEntity( this, _hitContainer[ "liftClouds" ]);
			entity.add( new Id( "liftClouds" ));
			
			if( !super.shellApi.checkEvent( _events.REACHED_SUMMIT ))
			{
				threshold = new Threshold( "y", "<" );
				threshold.threshold = 1420;
				threshold.entered.addOnce( discoverChairLift );
				
				super.player.add( threshold );
				super.addSystem( new ThresholdSystem(), SystemPriorities.update );
				
				entity = getEntityById( "liftShadow" );
				display = entity.get( Display );
				display.alpha = 0;
				
				entity = getEntityById( "chairLift" );
				display = entity.get( Display );
				display.alpha = 0;
			}
			else
			{
				entity = super.getEntityById( "random1" );
				EntityUtils.position( entity, 1390, 1170 );
				
				entity = super.getEntityById( "random2" );
				EntityUtils.position( entity, 1440, 1174 );
				
				super.removeEntity( getEntityById( "liftShadow" ));
				super.removeEntity( getEntityById( "liftClouds" ));
			}
			
			entity = EntityUtils.createMovingEntity( this, _hitContainer[ "axe" ]);
			entity.add( new Id( "axe" ));
			spatial = entity.get( Spatial );
			
			if( super.shellApi.checkEvent( _events.DONE_CLIMBING ))
			{
				if( super.shellApi.checkEvent( GameEvent.GOT_ITEM + _events.AXE ))
				{
					super.removeEntity( entity );
				}
				else
				{
					InteractionCreator.addToEntity( entity, [ InteractionCreator.CLICK ]);
					ToolTipCreator.addToEntity( entity );
					
					var sceneInteraction:SceneInteraction = new SceneInteraction();
					sceneInteraction.reached.add( getAxe );
					
					entity.add( sceneInteraction );
					
					spatial.x = 1590;
					spatial.y = 3395;
					spatial.rotation = -150;
				}
				super.removeEntity( getEntityById( "climber" ));
			}
				
			else
			{
				EntityUtils.getDisplay( entity ).visible = false;
			}
			
			_leadDeveloper = super.getEntityById( LEAD_DEVELOPER );
			
			if( super.shellApi.checkEvent( _events.DEVELOPER_RETURNED ))
			{
				super.removeEntity( _leadDeveloper );
			}
			else
			{
				var fliesEmitter:SwarmingFlies = new SwarmingFlies();
				entity = EmitterCreator.create(this, super._hitContainer, fliesEmitter, 0, 0);
				fliesEmitter.init(new Point(950, 550));
				
				//positional flies sound
				entity = new Entity();
				var audio:Audio = new Audio();
				audio.play(SoundManager.EFFECTS_PATH + FLIES, true, [SoundModifier.POSITION, SoundModifier.EFFECTS])
				//entity.add(new Display(super._hitContainer["soundSource"]));
				entity.add(audio);
				entity.add(new Spatial(960, 620));
				entity.add(new AudioRange(500, 0, 0.4, Quad.easeIn));
				entity.add(new Id("soundSource"));
				super.addEntity(entity);
			}
			
			SkinUtils.setRandomSkin( getEntityById( "random1" ));
			SkinUtils.setRandomSkin( getEntityById( "random2" ));
			
			setupBoulders();
			
			var foreground:Entity = getEntityById( "foreground" );
			var chairlift:Entity = getEntityById( "chairlift" );
			
			_adGroup = super.addChildGroup( new AdvertisementGroup( this, _hitContainer )) as AdvertisementGroup;	
		}		
		
		private function setupBoulders():void
		{
			var clip:MovieClip;
			var entity:Entity;	
			var motion:Motion;
			var creator:HitCreator = new HitCreator();
			var hazardHitData:HazardHitData;
			var number:int;
			var boulder:BoulderComponent;
			var audioGroup:AudioGroup = super.getGroupById( "audioGroup" ) as AudioGroup;
			
			boulder = new BoulderComponent();
			clip = _hitContainer[ "boulder"  ];
			DisplayUtils.moveToTop( clip );
			entity = EntityUtils.createMovingEntity( this, clip );
			motion = entity.get( Motion );
			
			motion.maxVelocity = new Point( 800, 1200 );
			motion.velocity = new Point( 45, 350 );
			motion.rotationVelocity = 45;
			motion.acceleration.y = MotionUtils.GRAVITY;
			
			boulder.startY = 1500 - ( 1100 );
			EntityUtils.position( entity, 0, boulder.startY );
			
			var edge:Edge = new Edge( -120, -120, 120, 120 );
			entity.add( new Id( "boulder" ));
			entity.add( edge );
			entity.add( boulder );
			
			var emitter:Emitter2D = new Emitter2D();
			var box:Rectangle = new Rectangle( -100, -100, 100, 100 );
			
			audioGroup.addAudioToEntity( entity );
			entity.add( new AudioRange( 1500, 0, 1 ));
			
			super.addSystem( new ThresholdSystem(), SystemPriorities.update );
			var collisionGroup:CollisionGroup = super.getGroupById( "collisionGroup" ) as CollisionGroup;
			
			super.addSystem( new BoulderSystem( collisionGroup.hitBitmapData, collisionGroup.hitBitmapDataScale, collisionGroup.hitBitmapOffsetX, collisionGroup.hitBitmapOffsetY ), SystemPriorities.checkCollisions );//, bitmapPlatforms ), SystemPriorities.update );
		}
		
		/*******************************
		 * 	       RAIN BARRIER
		 * *****************************/
		private function createGust( zoneId:String, playerId:String ):void
		{
			var entity:Entity = super.getEntityById( "gust" );
			var gust:Gust = entity.get( Gust );
			
			if( gust == null )
			{	
				gust = new Gust();
				entity.add( gust );
			}
			
			var spatial:Spatial = entity.get( Spatial );
			
			var playerSpatial:Spatial = player.get(Spatial);
			EntityUtils.position( entity, playerSpatial.x - 300, playerSpatial.y );
			
			gust.rotation = GeomUtils.degreeToRadian( spatial.rotation = GeomUtils.degreesBetween( playerSpatial.x, playerSpatial.y, playerSpatial.x, playerSpatial.y ));
			gust.t = 40;
			gust.curID = 0;
			gust.vx = 20;
			gust.stx = 0;
			gust.active = true;		
			
			
			var playerMotion:Motion = player.get( Motion );
			playerMotion.velocity = new Point();
			playerMotion.totalVelocity = new Point();
			playerMotion.acceleration = new Point();
		}
		
		/*******************************
		 * 	        CHAIR LIFT
		 * *****************************/
		private function discoverChairLift():void
		{
			SceneUtil.lockInput( this );
			
			var path:Vector.<Point> = new Vector.<Point>;
			MotionUtils.zeroMotion( super.player );
			path.push( new Point( 580, 1420 ), new Point( 658, 1260 ), new Point( 1100, 1170 ));
			
			CharUtils.followPath( super.player, path, spotChairLift, true );
			var characterMotion:CharacterMotionControl = super.player.get( CharacterMotionControl );
			characterMotion.maxVelocityX = 250;
		}
		
		private function spotChairLift( player:Entity ):void
		{
			var entity:Entity;
			var tween:Tween = new Tween();
			var display:Display;
			
			entity = super.getEntityById( "liftShadow" );
			display = entity.get( Display );
			
			tween.to( display, 1.5, { alpha : 1, onComplete : fadeInLift });
			entity.add( tween );
		}
		
		private function fadeInLift():void
		{			
			var entity:Entity;
			var tween:Tween = new Tween();
			var display:Display;
			
			entity = super.getEntityById( "liftShadow" );
			display = entity.get( Display );
			tween = entity.get( Tween );
			
			tween.to( display, 1, { alpha : 0 });
			
			entity = super.getEntityById( "chairLift" );
			display = entity.get( Display );
			
			tween.to( display, 1, { alpha : 1, onComplete : fadeOutClouds });
			entity.add( tween );
		}
		
		private function fadeOutClouds():void
		{
			var entity:Entity = super.getEntityById( "liftClouds" );
			var tween:Tween = new Tween();
			var display:Display = entity.get( Display );
			
			tween.to( display, 1, { alpha : 0, onComplete : disembarkRiders });
			entity.add( tween );
			
			var characterMotion:CharacterMotionControl = super.player.get( CharacterMotionControl );
			characterMotion.maxVelocityX = 1200;
		}
		
		private function disembarkRiders():void
		{
			var entity:Entity = getEntityById( "random1" );
			var path:Vector.<Point> = new Vector.<Point>;
			
			path.push( new Point( 1530, 1110 ), new Point( 1390, 1180 ));
			CharUtils.followPath( entity, path, chirpTheLift );
			
			entity = getEntityById( "random2" );
			path = new Vector.<Point>;
			
			path.push( new Point( 1530, 1110 ), new Point( 1440, 1180 ));
			CharUtils.followPath( entity, path );
		}
		
		private function chirpTheLift( entity:Entity ):void
		{
			var dialog:Dialog = entity.get( Dialog );
			
			dialog.sayById( "easiest_trip" );
		}
		
		/*******************************
		 * 	     EVENT HANDLER
		 * *****************************/
		private function eventTriggers( event:String, save:Boolean = true, init:Boolean = false, removeEvent:String = null ):void
		{
			var entity:Entity;
			var motionControl:MotionControl;
			
			switch( event )
			{
				case _events.DONE_CLIMBING: 
					entity = super.getEntityById( "climber"	);
					if( entity )
					{
						CharUtils.setAnim( entity, Tossup );
						var timeline:Timeline = entity.get( Timeline );
						timeline.labelReached.add( climberHandler );
					}
					break;
				
				case _events.MANCALA_STARTED:
					mancalaPopup();
					break;
				
				case _events.MANCALA_VICTORY:
					giveBadge();
					break;
				
				case _events.CHIRP_CHAIR_LIFT:
					SceneUtil.lockInput( this, false );
					
					motionControl = super.player.get(MotionControl);
					motionControl.lockInput = false;
					super.shellApi.triggerEvent( _events.REACHED_SUMMIT, true );
					break;
			}
		}
		
		/*******************************
		 * 	    PICKAXE / CLIMBER
		 * *****************************/
		private function climberHandler( label:String ):void
		{
			var entity:Entity = super.getEntityById( "climber" );
			
			switch( label )
			{
				case "trigger":
					SkinUtils.setSkinPart( entity, SkinUtils.ITEM, "empty" );
					tossPickaxe();
					break;
				
				case "ending":
					stormOff();
					break;
			}
		}
		
		private function tossPickaxe():void
		{
			var entity:Entity = super.getEntityById( "axe" );
			var spatial:Spatial = entity.get( Spatial );
			var motion:Motion = entity.get( Motion );
			var threshold:Threshold;
			
			EntityUtils.getDisplay( entity ).visible = true;
			
			motion.rotationVelocity = 45;
			motion.velocity.x = 60;
			motion.velocity.y = -.35 * MotionUtils.GRAVITY;
			motion.rotationVelocity = 100;
			motion.acceleration = new Point( 4, MotionUtils.GRAVITY );
			
			threshold = new Threshold( "y", ">" );
			threshold.threshold = 3390;
			threshold.entered.addOnce( Command.create( axeLanded, entity ));
			entity.add( threshold );
		}
		
		private function axeLanded( entity:Entity ):void
		{
			entity.remove( Motion );
			
			InteractionCreator.addToEntity( entity, [ InteractionCreator.CLICK ]);
			ToolTipCreator.addToEntity( entity );
			
			var sceneInteraction:SceneInteraction = new SceneInteraction();
			sceneInteraction.reached.add( getAxe );
			
			entity.add( sceneInteraction );
		}
		
		private function getAxe( char:Entity, axe:Entity ):void
		{
			super.shellApi.getItem( AXE, null, true );
			
			super.removeEntity( axe );
		}
		
		private function stormOff():void
		{
			var entity:Entity = super.getEntityById( "climber" );
			
			CharUtils.moveToTarget( entity, 850, 4350, true, removeClimber );
			var characterMotion:CharacterMotionControl = entity.get( CharacterMotionControl );
			characterMotion.maxVelocityX = 120;
		}
		
		private function removeClimber( entity:Entity ):void
		{	
			super.removeEntity( entity ); 
		}
		
		/*******************************
		 * 	    	MANCALA
		 * *****************************/
		
		private function mancalaPopup():void
		{
			var popup:Mancala = super.addChildGroup( new Mancala( super.overlayContainer )) as Mancala
			popup.id = "mancala";
			
			popup.complete.add( Command.create( completeMancala, popup ));
			popup.fail.add( Command.create( failMancala, popup ));
			popup.closeClicked.add( quitMancala );
		}
		
		private function completeMancala( popup:Mancala ):void
		{
			popup.close();
			//			SceneUtil.lockInput( this, false );
			
			var achievements:AchievementGroup = new AchievementGroup( this ); 
			super.addChildGroup( achievements );
			achievements.completeAchievement( _events.ACHIEVEMENT_MANCALA_MASTER, sillyGame, true );
		}
		
		private function failMancala( popup:Mancala ):void
		{			
			popup.close();	
			var dialog:Dialog = _leadDeveloper.get( Dialog );
			
			dialog.sayById( "try_again" );
			dialog.complete.addOnce( unlock );
		}
		
		private function quitMancala( popup:Mancala ):void
		{
			SceneUtil.lockInput( this );
			var dialog:Dialog = _leadDeveloper.get( Dialog );
			
			dialog.sayById( "try_again" );
			dialog.complete.addOnce( unlock );
		}
		
		/*******************************
		 * 	    	CODER
		 * *****************************/
		
		private function sillyGame():void
		{
			SceneUtil.lockInput( this );
			var dialog:Dialog = _leadDeveloper.get( Dialog );
			dialog.sayById( "silly_game" );
		}
		
		private function giveBadge():void 
		{
			var itemGroup:ItemGroup = super.getGroupById( "itemGroup" ) as ItemGroup;
			itemGroup.takeItem( DEVELOPER_ID, LEAD_DEVELOPER );
			
			shellApi.removeItem( DEVELOPER_ID ); 
			var showItem:ShowItem = super.getGroupById( "showItemGroup" ) as ShowItem;
			showItem.transitionComplete.addOnce( backToHQ );
		}

		private function backToHQ():void
		{
			super.shellApi.completeEvent( _events.DEVELOPER_RETURNED );
			super.shellApi.completeEvent( _events.INVENTORY_FIXED );
			
			shellApi.takePhoto( "12776", loadBasement);
		}

		private function loadBasement():void 
		{
			shellApi.loadScene( Basement, 650, 900, "right" );
		}
		
		private function unlock( dialogData:DialogData ):void
		{
			SceneUtil.lockInput( this, false );
		}
		
		private var _adGroup:AdvertisementGroup;
		
		private const AXE:String =					"axe";
		private const DEVELOPER_ID:String =			"developer_id";
		private const LEAD_DEVELOPER:String =		"leadDeveloper";
		private static const FLIES:String = 		"insect_flies_02_L.mp3";
		private var _leadDeveloper:Entity;
		private var _events:MocktropicaEvents;
	}
}
