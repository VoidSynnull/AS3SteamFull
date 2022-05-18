package game.scenes.reality2.cheetahRun
{	
	import com.greensock.easing.Quad;
	
	import flash.display.BitmapData;
	import flash.display.DisplayObject;
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.events.Event;
	import flash.events.TimerEvent;
	import flash.geom.Point;
	import flash.text.TextField;
	import flash.utils.Timer;
	
	import ash.core.Entity;
	import ash.core.NodeList;
	
	import engine.components.Audio;
	import engine.components.Display;
	import engine.components.Id;
	import engine.components.Interaction;
	import engine.components.Motion;
	import engine.components.MotionBounds;
	import engine.components.Spatial;
	import engine.util.Command;
	
	import game.components.Emitter;
	import game.components.animation.FSMControl;
	import game.components.audio.HitAudio;
	import game.components.entity.Dialog;
	import game.components.entity.LooperCollider;
	import game.components.entity.MotionMaster;
	import game.components.entity.character.CharacterMotionControl;
	import game.components.entity.character.CharacterMovement;
	import game.components.entity.collider.EmitterCollider;
	import game.components.hit.Zone;
	import game.components.motion.Destination;
	import game.components.motion.FollowTarget;
	import game.components.motion.Looper;
	import game.components.motion.Threshold;
	import game.components.scene.SceneInteraction;
	import game.components.timeline.Timeline;
	import game.components.timeline.TimelineClip;
	import game.creators.animation.FSMStateCreator;
	import game.creators.entity.EmitterCreator;
	import game.creators.ui.ToolTipCreator;
	import game.data.animation.AnimationLibrary;
	import game.data.animation.entity.character.AttackRun;
	import game.data.animation.entity.character.Run;
	import game.data.animation.entity.character.Walk;
	import game.data.animation.entity.character.poptropolis.HurdleJump;
	import game.data.character.LookAspectData;
	import game.data.character.LookData;
	import game.managers.ScreenManager;
	import game.nodes.hit.LooperHitNode;
	import game.scene.template.AudioGroup;
	import game.scene.template.CharacterGroup;
	import game.scenes.reality2.shared.Contest;
	import game.scenes.reality2.shared.Contestant;
	import game.scenes.survival5.chase.nodes.RunningCharacterStateNode;
	import game.scenes.survival5.chase.states.RunningCharacterHurt;
	import game.scenes.survival5.chase.states.RunningCharacterJump;
	import game.scenes.survival5.chase.states.RunningCharacterRoll;
	import game.scenes.survival5.chase.states.RunningCharacterRun;
	import game.scenes.survival5.chase.states.RunningCharacterState;
	import game.scenes.survival5.chase.states.RunningCharacterStumble;
	import game.systems.SystemPriorities;
	import game.systems.entity.AnimationLoaderSystem;
	import game.systems.entity.character.states.CharacterState;
	import game.systems.hit.ZoneHitSystem;
	import game.systems.motion.ThresholdSystem;
	import game.ui.elements.ConfirmationDialogBox;
	import game.ui.tutorial.TutorialGroup;
	import game.util.CharUtils;
	import game.util.DataUtils;
	import game.util.EntityUtils;
	import game.util.MotionUtils;
	import game.util.PlatformUtils;
	import game.util.SceneUtil;
	import game.util.SkinUtils;
	import game.util.TimelineUtils;
	import game.util.TweenUtils;
	import game.utils.LoopingSceneUtils;
	
	import org.flintparticles.common.actions.Age;
	import org.flintparticles.common.actions.Fade;
	import org.flintparticles.common.actions.ScaleImage;
	import org.flintparticles.common.counters.Blast;
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
	import org.flintparticles.twoD.zones.Zone2D;
	
	public class CheetahRun extends Contest
	{				
		
		private var INPUT_TYPE:String;
		
		private const SKIN_COLOR:uint = 0xcf936a;
		private const HAIR_COLOR:uint = 0x999999;
		
		private const LAND:String			= 	"land";
		private const TRIGGER:String 		=	"trigger";
		private const MALE:String 			=	"male";
		private const CASUAL:String 		= 	"casual";
		private const OPEN:String 			=	"open";
		private const FRONT:String 			=	"front";
		private const STILL:String 			=	"_still";
		private const BREATHLESS:String 	=	"breathless";
		
		private const HUNTERS:Vector.<String> = new <String>[ "c1", "c2", "c3" ];
		private const HUNTERS_VELOCITY:Vector.<Number> = new <Number>[ 350, 300, 640, 650 ];
		private const HUNTERS_PACE:Vector.<Number> = new <Number>[ 2,2.2, 3, .8 ];
		
		
		private var CONTESTANTS:Vector.<Entity>;
		
		private var _viewportRatioX:Number;
		private var _viewportRatioY:Number;
		
		private var _stillRunning:Boolean = true;
		private var _setWin:Boolean = false;
		
		private const HIT_PENALTY:Number = 20;
		private var _penalties:Array = new Array(0,0,0,0);
		private var _scores:Array = new Array(0,0,0,0);
		private var _isHit:Array = new Array(false,false,false,false);
		private var _isJumping:Array = new Array(false,false,false,false);
		private var _hitTimer:Array = new Array();
		private var _jumpTimer:Timer;
		private var _accelerationRate:Number = .1;
		private var _npcAccelerationRate:Number = .1;

		
		private const AI_JUMP_CHANCE:Number = 5; //1-10  5 == 50% jump rate
		
		private var _characterGroup:CharacterGroup;
		private var _audioGroup:AudioGroup;
		private var cameraStationary:Boolean = true;
		private var npcNum:int = 1;
		private var _looks:Array = new Array();
		private var _hitEffect:Entity;
		private var _cheetah:Entity;
		
		private var _playing:Boolean = true;
		public var numJumps:Number = 0;
		
		public function CheetahRun()
		{
			super();
			practiceEnding = "Way to show off your speed! Now get ready to run for real!";
			contestEnding = "You're crazy fast! Let's find out who won!";
		}
		
		// pre load setup
		override public function init(container:DisplayObjectContainer = null):void
		{			
			super.groupPrefix = "scenes/reality2/cheetahRun/";
			super.init(container);
		}
		
		// initiate asset load of scene specific assets.
		override public function load():void
		{
			super.load();
		}
		
		private function setUpCheetah():void
		{
			var clip:MovieClip = _hitContainer["cheetah"];
			
			_cheetah = EntityUtils.createSpatialEntity(this, clip);
		}
		private function addDistance(e:Event):void
		{
			var textField:TextField = e.target as TextField;
			var contestant:Number = DataUtils.getNumber(textField.parent.name.substr(1,1));
			if(_playing)
			{
				if(!practice)
				{
					_scores[contestant]+= 1;
					
					textField.text = _scores[contestant]+this.getEntityById("c"+contestant.toString()).get(Spatial).x;
					//_scores[contestant] = textField.text
					textField.maxChars = 4;
					var spatial:Spatial = CONTESTANTS[contestant-1].get(Spatial);
					if(spatial)
					{
						if(spatial.scaleX > 0)
							CharUtils.setDirection(CONTESTANTS[contestant-1], true);
						if(spatial.rotation != 0)
							spatial.rotation = 0;
					}
				}
			}
		}
		private function addPlayerDistance(e:Event):void
		{
			var textField:TextField = e.target as TextField;
			if(_playing)
			{
				_scores[0]++;
				textField.text = _scores[0]+ player.get(Spatial).x;
				textField.maxChars = 4;
				updateStandings();
			}
		}
		private function updateStandings():void
		{
			var arr:Array = [];
			var prefix:String;
			var contestant:Contestant;
			var tf:TextField;
			
			for(var i:int = 0; i < participants.length; i++)
			{
				prefix = i== 0?"player":"c"+i;
				participants[i].score = getEntityById(prefix).get(Spatial).x;
				arr.push(participants[i]);
			}
			arr.sortOn("score", Array.NUMERIC);
			for(i=0;i<arr.length;i++)
			{
				contestant = arr[i];
				contestant.place = arr.length-i;
			}
			for(i = 0; i < participants.length; i++)
			{
				contestant = participants[i];
				prefix = i==0? "player":"c"+i;
				tf = hud[prefix+"Ui"]["place"];
				tf.text = ""+contestant.place;
			}
		}
		override protected function gameOver(...args):void
		{
			TweenUtils.entityTo(_cheetah, Spatial, 1.5,{x:1200, ease:Quad.easeOut,onComplete:Command.create(setGameOver)});

		}
		private function setGameOver():void
		{
			if(!_playing)
				return;
			
			SceneUtil.lockInput(this, false);
			_playing = false;
			for(var i:int = 0; i < contestants.length-1; i++)
			{
				var clip:MovieClip =hud["c"+(i+1)+"Ui"];
				clip["score"].removeEventListener(Event.ENTER_FRAME,addDistance);
			}
			
			SceneUtil.lockInput(this, false);
			super.gameOver();
		}
		
		override protected function contestantDataLoaded(xml:XML):void
		{
			CONTESTANTS = new Vector.<Entity>();
			
			for(var i:int = 0; i < contestants.length-1; i++)
			{
				var contestant:Contestant = contestants[i];
				
				var npc:XML = xml.children()[contestant.index];
				contestant.id = DataUtils.getString(npc.attribute("id")[0]);
				var child:XML = npc.child("skin")[0];
				var look:LookData = new LookData( child);
				
				var clip:MovieClip = setUpUi("c"+(i+1),i,look);
				
				var entity:Entity = getEntityById("c"+npcNum);
				_looks.push(look);
				npcNum++;
				if(practice)
				{
					removeEntity(entity);
					continue;
				}
				clip["score"].addEventListener(Event.ENTER_FRAME,addDistance);
				CONTESTANTS.push(entity);
			}
			
			var playerclip:MovieClip =setUpUi("player", i, SkinUtils.getPlayerLook(this),npcLookApplied);
			playerclip["score"].addEventListener(Event.ENTER_FRAME,addPlayerDistance);
			CONTESTANTS.push(player);
		}
		
		private function npcLookApplied(entity:Entity=null):void
		{
			
			contestantsPrepared();
			prepareGame();
			
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
		private function prepareGame():void
		{	
			
			var spatial:Spatial = player.get( Spatial );
			spatial.x = -100;
			spatial.y = 450;
			if(!practice)
			{
				CONTESTANTS = new Vector.<Entity>();
				CONTESTANTS.push(getEntityById( "c1" ));
				CONTESTANTS.push(getEntityById( "c2" ));
				CONTESTANTS.push(getEntityById( "c3" ));
				SkinUtils.applyLook(getEntityById( "c1" ),_looks[0],true);
				SkinUtils.applyLook(getEntityById( "c2" ),_looks[1],true);
				SkinUtils.applyLook(getEntityById( "c3" ),_looks[2],true);
			}
			
			_viewportRatioX = shellApi.viewportWidth / ScreenManager.GAME_WIDTH;
			_viewportRatioY = shellApi.viewportHeight / ScreenManager.GAME_HEIGHT;
			
			setupPlayer();
			LoopingSceneUtils.createMotion(this, cameraStationary);
			
			this.addSystem( new ZoneHitSystem(), SystemPriorities.checkCollisions);
			
			setUpCheetah();
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
			_hitEffect = TimelineUtils.convertClip(_hitContainer[ "smack" ]);
			_hitEffect.add(new Spatial(-1000,0));
			var hitTime:Timeline = _hitEffect.get(Timeline);
			hitTime.gotoAndStop(1);
			hitTime.handleLabel("setEffect",resetHitEffect);
			

			TweenUtils.entityTo(_cheetah, Spatial, 2,{x:0, ease:Quad.easeOut});

			
			
			var emitter2D:Emitter2D;
			var name:String;
			
			var point:Point;
			var angle:Number;
			for each( entity in looperEntities )			
			{
				id = entity.get( Id );
				number = Number( id.id.substr( id.id.length - 1 ));
				type = id.id.substr( 0, id.id.length - 1 );
				spatial = entity.get( Spatial );
				
				switch( type )
				{
					
					case "lizard":
						createBitmappedFollower( _hitContainer[ "liz"+ number], spatial,"liz"+ number);
						
						break;
					case "zebra":
						createBitmappedFollower( _hitContainer[ "zeb" + number ], spatial ,"zeb" + number);
						break;
					case "ostrich":
						createBitmappedFollower( _hitContainer[ "ost" + number ], spatial,"ost" + number );
						break;
					case "lion":
						createBitmappedFollower( _hitContainer[ "lio" + number ], spatial,"lio" + number );
						break;
					case "croc":
						createBitmappedFollower( _hitContainer[ "cro" + number ], spatial,"cro" + number );
						break;
					case "turtle":
						createBitmappedFollower( _hitContainer[ "tur" + number ], spatial,"tur" + number );
						break;
					case "rhino":
						createBitmappedFollower( _hitContainer[ "rhi" + number ], spatial,"rhi" + number );
						break;
					case "hippo":
						createBitmappedFollower( _hitContainer[ "hip" + number ], spatial,"hip" + number );
						break;
					case "bird":
						createBitmappedFollower( _hitContainer[ "bir" + number ], spatial,"bir" + number );
						break;
					case "meercat":
						createBitmappedFollower( _hitContainer[ "mee" + number ], spatial,"mee" + number );
						break;
					case "finish":
						createBitmappedFollower( _hitContainer[ "fin" + number ], spatial,"fin" + number );
						break;
					
				}
				
				if(emitter2D)
					addEmitter( entity, emitter2D, name );
			}
			
			startRunning();
		}
		private function resetHitEffect():void
		{
			_hitEffect.get(TimelineClip).mc.x = -1000;
			_hitEffect.get(TimelineClip).mc.gotoAndStop(1);
		}
		public function enteredZone(zoneId:String, characterId:String):void
		{
			if (characterId != "player")
			{
				var index:int = DataUtils.getNumber(characterId.substr(1,1));
				if(Math.random() < participants[index].difficulty)
				{
					if(_isJumping[characterId.substr(1,1)] == false)
					{
						CharUtils.setState(getEntityById(characterId),CharacterState.JUMP);
						//node.motion.velocity.y = node.charMotionControl.jumpVelocity * -jumpHeight * dampener;
						_jumpTimer = new Timer(1000, 1);
						_jumpTimer.addEventListener(TimerEvent.TIMER_COMPLETE, Command.create(setRunState3,getEntityById( characterId ),characterId));
						_jumpTimer.start();
						_isJumping[characterId.substr(1,1)] = true;
						_isHit[characterId.substr(1,1)] = false;
						if(_hitTimer[characterId.substr(1,1)])
							_hitTimer[characterId.substr(1,1)].removeEventListener(TimerEvent.TIMER_COMPLETE, setRunState2);
					}
				}
			}
		}
		private function idleListen(event:Event):void
		{
			if(event.currentTarget.currentLabel == "startidle")
				event.currentTarget.gotoAndPlay(1);
			
		}
		private function createBitmappedFollower( displayObject:DisplayObject, spatial:Spatial = null, name:String=null ):Entity
		{
			var entity:Entity = EntityUtils.createMovingEntity( this, _hitContainer[name] );
			entity.add(new Id(name));
			MovieClip(_hitContainer[name]).addEventListener(Event.ENTER_FRAME,idleListen);
			
			entity.add( new Id( displayObject.name ));
			
			var zone:Zone = new Zone();
			zone.entered.add(Command.create(enteredZone));
			entity.add(zone);
			
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
		
		private function setupPlayer( fileName:String = "motionMaster.xml"  ):void
		{
			LoopingSceneUtils.setupPlayer( this, fileName );
			
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
			
			if(!practice)
			{
				for( var i:int = 0; i < CONTESTANTS.length; i++ )
				{
					CONTESTANTS[i].add( new LooperCollider());
					CONTESTANTS[i].get(LooperCollider).triggerFunction = contestantHit;
				}
			}
			player.get(LooperCollider).triggerFunction = playerHit;
			
		}
		private function playerHit(entity:Entity):void
		{
			if(_isHit[0] == false)
			{
				var display:Display = entity.get(Display);
				_hitTimer[0] = new Timer(500, 1);
				_hitTimer[0].addEventListener(TimerEvent.TIMER_COMPLETE, Command.create(setPlayerHit));
				_hitTimer[0].start();
				var str:String = entity.get(Id).id;
				str = str.substr(0,3);
				MovieClip(_hitContainer[str+"1"]).gotoAndPlay("hit");
				player.get(Spatial).x -= HIT_PENALTY;
				if(player.get(Spatial).x < 0)
					player.get(Spatial).x = 0;
				_hitEffect.get(TimelineClip).mc.x = player.get(Spatial).x;
				_hitEffect.get(TimelineClip).mc.gotoAndPlay(2);
				
				for( var i:int = 0; i < CONTESTANTS.length; i++ )
				{
					//CharUtils.moveToTarget( CONTESTANTS[i], CONTESTANTS[i].get( Spatial ) + HIT_PENALTY, CONTESTANTS[i].get( Spatial ).y, true);
					CONTESTANTS[i].get( Spatial ) + HIT_PENALTY;
				}
			}
		}
		private function contestantHit(id:String):void
		{
			if(_isHit[id.substr(1,1)] == false )
			{
				_isHit[id.substr(1,1)] = true;
				if(CharUtils.getStateType(getEntityById( id )) != CharacterState.JUMP)
				{
					//CharUtils.setAnimSequence(getEntityById( id ), new <Class>[AttackRun], false);
					CharUtils.setAnim(getEntityById( id ),AttackRun,false,.3);
				}
				_hitTimer[id.substr(1,1)] = new Timer(1500, 1);
				_hitTimer[id.substr(1,1)].addEventListener(TimerEvent.TIMER_COMPLETE, Command.create(setRunState2,getEntityById( id ),id));
				_hitTimer[id.substr(1,1)].start();
				var c:Entity = getEntityById( id );
				var spatial:Spatial = player.get( Spatial );
				_penalties[id.substr(1,1)]++;
				//CharUtils.moveToTarget( getEntityById( id ), spatial.x - _penalties[id.substr(1,1)]*HIT_PENALTY, spatial.y, true);
				getEntityById( id ).get(Spatial).x -= HIT_PENALTY;
			}
		}
		private function setRight(entity:Entity):void
		{
			CharUtils.setDirection(entity,true);
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
		
		private function startRunning():void
		{
			SceneUtil.lockInput( this, false );
			
			super.shellApi.eventTriggered.add( eventTriggers );
			
			if(!practice)
			{
				for( var number:int = 0; number < HUNTERS.length; number ++ )
				{
					setupHunters( getEntityById( HUNTERS[ number ]), _characterGroup, HUNTERS_VELOCITY[ number ]);
				}
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
				
				default:
					break;
			}
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
			
			
			triggerLayers();
			giveHimSomeRoom();
		}
		
		private function triggerLayers():void
		{
			LoopingSceneUtils.triggerLayers( this );
		}
		
		
		private function triggerObstacles():void
		{
			LoopingSceneUtils.triggerObstacles( this );
		}
		private function giveHimSomeRoom():void
		{
			startGracePeriod();
		}
		
		private function startGracePeriod():void
		{
			
			var motionMaster:MotionMaster = player.get( MotionMaster );
			motionMaster._distanceX = 0;
			motionMaster._distanceY = 0;
			
			var fsmControl:FSMControl = player.get( FSMControl );
			var type:String;
			var state:RunningCharacterState;
			
			for each( type in RunningCharacterState.STATES )
			{
				state = fsmControl.getState( type ) as RunningCharacterState;
				state.setReality(true);
				var clip:MovieClip = hud["playerUi"];
				state.setClip(clip["goalBar"]);
				state.setWinFunction(gameOver);
				
			}
			
			triggerObstacles();
			
			startTheRace();
		}	
		
		private function setJumpState( tutorialGroup:TutorialGroup ):void
		{
			super.restartSceneMotion();
			var fsmControl:FSMControl = player.get( FSMControl );
		}
		
		private function startTheRace(  ):void
		{
			LoopingSceneUtils.restartSceneMotion( this );
			var fsmControl:FSMControl = player.get( FSMControl );
			fsmControl.setState( RunningCharacterState.ROLL );
			var c1:Entity = getEntityById( "c1" );
			var spatial:Spatial = player.get( Spatial );
			if(!practice)
			{
				CharUtils.moveToTarget( c1, spatial.x, spatial.y, true, Command.create(setRunState) );
				CharUtils.moveToTarget( getEntityById( "c2" ), spatial.x + 50, spatial.y, true);
				CharUtils.moveToTarget( getEntityById( "c3" ), spatial.x + 150, spatial.y, true);
			}
			SceneUtil.lockInput( this, false );
			
			//getEntityById( "c2" ).get(Spatial).y - 1250;
			//getEntityById( "c3" ).get(Spatial).y + 1250;
			
			this.container.addEventListener(Event.ENTER_FRAME,acceleratePlayer);
			
		}
		private function acceleratePlayer(e:Event):void
		{
			player.get(Spatial).x += _accelerationRate;
			for( var i:int = 0; i < CONTESTANTS.length; i++ )
			{
				CONTESTANTS[i].get(Spatial).x += _npcAccelerationRate;
			}
		}
		
		
		private function setRunState(entity:Entity):void
		{
			for( var i:int = 0; i < CONTESTANTS.length; i++ )
			{
				CharUtils.setAnim(CONTESTANTS[i],Run);
			}
			_isHit[0] = false;
			_isHit[1] = false;
			_isHit[2] = false;
		}
		private function setPlayerHit(e:Event):void
		{
			resetHitEffect();
			_isHit[0] = false;
			_hitTimer[0].removeEventListener(TimerEvent.TIMER_COMPLETE, setPlayerHit);
		}
		private function setRunState2(e:Event,entity:Entity,id:String):void
		{
			
			CharUtils.setAnim(entity,Run);
			_isHit[id.substr(1,1)] = false;
			_hitTimer[id.substr(1,1)].removeEventListener(TimerEvent.TIMER_COMPLETE, setRunState2);
		}
		private function setRunState3(e:Event,entity:Entity,id:String):void
		{
			if(entity)
			{
				trace("set run state3 " + id);
				CharUtils.setAnim(entity,Run);
				_jumpTimer.removeEventListener(TimerEvent.TIMER_COMPLETE, setRunState3);
				_isJumping[id.substr(1,1)] = false;
			}
		}
		
		private function addLooperCollider( character:Entity, time:Number, width:Number, handler = null, addCollider:Boolean = true ):void
		{
			if( !character.has( LooperCollider ) && addCollider )
			{
				character.add( new LooperCollider()).add( new HitAudio());
			}
		}
		
		private function restart():void
		{
			shellApi.loadScene( CheetahRun, -100, 475 );
		}
		
		
		/** UTILITY FUNCTIONS **/
		private function addStates():void
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
			var jumpingState:RunningCharacterJump = fsmControl.getState( RunningCharacterState.JUMP) as RunningCharacterJump;
			
			if( PlatformUtils.isDesktop )
			{
				SceneUtil.getInput( this ).inputDown.add( runningState.onActiveInput );
				SceneUtil.getInput( this ).inputDown.add( jumpingState.onActiveInput );
			}
			else 
			{
				SceneUtil.getInput( this ).inputUp.add( runningState.onActiveInput );
				SceneUtil.getInput( this ).inputUp.add( jumpingState.onActiveInput );
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
		
		public override function destroy():void
		{
			if(participants)
			{
				if(container)
				{
					container.removeEventListener(Event.ENTER_FRAME, acceleratePlayer);
				}
				for(var i:int = 0; i < participants.length; i++)
				{
					var clip:MovieClip = i==0?hud["playerUi"]:hud["c"+(i)+"Ui"];
					if(i == 0)
						clip["score"].removeEventListener(Event.ENTER_FRAME,addPlayerDistance);
					else
						clip["score"].removeEventListener(Event.ENTER_FRAME,addDistance);
				}
			}
			
			super.destroy();
		}
	}
	
}


