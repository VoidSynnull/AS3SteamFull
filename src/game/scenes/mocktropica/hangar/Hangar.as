package game.scenes.mocktropica.hangar
{
	import com.greensock.easing.Sine;
	
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.display.Sprite;
	import flash.geom.Point;
	
	import ash.core.Entity;
	
	import engine.components.Audio;
	import engine.components.AudioRange;
	import engine.components.Display;
	import engine.components.Id;
	import engine.components.Interaction;
	import engine.components.Motion;
	import engine.components.Spatial;
	import engine.components.Tween;
	import engine.creators.InteractionCreator;
	import engine.managers.SoundManager;
	import engine.util.Command;
	
	import game.components.motion.Edge;
	import game.components.entity.Children;
	import game.components.entity.Dialog;
	import game.components.entity.Sleep;
	import game.components.timeline.Timeline;
	import game.components.entity.character.BitmapCharacter;
	import game.components.entity.character.Talk;
	import game.components.entity.character.animation.RigAnimation;
	import game.components.motion.Threshold;
	import game.components.scene.SceneInteraction;
	import game.creators.entity.AnimationSlotCreator;
	import game.creators.entity.EmitterCreator;
	import game.creators.ui.ToolTipCreator;
	import game.data.TimedEvent;
	import game.data.animation.entity.character.Cry;
	import game.data.animation.entity.character.DuckNinja;
	import game.data.animation.entity.character.Grief;
	import game.data.animation.entity.character.Hurt;
	import game.scenes.mocktropica.MocktropicaEvents;
	import game.data.sound.SoundModifier;
	import game.scene.template.AudioGroup;
	import game.scene.template.PlatformerGameScene;
	import game.scenes.mocktropica.basement.Basement;
	import game.scenes.mocktropica.basement.MatrixDissolveEmitter;
	import game.scenes.mocktropica.megaFightingBots.MegaFightingBots;
	import game.scenes.virusHunter.shipDemo.components.Current;
	import game.scenes.virusHunter.shipDemo.systems.CurrentSystem;
	import game.systems.SystemPriorities;
	import game.systems.motion.ThresholdSystem;
	import game.util.CharUtils;
	import game.util.EntityUtils;
	import game.util.MotionUtils;
	import game.util.SceneUtil;
	import game.util.TimelineUtils;
	
	public class Hangar extends PlatformerGameScene
	{
		public function Hangar()
		{
			super();
		}
		
		// pre load setup
		override public function init(container:DisplayObjectContainer = null):void
		{			
			super.groupPrefix = "scenes/mocktropica/hangar/";
			
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
			super.addSystem( new CurrentSystem());
			super.addSystem( new ThresholdSystem(), SystemPriorities.update );
			_events = super.events as MocktropicaEvents;
			
			setupBucketBot();
			setupScene();
			super.shellApi.eventTriggered.add( eventTriggers );
			
			trace( super.shellApi.sceneManager.previousScene );
			if( super.shellApi.sceneManager.previousScene == "game.scenes.mocktropica.basement::Basement" )
			{	
				Display( player.get( Display )).alpha = 0;
				SceneUtil.addTimedEvent( this, new TimedEvent( .5, 1, initDisolve ));
				matrixDissolveEmitter = new MatrixDissolveEmitter(); 
				matrixDissolve = EmitterCreator.create(this, super._hitContainer, matrixDissolveEmitter, 0, 0, player, "dissolveEntity", player.get(Spatial));
				this.getEntityById("dissolveEntity").get(Display).alpha = .8;
				matrixDissolveEmitter.init();
			}
			super.loaded();
		}
		
		private function setupScene():void
		{
			var entity:Entity;
			var clip:MovieClip;
			var number:uint;
			var motion:Motion;
			var spatial:Spatial;
			var sceneInteraction:SceneInteraction;
			var timeline:Timeline;
			var audioGroup:AudioGroup = super.getGroupById( "audioGroup" ) as AudioGroup;
			var audio:Audio;
			
			for( number = 1; number < 7; number ++ )
			{
				clip = _hitContainer[ "glow" + number ];
				entity = EntityUtils.createSpatialEntity( this, clip );
				entity.add( new Tween );
				
				dimLights( entity, DIM_VALUE );
			}
			
			for( number = 1; number < 5; number ++ )
			{
				clip = _hitContainer[ "ringGlow" + number ];
				entity = EntityUtils.createSpatialEntity( this, clip );
				entity.add( new Tween );
				
				dimLights( entity, DIM_VALUE );
			}
			
			for( number = 1; number < 3; number ++ )
			{
				clip = _hitContainer[ "vent" + number ];
				entity = EntityUtils.createMovingEntity( this, clip );
				motion = entity.get( Motion );
				
				motion.rotationVelocity = COMPUTER_VENT_VELOCITY;
			}
			
			for( number = 1; number < 3; number ++ )
			{
				clip = _hitContainer[ "roomVent" + number ];
				entity = EntityUtils.createMovingEntity( this, clip );
				motion = entity.get( Motion );
				
				motion.rotationVelocity = ROOM_VENT_VELOCITY;
			}
			
			// CONSOLE BUTTONS
			entity = EntityUtils.createSpatialEntity( this, _hitContainer[ "console" ]);
			entity.add( new Id( "console" )).add( new Tween()).add( new AudioRange( 600, 0, 1 ));
			audioGroup.addAudioToEntity( entity );
			
			entity = EntityUtils.createSpatialEntity( this, _hitContainer[ "arena" ]);
			entity.add( new Id( "arena" )).add( new Tween());
			Display( entity.get( Display )).alpha = 0;
			
			entity = EntityUtils.createSpatialEntity( this, _hitContainer[ "popHQ" ]);
			entity.add( new Id( "popHQ" )).add( new Tween());
			Display( entity.get( Display )).alpha = 0;
			
			entity = getEntityById( "screenInteraction" );
			sceneInteraction = entity.get( SceneInteraction );
			sceneInteraction.offsetY = 100;
			sceneInteraction.reached.add( megaConsole );
			
			var current:Current = new Current( 250, 250, 160, 40, 0, 50, 80, 3, 0x009C9C );
			var electricity:Entity = EntityUtils.createSpatialEntity( this, new Sprite(), _hitContainer[ "consoleCurrentContainer" ]);
			electricity.add( current );
			
			current = new Current( 110, 110, 180, 40, 0, 50, 100, 2, 0x009C9C ); // FF35A5FF
			electricity = EntityUtils.createSpatialEntity( this, new Sprite(), _hitContainer[ "resultsCurrentContainer" ]);//super.screen.content.rightContent.contentCurrentContainer );
			electricity.add( current );
			
			current = new Current( 220, 220, 80, 40, 0, 50, 50, 2, 0x009C9C ); // FF35A5FF
			electricity = EntityUtils.createSpatialEntity( this, new Sprite(), _hitContainer[ "arenaCurrentContainer" ]);//super.screen.content.rightContent.contentCurrentContainer );
			electricity.add( current );
			
			// create gate charges
			for( number = 1; number < 6; number ++ )
			{
				current = new Current( 180, 180, 5, 40, 0, 5, 50, 3, 0xFFFFFF ); // FF35A5FF
				electricity = EntityUtils.createSpatialEntity( this, new Sprite(), _hitContainer[ "gateCurrent" + number ]);//super.screen.content.rightContent.contentCurrentContainer );
				electricity.add( current );
			}
			
			// create ring charges
			for( number = 1; number < 7; number ++ )
			{
				current = new Current( 400, 400, 5, 80, 0, 5, 50, 3, 0xFFFFFF ); // FF35A5FF
				electricity = EntityUtils.createSpatialEntity( this, new Sprite(), _hitContainer[ "ringCurrent" + number ]);//super.screen.content.rightContent.contentCurrentContainer );
				electricity.add( current );
			}
			
			entity = EntityUtils.createSpatialEntity( this, _hitContainer[ "results" ]);
			TimelineUtils.convertClip( _hitContainer[ "results" ], this, entity );
			timeline = entity.get( Timeline );
			for( number = 1; number < 4; number ++ )
			{
				entity = EntityUtils.createSpatialEntity( this, _hitContainer[ "buzz" + number ]);
				entity.add( new Id( "buzz" )).add( new AudioRange( 600, 0, 1 ));
				audioGroup.addAudioToEntity( entity );
				
				audio = entity.get( Audio );
				audio.play( SoundManager.EFFECTS_PATH + "electric_buzz_01_loop.mp3", true, SoundModifier.POSITION );
			}
			
			for( number = 1; number < 5; number ++ )
			{
				entity = EntityUtils.createMovingEntity( this, _hitContainer[ "debris" + number ]);
				entity.add( new Id( "debris" + number ));
				
				Display( entity.get( Display )).visible = false;
			}
			
			if( super.shellApi.checkEvent( _events.DEFEATED_MFB ))
			{
				timeline.gotoAndStop( 1 );
				runToBucketBot();
			}
			
			clip = _hitContainer[ "window" ];
			entity = EntityUtils.createSpatialEntity( this, clip );
			entity.add( new Id( "window" ));
			audioGroup.addAudioToEntity( entity );
			
			TimelineUtils.convertClip( clip, this, entity );
			timeline = entity.get( Timeline );
			timeline.gotoAndStop( 0 );
		}
		
		/**
		 * EVENT HANDLER
		 */
		private function eventTriggers( event:String, save:Boolean = true, init:Boolean = false, removeEvent:String = null ):void
		{
			var entity:Entity;
			
			switch( event )
			{
				case _events.HERTZ_REJOINED:
					super.shellApi.loadScene( Basement, 800, 900 );
					break;
			}
		}
		
		/**
		 * AMBIENCE
		 */
		private function dimLights( entity:Entity, percent:Number ):void
		{
			var display:Display = entity.get( Display );
			var tween:Tween = entity.get( Tween );
			var newPercent:Number;
			
			if( percent == FLASH_VALUE )
			{
				newPercent = DIM_VALUE;
			}
			else
			{
				newPercent = FLASH_VALUE;
			}
			
			tween.to( display, DIM_SPEED, { alpha : percent, onComplete : dimLights, onCompleteParams : [ entity, newPercent ]});
		}
		
		/**
		 * BUCKET BOT
		 */
		private function setupBucketBot():void
		{
			var clip:MovieClip = _hitContainer[ "bucketBot" ];
			var entity:Entity = TimelineUtils.convertAllClips( clip, entity, this );
			entity.add( new Id( "bucketBot" ));
			var timeline:Timeline = entity.get( Timeline );
			timeline.handleLabel( "step", bucketBotStep, false );
			
			var audioGroup:AudioGroup = super.getGroupById( "audioGroup" ) as AudioGroup;
			audioGroup.addAudioToEntity( entity );
			
			entity.add(new Display(clip));
			entity.add(new Spatial());
			EntityUtils.syncSpatial(entity.get(Spatial), clip);
			
			CharUtils.assignDialog( entity, this, "bucketBot", true, -.22, .8 );
			
			Talk(entity.get(Talk)).instances.push("body");
			Talk(entity.get(Talk)).talkLabel = "talk";
			Talk(entity.get(Talk)).mouthDefaultLabel = "idle";
			
			entity.add( new BitmapCharacter());
			ToolTipCreator.addUIRollover( entity, "click" );
			
			InteractionCreator.addToEntity( entity, [ InteractionCreator.CLICK ]);
			var sceneInteraction:SceneInteraction = new SceneInteraction();
			sceneInteraction.offsetX = -Edge( entity.get( Edge )).rectangle.left;
			
			sceneInteraction.offsetY = 0;
			sceneInteraction.reached.removeAll();
			
			entity.add( sceneInteraction ).add( new Tween());			
		}
		
		private function bucketBotStep( ...args ):void
		{
			var audio:Audio = getEntityById( "bucketBot" ).get( Audio );
			audio.playCurrentAction( "trigger" );
		}
		
		private function megaConsole( character:Entity, interactionEnt:Entity ):void
		{
			var entity:Entity = getEntityById( "console" );
			var audio:Audio = entity.get( Audio );
			audio.playCurrentAction( "trigger" );
			
			var tween:Tween = entity.get( Tween );
			var display:Display = entity.get( Display );
			
			tween.to( display, 1, { alpha : 0, onComplete : showChoices });
		}
		
		private function showChoices():void
		{			
			var entity:Entity = getEntityById( "popHQ" );
			var tween:Tween = entity.get( Tween );
			var display:Display = entity.get( Display );
			
			tween.to( display, 1, { alpha : 1 });
			
			entity = getEntityById( "arena" );
			tween = entity.get( Tween );
			display = entity.get( Display );
			
			tween.to( display, 1, { alpha : 1, onComplete : chooseYourFate });
		
		}
		
		private function chooseYourFate():void
		{
			var entity:Entity = getEntityById( "arena" );
			var interaction:Interaction;
			
			InteractionCreator.addToEntity( entity, [ InteractionCreator.CLICK ]);
			interaction = entity.get( Interaction );
			interaction.click.add( intoTheArena );
			
			entity = getEntityById( "popHQ" );
			InteractionCreator.addToEntity( entity, [ InteractionCreator.CLICK ]);
			interaction = entity.get( Interaction );
			interaction.click.add( startDissolve );
			
		}
		
		private function intoTheArena( entity:Entity ):void
		{
			var spatial:Spatial;
			var timeline:Timeline;
			var tween:Tween;
			
			entity = getEntityById( "bucketBot" );
			spatial = entity.get( Spatial );
			tween = entity.get( Tween );
			
			SceneUtil.lockInput( this );
			SceneUtil.setCameraTarget( this, entity );
			
			if( spatial.scaleX > -1 )
			{
				spatial.scaleX *= -1;
			}
			
			timeline = entity.get( Timeline );
			timeline.gotoAndPlay( "walkStart" );
			
			timeline = entity.get( Children ).children[ 0 ].get( Timeline );
			timeline.gotoAndStop( "happy" );
			
			tween.to( spatial, 5, { x : 2000, onComplete : readyToFight }); 
			
			var test:Spatial = player.get( Spatial );
			trace( test.x + "  y : " + test.y );
		}
		
		private function readyToFight():void
		{
			var entity:Entity;
			var timeline:Timeline;
			
			entity = getEntityById( "bucketBot" );
			
			timeline = entity.get( Children ).children[ 0 ].get( Timeline );
			timeline.gotoAndPlay( "idle" );
			
			SceneUtil.addTimedEvent( this, new TimedEvent( 1, 1, launchMFB ));
		}
		
		private function launchMFB():void
		{
			super.shellApi.loadScene( MegaFightingBots );
		}
		
		// matrix transition in
		public function initDisolve():void 
		{
			var spatial:Spatial = player.get( Spatial );
			var tween:Tween = new Tween();
			SceneUtil.lockInput( this );
			
			player.add( tween );
			tween.to( spatial, 1, { x : 900, y : 1020, ease : Sine.easeInOut, onComplete : materialize });
			}
		
		private function materialize():void 
		{
			var spatial:Spatial = player.get( Spatial );
			var tween:Tween = player.get( Tween );
			
			tween.to( player.get( Display ), 1.8, { alpha : 1, ease : Sine.easeInOut, onComplete : regainControl });
		}
		
		private function regainControl():void
		{
			SceneUtil.lockInput( this, false );
			CharUtils.setDirection( player, true );
		}
		// matrix transition out
		private function startDissolve( entity:Entity ):void 
		{
			matrixDissolveEmitter = new MatrixDissolveEmitter(); 
			matrixDissolve = EmitterCreator.create(this, super._hitContainer, matrixDissolveEmitter, 0, 0, player, "dissolveEntity", player.get(Spatial));
			this.getEntityById("dissolveEntity").get(Display).alpha = .8;
			matrixDissolveEmitter.init();
			
			player.add(new Tween());
			player.get(Tween).to(player.get(Display), 1.8, { alpha:0, ease:Sine.easeInOut, onComplete:goInComputer });
		}
		
		private function goInComputer():void 
		{
			var spatial:Spatial = player.get( Spatial );
			var tween:Tween = player.get( Tween );
			tween.to( spatial, .2, { x : 300, y : 920, ease:Sine.easeInOut, onComplete:returnToBasement });
		}
		
		private function returnToBasement():void
		{
			super.shellApi.loadScene( Basement, 800, 900 );
		}
		
		
		/**
		 * BEAT MFB
		 */
		private function runToBucketBot():void
		{
			var entity:Entity = getEntityById( "bucketBot" );
			var sleep:Sleep = entity.get( Sleep );
			sleep.ignoreOffscreenSleep = true;
			
			var spatial:Spatial = entity.get( Spatial );
			var tween:Tween = entity.get( Tween );
			var timeline:Timeline;
			
			SceneUtil.lockInput( this );
			
			timeline = entity.get( Timeline );
			timeline.gotoAndPlay( "walkStart" );
			
			timeline = entity.get( Children ).children[ 0 ].get( Timeline );
			timeline.gotoAndStop( "happy" );
			
			tween.from( spatial, 4, { x : 2000, onComplete : sendInHertz });
			
			CharUtils.moveToTarget( player, 1090, 920, true );
		}
		
		private function sendInHertz():void
		{
			var entity:Entity = getEntityById( "bucketBot" );
			var audioGroup:AudioGroup = getGroupById( "audioGroup" ) as AudioGroup;
			var timeline:Timeline;
			var number:int; 
			var threshold:Threshold;
			var rotation:Number;
			var velocity:Number;
			
			timeline = entity.get( Timeline );
			timeline.gotoAndPlay( "idle" );
			
			entity = getEntityById( "window" );
			SceneUtil.setCameraTarget( this, entity );
			
			entity = getEntityById( "hertz" );
			var sleep:Sleep = entity.get( Sleep );
			var spatial:Spatial = entity.get( Spatial );
			
			sleep.sleeping = false;
			sleep.ignoreOffscreenSleep = true;
			var motion:Motion = new Motion();
			entity.add( motion );
			
			CharUtils.setAnim( entity, Hurt );
			
			motion.rotationVelocity = 360;
			motion.velocity.x = -400;
			motion.velocity.y = -MotionUtils.GRAVITY;
			motion.acceleration = new Point( 4, MotionUtils.GRAVITY );
			
			threshold = new Threshold( "x", "<" );
			threshold.threshold = 1550;
			threshold.entered.addOnce( shatterGlass );
			entity.add( threshold );
			
			for( number = 1; number < 5; number ++ )
			{
				entity = getEntityById( "debris" + number );
				Display( entity.get( Display )).visible = true;
				motion = entity.get( Motion );
				
				rotation = ( Math.random() * 180 ) + 180;
				velocity = ( Math.random() * 60 ) + 350;
				
				motion.rotationVelocity = rotation;
				motion.velocity.x = -velocity;
				motion.velocity.y = -MotionUtils.GRAVITY + 100;
				motion.acceleration = new Point( 4, MotionUtils.GRAVITY );
				
				entity.add( new Id( "debris" + number ));
				audioGroup.addAudioToEntity( entity );
				
				threshold = new Threshold( "y", ">" );
				threshold.threshold = 940;
				threshold.entered.addOnce( Command.create( stopMotion, entity ));
				entity.add( threshold );
			}
		}
		
		private function stopMotion( entity:Entity ):void
		{
			var spatial:Spatial = entity.get( Spatial );
			var motion:Motion = entity.get( Motion );
			var audio:Audio = entity.get( Audio );
			audio.playCurrentAction( "trigger" );
			var tween:Tween = new Tween();
			
			motion.rotationVelocity = 0;
			entity.add( tween );
			
			MotionUtils.zeroMotion( entity );			
			tween.to( spatial, .2, { x : spatial.x - 50, y : 1020 });
		}
		
		private function shatterGlass():void
		{
			var entity:Entity = getEntityById( "window" );
			var audio:Audio = entity.get( Audio );
			audio.playCurrentAction( "trigger" );
			var timeline:Timeline = entity.get( Timeline );
			var playerSpatial:Spatial = player.get( Spatial );
			timeline.gotoAndPlay( "break" );
			
			entity = getEntityById( "hertz" );
			SceneUtil.setCameraTarget( this, entity );
			CharUtils.moveToTarget( entity, playerSpatial.x - 100, playerSpatial.y - 20, false, hertzGrovel );
		}
		
		private function hertzGrovel( entity:Entity ):void
		{
			var motion:Motion = entity.get( Motion );
			var spatial:Spatial = entity.get( Spatial );
			
			
			motion.rotationVelocity = 0;
			spatial.rotation = 0;
			
			CharUtils.setDirection( entity, true );
			CharUtils.setDirection( player, false );
			
			var sequence:Vector.<Class> = new Vector.<Class>;
			sequence.push( Cry, Grief );
			CharUtils.setAnimSequence( entity, sequence, true );
			
			var rigAnim:RigAnimation = CharUtils.getRigAnim( entity, 1 );
			
			if ( rigAnim == null )
			{
				var animationSlot:Entity = AnimationSlotCreator.create( entity );
				rigAnim = animationSlot.get( RigAnimation ) as RigAnimation;
			}
			
			rigAnim.next = DuckNinja;
			rigAnim.addParts( 	CharUtils.HAND_FRONT, CharUtils.HAND_BACK, CharUtils.ARM_FRONT, CharUtils.ARM_BACK, 
				CharUtils.BODY_JOINT, CharUtils.NECK_JOINT, CharUtils.LEG_BACK, CharUtils.LEG_FRONT );
			
			SceneUtil.addTimedEvent( this, new TimedEvent( 2, 1, hertzReturns ));
		}
		
		private function hertzReturns():void
		{
			var entity:Entity = getEntityById( "hertz" );
			var dialog:Dialog = entity.get( Dialog );
			
			dialog.sayById( "monster" );
		}
		
		private static const FLASH_VALUE:uint = 1;
		private static const DIM_VALUE:Number = .3;
		private static const DIM_SPEED:Number = .75;
		private static const COMPUTER_VENT_VELOCITY:uint = 555;
		private static const ROOM_VENT_VELOCITY:uint = 250;
		
		private var _dialogTimedEvent:TimedEvent;
		private var _events:MocktropicaEvents;
		
		private var matrixDissolveEmitter:MatrixDissolveEmitter;
		private var matrixDissolve:Entity;
	}
}