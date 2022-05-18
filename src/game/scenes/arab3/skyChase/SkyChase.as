package game.scenes.arab3.skyChase
{
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.geom.Point;
	
	import ash.core.Entity;
	
	import engine.components.Display;
	import engine.components.Id;
	import engine.components.Interaction;
	import engine.components.Motion;
	import engine.components.Spatial;
	import engine.components.SpatialAddition;
	import engine.components.Tween;
	import engine.util.Command;
	
	import game.components.Timer;
	import game.components.animation.FSMControl;
	import game.components.entity.Dialog;
	import game.components.entity.Sleep;
	import game.components.motion.Edge;
	import game.components.motion.FollowTarget;
	import game.components.motion.Threshold;
	import game.components.motion.WaveMotion;
	import game.components.entity.FlyingPlatformHealth;
	import game.components.scene.SceneInteraction;
	import game.components.timeline.Timeline;
	import game.creators.animation.FSMStateCreator;
	import game.creators.entity.EmitterCreator;
	import game.creators.ui.ToolTipCreator;
	import game.data.TimedEvent;
	import game.data.WaveMotionData;
	import game.data.animation.entity.character.Hurt;
	import game.data.animation.entity.character.Laugh;
	import game.data.animation.entity.character.Proud;
	import game.data.animation.entity.character.Stand;
	import game.data.animation.entity.character.Stomp;
	import game.data.scene.characterDialog.DialogData;
	import game.managers.ScreenManager;
	import game.nodes.entity.character.FlyingPlatformStateNode;
	import game.scene.template.AudioGroup;
	import game.scene.template.CharacterGroup;
	import game.scenes.arab3.Arab3Events;
	import game.scenes.arab3.desert.Desert;
	import game.scenes.arab3.shared.SmokePuffGroup;
	import game.scenes.shrink.carGame.creators.RaceSegmentCreator;
	import game.scenes.survival5.chase.scenes.EndlessRunnerScene;
	import game.systems.entity.LooperCollisionSystem;
	import game.systems.entity.character.states.FlyingPlatformHurt;
	import game.systems.entity.character.states.FlyingPlatformRide;
	import game.systems.entity.character.states.FlyingPlatformState;
	import game.systems.SystemPriorities;
	import game.systems.entity.EyeSystem;
	import game.systems.entity.character.DialogInteractionSystem;
	import game.systems.motion.NavigationSystem;
	import game.systems.motion.ThresholdSystem;
	import game.systems.motion.WaveMotionSystem;
	import game.util.CharUtils;
	import game.util.DisplayUtils;
	import game.util.EntityUtils;
	import game.util.MotionUtils;
	import game.util.SceneUtil;
	import game.util.SkinUtils;
	import game.util.TimelineUtils;
	import game.utils.LoopingSceneUtils;
	
	import org.flintparticles.common.actions.Age;
	import org.flintparticles.common.actions.ColorChange;
	import org.flintparticles.common.counters.Steady;
	import org.flintparticles.common.displayObjects.Dot;
	import org.flintparticles.common.initializers.ImageClass;
	import org.flintparticles.common.initializers.Lifetime;
	import org.flintparticles.common.initializers.ScaleImageInit;
	import org.flintparticles.twoD.actions.Move;
	import org.flintparticles.twoD.actions.RandomDrift;
	import org.flintparticles.twoD.emitters.Emitter2D;
	import org.flintparticles.twoD.initializers.Position;
	import org.flintparticles.twoD.zones.RectangleZone;
	
	public class SkyChase extends EndlessRunnerScene
	{
		private const HIT:String 				= "hit";
		private const OBSTACLE:String 			= "obstacle";
		private var _gameOver:Boolean 			= false;
		
		protected var _numSpellTargets:Number 	= 6;   	// ONE OF THESE WILL BE INFRONT OF THE GENIE'S HANDS
		protected var _hasGenie:Boolean 	  	= true;
		
		private const _obstacles:Vector.<String> 	= 	new <String>[ "elephantHit", "anvilHit", "chillerHit"
																	, "safeHit", "barrelHit", "watermelonHit", "cactusHit"
																	, "vaseHit", "ufoHit", "cannonHit", "pillarHit"
																	, "bellHit", "totemHit", "carHit", "signHit"
																	, "lanternHit", "sinkHit", "clockHit" ]; // "soccer_ballHit", "fountainHit", "buggyHit"
		
		private var _viewportRatioY:Number;
		private var verticalPosition:Number;
		
		private var _componentInstances:Array = [];
		private var _carpet:Entity;
		private var _particles:Entity;
		
		private var _thief:Entity;
		private var _smokePuffGroup:SmokePuffGroup;
		private var _events:Arab3Events;
		private var _raceSegmentCreator:RaceSegmentCreator;
		
		public function SkyChase()
		{
			super();
		}
		
		override public function init(container:DisplayObjectContainer = null):void
		{			
			super.groupPrefix = "scenes/arab3/skyChase/";
			super.init(container);
		}
		
		override protected function addBaseSystems():void
		{
			addSystem( new ThresholdSystem());	
			super.addBaseSystems();
		}
		
		override protected function addCharacters():void
		{
			var charContainer:DisplayObjectContainer = ( _hitContainer ) ? _hitContainer : super.groupContainer;
			
			// this group handles loading characters, npcs (parses npcs.xml), and creates the player character.
			var characterGroup:CharacterGroup = new CharacterGroup();
			characterGroup.setupScene( this, charContainer, super.getData("npcs.xml"), addLoopers, (super.sceneData.startPosition!=null));
			
			super.addSystem(new DialogInteractionSystem(), SystemPriorities.lowest);
			super.addSystem(new NavigationSystem(), SystemPriorities.update);
		}
		
		protected function addLoopers():void
		{
			_raceSegmentCreator = new RaceSegmentCreator();
			var data:XML = SceneUtil.mergeSharedData( this, "segmentPatterns.xml", "ignore" );
			
			_raceSegmentCreator.createSegments( this, data, _hitContainer, _audioGroup, allCharactersLoaded );
		}
		
		override public function loaded():void
		{
			_smokePuffGroup = addChildGroup( new SmokePuffGroup()) as SmokePuffGroup;
			_smokePuffGroup.smokeLoadCompleted.addOnce( smokeReady );
			_smokePuffGroup.initJinnSmoke( this, _hitContainer, 0, _numSpellTargets );
		}
		
		public function smokeReady():void
		{
			_events = shellApi.islandEvents as Arab3Events;
			_audioGroup = getGroupById( AudioGroup.GROUP_ID ) as AudioGroup;

			shellApi.eventTriggered.add( eventTriggered );
			
			super.loaded();
			_thief = getEntityById( "thief" );

			_events = shellApi.islandEvents as Arab3Events;
			
			var first:Entity = EntityUtils.createSpatialEntity( this, _hitContainer[ "first" ]);
			first.add( new Id( "first" ));
			Display( first.get( Display )).alpha = 0;
			
			_thief.remove( SceneInteraction );
			_thief.remove( Interaction );
			ToolTipCreator.removeFromEntity( _thief );
			
			var displayObject:MovieClip 	= 	Display( _thief.get( Display )).displayObject;
			displayObject.mouseChildren 	= 	false;
			displayObject.mouseEnabled 		= 	false;
			
			this.addGenieWaveMotion();
			LoopingSceneUtils.hideObstacles(_raceSegmentCreator, _obstacles);
			setupPlayer();
			LoopingSceneUtils.createMotion(this, cameraStationary, finishedRace);
			super.stopSceneMotion();
			
			introSequence();
		}
		
		override protected function setupPlayer( fileName:String="motionMaster.xml" ):void
		{
			// set number of hits to 4 before losing game
			player.add( new FlyingPlatformHealth( 4, this.loseGame ));
			
			super.setupPlayer(fileName);
						
			LoopingSceneUtils.setupFlyingPlayer(this);
			LoopingSceneUtils.startFlyingPlayer(this, _componentInstances);
												
			shellApi.loadFile( shellApi.assetPrefix + "scenes/arab3/shared/carpet.swf", onCarpetLoaded);
			
			// CARPET PARTICLE EMITTER
			var emitter:Emitter2D = new Emitter2D();
			emitter.counter = new Steady( 40 ); 
			emitter.addInitializer( new ImageClass( Dot, [2], true, 70 ));
			emitter.addInitializer( new Position( new RectangleZone( -50, -2, 50, 2 )));
			emitter.addInitializer( new Lifetime( 1.2 ));
			emitter.addInitializer( new ScaleImageInit( 0.5, 1 ));
			emitter.addAction( new ColorChange( 0xFFEBBF3F, 0x00000000 ));
			emitter.addAction( new RandomDrift( 50, 50 ));
			emitter.addAction( new Move());
			emitter.addAction( new Age());
			
			var container:DisplayObjectContainer = Display( player.get( Display )).displayObject.parent;
			_particles = EmitterCreator.create( this, container, emitter, 0, 37, null, null, player.get( Spatial ));
		}
		
		private function onCarpetLoaded( clip:MovieClip ):void
		{
			if(clip)
			{
				clip.y = 105;
				clip.scaleX = 2;
				clip.scaleY = 2;
				
				var container:DisplayObjectContainer = Display( player.get( Display )).displayObject;
				_carpet = EntityUtils.createSpatialEntity( this, container.addChild( clip ));
				TimelineUtils.convertClip( clip, this, _carpet );
				
				DisplayUtils.moveToOverUnder( Display( _carpet.get( Display )).displayObject, Display( player.get( Display )).displayObject, false );
			}
		}
		
		protected function addGenieWaveMotion():void
		{
			if( !this.getSystem( WaveMotionSystem ))
			{
				this.addSystem( new WaveMotionSystem());
			}
			
			var spatialAddition:SpatialAddition = _thief.get( SpatialAddition );
			if( !spatialAddition )
			{
				spatialAddition = new SpatialAddition();
				_thief.add( spatialAddition );
			}
			
			var waveMotion:WaveMotion = _thief.get( WaveMotion );
			if( !waveMotion )
			{
				waveMotion = new WaveMotion();
				_thief.add( waveMotion );
			}
			
			var waveMotionData:WaveMotionData = waveMotion.dataForProperty( "y" );
			if( !waveMotionData )
			{
				waveMotionData = new WaveMotionData( "y", 10, 2, "sin", 0, true );
				waveMotion.add( waveMotionData );
			}
			
			_smokePuffGroup.addJinnTailSmoke( _thief, true );
		}
		
		private function eventTriggered( event:String, makeCurrent:Boolean=true, init:Boolean=false, removeEvent:String=null ):void
		{
			if( event == _events.SKY_CHASE_COMPLETE )
			{
				SceneUtil.lockInput( this );
				
	//			_smokePuffGroup.stopSpellCasting( _thief );
				thiefAngery();
			}
		}
		
		/**
		 * GAME OBSTACLE LOGIC
		 */		
		public function loseGame():void
		{
			_gameOver = true;
			_thief.remove( Motion );
			
			var timer:Timer = SceneUtil.getTimer( this, SceneUtil.TIMER_ID );
			timer.timedEvents.pop();
			
			_smokePuffGroup.stopSpellCasting( _thief );
			super.stopSceneMotion( false );
			removeFlyingPlatform();
			playerFalls( "SkyChase" );
		}
		
		override protected function finishedRace( ...args ):void
		{
			super.stopSceneMotion( true );
			var first:Entity 		= 		getEntityById( "first" );
			
			var spatial:Spatial 	= 		first.get( Spatial );
			spatial.y 				= 		220;
			spatial.x 				=		Spatial( _thief.get( Spatial )).x;
			
			_smokePuffGroup.poofAt( getEntityById( "first" ), .5, true, jinnAppears, true );
		}
		
		private function jinnAppears():void
		{
			var spatial:Spatial 			=	_thief.get( Spatial );
			spatial.y 						=	225;
			
			shellApi.triggerEvent( _events.SKY_CHASE_COMPLETE, true );
		}
		
		/**
		 * CINEMATICS
		 */
		// PRE GAME
		private function introSequence():void
		{
			SceneUtil.lockInput( this );
			
			CharUtils.setAnim( _thief, Proud );
			var dialog:Dialog = _thief.get( Dialog );
			dialog.sayById( "my_kingdom" );
			dialog.faceSpeaker = false;
			dialog.complete.addOnce( panInCarpet );
			
			SceneUtil.setCameraPoint( this, 0, 0, true );
			shellApi.eventTriggered.add( eventTriggered );
			
			var waveMotionData:WaveMotionData		=	new WaveMotionData( "y", 3, .08 );
			var waveMotion:WaveMotion 				=	new WaveMotion();
			waveMotion.add( waveMotionData );
			_thief.add( waveMotion );
			_thief.add( new SpatialAddition());
		}
		
		private function panInCarpet( dialogData:DialogData ):void
		{
			var spatial:Spatial = player.get( Spatial );
			
//			_viewportRatioY = shellApi.viewportHeight / ScreenManager.GAME_HEIGHT;
	//	spatial.y = _viewportRatioY * ( 620 - .5 * spatial.height );
			spatial.x = shellApi.offsetX( -150 );
			spatial.y = DisplayUtils.localToLocalPoint( new Point( spatial.x, ( shellApi.viewportHeight - ( 4.5 * Edge( player.get( Edge )).rectangle.bottom )) * shellApi.viewportScale ), this.groupContainer.stage, _hitContainer ).y; 
			
			var tween:Tween = new Tween();
			tween.to( spatial, 1.2, { x : 100, onComplete : spottedJinn });
			
			player.add( tween );
			
			SkinUtils.setEyeStates( _thief, EyeSystem.SQUINT );
		}
		
		private function spottedJinn():void
		{
			super.sceneData.bounds.left = 0;
			CharUtils.setDirection( _thief, false );
			
			var dialog:Dialog = player.get( Dialog );
			dialog.sayById( "not_so_fast" );
			dialog.complete.addOnce( thiefTaunt );
		}
		
		private function thiefTaunt( dialogData:DialogData ):void
		{
			CharUtils.setAnim( _thief, Laugh );
			
			var dialog:Dialog = _thief.get( Dialog );
			dialog.sayById( "you_stop_me" );
			dialog.faceSpeaker = true;
			dialog.complete.addOnce( startFirstSpell );
		}
		
		private function startFirstSpell( dialogData:DialogData ):void
		{
			Spatial( getEntityById( "first" ).get( Spatial )).y 	= 	50;
			_smokePuffGroup.startSpellCasting( _thief, true );
			_smokePuffGroup.poofAt( getEntityById( "first" ), 1, true, castFirstSpell, true );
		}
		
		private function castFirstSpell():void
		{
			// DROP ANVIL
			var first:Entity 			=	getEntityById( "first" );
			var display:Display 		=	first.get( Display );
			display.alpha 				= 	1;
			
			var spatial:Spatial 		= 	first.get( Spatial );
			spatial.x 					-=	.5 * spatial.width;
			spatial.y 					=	-spatial.height;
			
			var motion:Motion 			= 	new Motion();
			motion.acceleration 		=	new Point( 0, 0 );
			motion.maxVelocity 			= 	new Point( Infinity, Infinity );
			motion.velocity 			=	new Point( 0, 600 );
			motion.y 					=	-spatial.height;
			
			var threshold:Threshold 	=	new Threshold( "y", ">=" );
			threshold.threshold 		=	shellApi.viewportHeight + display.displayObject.height;
			threshold.entered.addOnce( removeFirstObstacle );
			
			first.add( motion ).add( threshold );
			
			// MOVE PLAYER
			spatial				 		=	player.get( Spatial );
			var tween:Tween 			= 	new Tween();
			tween.to( spatial, 1, { x : spatial.x + 300, onComplete : thatWasClose });
			player.add( tween );
		}
		
		private function thatWasClose():void
		{
			jinnFlysAway();
			
			var dialog:Dialog = player.get( Dialog );
			dialog.sayById( "thatWasClose" );
			
			dialog.complete.addOnce( startChase );
		}
		
		private function removeFirstObstacle():void
		{
			var first:Entity				= 	getEntityById( "first" );
			var display:Display 			=	first.get( Display );
			display.visible 				=	false;
			
			first.remove( Motion );
		}
		
		private function jinnFlysAway():void
		{
			// PAN OUT JINN
			var spatial:Spatial			=	_thief.get( Spatial );
			var tween:Tween 			=	new Tween();
			
			Sleep( _thief.get( Sleep )).ignoreOffscreenSleep  	= 	true;
			
			tween.to( spatial, 1, { y : -100 });//, onComplete : repositionJinn });//, onComplete : syncJinn });
			_thief.add( tween );
		}
		
		private function startChase( dialogData:DialogData ):void
		{
			SceneUtil.lockInput( this, false );	
			super.triggerLayers();
			super.triggerObstacles();
			LoopingSceneUtils.startObstacles( this, _raceSegmentCreator, _obstacles );
			
			addSystem( new LooperCollisionSystem());	
			
			
			var inputSpatial:Spatial = shellApi.inputEntity.get( Spatial );
			var followTarget:FollowTarget 		= new FollowTarget( inputSpatial, .05 );
			followTarget.properties			 	= new <String>["x"];
			followTarget.allowXFlip 			= true;
			player.add( followTarget );
		}
		
//		private function repositionJinn():void
//		{
//			var spatial:Spatial 			=	_thief.get( Spatial );
//			spatial.y 						=	125;
//			
//			var display:Display 			=	_thief.get( Display );
//			display.visible 				=	false;
//			// turn off display
//		}
//		private function syncJinn():void
//		{
//			var spatial:Spatial 			= 	_thief.get( Spatial );
//			spatial.y 						= 	-9000;
//			
//			var motion:Motion				=	new Motion();
//			var motionMaster:MotionMaster	=	player.get( MotionMaster );
//			
//			motion.velocity 				= 	motionMaster.velocity;
//			motion.minVelocity 				= 	new Point( 0, 0 );
//			motion.maxVelocity 				= 	motionMaster.maxVelocity;
//			motion.acceleration 			= 	motionMaster.acceleration;
//			_thief.add( motion );
//		}
		
		// POST GAME
		private function thiefAngery():void
		{
			player.remove( FollowTarget );
			
			var playerFaceRight:Boolean = Spatial( player.get( Spatial )).x < Spatial( _thief.get( Spatial )).x ? true : false;
			MotionUtils.zeroMotion( player );
			
			CharUtils.setDirection( player, playerFaceRight );
			CharUtils.setDirection( _thief, !playerFaceRight );
			
			CharUtils.setAnim( _thief, Stomp, false, 0, 0, true );
			Timeline( _thief.get( Timeline )).handleLabel( "ending", pauseThiefAnim );
			beatThief();
		}	
		
		private function pauseThiefAnim():void
		{
			CharUtils.setAnim( _thief, Stand );
		}
		
		private function beatThief():void
		{
			var dialog:Dialog = _thief.get( Dialog );
			dialog.sayById( "enough_games" );
			dialog.complete.addOnce( startDestroyRug );
		}
		
		private function startDestroyRug( dialogData:DialogData ):void
		{
			_smokePuffGroup.startSpellCasting( _thief, true );
			SceneUtil.addTimedEvent( this, new TimedEvent( .75, 1, destroyRug ), "castTimer" );
		}
		
		private function destroyRug():void
		{
			_smokePuffGroup.castSpell( _thief, new <Entity>[ player ], removeFlyingPlatform, playerFalls, false, false, true );
		}
		
		private function removeFlyingPlatform():void
		{
			CharUtils.setAnim( _thief, Proud, false, 0, 0, true );
			Timeline( _thief.get( Timeline )).handleLabel( "stand", jinnWonPose );
			
			removeEntity( _carpet );
			_carpet = null;
			
			if( _particles )
			{
				removeEntity(this._particles);
				_particles = null;
			}
			
			LoopingSceneUtils.endFlyingPlayer( this, _componentInstances);
		}
		
		private function jinnWonPose():void
		{
			Timeline( _thief.get( Timeline )).stop();
		}
		
		private function playerFalls( scene:String = "Desert" ):void
		{
			player.remove( FollowTarget );
			CharUtils.setAnim( player, Hurt );
			
			var motion:Motion 			=	player.get( Motion );
			motion.acceleration.y		=	MotionUtils.GRAVITY;
			
			var threshold:Threshold		=	new Threshold( "y", ">=" );
			threshold.threshold			=	800;
			threshold.entered.addOnce( Command.create( loadScene, scene ));
			player.add( threshold );
		}
		
		private function loadScene( scene:String ):void
		{
			var nextScene:* = scene == "Desert" ? Desert : SkyChase;
			shellApi.loadScene( nextScene );
		}
		
		public function get smokePuffGroup():SmokePuffGroup { return _smokePuffGroup; }
	}
}