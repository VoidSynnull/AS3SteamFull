package game.scenes.survival5.chase
{	
	import flash.display.BitmapData;
	import flash.display.DisplayObject;
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.geom.Point;
	
	import ash.core.Entity;
	import ash.core.NodeList;
	
	import engine.components.Audio;
	import engine.components.Display;
	import engine.components.Id;
	import engine.components.Interaction;
	import engine.components.Motion;
	import engine.components.MotionBounds;
	import engine.components.Spatial;
	import engine.components.Tween;
	import engine.managers.SoundManager;
	import engine.util.Command;
	
	import game.components.Emitter;
	import game.components.animation.FSMControl;
	import game.components.audio.HitAudio;
	import game.components.entity.Dialog;
	import game.components.entity.Sleep;
	import game.components.entity.character.CharacterMotionControl;
	import game.components.entity.character.CharacterMovement;
	import game.components.entity.character.Rig;
	import game.components.entity.character.part.eye.Eyes;
	import game.components.entity.collider.EmitterCollider;
	import game.components.motion.Destination;
	import game.components.motion.Edge;
	import game.components.motion.FollowTarget;
	import game.components.motion.Looper;
	import game.components.motion.MotionControl;
	import game.components.motion.MotionTarget;
	import game.components.motion.TargetSpatial;
	import game.components.motion.Threshold;
	import game.components.scene.SceneInteraction;
	import game.components.ui.WordBalloon;
	import game.creators.animation.FSMStateCreator;
	import game.creators.entity.EmitterCreator;
	import game.creators.entity.character.CharacterCreator;
	import game.creators.ui.ToolTipCreator;
	import game.data.TimedEvent;
	import game.data.animation.AnimationLibrary;
	import game.data.animation.FrameEvent;
	import game.data.animation.entity.character.AttackRun;
	import game.data.animation.entity.character.Fall;
	import game.data.animation.entity.character.Run;
	import game.data.animation.entity.character.Walk;
	import game.data.animation.entity.character.poptropolis.HurdleJump;
	import game.data.character.LookAspectData;
	import game.data.character.LookData;
	import game.data.display.BitmapWrapper;
	import game.data.scene.characterDialog.DialogData;
	import game.data.tutorials.ShapeData;
	import game.data.tutorials.StepData;
	import game.data.tutorials.TextData;
	import game.managers.ScreenManager;
	import game.nodes.hit.LooperHitNode;
	import game.nodes.ui.WordBalloonNode;
	import game.scene.template.AudioGroup;
	import game.scene.template.CharacterGroup;
	import game.components.entity.LooperCollider;
	import game.components.entity.MotionMaster;
	import game.scenes.survival5.chase.nodes.RunningCharacterStateNode;
	import game.scenes.survival5.chase.scenes.EndlessRunnerScene;
	import game.scenes.survival5.chase.states.RunningCharacterHurt;
	import game.scenes.survival5.chase.states.RunningCharacterJump;
	import game.scenes.survival5.chase.states.RunningCharacterRoll;
	import game.scenes.survival5.chase.states.RunningCharacterRun;
	import game.scenes.survival5.chase.states.RunningCharacterState;
	import game.scenes.survival5.chase.states.RunningCharacterStumble;
	import game.systems.entity.LoopingObjectSystem;
	import game.scenes.survival5.underground.Underground;
	import game.systems.SystemPriorities;
	import game.systems.entity.AnimationLoaderSystem;
	import game.systems.entity.character.states.CharacterState;
	import game.systems.motion.ThresholdSystem;
	import game.ui.elements.DialogPicturePopup;
	import game.ui.tutorial.TutorialGroup;
	import game.util.BitmapUtils;
	import game.util.CharUtils;
	import game.util.DisplayUtils;
	import game.util.EntityUtils;
	import game.util.MotionUtils;
	import game.util.PerformanceUtils;
	import game.util.PlatformUtils;
	import game.util.SceneUtil;
	import game.util.SkinUtils;
	import game.utils.LoopingSceneUtils;
	
	import org.flintparticles.common.actions.Age;
	import org.flintparticles.common.actions.Fade;
	import org.flintparticles.common.actions.ScaleImage;
	import org.flintparticles.common.counters.Blast;
	import org.flintparticles.common.displayObjects.Blob;
	import org.flintparticles.common.initializers.BitmapImage;
	import org.flintparticles.common.initializers.ColorInit;
	import org.flintparticles.common.initializers.Lifetime;
	import org.flintparticles.twoD.actions.Accelerate;
	import org.flintparticles.twoD.actions.Move;
	import org.flintparticles.twoD.actions.MutualGravity;
	import org.flintparticles.twoD.actions.RandomDrift;
	import org.flintparticles.twoD.actions.Rotate;
	import org.flintparticles.twoD.emitters.Emitter2D;
	import org.flintparticles.twoD.initializers.RotateVelocity;
	import org.flintparticles.twoD.initializers.Velocity;
	import org.flintparticles.twoD.zones.EllipseZone;
	import org.flintparticles.twoD.zones.LineZone;
	import org.flintparticles.twoD.zones.PointZone;
	import org.flintparticles.twoD.zones.Zone2D;
	
	public class Chase extends EndlessRunnerScene
	{				
		private const LOST_VAN_BUREN:String 			=	 	"lost_van_buren";
		private const FELL_IN_PIT:String 				=		"fell_in_pit";
		private const REPOSITION_PIT_COVER:String 		=		"reposition_pit_cover";
		private var INPUT_TYPE:String;
		
		private const SKIN_COLOR:uint = 0xcf936a;
		private const HAIR_COLOR:uint = 0x999999;
		
		private const LAND:String			= 	"land";
		private const BARKING:String		= 	"barking";
		private const TRIGGER:String 		=	"trigger";
		private const MALE:String 			=	"male";
		private const VAN_BUREN:String 		=	"survival_vanburen";
		private const CASUAL:String 		= 	"casual";
		private const OPEN:String 			=	"open";
		private const FRONT:String 			=	"front";
		private const STILL:String 			=	"_still";
		private const BREATHLESS:String 	=	"breathless";
		
		// MVB's head velocity
		private const VAN_BUREN_VELOCITY:Number = 12; // 12, 14 - leaves very little room for error, 15 - he'll catch you
		private const HUNTERS:Vector.<String> = new <String>[ "buren", "winston", "dog1", "dog2" ];
		private const HUNTERS_VELOCITY:Vector.<Number> = new <Number>[ 350, 300, 640, 650 ];
		private const HUNTERS_PACE:Vector.<Number> = new <Number>[ 1, 1.2, .3, .5 ];
		
		private var _viewportRatioX:Number;
		private var _viewportRatioY:Number;
		
		private var _playerHead:Entity;
		private var _vanBurenHead:Entity;
		private var _vanBurenTalker:Entity;
		private var _inRange:Boolean = false;
		private var _arrowBehind:Boolean = true;
		private var _stillRunning:Boolean = true;
		private var _setWin:Boolean = false;
		
		private var _tutorialGroup:TutorialGroup;
		private const TUTORIAL_ALPHA:Number = .7;
		
		
		public function Chase()
		{
			super();
		}
		
			// pre load setup
		override public function init(container:DisplayObjectContainer = null):void
		{			
			super.groupPrefix = "scenes/survival5/chase/";
			super.init(container);
		}
		
			// initiate asset load of scene specific assets.
		override public function load():void
		{
			if( shellApi.checkEvent( FELL_IN_PIT ) || shellApi.checkItemEvent( "medal_survival5" ))
			{
				shellApi.loadScene( Underground );
				return;
			}
			super.load();
		}
		
		override protected function addCharacters():void
		{
			super.addCharacters();
			
				// needed for stumble state
			_characterGroup = super.getGroupById( CharacterGroup.GROUP_ID ) as CharacterGroup;
			_characterGroup.preloadAnimations( new <Class>[ AttackRun, HurdleJump ], this );
			_characterGroup.preloadAnimations( new <Class>[ Walk ], this, AnimationLibrary.CREATURE );
			
			_audioGroup = getGroupById( AudioGroup.GROUP_ID ) as AudioGroup;
			var entity:Entity
			for( var number:int = 0; number < HUNTERS.length; number ++ )
			{
				entity = getEntityById( HUNTERS[ number ]);
				
				EntityUtils.removeInteraction( entity );
				var displayObject:MovieClip = Display( entity.get( Display )).displayObject;
				displayObject.mouseChildren = false;
				displayObject.mouseEnabled = false;	
				_characterGroup.addAudio( entity );
				
				_audioGroup.addAudioToEntity( entity );
			}
		}
		
		// all assets ready
		override public function loaded():void
		{	
			super.loaded();
			
			var spatial:Spatial = player.get( Spatial );
			spatial.x = -100;
			spatial.y = 450;
				
			_viewportRatioX = shellApi.viewportWidth / ScreenManager.GAME_WIDTH;
			_viewportRatioY = shellApi.viewportHeight / ScreenManager.GAME_HEIGHT;
			
			setupPlayer();
			LoopingSceneUtils.createMotion(this, cameraStationary, finishedRace);
			
			if( !PlatformUtils.isDesktop )
			{
				INPUT_TYPE = "Tap and release";
			}
			else
			{
				INPUT_TYPE = "Click";
			}
			
			optimizeObstacles();
		}
		
		/**
		 * 
		 * SET UP LOOPING HIT VISUALS AND EMITTERS
		 * 
		 */ 
		private function optimizeObstacles():void
		{
			var clip:MovieClip;
			var entity:Entity;
			var id:Id;
			var number:Number;
			var spatial:Spatial;
			var type:String;
			
				// GET LOOPING HITS AND BITMAP THEIR EMITTER DATA
			var looperEntities:Vector.<Entity> = new Vector.<Entity>;
			var looperHitNodes:NodeList = super.systemManager.getNodeList( LooperHitNode );
			var node:LooperHitNode;
			
			for( node = looperHitNodes.head; node; node = node.next )
			{
				looperEntities.push( node.entity );
			}
			
			var leaf01:BitmapData = BitmapUtils.createBitmapData( _hitContainer[ "leaf1" ]);
			var leaf02:BitmapData = BitmapUtils.createBitmapData( _hitContainer[ "leaf2" ]);
			var deadLeaf:BitmapData = BitmapUtils.createBitmapData( _hitContainer[ "dead_leaf" ]);
			var snow:BitmapData = BitmapUtils.createBitmapData( new Blob( 4 ));
			var splash:BitmapData = BitmapUtils.createBitmapData( new Blob( 4 ));
						
			var emitter2D:Emitter2D;
			var name:String;
			
			var point:Point;
			var angle:Number;
				// ADD SNOW EMITTER TO TREES
			for each( entity in looperEntities )			
			{
				id = entity.get( Id );
				number = Number( id.id.substr( id.id.length - 1 ));
				type = id.id.substr( 0, id.id.length - 1 );
				spatial = entity.get( Spatial );
				
				switch( type )
				{
					case "tree":
						createBitmappedFollower( _hitContainer[ "trunk" + number ], spatial );
						createBitmappedFollower( _hitContainer[ "branch" + number ], spatial, true );
						
						emitter2D = emitterType( snow, 20, .3
							, new ColorInit( 0x99E3F0, 0x309C93 )
							, new EllipseZone( new Point( 0, 0), 5, 1 )
							, new MutualGravity( 2, 10, 2 )
							, new RandomDrift( 20, 0 )
							, new ScaleImage( 1.5, .75 )
							, new Accelerate( 0, 1600 ));
						name = "snowEmitter" + number;
						break;
					
					case "bush":
							// BUSHES HAVE 2 DIFFERENT LEAVES, MAKE HALF OF EACH
						createBitmappedFollower( _hitContainer[ "backBush" + number ], spatial );
						createBitmappedFollower( _hitContainer[ "frontBush" + number ], spatial, true );
						
						point = new Point();
						angle = 10 * Math.PI / 180;
						point.x = point.x + 24 * Math.cos( angle );
						point.y = point.y + 24 * Math.sin( angle );
						
						emitter2D = emitterType( leaf01, 10, .5
							, new ColorInit( 0x41B6E1, 0x4DCBDE )
							, new PointZone( point )
							, new MutualGravity( 1, 30, 1 )
							, new RandomDrift( 50, 10 )
							, new ScaleImage( 1, .6 )
							, new Accelerate( 0, 24 )
							, new RotateVelocity( -10, 10 ));
						addEmitter( entity, emitter2D, "leaf1Emitter" + number );
						
							// SECOND LEAF EMITTER						
						emitter2D = emitterType( leaf02, 10, .5
							, new ColorInit( 0x41B6E1, 0x4DCBDE )
							, new PointZone( point )
							, new MutualGravity( 1, 30, 1 )
							, new RandomDrift( 50, 10 )
							, new ScaleImage( 1, .6 )
							, new Accelerate( 0, 24 )
							, new RotateVelocity( -10, 10 ));
						name = "leaf2Emitter" + number;
						break;
					
					case "puddle":
						createBitmappedFollower( _hitContainer[ "puddleBase" + number ], spatial );
						createBitmappedFollower( _hitContainer[ "puddleFront" + number ], spatial, true );
						
						emitter2D = emitterType( splash, 20, .5
							, new ColorInit( 0x4F7A9E, 0x6BA4D4 )
							, new LineZone( new Point( -10, -50 ), new Point( 10, -50 ))
							, new MutualGravity( 1, 10, 1 )
							, new RandomDrift( 14, 10 )
							, new ScaleImage( 1, .5 )
							, new Accelerate( 0, 80 ));
						name = "splashEmitter" + number;
						break;
					
					case "pit":
						createBitmappedFollower( _hitContainer[ "hole" ], spatial );
						createBitmappedFollower( _hitContainer[ "grassCover" ], spatial, true );
							
						emitter2D = emitterType( deadLeaf, 20, .5
							, new ColorInit( 0x597D4E, 0x737D4E )
							, new LineZone( new Point( -10, -90 ), new Point( 10, -90 ))
							, new MutualGravity( 1, 30, 1 )
							, new RandomDrift( 50, 10 )
							, new ScaleImage( 1, .6 )
							, new Accelerate( 0, 15 )
							, new RotateVelocity( -10, 10 ));
						name = "pitfallEmitter";
						break;
				}
				
				addEmitter( entity, emitter2D, name );
			}
			
				// SETUP ARROW VB WILL SHOOT WHEN HOT ON YOUR TRAIL
			entity = createBitmappedFollower( _hitContainer[ "arrow" ]);
			entity.add( new Threshold()).add( new Sleep( false, true ));
			_audioGroup.addAudioToEntity( entity );				
			
				// SETUP LEAF PILE THAT WILL LOOP THROUGHOUT THE SCENE
			createBitmappedFollower( _hitContainer[ "leafPile" ]);
			
			var introPopup:DialogPicturePopup = new DialogPicturePopup( overlayContainer );
			introPopup.updateText( "                                           Survive!", "start" );
			introPopup.configData( "introPopup.swf", "scenes/survival5/chase/" );
			introPopup.popupRemoved.addOnce( startRunning );
			addChildGroup( introPopup );
		}

		private function createBitmappedFollower( displayObject:DisplayObject, spatial:Spatial = null, moveToFront:Boolean = false ):Entity
		{
			var wrapper:BitmapWrapper = DisplayUtils.convertToBitmapSprite( displayObject, null, NaN, true );//, container );
			var entity:Entity = EntityUtils.createMovingEntity( this, wrapper.sprite );
			entity.add( new Id( displayObject.name ));
			
			if( spatial )
			{
				entity.add( new FollowTarget( spatial ));
			}
			
			return entity;
		}
		
		private function emitterType( bitmapData:BitmapData, particleNum:Number, lifetime:Number, color:ColorInit, velocityZone:Zone2D, gravity:MutualGravity, drift:RandomDrift, scale:ScaleImage, acceleration:Accelerate, rotateVelocity:RotateVelocity = null ):Emitter2D 
	  	{
		  var emitter:Emitter2D = new Emitter2D();
		  emitter.counter = new Blast( particleNum );
		  emitter.addInitializer( new BitmapImage( bitmapData, true, 2 * particleNum ));
		  emitter.addInitializer( new Lifetime( lifetime ));
		  emitter.addInitializer( color );
		  emitter.addInitializer( new Velocity( velocityZone ));
			  
		  emitter.addAction( new Move());
		  emitter.addAction( new Fade( 1, .5 ));			
		  emitter.addAction( new Age());
		  emitter.addAction( gravity );
		  emitter.addAction( drift );
		  emitter.addAction( acceleration );
		  
		  if( rotateVelocity )
		  {
			  emitter.addInitializer( rotateVelocity );
			  emitter.addAction( new Rotate());
		  }
		  return emitter;
	  	}
		
		private function addEmitter( entity:Entity, emitter:*, name:String ):void
		{
			var looper:Looper = entity.get( Looper );
			var spatial:Spatial = entity.get( Spatial );
			
			var emitterEntity:Entity = EmitterCreator.create( this, _hitContainer, emitter, -.5 * spatial.width, 0, entity, name, spatial, false );
			if( !looper.emitters )
			{
				looper.emitters = new Vector.<Emitter>;
			}
			looper.emitters.push( emitterEntity.get( Emitter ));
		}
		
		/**
		 * 
		 * SCENE SPECIFIC EDITS TO PLAYER AND ANIMATIONS
		 * 
		 */
		override protected function setupPlayer( fileName:String = "motionMaster.xml"  ):void
		{
			super.setupPlayer(fileName);
			
			SkinUtils.setSkinPart( player, SkinUtils.MOUTH, "breathless", false, null, true );
			var animationLoader:AnimationLoaderSystem = super.getSystem( AnimationLoaderSystem ) as AnimationLoaderSystem;
			
			var runAnimation:Run = animationLoader.animationLibrary.getAnimation( Run ) as Run;
			runAnimation.data.frames[0].events[0].args[0] = OPEN;

			var lookData:LookData = SkinUtils.getLook( player );
			var eyeState:LookAspectData = lookData.getAspect( "eyeState" );
			eyeState.value = OPEN + STILL;
			var mouthState:LookAspectData = lookData.getAspect( "mouth" );
			mouthState.value = BREATHLESS;
			
			var verticalPosition:Number = _viewportRatioY * 600;
			var horizontalPosition:Number = _viewportRatioX * 30;
			
			var ui:Entity = EntityUtils.createSpatialEntity( this, _hitContainer[ "chaseBar" ], overlayContainer );
			ui.add( new Id( "ui" ));
			var display:Display = ui.get( Display );
		//	display.visible = false;
			
			// setup trail ui
			var spatial:Spatial = ui.get( Spatial );
			spatial.width = _viewportRatioX * 940;
			spatial.y = verticalPosition;
			spatial.x = _viewportRatioX * 480;
			
			
			_playerHead = _characterGroup.createDummy( "playerHead", lookData, "right", CharacterCreator.VARIANT_HEAD, this.overlayContainer
				, null, null, false, NaN, CharacterCreator.TYPE_PORTRAIT, new Point( horizontalPosition, verticalPosition ));
			
			_vanBurenTalker = getEntityById( "vanBurenTalker" );
			lookData = SkinUtils.getLook( _vanBurenTalker );
			eyeState = lookData.getAspect( "eyeState" );
			eyeState.value = CASUAL + STILL;
			
			_vanBurenHead = _characterGroup.createDummy( "vanBurenHead", lookData, "right", CharacterCreator.VARIANT_HEAD, this.overlayContainer
				, null, null, false, NaN, CharacterCreator.TYPE_PORTRAIT, new Point( horizontalPosition, verticalPosition ));
			
			display = _vanBurenTalker.get( Display );
			this.uiLayer.addChildAt(display.displayObject, 0);
			display.visible = false;
			
			_audioGroup.addAudioToEntity( _vanBurenTalker );
			
			removeMouseDetection( new <Entity>[ _vanBurenTalker, _vanBurenHead, _playerHead ]);
			
			var dialog:Dialog = _vanBurenTalker.get( Dialog );
			dialog.complete.add( hideVanBurenTalkingHead );
			
		}
		
		private function removeMouseDetection( entities:Vector.<Entity> ):void
		{
			var display:Display;
			var entity:Entity;
			
			for each( entity in entities )
			{
				ToolTipCreator.removeFromEntity( entity );
				display = entity.get( Display );
				display.visible = false;
				display.displayObject.mouseChildren = false;
				display.displayObject.mouseEnabled = false;	
			}
		}
		
		/**
		 * 
		 * INTRO CINEMATICS
		 * 
		 */
		private function startRunning():void
		{
			SceneUtil.lockInput( this );
			
			super.shellApi.eventTriggered.add( eventTriggers );
			
				// SETUP VAN_BUREN, WINSTON AND THE DOGS WITH FMS
			for( var number:int = 0; number < HUNTERS.length; number ++ )
			{
				setupHunters( getEntityById( HUNTERS[ number ]), _characterGroup, HUNTERS_VELOCITY[ number ]);
			}
			
			moveToCenter();		
			player.remove( EmitterCollider );
		}
		
		private function setupHunters( character:Entity, characterGroup:CharacterGroup, runVelocity:Number ):void
		{
			characterGroup.addFSM( character );
			character.remove( EmitterCollider );
			CharacterMotionControl( character.get( CharacterMotionControl )).minRunVelocity = runVelocity;	
			
			character.remove( SceneInteraction );
			character.remove( Interaction );
			
			var display:Display = character.get( Display );
			display.displayObject.mouseChildren = false;
			display.displayObject.mouseEnabled = false;
			display.setContainer( _hitContainer[ "characterSpace" ]);
			
//			if( character.get( Id ).id == "dog2" )
//			{
//				character.add( new Tween()).add( new LooperCollider()).add( new HitAudio());
//			}
		}
		
		private function eventTriggers( event:String, save:Boolean = true, init:Boolean = false, removeEvent:String = null ):void
		{
			var arrow:Entity;
			var audio:Audio;
			var charMovement:CharacterMovement;
			var dialog:Dialog;
			var display:Display;
			var fsmControl:FSMControl;
			var leafPile:Entity;
			var motion:Motion;
			var motionBounds:MotionBounds;
			var motionMaster:MotionMaster;
			var runningState:RunningCharacterRun;
			var spatial:Spatial;
			var threshold:Threshold;
			
			switch( event )
			{
				case "tally-ho":	
					dialog = _vanBurenTalker.get( Dialog );
					dialog.start.addOnce( toggleTallyHoLength );

					audio = _vanBurenTalker.get( Audio );
					audio.playCurrentAction( TRIGGER );
					
						//START VAN BUREN CHASE 
					display = _vanBurenHead.get( Display );
					display.visible = true;
					
					motion = new Motion();
					motion.velocity.x = VAN_BUREN_VELOCITY;
					
					_vanBurenHead.add( motion );
					
					threshold = new Threshold( "x", ">=", _playerHead, -100 );
					threshold.entered.addOnce( vanBurenCanAttack );
					
					_vanBurenHead.add( threshold );
					break;
				
				case REPOSITION_PIT_COVER:
					leafPile = getEntityById( "leafPile" );
					threshold = leafPile.get( Threshold );
					
						// REMOVE LOOPING BEHAVIOR AND POSITION OVER PIT
					threshold.entered.removeAll();
					threshold.entered.addOnce( coverPitTrap );
					break;
				
				case LOST_VAN_BUREN:
					_stillRunning = false;
					motionMaster = player.get( MotionMaster );
					motionMaster.velocity.x -= 300;
					motionMaster.acceleration.x = 0;
					motionMaster.active = false;
					
					toggleLooperEvent( LOST_VAN_BUREN );
					arrow = getEntityById( "arrow" );
					spatial = arrow.get( Spatial );
					motion = arrow.get( Motion );
					
					if( spatial.x > 0 )
					{
						threshold = arrow.get( Threshold );
						if( motion.velocity.y != 0 )
						{
							_setWin = true;
						}
						else
						{
							threshold.entered.addOnce( triggerThePit );
						}
					}
					else
					{
						triggerThePit();
					}
					
					fsmControl = player.get( FSMControl );
					runningState = fsmControl.getState( RunningCharacterState.RUN ) as RunningCharacterRun;
					removeInput();
					
						// KILL THE UI
					removeEntity( getEntityById( "ui" ) );
					removeEntity( _vanBurenHead );
					removeEntity( _playerHead );
					break;
				
				case FELL_IN_PIT:
					stopSceneMotion();
					motion = player.get( Motion );
					motion.velocity.x = 0;
					motion.acceleration.y = MotionUtils.GRAVITY;
					CharUtils.setAnim( player, Fall );
					
					motionBounds = player.get( MotionBounds );
					motionBounds.box.bottom = 700;
					
					threshold = new Threshold( "y", ">=" );
					threshold.threshold = 600;
					threshold.entered.add( vanBurenEnters );
					
					player.add( threshold );
					
						// KILL THE PIT COVER
					leafPile = getEntityById( "leafPile" );
					display = leafPile.get( Display );
					display.visible = false;
					
					getEntityById( "pit1" ).remove( LooperCollider );
					break;
				
				default:
					break;
			}
		}
		
		private function toggleTallyHoLength( dialogData:DialogData ):void
		{
			var wordBalloonNodes:NodeList = super.systemManager.getNodeList( WordBalloonNode );
			var wordBalloonNode:WordBalloonNode = wordBalloonNodes.head;
			var wordBalloon:WordBalloon = wordBalloonNode.wordBalloon;
			wordBalloon.lifespan = 1.25;
		}
		
		private function moveToCenter():void
		{
			var motion:Motion = player.get( Motion );
			motion.maxVelocity.x = 500;
			motion.minVelocity.x = 500;
			motion.velocity.x = 500;
			
			var display:Display = player.get( Display );
			display.setContainer( _hitContainer[ "characterSpace" ]);
			
			CharUtils.setDirection( player, true );
			CharacterMotionControl( player.get( CharacterMotionControl )).minRunVelocity = 500;
			var destination:Destination = MotionUtils.followPath( player, new < Point >[ new Point( shellApi.viewportWidth / 4, sceneData.bounds.bottom )], startMotion, true );
			destination.motionToZero.push( "x" );	
			FSMControl( player.get( FSMControl )).setState( CharacterState.SKID );
		}
		
		private function startMotion( player:Entity ):void
		{
			CharUtils.setDirection( player, true );
			
			addStates();
			player.remove( Destination );
			super.addSystem( new ThresholdSystem(), SystemPriorities.update );
			
			CharacterMovement( player.get( CharacterMovement )).active = false;   
			
				// SET PLAYER HEAD'S EYES AND EYESTATE
			trace(_playerHead);
			var eyes:Eyes = Rig( _playerHead.get( Rig )).getPart( "eyes" ).get( Eyes );
			eyes.pupilState = FRONT;
			
			triggerLayers();
			giveHimSomeRoom();
		}
		
		/**
		 * 
		 * PLAYER'S GRACE PERIOD
		 * 
		 */
		private function giveHimSomeRoom():void
		{
			var dialog:Dialog = _vanBurenTalker.get( Dialog );
			var display:Display = _vanBurenTalker.get( Display );	
			display.visible = true;
			
			var lookData:LookData = SkinUtils.getLook( player );
			var lookAspectData:LookAspectData = lookData.getAspect( "gender" );
			if( lookAspectData.value == MALE )
			{
				dialog.sayById( "start" );
			}
			else
			{
				dialog.sayById( "start_lass" );
			}
			dialog.complete.addOnce( startGracePeriod );
		}
		
		private function startGracePeriod( dialogData:DialogData ):void
		{
			var display:Display = _playerHead.get( Display );
			display.visible = true;
			
			display = getEntityById( "ui" ).get( Display );
			display.visible = true;
			
		//	display = _vanBurenTalker.get( Display );
		//	display.visible = false;
			
			var motionMaster:MotionMaster = player.get( MotionMaster );
			motionMaster._distanceX = 0;
			motionMaster._distanceY = 0;
			
			var fsmControl:FSMControl = player.get( FSMControl );
			var type:String;
			var state:RunningCharacterState;

			for each( type in RunningCharacterState.STATES )
			{
				state = fsmControl.getState( type ) as RunningCharacterState;
				state.addUIHead( _playerHead, _viewportRatioX );
			}
			
			triggerObstacles();
			
			var loopingObjectNodes:NodeList = super.systemManager.getNodeList( LooperHitNode );
			var loopingObjectNode:LooperHitNode;
			var threshold:Threshold = new Threshold( "x", "<=", player, 200 );
			
			for( loopingObjectNode = loopingObjectNodes.head; loopingObjectNode; loopingObjectNode = loopingObjectNode.next )
			{
				if( !loopingObjectNode.sleep.sleeping )
				{
					threshold.entered.addOnce( tutorialPart1 );
					loopingObjectNode.entity.add( threshold );
				}
			}
		}	
		
		/**
		 * 
		 * TUTORIAL
		 * 
		 */
		private function tutorialPart1():void
		{
			var loopingObjectSystem:LoopingObjectSystem = getSystem( LoopingObjectSystem ) as LoopingObjectSystem;
			loopingObjectSystem.wakeSignal.addOnce( prepTutorial2 );
			
			CharUtils.setDirection( player, true );
			var stepDatas:Vector.<StepData> = new Vector.<StepData>();
			var shapes:Vector.<ShapeData> = new Vector.<ShapeData>();
			var texts:Vector.<TextData> = new Vector.<TextData>();
			
			var spatial:Spatial = player.get( Spatial );
			var edge:Edge = player.get( Edge );
			
			shapes.push( new ShapeData( ShapeData.RECTANGLE, new Point( 0, 0 ), shellApi.viewportWidth, spatial.y * _viewportRatioY , "roll" ));
			texts.push( new TextData( INPUT_TYPE + " above the player to jump over puddles and shrubs", "tutorialwhite", new Point( 330 * _viewportRatioX, 480 * _viewportRatioY )));
			var jumpStep:StepData = new StepData( "jump", TUTORIAL_ALPHA, 0x000000, 0, true, shapes, texts );
			stepDatas.push( jumpStep );	
			
			super.stopSceneMotion();
			var tutorialGroup:TutorialGroup = new TutorialGroup( overlayContainer, stepDatas );
			this.addChildGroup( tutorialGroup );
			tutorialGroup.start();
			tutorialGroup.complete.addOnce( setJumpState );
		}
		
		private function prepTutorial2( node:LooperHitNode ):void
		{
			if( node.id.id.indexOf( "tree" ) > -1 )
			{
				var threshold:Threshold = new Threshold( "x", "<=", player, 200 );
				threshold.entered.addOnce( tutorialPart2 );
				node.entity.add( threshold );
				
				var tutorialGroup:TutorialGroup = getGroupById( TutorialGroup.GROUP_ID ) as TutorialGroup;
				super.removeGroup( tutorialGroup );
			}
		}
		
		private function tutorialPart2():void
		{
			var stepDatas:Vector.<StepData> = new Vector.<StepData>();
			var shapes:Vector.<ShapeData> = new Vector.<ShapeData>();
			var texts:Vector.<TextData> = new Vector.<TextData>();
			var spatial:Spatial = player.get( Spatial );
			
			shapes.push( new ShapeData( ShapeData.RECTANGLE, new Point( 0, spatial.y * _viewportRatioY ), shellApi.viewportWidth, shellApi.viewportHeight * .5 ));
			texts.push( new TextData( INPUT_TYPE + " below the player to roll under tree branches", "tutorialwhite", new Point( 330 * _viewportRatioX, 250 * _viewportRatioY )));
			var rollStep:StepData = new StepData( "roll", TUTORIAL_ALPHA, 0x000000, 0, true, shapes, texts );
			stepDatas.push( rollStep );
			
			super.stopSceneMotion();
			var tutorialGroup:TutorialGroup = new TutorialGroup( overlayContainer, stepDatas );
			this.addChildGroup( tutorialGroup );
			tutorialGroup.start();
			tutorialGroup.complete.addOnce( startTheHunt );
		}
		
		private function setJumpState( tutorialGroup:TutorialGroup ):void
		{
			super.restartSceneMotion();
			var fsmControl:FSMControl = player.get( FSMControl );
			fsmControl.setState( RunningCharacterState.JUMP  );
		}
		
		/**
		 * 
		 * VAN BUREN STARTS CHASING
		 * 
		 */
		private function startTheHunt( tutorialGroup:TutorialGroup ):void
		{
			super.restartSceneMotion();
			super.removeGroup( tutorialGroup );
			var fsmControl:FSMControl = player.get( FSMControl );
			fsmControl.setState( RunningCharacterState.ROLL );

			var display:Display = _vanBurenTalker.get( Display );
			display.visible = true;
			
			var dialog:Dialog = _vanBurenTalker.get( Dialog );
			dialog.sayById( "chase" );
			
			SceneUtil.lockInput( this, false );
		}
		
		private function hideVanBurenTalkingHead( dialogData:DialogData ):void
		{
			var display:Display = _vanBurenTalker.get( Display );
			display.visible = false;
			
				// START THE LEAF PILE MOTION
			var leafPile:Entity = getEntityById( "leafPile" );
			var motion:Motion = leafPile.get( Motion );
			var spatial:Spatial = leafPile.get( Spatial );
			
			var threshold:Threshold = new Threshold( "x", "<=" );
			threshold.threshold = -spatial.width * _viewportRatioX;
			threshold.entered.add( repositionLeaves );
			
			var motionMaster:MotionMaster = player.get( MotionMaster );
			motion.velocity = motionMaster.velocity;
			motion.acceleration = motionMaster.acceleration;
			motion.maxVelocity = motionMaster.maxVelocity;
			motion.minVelocity = motionMaster.minVelocity;
			
			leafPile.add( threshold );
		}
		
		/**
		 * 
		 * PIT COVER LOGIC
		 * 
		 */
		private function repositionLeaves():void
		{
			var leafPile:Entity = getEntityById( "leafPile" );
			var spatial:Spatial = leafPile.get( Spatial );
			
			spatial.x = shellApi.viewportWidth + spatial.width * _viewportRatioX;
		}
		
		private function coverPitTrap():void
		{
			var leafPile:Entity = getEntityById( "leafPile" );
			var spatial:Spatial = leafPile.get( Spatial );
			var pit:Entity = getEntityById( "pit1" );
		
			leafPile.remove( Motion );
			leafPile.add( new FollowTarget( pit.get( Spatial )));
		}
		
		/**
		 * 
		 * VAN BUREN STARTS ATTACKING
		 * 	ya know, cause he's like right on your tail
		 *
		 */
		private function vanBurenCanAttack():void
		{
				// TOGGLE MVB's EYE STATE AND LOSE STATE THRESHOLD
			var threshold:Threshold;
			
			if( _stillRunning )
			{
				if( !_inRange )
				{
					SkinUtils.setEyeStates( _vanBurenHead, "mean_still", "forward" );
					_inRange = true;
					
					_vanBurenHead.remove( Threshold );
					
					threshold = new Threshold( "x", ">=", _playerHead, -10 ); // -20
					threshold.entered.addOnce( vanBurenCaughtUp );
					
					_vanBurenHead.add( threshold );
					
					if( PerformanceUtils.qualityLevel >= PerformanceUtils.QUALITY_MEDIUM )
					{	
						sendInTheHounds();
					}
				}
				
				if( PerformanceUtils.qualityLevel >= PerformanceUtils.QUALITY_MEDIUM )
				{
					var arrow:Entity = getEntityById( "arrow" );
					var spatial:Spatial = arrow.get( Spatial );
					spatial.x = -100 * _viewportRatioX;
					spatial.y = 350 * _viewportRatioY;
					spatial.rotation = 180;
					
					var audio:Audio = arrow.get( Audio );
					audio.playCurrentAction( TRIGGER );				
					
					var motion:Motion = arrow.get( Motion );
					motion.velocity = new Point( 600, 100 );
					motion.rotationVelocity = 10;
					
					arrow.remove( Threshold );
					var target:Number = setArc( arrow );
					
					threshold = new Threshold( "y", ">=" );
					threshold.threshold = target;
					threshold.entered.addOnce( arrowLands );
					arrow.add( threshold );
				}
				
					// TRIGGER DOG BARKS
				audio = getEntityById( "vanBurenTalker" ).get( Audio );
				if( audio.isPlaying( SoundManager.EFFECTS_PATH + "dog_barking_01.mp3" ))
				{
					if( audio._playing[ 0 ].volumeModifiers[ "base" ] < 10 )
					{
						audio._playing[ 0 ].volumeModifiers[ "base" ] += .5;
						audio._playing[ 1 ].volumeModifiers[ "base" ] += .5;
					}
				}
				else
				{
					audio.playCurrentAction( BARKING );
				}
			}
		}
		
		private function sendInTheHounds():void
		{
			if( _inRange && _stillRunning )
			{
				var dog:Entity = getEntityById( "dog2" );
				var spatial:Spatial = player.get( Spatial );
				var headSpatial:Spatial = _playerHead.get( Spatial );
				var vbSpatial:Spatial = _vanBurenHead.get( Spatial );
				
				if( !dog.get( LooperCollider ))
				{
					dog.add( new LooperCollider()).add( new HitAudio()).add( new Tween());
				}
				
				CharUtils.moveToTarget( dog, 100 - Math.round( headSpatial.x - vbSpatial.x ), spatial.y, true, houndsFalter );
			}
		}
		
		private function houndsFalter( dog:Entity ):void
		{
			var spatial:Spatial = dog.get( Spatial );
			
			CharUtils.setAnim( dog, Run );
			var tween:Tween = dog.get( Tween );;
			tween.to( spatial, 2, { x : -100, onComplete : composeYourself  });
		}
		
		private function composeYourself():void
		{
			if( _inRange && _stillRunning )
			{
				SceneUtil.addTimedEvent( this, new TimedEvent(( Math.random() * 3 ) + 2, 1, sendInTheHounds ));
			}
		}
		
		private function setArc( arrow:Entity ):Number
		{
			var target:Number;
			var display:Display = arrow.get( Display );
			_arrowBehind = !_arrowBehind;
			
			if( _arrowBehind )
			{
				display.container.setChildIndex( display.displayObject, 0 );
				target = 450;
			}
			else
			{
				display.container.setChildIndex( display.displayObject, display.container.numChildren - 1 );
				target = 485;
			}
			
			return target;
		}
		
		private function arrowLands():void
		{
			var arrow:Entity = getEntityById( "arrow" );
			var audio:Audio = arrow.get( Audio );
			var motion:Motion = arrow.get( Motion );
			var motionMaster:MotionMaster = player.get( MotionMaster );
			var threshold:Threshold;
			
			if( Math.random() < .5 )
			{
				audio.playCurrentAction( LAND + "1" );
			}
			else
			{
				audio.playCurrentAction( LAND + "2" );
			}
			
			if( _stillRunning )
			{
				var spatial:Spatial = arrow.get( Spatial );
				
				motion.velocity = motionMaster.velocity;
				motion.rotationVelocity = 0;
				
				arrow.remove( Threshold );
				
				threshold = new Threshold( "x", "<=" );
				threshold.threshold = -50;
				threshold.entered.addOnce( resetArrow );
				arrow.add( threshold );
			}
			else
			{
					// got caught
				if( !shellApi.checkEvent( LOST_VAN_BUREN ))
				{
					arrow.remove( Motion );
				}
					// made it out alive
				else
				{ 
					var sleep:Sleep = arrow.get( Sleep );
					sleep.ignoreOffscreenSleep = false;
					
					motion.velocity.x = motionMaster.velocity.x;
					motion.acceleration = new Point( 0, 0 );
					motion.velocity.y = 0;
					motion.rotationVelocity = 0;
					
					arrow.remove( Threshold );
					threshold = new Threshold( "x", "<=" );
					threshold.threshold = -50;
					threshold.entered.addOnce( triggerThePit );
					arrow.add( threshold );
				}
			}
		}
		
		private function resetArrow():void
		{
			if( _stillRunning )
			{
				var arrow:Entity = getEntityById( "arrow" );
				var motion:Motion = arrow.get( Motion );
				motion.velocity = new Point( 0, 0 );
				var threshold:Threshold;
				
				if( checkInRange())
				{
					vanBurenCanAttack();
				}
				else
				{
					SkinUtils.setEyeStates( _vanBurenHead, "casual_still", "forward" );
					_inRange = false;
					
					threshold = new Threshold( "x", ">=", _playerHead, -100 );
					threshold.entered.addOnce( vanBurenCanAttack );
					threshold.entered.addOnce( sendInTheHounds );
					_vanBurenHead.remove( Threshold );
					_vanBurenHead.add( threshold );
				}
			}
		}
		
		private function checkInRange():Boolean
		{
			if( _stillRunning )
			{
				var spatial:Spatial = _playerHead.get( Spatial );
				var vbSpatial:Spatial = _vanBurenHead.get( Spatial );
				
				return ( spatial.x - vbSpatial.x < 100 );
			}
			else
			{
				return false;
			}
		}
		
		/**
		 * 
		 * FAIL CINEMATIC
		 * 
		 */
		private function vanBurenCaughtUp():void
		{
			_stillRunning = false;
			
			if( PerformanceUtils.qualityLevel >= PerformanceUtils.QUALITY_MEDIUM )
			{
				
				var arrow:Entity = getEntityById( "arrow" );
				var motion:Motion = arrow.get( Motion );
				
				if( motion.velocity.y == 0 )
				{
					arrow.remove( Motion );
				}
			}
			
			sceneData.bounds.right = 1200 * _viewportRatioX;
			var fsmControl:FSMControl = player.get( FSMControl );
			var runningState:RunningCharacterRun = fsmControl.getState( RunningCharacterState.RUN ) as RunningCharacterRun;
			
			var leafPile:Entity = getEntityById( "leafPile" );
			leafPile.remove( Motion );
			
			removeInput();
			SceneUtil.lockInput( this );
			
			MotionMaster( player.get( MotionMaster )).active = false;
			CharacterMovement( player.get( CharacterMovement )).active = true;   
			
			var charMovement:CharacterMovement = player.get( CharacterMovement );
			charMovement.state = CharacterMovement.GROUND;
			
				// KILL THE UI
			removeEntity(  getEntityById( "ui" ) );
			removeEntity( _vanBurenHead );
			removeEntity( _playerHead );
			
			stopSceneMotion();   
			
			CharUtils.moveToTarget( player, 1200 * _viewportRatioX, 475, true, triggerFollowers );
		}
		
		private function triggerFollowers( player:Entity ):void
		{
			var fsmControl:FSMControl = player.get( FSMControl );
			var runningState:RunningCharacterRun = fsmControl.getState( RunningCharacterState.RUN ) as RunningCharacterRun;
			runningState.stopMotion();
			var handler:Function;
			var display:Display;
			var hunter:Entity;
			
			for( var number:int = 0; number < HUNTERS.length; number ++ )
			{
				handler = null;
				hunter = getEntityById( HUNTERS[ number ]);
				if( number == 1 )
				{
					handler = caughtPlayer;
				}
				
				addLooperCollider( hunter, HUNTERS_PACE[ number ], sceneData.bounds.right, handler );
			}
		}
		
		private function addLooperCollider( character:Entity, time:Number, width:Number, handler = null, addCollider:Boolean = true ):void
		{
			if( !character.has( LooperCollider ) && addCollider )
			{
				character.add( new LooperCollider()).add( new HitAudio());
			}
			SceneUtil.addTimedEvent( this, new TimedEvent( time, 1, Command.create( repositionForEnding, character, width, handler )));
		}
		
		private function caughtPlayer( charcater:Entity ):void
		{
			var audio:Audio = getEntityById( "vanBurenTalker" ).get( Audio );
			audio.stop( SoundManager.EFFECTS_PATH + "dog_barking_01.mp3" );
			audio.stop( SoundManager.EFFECTS_PATH + "dog_barking_02.mp3" );
				
			SceneUtil.lockInput( this, false );
			var caughtPopup:DialogPicturePopup = new DialogPicturePopup( overlayContainer );
			caughtPopup.updateText( "You've been caught! Outrun Van Buren to stay alive!", "try again" );
			caughtPopup.configData( "caughtPopup.swf", "scenes/survival5/chase/" );
			caughtPopup.popupRemoved.addOnce( restart );
			addChildGroup( caughtPopup );
		}
		
		private function restart():void
		{
			shellApi.loadScene( Chase, -100, 475 );
		}
		
		/**
		 * 
		 * WIN CINEMATIC
		 * 
		 */		
		private function triggerThePit():void
		{
			var charMovement:CharacterMovement = player.get( CharacterMovement );
			charMovement.state = CharacterMovement.GROUND;
			CharUtils.moveToTarget( player, shellApi.viewportWidth * .75, 475, true );
		}
		
		private function vanBurenEnters():void
		{
			var audio:Audio = getEntityById( "vanBurenTalker" ).get( Audio );
			audio.stop( SoundManager.EFFECTS_PATH + "dog_barking_01.mp3" );
			audio.stop( SoundManager.EFFECTS_PATH + "dog_barking_02.mp3" );
			
			
			Display( player.get( Display )).visible = false;
			var width:Number;
			sceneData.bounds.bottom = 475;
			var handler:Function;
			
			for( var number:int = 0; number < HUNTERS.length; number ++ )
			{
				handler = null;
				switch( number )
				{
					case 0:
						width = shellApi.viewportWidth * .25;
						break;
					case 1:
						width = shellApi.viewportWidth * .15;
						handler = lostHim;
						break;
					case 2: 
						width = shellApi.viewportWidth * .25 + ( Math.random() * 50 ) - 25;
						break;
					case 3:
						width = shellApi.viewportWidth * .25 + ( Math.random() * 50 ) - 25;
						getEntityById( HUNTERS[ number ]).remove( LooperCollider );
						getEntityById( HUNTERS[ number ]).remove( HitAudio );
						break;
				}
				
				addLooperCollider( getEntityById( HUNTERS[ number ]), HUNTERS_PACE[ number ], width, handler, false );
			}
		}
		
		private function repositionForEnding( entity:Entity, endingX:Number, handler:Function = null ):void
		{			
			CharUtils.moveToTarget( entity, endingX, 475, true, handler );
		}
		
		private function setDogTrackAnim():void
		{
			// DOG'S HUNT ANIMATION
			var animationLoader:AnimationLoaderSystem = super.getSystem( AnimationLoaderSystem ) as AnimationLoaderSystem;
			
			var creatureWalkAnimation:Walk = animationLoader.animationLibrary.getAnimation( Walk, AnimationLibrary.CREATURE ) as Walk;
			var delta:Number;
			
			for( var number:int = 0; number < creatureWalkAnimation.data.duration - 1; number ++ )
			{
				// REPOSITION HANDS SO IT LOOKS LIKE HE IS TRACKING
				creatureWalkAnimation.data.parts[ "arm1" ].kframes[ number ].y += 20;
				creatureWalkAnimation.data.parts[ "arm2" ].kframes[ number ].y += 20;
				creatureWalkAnimation.data.parts[ "hand1" ].kframes[ number ].x -= 20; 
				creatureWalkAnimation.data.parts[ "hand2" ].kframes[ number ].x -= 20;
				creatureWalkAnimation.data.parts[ "foot1" ].kframes[ number ].x += 10;
				creatureWalkAnimation.data.parts[ "foot2" ].kframes[ number ].x += 10;
				
				// LOWER THE DIFFERENCE IN HEAD BOBBING
				delta = creatureWalkAnimation.data.parts[ "neck" ].kframes[ number ].y % 5;
				creatureWalkAnimation.data.parts[ "neck" ].kframes[ number ].y = delta + 70;
				delta = creatureWalkAnimation.data.parts[ "neck" ].kframes[ number ].x % 2;
				creatureWalkAnimation.data.parts[ "neck" ].kframes[ number ].x = delta - 5;
				
				creatureWalkAnimation.data.parts[ "body" ].kframes[ number ].y += 10;
				creatureWalkAnimation.data.parts[ "body" ].kframes[ number ].rotation -= 30;
			}
			
			var frameEvent:FrameEvent = new FrameEvent( "setEyes", "squint", "down" );
			creatureWalkAnimation.data.frames[ 0 ].events.pop();
			creatureWalkAnimation.data.frames[ 0 ].events.push( frameEvent );
		}
		
			// HAVE THEM WALK BACK AND FORTHER WITH PAUSES AT EITHER END
		private function moveToAlphaPoint( character:Entity ):void
		{
			var id:Id = character.get( Id );
			var point:Point;
			var time:Number;
			var display:Display = character.get( Display );
			CharacterMotionControl( character.get( CharacterMotionControl )).maxVelocityX = 120;
			
			if( id.id == "dog1" )
			{
				point = new Point( -shellApi.viewportWidth * .1, 475 );
				time = Math.random() * 3;
			}
			else
			{
				point = new Point( -shellApi.viewportWidth * .07, 475 );	
				time = Math.random() * 3;
			}
			
			display.container.setChildIndex( display.displayObject, display.container.numChildren - 1 );
			SceneUtil.addTimedEvent( this, new TimedEvent( time, 1, Command.create( CharUtils.moveToTarget, character, point.x, point.y, true, moveToBetaPoint )));
		}
		
		private function moveToBetaPoint( character:Entity ):void
		{
			var id:Id = character.get( Id );
			var point:Point;
			var time:Number;
			var display:Display = character.get( Display );
			CharacterMotionControl( character.get( CharacterMotionControl )).maxVelocityX = 120;
			
			if( id.id == "dog1" )
			{
				point = new Point( shellApi.viewportWidth * .5, 475 );
				time = Math.random() * 1;
			}
			else
			{
				point = new Point( shellApi.viewportWidth * .52, 475 );				
				time = Math.random() * 1;
			}
			
			display.container.setChildIndex( display.displayObject, 0 );
			SceneUtil.addTimedEvent( this, new TimedEvent( time, 1, Command.create( CharUtils.moveToTarget, character, point.x, point.y, true, moveToAlphaPoint )));
		}
		
		private function lostHim( winston:Entity ):void
		{
			setDogTrackAnim();
			var audio:Audio = getEntityById( "dog1" ).get( Audio );
			audio.playCurrentAction( TRIGGER );
			
			audio = getEntityById( "dog2" ).get( Audio );
			audio.playCurrentAction( TRIGGER );
			
			moveToAlphaPoint( getEntityById( "dog1" ));
			moveToBetaPoint( getEntityById( "dog2" ));
			
			var vanBuren:Entity = getEntityById( "buren" );
			var dialog:Dialog = vanBuren.get( Dialog );
			
			dialog.faceSpeaker = false;
			dialog.sayById( "lost_him" );
			dialog.complete.addOnce( setupCamp );

			CharacterMotionControl( vanBuren.get( CharacterMotionControl )).maxVelocityX = 100;
			CharacterMotionControl( getEntityById( "winston" ).get( CharacterMotionControl )).maxVelocityX = 70;
		}
		
		private function setupCamp( dialogData:DialogData ):void
		{
			var vanBuren:Entity = getEntityById( "buren" );
			
			var dialog:Dialog = vanBuren.get( Dialog );
			dialog.sayById( "setup_camp" );
			dialog.complete.addOnce( exitStageLeft );
		}
		
		private function exitStageLeft( dialogData:DialogData ):void
		{			
			var cameraEntity:Entity = super.getEntityById("camera");
			var cameraTarget:TargetSpatial = cameraEntity.get(TargetSpatial);
			
			cameraTarget.target = getEntityById( "pit1" ).get( Spatial );
			
			CharUtils.moveToTarget( getEntityById( "winston" ), -200, 475, true );
			CharUtils.moveToTarget( getEntityById( "buren" ), -200, 475, true );
			shellApi.loadScene( Underground, 1220, 450, "right", NaN, 3 );
		}
		
		/** UTILITY FUNCTIONS **/
		override protected function addStates():void
		{
			var fsmControl:FSMControl = player.get( FSMControl );
			fsmControl.removeAll(); 

			var stateCreator:FSMStateCreator = new FSMStateCreator();
			var stateClasses:Vector.<Class> = new <Class>[ RunningCharacterHurt, RunningCharacterJump
				, RunningCharacterRoll, RunningCharacterRun, RunningCharacterStumble ];

			stateCreator.createStateSet( stateClasses, player, RunningCharacterStateNode );
			
			fsmControl.setState( RunningCharacterState.RUN );	
			
			var motion:Motion = player.get( Motion );
			var spatial:Spatial = player.get( Spatial );
			motion.x = spatial.x;
			motion.y = spatial.y;
			
			var runningState:RunningCharacterRun = fsmControl.getState( RunningCharacterState.RUN ) as RunningCharacterRun;
			// HANDLE SCREEN CLICKS
			
			if( PlatformUtils.isDesktop )
			{
				SceneUtil.getInput( this ).inputDown.add( runningState.onActiveInput );
			}
			else 
			{
				SceneUtil.getInput( this ).inputUp.add( runningState.onActiveInput );
			}
		}
		
		private function removeInput():void
		{
			var fsmControl:FSMControl = player.get( FSMControl );
			fsmControl.setState( RunningCharacterState.RUN );	
			
			var runningState:RunningCharacterRun = fsmControl.getState( RunningCharacterState.RUN ) as RunningCharacterRun;
			
			if( PlatformUtils.isDesktop )
			{
				SceneUtil.getInput( this ).inputDown.remove( runningState.onActiveInput );	
			}
			else
			{
				SceneUtil.getInput( this ).inputUp.remove( runningState.onActiveInput );
			}
		}
	}
}