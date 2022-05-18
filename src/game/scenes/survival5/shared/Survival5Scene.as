package game.scenes.survival5.shared
{
	import com.greensock.easing.Sine;
	
	import flash.display.DisplayObject;
	import flash.display.MovieClip;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	
	import ash.core.Entity;
	import ash.core.NodeList;
	
	import engine.components.Audio;
	import engine.components.AudioRange;
	import engine.components.Display;
	import engine.components.Id;
	import engine.components.Interaction;
	import engine.components.Spatial;
	import engine.creators.InteractionCreator;
	import engine.managers.SoundManager;
	import engine.util.Command;
	
	import game.components.animation.FSMControl;
	import game.components.entity.Dialog;
	import game.components.entity.Hide;
	import game.components.entity.NPCDetector;
	import game.components.entity.Sleep;
	import game.components.entity.character.CharacterMotionControl;
	import game.components.hit.EntityIdList;
	import game.components.input.Input;
	import game.components.motion.Proximity;
	import game.components.scene.SceneInteraction;
	import game.components.timeline.Timeline;
	import game.creators.entity.BitmapTimelineCreator;
	import game.creators.ui.ToolTipCreator;
	import game.data.TimedEvent;
	import game.data.animation.AnimationLibrary;
	import game.data.animation.FrameData;
	import game.data.animation.FrameEvent;
	import game.data.animation.entity.PartAnimationData;
	import game.data.animation.entity.character.Alerted;
	import game.data.animation.entity.character.DuckDown;
	import game.data.animation.entity.character.DuckNinja;
	import game.data.animation.entity.character.FightStance;
	import game.data.animation.entity.character.Ride;
	import game.data.animation.entity.character.Sneeze;
	import game.data.animation.entity.character.Stand;
	import game.data.animation.entity.character.ThrowReady;
	import game.data.animation.entity.character.Tremble;
	import game.data.animation.entity.character.Walk;
	import game.data.animation.entity.character.WalkNinja;
	import game.nodes.hit.BitmapHitNode;
	import game.particles.FlameCreator;
	import game.scene.template.AudioGroup;
	import game.scene.template.CharacterGroup;
	import game.scene.template.PlatformerGameScene;
	import game.scenes.survival1.shared.components.TriggerHit;
	import game.scenes.survival1.shared.systems.TimedEntitySystem;
	import game.scenes.survival1.shared.systems.TriggerHitSystem;
	import game.scenes.survival2.shared.systems.HookSystem;
	import game.scenes.survival5.Survival5Events;
	import game.scenes.survival5.baseCamp.BaseCamp;
	import game.scenes.survival5.chase.Chase;
	import game.scenes.survival5.sawmill.Sawmill;
	import game.scenes.survival5.shared.whistle.ListenerData;
	import game.scenes.survival5.shared.whistle.WhistleListener;
	import game.scenes.survival5.shared.whistle.WhistleNode;
	import game.scenes.survival5.traps.Traps;
	import game.scenes.survival5.underground.Underground;
	import game.scenes.survival5.waterEdge.WaterEdge;
	import game.systems.SystemPriorities;
	import game.systems.entity.AnimationLoaderSystem;
	import game.systems.entity.NPCDetectionSystem;
	import game.systems.entity.character.states.CharacterState;
	import game.systems.entity.character.states.StandState;
	import game.systems.entity.character.states.WalkState;
	import game.systems.motion.ThresholdSystem;
	import game.systems.timeline.BitmapSequenceSystem;
	import game.ui.elements.DialogPicturePopup;
	import game.util.AudioUtils;
	import game.util.CharUtils;
	import game.util.DisplayUtils;
	import game.util.EntityUtils;
	import game.util.MotionUtils;
	import game.util.SceneUtil;
	import game.util.SkinUtils;
	import game.util.TimelineUtils;
	
	import org.osflash.signals.Signal;
	
	public class Survival5Scene extends PlatformerGameScene
	{
		public static const PATROL_SPEED:Number = 200;
		public static const INVESTIGATE_SPEED:Number = 400;
		public static const SNEAK_SPEED:Number = 120;
		public static const MAX_SPEED:Number  = 800;
		private static const STICKS:String = "sticks";
		private static const HIDE:String = "hide";
		private static const FLAME:String = "flame";
		private static const RANDOM:String = "random";
		
		private var flameCount:Number = 0;
		private var _flameCreator:FlameCreator;
		private var _canSneak:Boolean = true;
		private var _dogTracking:Boolean = false;
		
		private var dogNeckOffsetX:Vector.<Number>;
		private var dogNeckOffsetY:Vector.<Number>;

		private var _animationLoader:AnimationLoaderSystem;
		private var _characterGroup:CharacterGroup;
		public var _events:Survival5Events;
		public var whistleListeners:Vector.<ListenerData>;
		
		protected const SHARED_PREFIX:String = "scenes/survival5/shared/";
		protected var _audioGroup:AudioGroup;
		
		public function Survival5Scene()
		{
			whistleListeners = new Vector.<ListenerData>();
			dogNeckOffsetX = new Vector.<Number>;
			dogNeckOffsetY = new Vector.<Number>;
			super();
		}
		
		override protected function addCharacters():void
		{
			super.addCharacters();
			
			// PRELOAD ANIMATIONS FOR SNEAKING
			_characterGroup = super.getGroupById( CharacterGroup.GROUP_ID ) as CharacterGroup;
			_characterGroup.preloadAnimations( new <Class>[ Alerted, DuckNinja, FightStance, Ride, Stand, WalkNinja ], this );
			_characterGroup.preloadAnimations( new <Class>[ Walk ], this, AnimationLibrary.CREATURE );
			
			_animationLoader = super.getSystem( AnimationLoaderSystem ) as AnimationLoaderSystem;
		}
		
		override protected function addBaseSystems():void
		{
			super.addSystem( new ThresholdSystem());
			super.addSystem( new NPCDetectionSystem());		
			super.addSystem( new TriggerHitSystem());
			super.addSystem( new BitmapSequenceSystem());
			super.addSystem( new TimedEntitySystem());
			super.addSystem( new HookSystem());
			
			super.addBaseSystems();
		}
		
		override public function destroy():void
		{
			shellApi.eventTriggered.removeAll();
			super.destroy();
		}
		
		override public function loaded():void
		{
			_events = events as Survival5Events;
			shellApi.eventTriggered.add(onEventTriggered);
			super.loaded();
			
			_audioGroup = getGroupById( AudioGroup.GROUP_ID ) as AudioGroup;
			setupEnvironmentalAssets();
			if( shellApi.checkEvent( _events.ISLAND_INCOMPLETE ))
			{	
				setUpListeners();
				setHuntingAnimations();
				createHuntingAnimations();
				setupSneakPlatforms();
			}
		}
		
		private function setupEnvironmentalAssets():void
		{
			var child:DisplayObject;
			for each ( child in _hitContainer )
			{
				if( child.name.indexOf( STICKS ) == 0 )
				{
					setupSticks(child as MovieClip);	
				}
				if(child.name.indexOf(HIDE) == 0 )
				{
					setUpHideBushes(child as MovieClip);
				}
				if(child.name.indexOf(FLAME) == 0 )
				{
					flameCount ++;
				}
			}
			
			if( flameCount > 0 )
			{
				setupFlames();
			}
		}
		
		private function setUpHideBushes(clip:MovieClip):void
		{
			var hideable:Entity = EntityUtils.createSpatialEntity(this, clip);
			BitmapTimelineCreator.convertToBitmapTimeline(hideable, clip);
			
			InteractionCreator.addToEntity(hideable, [InteractionCreator.CLICK]);
			var sceneInteraction:SceneInteraction = new SceneInteraction();
			sceneInteraction.reached.addOnce(hideReached);
			sceneInteraction.validCharStates = new <String> [ CharacterState.STAND];
			sceneInteraction.minTargetDelta = new Point(30, 100);
			sceneInteraction.ignorePlatformTarget = false;
			hideable.add(sceneInteraction);
			ToolTipCreator.addToEntity(hideable);
		}
		
		private function hideReached(player:Entity, hideable:Entity):void
		{
			var hide:Hide = player.get(Hide);
			
			var timeline:Timeline = hideable.get(Timeline);
			
			if(timeline)
				timeline.play();
			
			AudioUtils.play(this, SoundManager.EFFECTS_PATH + "grass_rustle_01.mp3");
			
			DisplayUtils.moveToOverUnder(player.get(Display).displayObject, hideable.get(Display).displayObject, false);
			
			var hideableSpatial:Spatial = hideable.get(Spatial);
			var playerSpatial:Spatial = player.get(Spatial);
			
			playerSpatial.x = hideableSpatial.x;
			playerSpatial.y = hideableSpatial.y;
			
			CharUtils.setAnim(player, DuckDown);
			CharUtils.lockControls(player);
			hide.hidden = true;
			
			// avoiding flip rock issues
			var flipRock:Entity = getEntityById("flip2");
			
			if(flipRock != null)
			{
				Interaction(flipRock.get(Interaction)).lock = true;
			}
			
			hideable.get(Interaction).click.addOnce(hiddenClick);
			
			var proxy:Proximity = new Proximity(50, hideable.get(Spatial));
			proxy.exited.add(Command.create(unHide, hideable));
			player.add(proxy);
		}
		
		private function unHide(player:Entity, hideable:Entity):void
		{
			hiddenClick(hideable);
			SceneInteraction(hideable.get(SceneInteraction)).reached.remove(unHideReached);
			unHideReached(player, hideable);
		}
		
		private function hiddenClick(hideable:Entity):void
		{
			var hide:Hide = player.get(Hide);
			
			var timeline:Timeline = hideable.get(Timeline);
			if(timeline)
				timeline.play();
			
			AudioUtils.play(this, SoundManager.EFFECTS_PATH + "grass_rustle_01.mp3");
			
			Display(player.get(Display)).moveToFront();
			CharUtils.setState(player, CharacterState.STAND);
			CharUtils.lockControls(player, false, false);
			hide.hidden = false;
			
			var flipRock:Entity = getEntityById("flip2");
			
			if(flipRock != null)
			{
				trace("unlock");
				Interaction(flipRock.get(Interaction)).lock = false;
			}
			
			hideable.get(SceneInteraction).reached.addOnce(unHideReached);
		}
		
		private function unHideReached(player:Entity, hideable:Entity):void
		{
			hideable.get(SceneInteraction).reached.addOnce(hideReached);
			player.remove(Proximity);
		}
		
		private function setupSticks( clip:MovieClip ):void
		{
			var entity:Entity;
			var number:String = clip.name.substr( 6 );
			var timeline:Timeline;
			var platformEntity:Entity = getEntityById( "stickHit" + number );
			
			entity = EntityUtils.createSpatialEntity( this, clip, _hitContainer );
			entity.add( new Id( clip.name ));
			TimelineUtils.convertClip( clip, this, entity, null, false );
			
			var animatedHit:TriggerHit = new TriggerHit( entity.get( Timeline ));
			animatedHit.triggered = new Signal();
			
			if( shellApi.checkEvent( _events.ISLAND_INCOMPLETE ))
			{
				animatedHit.triggered.add( caughtBySticks );//caughtBySticks );
				animatedHit.triggerAfterAnimation = steppedOnSticks;
				platformEntity.add( animatedHit );
			}
		}
		
			// FLAME LOGIC
		private function setupFlames():void
		{
			_flameCreator = new FlameCreator();
			_flameCreator.setup( this, super._hitContainer[ "flame1" ], null, onFlameLoaded );
		}
		
		private function onFlameLoaded():void
		{
			var audio:Audio;
			var audioRange:AudioRange;
			var clip:MovieClip;
			var flameEntity:Entity;
			var spatial:Spatial;
			
			for( var number:uint = 1; number < flameCount + 1; number ++ )
			{
				clip = super._hitContainer[ "flame" + number ];
				flameEntity = _flameCreator.createFlame( this, clip, true );
				flameEntity.add( new Id( "flame" + number ));
				
				if( number == 0 )
				{
					flameEntity.add( new AudioRange( 600, .02, 2 ));
					_audioGroup.addAudioToEntity( flameEntity );
					
					audio = flameEntity.get( Audio );
					audio.playCurrentAction( RANDOM );
				}
			}
		}
			
			// PRIVATE FUNCTION TO CREATE UNIQUE HUNTING ANIMATIONS FOR VAN BUREN AND DOG
		private function createHuntingAnimations():void
		{
			var fightStanceAnimation:FightStance = _animationLoader.animationLibrary.getAnimation( FightStance ) as FightStance;
			var frameData:FrameData;
			var frameEvent:FrameEvent;
			var number:int;
			var ninjaWalkAnimation:WalkNinja = _animationLoader.animationLibrary.getAnimation( WalkNinja ) as WalkNinja;
			var rideAnimation:Ride = _animationLoader.animationLibrary.getAnimation( Ride ) as Ride;
			var idleStandAnimation:Alerted = _animationLoader.animationLibrary.getAnimation( Alerted ) as Alerted;
			var duckNinjaAnimation:DuckNinja = _animationLoader.animationLibrary.getAnimation( DuckNinja ) as DuckNinja;
		
			// VAN BUREN'S HUNT ANIMATION
				// STRETCH OUT THE FIGHT STANCE LENGTH
			for( number = 0; number < 11; number ++ )
			{
				frameData = new FrameData();
				frameData.index = fightStanceAnimation.data.frames.length;
				fightStanceAnimation.data.frames.push( frameData );
			}
			
				// SET ANIMATION LENGTH TO 20 AND LOOP IT BACK TO 10
			fightStanceAnimation.data.duration = 34;
			
				// SET THE HAND/ARM ANIMATIONS
			var replacementData:PartAnimationData = rideAnimation.data.parts[ "arm1" ];
			fightStanceAnimation.data.parts[ "arm1" ] = replacementData;
			
			replacementData = rideAnimation.data.parts[ "arm2" ];
			fightStanceAnimation.data.parts[ "arm2" ] = replacementData;
			
			replacementData = rideAnimation.data.parts[ "hand1" ];
			fightStanceAnimation.data.parts[ "hand1" ] = replacementData;
			
			for( number = 0; number < fightStanceAnimation.data.duration - 1; number ++ )
			{
				fightStanceAnimation.data.parts[ "hand1" ].kframes[ number ].y += 40;
				fightStanceAnimation.data.parts[ "hand1" ].kframes[ number ].x += 40;
			}
			
			replacementData = rideAnimation.data.parts[ "hand2" ];
			fightStanceAnimation.data.parts[ "hand2" ] = replacementData;
			
			for( number  = 0; number <  fightStanceAnimation.data.duration - 1; number ++ )
			{
				fightStanceAnimation.data.parts[ "hand2" ].kframes[ number ].y += 70;
				fightStanceAnimation.data.parts[ "hand2" ].kframes[ number ].x -= 25;
			}
			
				// SET THE FOOT/LEG/BODY/HEAD ANIMATIONS
			replacementData = ninjaWalkAnimation.data.parts[ "foot1" ];
			fightStanceAnimation.data.parts[ "foot1" ] = replacementData;
			
			replacementData = ninjaWalkAnimation.data.parts[ "foot2" ];
			fightStanceAnimation.data.parts[ "foot2" ] = replacementData;
			
			replacementData = ninjaWalkAnimation.data.parts[ "leg1" ];
			fightStanceAnimation.data.parts[ "leg1" ] = replacementData;
			
			replacementData = ninjaWalkAnimation.data.parts[ "leg2" ];
			fightStanceAnimation.data.parts[ "leg2" ] = replacementData;
			
			replacementData = ninjaWalkAnimation.data.parts[ "body" ];
			fightStanceAnimation.data.parts[ "body" ] = replacementData;
			
			replacementData = ninjaWalkAnimation.data.parts[ "neck" ];
			fightStanceAnimation.data.parts[ "neck" ] = replacementData;
			
				// MOVE LOOP TO FRAME 9
			fightStanceAnimation.data.frames[ 1 ].label = null;
			fightStanceAnimation.data.frames[ 22 ].events.pop();
			fightStanceAnimation.data.frames[ 9 ].label = "loop";
			frameEvent = new FrameEvent( "gotoAndPlay", "loop" );
			fightStanceAnimation.data.frames[ 33 ].events.push( frameEvent );
			
				// ADD STEPS
			fightStanceAnimation.data.frames[ 10 ].label = "step";
			fightStanceAnimation.data.frames[ 21 ].label = "step";

			frameEvent = new FrameEvent( "setEyes", "mean", "back" );
			fightStanceAnimation.data.frames[ 10 ].events.push( frameEvent );
			
			frameEvent = new FrameEvent( "setEyes", "mean", "front" );
			fightStanceAnimation.data.frames[ 20 ].events.push( frameEvent );

			var creatureWalkAnimation:Walk = _animationLoader.animationLibrary.getAnimation( Walk, AnimationLibrary.CREATURE ) as Walk;

				// STORE DOG WALK ANIMATION LEG OFFSETS FOR LATER TOGGLING
			for( number = 0; number < creatureWalkAnimation.data.duration; number ++ )
			{
				dogNeckOffsetY.push( creatureWalkAnimation.data.parts[ "neck" ].kframes[ number ].y );
				dogNeckOffsetX.push( creatureWalkAnimation.data.parts[ "neck" ].kframes[ number ].x );
			}
			toggleDogTrack( true );
			_dogTracking = true;
			
				// PLAYER'S SNEAK ANIMATION
			ninjaWalkAnimation.data.frames[ 0 ].events.pop();
			ninjaWalkAnimation.data.frames[ 0 ].events.pop();
			ninjaWalkAnimation.data.frames[ 0 ].events.pop();
			
			frameEvent = new FrameEvent( "setEyes", "open", "front" );
			ninjaWalkAnimation.data.frames[ 0 ].events.push( frameEvent );
			frameEvent = new FrameEvent( "setPart", "mouth", "nessie_tourist" );
			ninjaWalkAnimation.data.frames[ 0 ].events.push( frameEvent );
			ninjaWalkAnimation.data.frames[ 9 ].label = "loop";
			
				// PLAYER'S PETRIFIED CROUCH ANIMATION
			duckNinjaAnimation.data.frames[ 0 ].events.pop();
			duckNinjaAnimation.data.frames[ 0 ].events.pop();
			duckNinjaAnimation.data.frames[ 0 ].events.pop();
			
			frameEvent = new FrameEvent( "setEyes", "open", "front" );
			duckNinjaAnimation.data.frames[ 0 ].events.push( frameEvent );
			frameEvent = new FrameEvent( "setPart", "mouth", "nessie_tourist" );
			duckNinjaAnimation.data.frames[ 0 ].events.push( frameEvent );
		}
		
		protected function toggleDogTrack( tracking:Boolean = true ):void
		{
			var frameEvent:FrameEvent;
			var number:int;
			var creatureWalkAnimation:Walk = _animationLoader.animationLibrary.getAnimation( Walk, AnimationLibrary.CREATURE ) as Walk;

			var footTweek:Number = 10;
			var bodyTweek:Number = 10;
			var rotationTweek:Number = 30;
			var eyeState:String = "squint";
			var pupilValue:String = "down";
			var mouthPart:String = "default";
			var neckOffsetX:Number;
			var neckOffsetY:Number;
				
			if( tracking != _dogTracking )
			{
				if( !tracking )
				{
					footTweek *= -1;
					bodyTweek *= -1;
					rotationTweek *= -1;
					eyeState = "mean_still";
					pupilValue = "front";
					mouthPart = "dogBite";
				}
				for( number = 0; number < creatureWalkAnimation.data.duration; number ++ )
				{
					creatureWalkAnimation.data.parts[ "arm1" ].kframes[ number ].y += 2 * footTweek;
					creatureWalkAnimation.data.parts[ "arm2" ].kframes[ number ].y += 2 * footTweek;
					creatureWalkAnimation.data.parts[ "hand1" ].kframes[ number ].y -= footTweek; // -= 20 for these
					creatureWalkAnimation.data.parts[ "hand2" ].kframes[ number ].y -= footTweek;
					creatureWalkAnimation.data.parts[ "hand1" ].kframes[ number ].x -= 2 * footTweek; // -= 20 for these
					creatureWalkAnimation.data.parts[ "hand2" ].kframes[ number ].x -= 2 * footTweek;
					creatureWalkAnimation.data.parts[ "foot1" ].kframes[ number ].y -= footTweek;
					creatureWalkAnimation.data.parts[ "foot2" ].kframes[ number ].y -= footTweek;
					creatureWalkAnimation.data.parts[ "foot1" ].kframes[ number ].x += footTweek;
					creatureWalkAnimation.data.parts[ "foot2" ].kframes[ number ].x += footTweek;
					
						// LOWER THE DIFFERENCE IN HEAD BOBBING
					neckOffsetX = ( dogNeckOffsetX[ number ] % 2 ) - 5;
					neckOffsetY = ( dogNeckOffsetY[ number ] % 5 ) + 70;
					if( !tracking )
					{
						neckOffsetX = dogNeckOffsetX[ number ];
						neckOffsetY = dogNeckOffsetY[ number ];
					}
					creatureWalkAnimation.data.parts[ "neck" ].kframes[ number ].x = neckOffsetX;
					creatureWalkAnimation.data.parts[ "neck" ].kframes[ number ].y = neckOffsetY;
					
					creatureWalkAnimation.data.parts[ "body" ].kframes[ number ].y += bodyTweek;
					creatureWalkAnimation.data.parts[ "body" ].kframes[ number ].rotation -= rotationTweek;
				}
				
				for( number = 0; number < creatureWalkAnimation.data.frames[ 0 ].events.length; number ++ )
				{
					creatureWalkAnimation.data.frames[ 0 ].events.pop();
				}
				frameEvent = new FrameEvent( "setEyes", eyeState, pupilValue );
				creatureWalkAnimation.data.frames[ 0 ].events.push( frameEvent );
				frameEvent = new FrameEvent( "setPart", "mouth", mouthPart );
			}
		}
		
		protected function setHuntingAnimations():void
		{
				// SET VAN BUREN'S NEW, AWESOME HUNT ANIMATION
			var dog:Entity = getEntityById( "dog" );
			var dogWalkState:WalkState;
			var fsmControl:FSMControl;
			var number:int;
			var vanBuren:Entity = getEntityById( "buren" );
			var vanBurenWalkState:WalkState;
			
			if( vanBuren )
			{
				fsmControl = vanBuren.get( FSMControl );
				if( !fsmControl )
				{
					fsmControl = _characterGroup.addFSM( vanBuren );
					fsmControl = vanBuren.get( FSMControl );
				}
				
				vanBurenWalkState = fsmControl.getState( CharacterState.WALK ) as WalkState;
					// GOING WITH FIGHT STANCE SO THE PLAYER CAN USE WALK NINJA
				vanBurenWalkState.walkAnim = FightStance;
				cleanNPC( vanBuren );
			}
			
				// SET DOG'S NEW, AWESOME TRACK ANIMATION
			if( dog )
			{
				fsmControl = dog.get( FSMControl );
				if( !fsmControl )
				{
					fsmControl = _characterGroup.addFSM( dog );
					fsmControl = dog.get( FSMControl );
				}
				
				dogWalkState = fsmControl.getState( CharacterState.WALK ) as WalkState;
				dogWalkState.walkAnim = Walk;
				cleanNPC( dog );
			}
		}
		
			// REMOVE SCENE INTERACTION, INTERACTION AND MOUSE LISTENERS
		protected function cleanNPC( entity:Entity ):void
		{
			var characterGroup:CharacterGroup = getGroupById( CharacterGroup.GROUP_ID ) as CharacterGroup;
			
			EntityUtils.removeInteraction( entity );
			var displayObject:MovieClip = Display( entity.get( Display )).displayObject;
			displayObject.mouseChildren = false;
			displayObject.mouseEnabled = false;	
			characterGroup.addAudio( entity );
		}
			
			// SETUP SNEAKY ENTITIES SO THE PLAYER WILL USE HIS SNEAK ANIMATION WHEN ON THESE PLATFORMS
		private function setupSneakPlatforms():void
		{
			var bitmapHitNodes:NodeList = systemManager.getNodeList( BitmapHitNode );
			var entity:Entity;
			var id:Id;
			var name:String;
			var triggerHit:TriggerHit;
			
			for(var node:BitmapHitNode = bitmapHitNodes.head; node; node = node.next)
			{
				entity = node.entity;
				id = entity.get( Id );

				if( id )
				{
					name = id.id;
					if( name.indexOf( "sneak" ) >= 0 )
					{
						triggerHit = new TriggerHit();
						triggerHit.triggered = new Signal();
						triggerHit.offTriggered = new Signal();
						triggerHit.triggered.add( sneakOn );
						triggerHit.offTriggered.add( sneakOff );
						entity.add( triggerHit ).add( new EntityIdList());
					}
				}
			}
		}
		
		protected function sneakOn():void
		{
			if( _canSneak )
			{
				var fsmControl:FSMControl = player.get( FSMControl );
				var motionControl:CharacterMotionControl = player.get( CharacterMotionControl );
				
				var walkState:WalkState = fsmControl.getState( CharacterState.WALK ) as WalkState;
				walkState.walkAnim = WalkNinja;
				
				var standState:StandState = fsmControl.getState( CharacterState.STAND ) as StandState;
				standState.standAnim = DuckNinja; 
				
				motionControl.maxVelocityX = SNEAK_SPEED;
			}
		}
		
		protected function sneakOff():void
		{
			var fsmControl:FSMControl = player.get( FSMControl );
			var motionControl:CharacterMotionControl = player.get( CharacterMotionControl );
			
			var walkState:WalkState = fsmControl.getState( CharacterState.WALK ) as WalkState;
			walkState.walkAnim = Walk;
			
			var standState:StandState = fsmControl.getState( CharacterState.STAND ) as StandState;
			standState.standAnim = Stand;
			
			motionControl.maxVelocityX = MAX_SPEED;
		}
		
			// SETUP WHISTLE LISTENER, DETECTOR AND PATROL
		private function setUpListeners():void
		{
			addSystem( new NPCDetectionSystem(), SystemPriorities.resolveCollisions );
			
			player.add(new Hide());
			var data:ListenerData;
			var entity:Entity;
			var whistleListener:WhistleListener;
			var sleep:Sleep;
			
			for(var i:int = 0; i < whistleListeners.length; i++)
			{
				data = whistleListeners[i];
				entity = getEntityById(data.id);
				
				if(entity != null)
				{
					sleep = entity.get( Sleep );
					sleep.sleeping = false;
					sleep.ignoreOffscreenSleep = true;
					
					var detector:NPCDetector = new NPCDetector( data.lookDistance, -Spatial(entity.get(Spatial)).height / 2 );
					detector.detected.addOnce( Command.create(playerDetected, entity, data.caughtPlayer) );
					
					var characterMotionControl:CharacterMotionControl = new CharacterMotionControl();
					characterMotionControl.maxVelocityX = SNEAK_SPEED;//PATROL_SPEED;
					
					whistleListener = new WhistleListener( data.listenArea, data.inspectTime, data.patrolTime, data.alphaPoint, data.betaPoint );
					entity.add( whistleListener ).add( detector ).add( characterMotionControl ).add( new AudioRange( 600, 0, 1, Sine.easeIn ));
					_audioGroup.addAudioToEntity( entity );
					
					if( data.alphaPoint && data.betaPoint )
					{
						moveToAlphaPoint( entity );
					}
				}
			}
		}
		
		// MOVE HUNTER ENTITIES
		protected function moveToAlphaPoint( character:Entity ):void
		{
			var listener:WhistleListener = character.get( WhistleListener );
			if( character.get( Id ).id == "dog" )
			{
				var audio:Audio = character.get( Audio );
				if( audio.isPlaying( SoundManager.EFFECTS_PATH + "dog_sniffing_01_loop.mp3" ))
				{
					audio.stopActionAudio( RANDOM );
				}
			}
			if( listener && !listener.inspecting )
			{
				var motionControl:CharacterMotionControl = character.get( CharacterMotionControl );
				motionControl.maxVelocityX = SNEAK_SPEED;
				
				listener.alphaNext = false;
				
				SceneUtil.addTimedEvent( this, new TimedEvent( listener.patrolTime, 1, Command.create( moveToNextPoint, character, listener.alphaPoint.x, listener.alphaPoint.y, true, moveToBetaPoint )));
			}
		}
		
		protected function moveToBetaPoint( character:Entity ):void
		{
			var listener:WhistleListener = character.get( WhistleListener );
			if( character.get( Id ).id == "dog" )
			{
				var audio:Audio = character.get( Audio );
				if( audio.isPlaying( SoundManager.EFFECTS_PATH + "dog_sniffing_01_loop.mp3" ))
				{
					audio.stopActionAudio( RANDOM );
				}
			}
			if( listener && !listener.inspecting )
			{
				var motionControl:CharacterMotionControl = character.get( CharacterMotionControl );
				motionControl.maxVelocityX = SNEAK_SPEED;
				
				listener.alphaNext = true;
				
				SceneUtil.addTimedEvent( this, new TimedEvent( listener.patrolTime, 1, Command.create( moveToNextPoint, character, listener.betaPoint.x, listener.betaPoint.y, true, moveToAlphaPoint )));
			}
		}
		
		// Buffer function to make sure he isn't inspecting when we try to have him patrol
		protected function moveToNextPoint( character:Entity, targetX:Number, targetY:Number, lockControl:Boolean=false, handler:Function=null, minTargetDelta:Point=null ):void
		{
			var listener:WhistleListener = character.get( WhistleListener );
			if( listener && !listener.inspecting )
			{
				if( character.get( Id ).id == "dog" )
				{
					var audio:Audio = character.get( Audio );
					audio.playCurrentAction( RANDOM );
				}
				CharUtils.moveToTarget( character, targetX, targetY, false, handler, minTargetDelta );
			}
		}
		
			// PLAYER WAS SPOTTED
		private function playerDetected( player:Entity, entity:Entity, listener:Function ):void
		{
			var input:Input = shellApi.inputEntity.get( Input );
			
				// IF NOT ALREADY CAUGHT, SET THE PLAYERS CAUGHT ANIMATIONS
			if( !input.lockInput )
			{
				var whistleListener:WhistleListener = entity.get( WhistleListener );
				whistleListener.inspecting = true;
				
				setPlayerCaught();
			}
			
			var audio:Audio = entity.get( Audio );
			if( audio.isPlaying( SoundManager.EFFECTS_PATH + "dog_sniffing_01_loop.mp3" ))
			{
				audio.stopActionAudio( RANDOM );
			}
			
//			CharUtils.stateDrivenOn( entity );
			SceneUtil.setCameraTarget( this, entity );
			
			setSpotState( entity );
			CharUtils.setState( entity, CharacterState.STAND );
			
			var motionControl:CharacterMotionControl = entity.get( CharacterMotionControl );
			motionControl.maxVelocityX = INVESTIGATE_SPEED;
			
			var spatial:Spatial = entity.get(Spatial);
			CharUtils.moveToTarget(entity, spatial.x, spatial.y);
			
			var id:Id = entity.get( Id );
			if( id.id == "dog" )
			{
				toggleDogTrack( false );
				_dogTracking = false;
				SceneUtil.delay( this, 1, Command.create( walkToPlayer, entity, listener ));
			}
			else
			{
				SceneUtil.delay(this, 2, Command.create( listener, entity));
			}
		}
		
		private function caughtBySticks( ...args ):void
		{
			setPlayerCaught( false );
		}
		
		protected function setPlayerCaught( moveToPosition:Boolean = true ):void
		{
			var fsmControl:FSMControl = player.get( FSMControl );
			
			//waiting on fsm is allowing for too much time for player to do weird stuff
			//just force it into what we want
			
			fsmControl.setState( CharacterState.IDLE );
			var standState:StandState = fsmControl.getState( CharacterState.STAND ) as StandState;
			standState.standAnim = Tremble;
			fsmControl.setState( CharacterState.STAND );
			if( moveToPosition )
			{
				var pos:Spatial = player.get(Spatial);
				CharUtils.moveToTarget(player, pos.x, pos.y);
			}
			MotionUtils.zeroMotion( player );
			SceneUtil.zeroRotation( player );
			SceneUtil.lockInput( this);
			CharUtils.lockControls(player);
		}
				
		protected function setSpotState( catcher:Entity ):void
		{
			var fsmControl:FSMControl = catcher.get( FSMControl );
			var standState:StandState = fsmControl.getState( CharacterState.STAND ) as StandState;
			var walkState:WalkState = fsmControl.getState( CharacterState.WALK ) as WalkState;
			walkState.walkAnim = Walk;
			var id:String = catcher.get(Id).id;
			if(id == "buren")
			{
				standState.standAnim = ThrowReady; 
				AudioUtils.play(this, SoundManager.EFFECTS_PATH + "tally_ho_01.mp3");
			}
			else
			{
				var stand:Stand = _animationLoader.animationLibrary.getAnimation( Stand, AnimationLibrary.CREATURE ) as Stand;
				var frameEvent:FrameEvent;
				
				for( var number:int = 0; number < stand.data.frames[ 0 ].events.length; number ++ )
				{
					stand.data.frames[ 0 ].events.pop();
				}
				
				frameEvent = new FrameEvent( "setPart", "mouth", "dogBite" );
				stand.data.frames[ 0 ].events.push( frameEvent );
				frameEvent = new FrameEvent( "setEyes", "mean", "forward" );
				stand.data.frames[ 0 ].events.push( frameEvent );
				standState.standAnim = Stand;
				
				AudioUtils.play(this, SoundManager.EFFECTS_PATH + "dog_bark_01.mp3");
			}
		}
		
		private function walkToPlayer( catcher:Entity, listener:Function ):void
		{
			setCaughtState(catcher);
			var playerSpatial:Spatial = player.get( Spatial );
			CharUtils.moveToTarget( catcher, playerSpatial.x, playerSpatial.y, true, null, new Point(100, 100) );
			SceneUtil.delay(this, 1, Command.create( listener, catcher));
		}
		
		protected function setCaughtState(catcher:Entity):void
		{
			var fsmControl:FSMControl = catcher.get( FSMControl );
			
			var standState:StandState = fsmControl.getState( CharacterState.STAND ) as StandState;
			
			standState.standAnim = Stand;
		}
		
		public function caughtByDog( ...args ):void
		{
			SceneUtil.lockInput( this, false );
			var dogPopup:DialogPicturePopup = new DialogPicturePopup( overlayContainer );
			dogPopup.updateText( "You were caught! You'll need to be more careful.", "Try Again" );
			dogPopup.configData( "dogPopup.swf", SHARED_PREFIX );
			dogPopup.popupRemoved.addOnce(reloadScene);
			addChildGroup( dogPopup );
		}
		
		public function reloadScene( ...args ):void
		{
			switch (shellApi.sceneName)
			{
				case "BaseCamp":
					shellApi.loadScene(BaseCamp)
					break;
				case "Chase":
					shellApi.loadScene(Chase)
					break;
				case "Sawmill":
					shellApi.loadScene(Sawmill)
					break;
				case "Traps":
					shellApi.loadScene(Traps);
					break;
				case "Underground":
					shellApi.loadScene(Underground)
					break;
				case "WaterEdge":
					shellApi.loadScene(WaterEdge)
					break;
			}
		}
		
		protected function onEventTriggered(event:String, save:Boolean = true, init:Boolean = false, removeEvent:String = null):void
		{
			if(event == _events.USE_WHISTLE)
			{
				var fsm:FSMControl = player.get(FSMControl);
				if(fsm.state.type != CharacterState.STAND)
				{
					fsm.stateChange = new Signal();
					fsm.stateChange.add(checkState);
				}
				else
					checkState(CharacterState.STAND, player);
			}else if(event == "no_use_gear"){
				Dialog(player.get(Dialog)).sayById("no_use_gear");
			}else if(event == "no_use_rope"){
				Dialog(player.get(Dialog)).sayById("no_use_rope");
			}
		}
		
		private function checkState(type:String, entity:Entity):void
		{
			if(type == CharacterState.STAND)
			{
				CharUtils.setAnim(player, Sneeze);
				SkinUtils.setSkinPart(player, SkinUtils.ITEM, "wwwhistle",false);
				var timeline:Timeline = player.get(Timeline);
				timeline.handleLabel("ending", activateFsm);
				timeline.handleLabel( "fire", playWhistleSound );
				FSMControl(player.get(FSMControl)).stateChange = null;
			}
		}
		
		private function playWhistleSound():void
		{
			AudioUtils.play(this, SoundManager.EFFECTS_PATH + "whistle_blow_01.mp3");
			SkinUtils.emptySkinPart(player, SkinUtils.ITEM,false);
		}
		
		private function activateFsm():void
		{
			respondToNoise();
			FSMControl(player.get(FSMControl)).active = true;
		}
		
			// CAUGHT BY THE STICKS
		private function steppedOnSticks():void
		{
			var spatial:Spatial = player.get( Spatial );
			var whistleNodes:NodeList = systemManager.getNodeList( WhistleNode );
			
			var walkState:WalkState;
			
			for(var node:WhistleNode = whistleNodes.head; node; node = node.next)
			{
				var listenArea:Rectangle = node.listener.listenArea;
				if(listenArea != null)
				{
					if(!listenArea.contains(spatial.x, spatial.y))
						continue;
					
					if( listenArea.contains( spatial.x, spatial.y ))
					{
						walkState = node.fsmControl.getState( CharacterState.WALK ) as WalkState;
						walkState.walkAnim = Walk;
						node.listener.inspecting = true;
					}
				}
				
				var id:Id = node.id;
				node.motionControl.maxVelocityX = INVESTIGATE_SPEED;
				
				if( id.id == "dog" )
				{
					toggleDogTrack( false );
					_dogTracking = false;
					CharUtils.moveToTarget( node.entity, spatial.x, spatial.y-100, true, caughtBySticks);
				}
				else
				{
					CharUtils.moveToTarget( node.entity, spatial.x, spatial.y, true, caughtBySticks);
				}
			}
		}
		
			// GIVE THEM A NORMAL WALK TO USE FOR NOW
		private function respondToNoise():void
		{
			var spatial:Spatial = player.get(Spatial);
			var whistleNodes:NodeList = systemManager.getNodeList(WhistleNode);
						
			var walkState:WalkState;
			
			for(var node:WhistleNode = whistleNodes.head; node; node = node.next)
			{
				var listenArea:Rectangle = node.listener.listenArea;
				if(listenArea != null)
				{
					if(!listenArea.contains(spatial.x, spatial.y))
						continue;
					
					if( listenArea.contains( spatial.x, spatial.y ))
					{
						walkState = node.fsmControl.getState( CharacterState.WALK ) as WalkState;
						walkState.walkAnim = Walk;
						node.listener.inspecting = true;
					}
				}
				
				var id:Id = node.id;
				if( id.id == "dog" )
				{
					toggleDogTrack( false );
					_dogTracking = false;
					
					var audio:Audio = node.entity.get( Audio );
					if( audio.isPlaying( SoundManager.EFFECTS_PATH + "dog_sniffing_01_loop.mp3" ))
					{
						audio.stopActionAudio( RANDOM );
					}
				}
				node.motionControl.maxVelocityX = INVESTIGATE_SPEED;
				
				CharUtils.moveToTarget(node.entity, spatial.x, node.spatial.y, true, inspect, new Point(100, 100));
			}
		}
		
		private function inspect(entity:Entity):void
		{
			var motionControl:CharacterMotionControl = entity.get( CharacterMotionControl );
			motionControl.maxVelocityX = SNEAK_SPEED;
			
			var delayTime:Number = WhistleListener(entity.get(WhistleListener)).inspectTime;
			if(delayTime >= 0)
			{
				SceneUtil.delay(this, delayTime, Command.create(goBackToBusiness, entity));
			}
		}
		
			// override to do what you need to have the npc behave how you want normally
		public function goBackToBusiness( entity:Entity ):void
		{
			var id:Id = entity.get( Id );
			var listener:WhistleListener = entity.get( WhistleListener );
			var fsmControl:FSMControl = entity.get( FSMControl );
			var walkState:WalkState = fsmControl.getState( CharacterState.WALK ) as WalkState;
			
			if( id.id == "buren" )
			{
				walkState.walkAnim = FightStance;
			}
			else
			{
				toggleDogTrack( true );
				_dogTracking = true;
				walkState.walkAnim = Walk;
			}
			
			listener.inspecting = false;
			if( listener.alphaPoint && listener.betaPoint )
			{
				if( listener.alphaNext )
				{
					moveToAlphaPoint( entity );
				}
				else
				{
					moveToBetaPoint( entity );
				}
			}
			
			_canSneak = true;
		}
	}
}