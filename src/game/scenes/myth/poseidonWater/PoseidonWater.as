package game.scenes.myth.poseidonWater{
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.geom.Point;
	
	import ash.core.Entity;
	
	import engine.components.Audio;
	import engine.components.AudioRange;
	import engine.components.Display;
	import engine.components.Id;
	import engine.components.Spatial;
	import engine.components.Tween;
	import engine.creators.InteractionCreator;
	import engine.group.TransportGroup;
	
	import game.components.entity.Dialog;
	import game.components.entity.Sleep;
	import game.components.entity.character.CharacterMotionControl;
	import game.components.entity.collider.RadialCollider;
	import game.components.hit.Hazard;
	import game.components.hit.MovieClipHit;
	import game.components.hit.Zone;
	import game.components.motion.FollowTarget;
	import game.components.scene.SceneInteraction;
	import game.components.timeline.Timeline;
	import game.creators.entity.EmitterCreator;
	import game.creators.scene.HitCreator;
	import game.creators.ui.ToolTipCreator;
	import game.data.TimedEvent;
	import game.data.WaveMotionData;
	import game.data.animation.entity.character.Stomp;
	import game.data.game.GameEvent;
	import game.data.scene.characterDialog.DialogData;
	import game.data.scene.hit.HazardHitData;
	import game.data.scene.hit.HitType;
	import game.scenes.myth.poseidonWater.components.AirBubble;
	import game.scenes.myth.poseidonWater.components.Barnicle;
	import game.scenes.myth.poseidonWater.systems.AirBubbleSystem;
	import game.scenes.myth.poseidonWater.systems.BarnicleSystem;
	import game.scenes.myth.shared.Mirror;
	import game.scenes.myth.shared.MythScene;
	import game.scenes.poptropolis.promoDive.particles.BubbleStream;
	import game.systems.SystemPriorities;
	import game.systems.hit.MovieClipHitSystem;
	import game.util.CharUtils;
	import game.util.EntityUtils;
	import game.util.MotionUtils;
	import game.util.PerformanceUtils;
	import game.util.SceneUtil;
	import game.util.TimelineUtils;
	
	import org.flintparticles.twoD.initializers.Velocity;
	import org.flintparticles.twoD.zones.PointZone;
	
	public class PoseidonWater extends MythScene
	{
		public function PoseidonWater()
		{
			super();
		}
		
		// pre load setup
		override public function init(container:DisplayObjectContainer = null):void
		{			
			super.groupPrefix = "scenes/myth/poseidonWater/";
		//	showHits = true;
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

			this.addSystem(new MovieClipHitSystem());
			
			setupAirBubbles();
			setupClamShell();
			setupBarnicles();
			setupWaterMist();
			
			player.add(new RadialCollider());
			
			var characterMotion:CharacterMotionControl = super.player.get( CharacterMotionControl );
			characterMotion.maxVelocityX = 300;
			
			var entity:Entity = EntityUtils.createSpatialEntity( this, super._hitContainer[ "block" ]);
			entity.add( new Id( "block" ));
			
			ToolTipCreator.addToEntity( entity );
			
			InteractionCreator.addToEntity( entity, [ InteractionCreator.CLICK ]);
			var sceneInteraction:SceneInteraction = new SceneInteraction();
			
			sceneInteraction.reached.removeAll();
			sceneInteraction.reached.add( digThatBoulder );
			
			entity.add( sceneInteraction );
			
			super.shellApi.eventTriggered.add(eventTriggers);
			super.showHits = true;
			
			if( super.shellApi.checkEvent( _events.HERCULES_UNDERWATER ))
			{
				if( super.shellApi.checkEvent( _events.POSEIDON_THRONE_OPEN ))
				{
					super.removeEntity( entity );
					super.removeEntity( super.getEntityById( "rockBarrier" ));
				}
			}
			
			if( super.shellApi.checkEvent( _events.TELEPORT ))
			{
				if(PerformanceUtils.qualityLevel >= PerformanceUtils.QUALITY_MEDIUM)
				{
					var transportGroup:TransportGroup = super.addChildGroup( new TransportGroup()) as TransportGroup;
				}
				if(transportGroup)
				{
					transportGroup.transportIn( player );
				}
				else
				{
					this.shellApi.removeEvent(_events.TELEPORT);
					this.shellApi.triggerEvent(_events.TELEPORT_FINISHED);
				}
				if( super.shellApi.checkEvent( _events.TELEPORT_HERC ))
				{
					if(transportGroup) transportGroup.transportIn( super.getEntityById( "herc" ), false);
					super.shellApi.removeEvent( _events.TELEPORT_HERC );
				}
			}
		}
		
		private function digThatBoulder( char:Entity, boulder:Entity ):void
		{
			// lock controls
			SceneUtil.lockInput( this );
			
			if( !shellApi.checkEvent( _events.POSEIDON_THRONE_OPEN ))
			{
				// not open
				Dialog( char.get( Dialog )).sayById( "rocks_blocking" );
				Dialog( char.get( Dialog )).complete.add( unlockInput );
			}
		}
		
		private function unlockInput( dialogData:DialogData = null ):void
		{
			SceneUtil.lockInput( this, false, false );
		}
		
		private function hercMovesBoulder():void
		{
			// TODO: animation 
			SceneUtil.lockInput( this );
			
			var entity:Entity;
			
			entity = super.getEntityById( "herc" );
			var dialog:Dialog = entity.get( Dialog );
			
			dialog.sayById( "open_path" );
			dialog.complete.addOnce( doStomp );
		}
		
		private function doStomp( dialogData:DialogData ):void
		{
			var entity:Entity = super.getEntityById( "herc" );
			CharUtils.setAnim( entity, Stomp );
			
			var timeline:Timeline = CharUtils.getTimeline( entity );
			timeline.labelReached.add( hercLabelHandler );
		}
		
		public function hercLabelHandler( label:String ):void
		{
			if( label == "ending" )
			{
				smashRocks();
				
				var entity:Entity = super.getEntityById( "herc" );
				var timeline:Timeline = CharUtils.getTimeline( entity );
				timeline.labelReached.remove( hercLabelHandler );
			}
		}
		
		private function smashRocks():void
		{
			var entity:Entity = super.getEntityById( "block" );
			var spatial:Spatial = entity.get( Spatial );
			
			var tween:Tween = new Tween();
			tween.to( spatial, 2, { y : spatial.y + 400, onComplete : sayThanks });
			super.shellApi.triggerEvent( "break_rock" );
			entity.add( tween );
		}
		
		private function sayThanks():void
		{
			super.removeEntity( super.getEntityById( "block" ));
			
			var dialog:Dialog = player.get( Dialog );
			dialog.sayById( "thanks" );
			dialog.complete.addOnce( waitHere );
		}
		
		private function waitHere( dialogData:DialogData ):void
		{
			var entity:Entity = super.getEntityById( "herc" );
			var dialog:Dialog = entity.get( Dialog );
			
			dialog.say( "no_problem" );
			dialog.complete.addOnce( openThrone );
		}
		
		private function openThrone( dialogData:DialogData ):void
		{
			SceneUtil.lockInput( this, false );
			airSys.draining = true;
			super.removeEntity( super.getEntityById( "rockBarrier" ));
			super.shellApi.triggerEvent( _events.POSEIDON_THRONE_OPEN, true );
		}	


		// process incoming events
		private function eventTriggers(event:String, save:Boolean = true, init:Boolean = false, removeEvent:String = null):void
		{
			if( event == GameEvent.GOT_ITEM + _events.GIANT_PEARL )
			{
				Timeline(getEntityById("clamPearl").get(Timeline)).gotoAndStop("hide");
			}
			
			if( event == _events.USE_MIRROR )
			{
				showPopup(); 
			}
			
			if( event == _events.NOT_APHRODITE || event == _events.NOT_HADES || event == _events.NOT_POSEIDON || event == _events.NOT_ZEUS )
			{
				var entity:Entity = super.getEntityById( "herc" );
				var dialog:Dialog = entity.get( Dialog );
				
				dialog.sayById( event + "_text" )
			}
			
			if( event == _events.TELEPORT_FINISHED )
			{
				if( super.shellApi.checkEvent( _events.HERCULES_UNDERWATER ))
				{
					if( !super.shellApi.checkEvent( _events.POSEIDON_THRONE_OPEN ))
					{
						airSys.draining = false;
						hercMovesBoulder();
					}
				}
				super.shellApi.removeEvent( _events.TELEPORT_FINISHED );
			}
		}
		
		private function showPopup():void
		{
			var popup:Mirror = super.addChildGroup( new Mirror( super.overlayContainer, true )) as Mirror;
			popup.id = "mirror";
		}
		
		// add bubble system and configure bubble entities
		private function setupAirBubbles():void
		{
			//bubble particles
			var bubbles:BubbleStream = new BubbleStream(); 
			bubbles.init();
			bubbles.addInitializer( new Velocity( new PointZone( new Point( 0, -50 ) ) ) );
			EmitterCreator.create(this, super._hitContainer,bubbles, 0, -30, player, "bubbleEntity", player.get(Spatial));

			airSys = AirBubbleSystem(addSystem(new AirBubbleSystem(), SystemPriorities.lowest));
			var num:uint = 10;			
			for(var i:int = 1; i <= num; i++)
			{
				var airBubble:AirBubble = new AirBubble();
	
				var bubbleEnt:Entity = EntityUtils.createSpatialEntity(this, this._hitContainer["bubble"+i]);
				bubbleEnt.add(new Sleep());				
				// config zone
				var bubbleHit:Entity = getEntityById( "bubbleZone"+i );
				var zone:Zone = bubbleHit.get( Zone );
				var sleep:Sleep = new Sleep();
				bubbleHit.add( sleep );
				zone.pointHit = true;			
				airBubble.hitZone = zone;
				airBubble.hitSleep = sleep;
				
				this._hitContainer.setChildIndex(_hitContainer["bubble"+i], _hitContainer.numChildren-1);
				// bubble bobbing
				MotionUtils.addWaveMotion(bubbleEnt,new WaveMotionData( "y", 15, .03 ),this);										
				airBubble.hit = bubbleHit;
				bubbleEnt.add(airBubble);
			}
		}
		
		private function setupClamShell():void
		{
//			var audioGroup:AudioGroup = super.getGroupById( "audioGroup" ) as AudioGroup;
			// make timelines
			var clamBody:Entity = EntityUtils.createSpatialEntity( this, _hitContainer["clam"] );
			TimelineUtils.convertClip( MovieClip( EntityUtils.getDisplayObject( clamBody )), this, clamBody );
			clamBody.add( new Id( "clamBody" )).add( new AudioRange( 500, 0.01, 1 ));
			Sleep( clamBody.get( Sleep )).ignoreOffscreenSleep = true;
			_audioGroup.addAudioToEntity( clamBody, "clamHit" );
			var clamPearl:Entity = TimelineUtils.convertClip(_hitContainer["clam"].getChildByName("pearl"),this);
			var pearlHit:Entity = getEntityById("pearlZone0");
			//rename
			clamPearl.add(new Id("clamPearl"));			
			//init animations
			Timeline(clamPearl.get(Timeline)).gotoAndStop("show");
			
			if(shellApi.checkItemEvent("giantPearl"))
			{
				Timeline(clamPearl.get(Timeline)).gotoAndStop("hide");
			}
			
			//add triggered funcs
			Timeline(clamBody.get(Timeline)).labelReached.add(clamHitToggle);
			Zone(pearlHit.get(Zone)).entered.add(handleHitPearl);
			
			this.player.add(new MovieClipHit("player","clam"));
			var hit:Entity = getEntityById("clamHit");
			hit.add(new MovieClipHit("clam", "player"));
			hit.remove(Hazard);
			hit.remove(HazardHitData);
			addHit(hit,.75,.75,1000);
		}
		
		private function addHit( entity:Entity, coolDown:Number = .75, interval:Number = .75, velocity:Number = 300 ):void
		{
			var hitCreator:HitCreator = new HitCreator();
			var hazardHitData:HazardHitData = new HazardHitData();
			hazardHitData.knockBackCoolDown = coolDown;
			hazardHitData.knockBackInterval = interval;
			hazardHitData.velocityByHitAngle = true;
			hazardHitData.knockBackVelocity = new Point(velocity, 0);	// when velocityByHitAngle = true knockBackVelocity's length is used to create applied velocity
			hitCreator.makeHit(entity, HitType.HAZARD, hazardHitData, this);
		}
		
		// activates/deactivates the hazard hit and item for clam
		private function clamHitToggle(label:String):void
		{
			var hit:Entity = getEntityById("clamHit");
			var clam:Entity = super.getEntityById( "clamBody" );
			var audio:Audio = clam.get( Audio );
			var timeline:Timeline = clam.get( Timeline );
			switch(label){
				case "hitOn1":
					setSleep(hit,false);
					pearlActive = false;
					audio.playCurrentAction( OPEN );
//					audio.play( SoundManager.EFFECTS_PATH + OYSTER_OPEN, false, SoundModifier.POSITION );
					//shellApi.triggerEvent("oysterOpen");
					break;
				case "hitOn2":
					setSleep(hit,false);
					pearlActive = false;
					audio.playCurrentAction( CLOSE );
//					audio.play( SoundManager.EFFECTS_PATH + OYSTER_CLOSE, false, SoundModifier.POSITION );
					break;
				case "hitOff1":
					setSleep(hit,true);
					pearlActive = true;
					timeline.stop();
					SceneUtil.addTimedEvent(this, new TimedEvent(0.8,1,timeline.play));
					break;
				case "hitOff2":
					setSleep(hit,true);
					pearlActive = false;
					timeline.stop();
					SceneUtil.addTimedEvent(this, new TimedEvent(0.8,1,timeline.play));
					break;
			}
		}
		
		private function handleHitPearl(arg:*,arg2:*):void{
			if(pearlActive && !shellApi.checkItemEvent("giantPearl")){
				shellApi.getItem("giantPearl","myth",true);
				Timeline(getEntityById("clamPearl").get(Timeline)).gotoAndStop("hide");
				setSleep(getEntityById("clamHit"),true);
				Timeline(getEntityById( "clamBody" ).get(Timeline)).gotoAndPlay("close");
			}
		}

		private function setupBarnicles():void
		{	
			var barnicleClip:MovieClip;
			var barnicleEnt:Entity;
			var num:uint = 43;			
			for(var i:int = 1; i <= num; i++)
			{
				barnicleClip = this._hitContainer["b"+i];
				barnicleEnt = EntityUtils.createSpatialEntity(this, barnicleClip);				
				var tween:Tween = new Tween();
				barnicleEnt.add(tween);
				var barnicle:Barnicle = new Barnicle();
				barnicle.startScaleX = Spatial(barnicleEnt.get(Spatial)).scaleX;
				barnicle.startScaleY = Spatial(barnicleEnt.get(Spatial)).scaleY;
				barnicle.triggerRadius = 200;
				barnicleEnt.add(barnicle);
			}
			super.addSystem(new BarnicleSystem(), SystemPriorities.update);		
		}
		
		private function setupWaterMist():void
		{
			// blue shadow that follows player
			_waterMist = EntityUtils.createSpatialEntity(this,_hitContainer["overlay"]);
			addPlayerFollow(_waterMist);
			// bring to front
			_hitContainer.setChildIndex(Display(_waterMist.get(Display)).displayObject, _hitContainer.numChildren-1);
		}

		private function addPlayerFollow(entity:Entity):void
		{
			var follow:FollowTarget = new FollowTarget(shellApi.player.get(Spatial), 1);
			follow.properties = new <String>["x","y"];
			follow.offset = new Point(0, 0);			
			entity.add(follow);
		}
		
		private function setSleep( entity:Entity, sleeping:Boolean):void
		{
			var sleep:Sleep = entity.get(Sleep);
			if(sleep==null){
				sleep = new Sleep();
				entity.add(sleep);
			}
			sleep.sleeping = sleeping;
			sleep.ignoreOffscreenSleep = sleeping;
			entity.ignoreGroupPause = sleeping;
		}
		
		private var _waterMist:Entity;
		private var pearlActive:Boolean = false;
		
		private static const OPEN:String	=			"open";
		private static const CLOSE:String	=			"close";
//		private static const OYSTER_OPEN:String = 		 "myth_oyster_open_01.mp3";
//		private static const OYSTER_CLOSE:String =		 "myth_oyster_shut_01.mp3";
		private var airSys:AirBubbleSystem;
	}
}