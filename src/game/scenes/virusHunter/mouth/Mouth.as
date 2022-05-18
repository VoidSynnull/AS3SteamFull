package game.scenes.virusHunter.mouth
{
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.geom.Point;
	import flash.text.TextFormat;
	import flash.utils.Dictionary;
	
	import ash.core.Entity;
	
	import engine.components.Display;
	import engine.components.Id;
	import engine.components.Interaction;
	import engine.components.Motion;
	import engine.components.Spatial;
	import engine.components.Tween;
	import engine.util.Command;
	
	import game.components.Emitter;
	import game.components.entity.DepthChecker;
	import game.components.entity.Sleep;
	import game.components.hit.Door;
	import game.components.hit.Item;
	import game.components.motion.ShakeMotion;
	import game.components.motion.Threshold;
	import game.components.scene.SceneInteraction;
	import game.components.timeline.Timeline;
	import game.creators.entity.EmitterCreator;
	import game.creators.scene.HitCreator;
	import game.data.TimedEvent;
	import game.data.animation.entity.character.Celebrate;
	import game.data.scene.DoorData;
	import game.data.scene.hit.HitType;
	import game.managers.EntityPool;
	import game.scene.template.PlatformerGameScene;
	import game.scenes.virusHunter.VirusHunterEvents;
	import game.scenes.virusHunter.mouth.components.Bubble;
	import game.scenes.virusHunter.mouth.components.Mucus;
	import game.scenes.virusHunter.mouth.emitters.Static;
	import game.scenes.virusHunter.mouth.systems.BubbleSystem;
	import game.scenes.virusHunter.mouth.systems.MucusSystem;
	import game.scenes.virusHunter.shared.ui.ShipDialogWindow;
	import game.systems.SystemPriorities;
	import game.systems.entity.character.CharacterDepthSystem;
	import game.systems.motion.ShakeMotionSystem;
	import game.systems.motion.ThresholdSystem;
	import game.ui.popup.CharacterDialogWindow;
	import game.util.CharUtils;
	import game.util.ClassUtils;
	import game.util.EntityUtils;
	import game.util.MotionUtils;
	import game.util.SceneUtil;
	import game.util.SkinUtils;
	import game.util.TextUtils;
	import game.util.TimelineUtils;
	
	import org.flintparticles.common.actions.Age;
	import org.flintparticles.common.actions.Fade;
	import org.flintparticles.common.actions.ScaleImage;
	import org.flintparticles.common.counters.Random;
	import org.flintparticles.common.displayObjects.Blob;
	import org.flintparticles.common.easing.Quadratic;
	import org.flintparticles.common.initializers.AlphaInit;
	import org.flintparticles.common.initializers.ImageClass;
	import org.flintparticles.common.initializers.Lifetime;
	import org.flintparticles.twoD.actions.Accelerate;
	import org.flintparticles.twoD.actions.Move;
	import org.flintparticles.twoD.actions.RandomDrift;
	import org.flintparticles.twoD.emitters.Emitter2D;
	import org.flintparticles.twoD.initializers.Position;
	import org.flintparticles.twoD.initializers.Velocity;
	import org.flintparticles.twoD.zones.EllipseZone;
	import org.flintparticles.twoD.zones.LineZone;
	import org.flintparticles.twoD.zones.RectangleZone;
	
	public class Mouth extends PlatformerGameScene
	{
		public function Mouth()
		{
			super();
		}
		
		// pre load setup
		override public function init(container:DisplayObjectContainer = null):void
		{			
			super.groupPrefix = "scenes/virusHunter/mouth/";
			
			super.init(container);
			
			_entityPool = new EntityPool();
			_total = new Dictionary();
		}
		
		// initiate asset load of scene specific assets.
		override public function load():void
		{
			createCharacterDialogWindow();
			
			super.load();
		}
		
		override protected function allCharactersLoaded():void
		{
			super.player.remove(DepthChecker);
			
			super.allCharactersLoaded();
		}
		
		// all assets ready
		override public function loaded():void
		{
			_events = super.events as VirusHunterEvents;
			
			super.loaded();
			
			addSystem( new BubbleSystem( this, _entityPool, _total ), SystemPriorities.update );
			addSystem( new MucusSystem( this, _entityPool, _total ), SystemPriorities.update );
			addSystem( new ThresholdSystem(), SystemPriorities.update );
			
			_hitContainer.swapChildren( Display( player.get( Display )).displayObject,  _hitContainer[ "playerEmpty" ]);
			Display( shellApi.player.get(Display) ).displayObject.mouseEnabled = false;

			setupScene();
		}
		
		public function setupScene():void
		{
			var shield:Entity = super.getEntityById( "shield" );
			
			toothLoader();
			
			super.loadFile( "bubble.swf", bubbleLoader );
			super.loadFile( "mucus.swf", mucusLoader );
			
			if(! super.shellApi.checkEvent( _events.GOT_SHIELD ))
			{
				var shipShield:Entity = EntityUtils.createSpatialEntity( this, MovieClip( super._hitContainer[ "shipShield" ]) );
				shipShield.add( new Id( "shipShield" ));
				Display( shipShield.get( Display )).alpha = 0;
				
				var emitter:Static = new Static();
				emitter.init();
				
				EmitterCreator.create( this, super.getEntityById( "shield" ).get( Display ).displayObject, emitter );
				
				var interactionEntity:Entity = super.getEntityById( "toothInteraction" );
				shield.remove( Item );
				
				shield.add( new ShakeMotion());
				ShakeMotionSystem( super.addSystem( new ShakeMotionSystem() )).configEntity( shield );
				shakeShield();
								
				var interaction:Interaction = interactionEntity.get( Interaction );
				interaction.click.add( interactionTriggered );
			}
			else
			{
				super.removeEntity( super.getEntityById( "toothInteraction" ));
				super.removeEntity( shield );
			}
			var door:Entity = super.getEntityById( "doorStomach" );
			
			var shipInteraction:SceneInteraction = super.getEntityById( "doorStomach" ).get( SceneInteraction );
			shipInteraction.reached.removeAll(); 
				
			shipInteraction.reached.add( closeShipHatch );
			
			if(! super.shellApi.checkEvent( _events.GOT_ANTIGRAV ))
			{
				MovieClip( super._hitContainer[ "antiGrav" ]).visible = false;
			}
			
			SceneUtil.lockInput( this );
			 //progressOnFoot ));//
			super.removeSystemByClass( CharacterDepthSystem ); // openShipHatch
			progressOnFoot();
//			SceneUtil.addTimedEvent( this, new TimedEvent( 3, 1, progressOnFoot ));
		}
		
		/*********************************************************************************
		 * SCENE DOOR CONTROLS
		 */
		private function progressOnFoot():void
		{
			playMessage( "arrived_in_throat", false );
			_dialogWindow.messageComplete.addOnce( playerAcquiesce );
		}
		
		private function playerAcquiesce():void
		{
			playMessage( "say_so", true, null, "player" );
			_dialogWindow.messageComplete.addOnce( openShipHatch );
		}
		
		private function openShipHatch():void
		{
			var windowR:Entity = EntityUtils.createSpatialEntity( this, super._hitContainer[ "windowR" ]);
			var windowL:Entity = EntityUtils.createSpatialEntity( this, super._hitContainer[ "windowL" ]);
			
			var tween:Tween = new Tween();
			var spatial:Spatial = windowL.get( Spatial );
			tween.to( spatial, 1.5, { rotation : -118 });
			windowL.add( tween ).add( new Id( "windowL" ));
			
			tween = new Tween();
			spatial = windowR.get( Spatial );
			tween.to( spatial, 1.5, { rotation : 150 });
			windowR.add( tween ).add( new Id( "windowR" ));
			
			super.shellApi.triggerEvent( _events.HATCH_OPEN );
			startSmoke();
		}
		
		private function startSmoke():void
		{
			var emitter:Emitter2D = new Emitter2D();
			
			emitter.counter = new Random( 100, 200 );
			emitter.addInitializer( new ImageClass( Blob, [10, 0xEEEEEE], true ) );
			emitter.addInitializer( new AlphaInit( .6, .7 ));
			emitter.addInitializer( new Lifetime( .5, 1 ) ); 
			emitter.addInitializer( new Velocity( new LineZone( new Point( -75, -100), new Point( 100, -55 ) ) ) );
			emitter.addInitializer( new Position( new EllipseZone( new Point( 10, 0 ), 30, 5)));
			
			emitter.addAction( new Age( Quadratic.easeOut ) );
			emitter.addAction( new Move() );
			emitter.addAction( new RandomDrift( 100, 100 ) );
			emitter.addAction( new ScaleImage( .7, 1.5 ) );
			emitter.addAction( new Fade(.7, 0));
			emitter.addAction( new Accelerate( 0, -10) );
			
			EmitterCreator.create( this, super._hitContainer[ "playerBubbleEmpty" ], emitter, 505, 3600, null, "smokeEmitter" );
			
			weakenStream( 1 );
		}
		
		private function weakenStream( loop:int ):void
		{
			var counter:int = loop + 1;
			var smoke:Entity = super.getEntityById( "smokeEmitter" );
			var emitter:Emitter2D = super.getEntityById( "smokeEmitter" ).get( Emitter ).emitter;
			if( counter < 20 )
			{
				emitter.counter = new Random( 100 - ( counter * 5 ), 200 - ( counter * 10 ));
				SceneUtil.addTimedEvent( this, new TimedEvent( .1, 1, Command.create( weakenStream, counter )));
			}
			else if( counter < 30 )
			{
				emitter.counter = new Random( 1, 30 - loop );
				SceneUtil.addTimedEvent( this, new TimedEvent( .1, 1, Command.create( weakenStream, counter )));
			}
			else
			{
				equalizePressure( );
			}
		}
		
		private function equalizePressure():void
		{
			super.removeEntity( super.getEntityById( "smokeEmitter" ));	
			SceneUtil.lockInput( this, false, false );
	//		progressOnFoot();
		}
		
		private function closeShipHatch( player:Entity, shipDoor:Entity ):void
		{
			SceneUtil.lockInput( this, true, false );
			
			var windowR:Entity = super.getEntityById( "windowR" );
			var windowL:Entity = super.getEntityById( "windowL" );
			
			var tween:Tween = windowL.get( Tween );
			var spatial:Spatial = windowL.get( Spatial );
			tween.to( spatial, 1.5, { rotation : 16.8 });
			
			tween = windowR.get( Tween );
			spatial = windowR.get( Spatial );
			
			super.shellApi.triggerEvent( _events.HATCH_CLOSE );
			
			var args:Object = new Object();
			args.rotation = 16.8;
			
			if( _gotShield )
			{
				args.onComplete = checkShield;
			}
			else
			{
				args.onComplete = switchScenes;
			}
			
			tween.to( spatial, 1.5, args );
		}
		
		private function checkShield( ):void
		{
			var shipShield:Entity = super.getEntityById( "shipShield" );
			var display:Display = shipShield.get( Display );
			var tween:Tween = new Tween();
			
			super.shellApi.triggerEvent( _events.GOT_SHIELD, true );
			tween.to( display, 1.5, { alpha : 1 });
			shipShield.add( tween );
			
			playMessage( "shield_online", false );
			_dialogWindow.messageComplete.addOnce( switchScenes );
		}
		
		private function switchScenes():void
		{
			var data:DoorData = super.getEntityById( "doorStomach" ).get( Door ).data;
			
			super.shellApi.loadScene( ClassUtils.getClassByName( data.destinationScene ), data.destinationSceneX, data.destinationSceneY, data.destinationSceneDirection );
			
		}
			
		/*********************************************************************************
		 * TOOTH :: SECONDARY OBJECTIVE
		 */
		private function toothLoader():void
		{
			var tooth:Entity = EntityUtils.createSpatialEntity( this, super._hitContainer[ "tooth" ]);
			
			if( super.shellApi.checkEvent( _events.TOOTH_REMOVED ))
			{
				Display( tooth.get( Display )).visible = false;	
				super.removeEntity( super.getEntityById( "snaggleWall" ));
				super.removeEntity( super.getEntityById( "snaggleTooth" ));
				super.removeEntity( super.getEntityById( "toothHazard" ));
			}
			
			else
			{
				TimelineUtils.convertClip( MovieClip( EntityUtils.getDisplayObject( tooth )), this, tooth );
				var timeline:Timeline = tooth.get( Timeline );
			
				if( super.shellApi.checkEvent( _events.TOOTH_CHIPPED_ + "4" ))
				{
					timeline.gotoAndStop( 4 );
				}
				else if( super.shellApi.checkEvent( _events.TOOTH_CHIPPED_ + "3" ))
				{
					timeline.gotoAndStop( 3 );
				}
				else if( super.shellApi.checkEvent( _events.TOOTH_CHIPPED_ + "2" ))
				{
					timeline.gotoAndStop( 2 );
				}
				else if( super.shellApi.checkEvent( _events.TOOTH_CHIPPED_ + "1" ))
				{
					timeline.gotoAndStop( 1 );
				}
				else
				{
					timeline.gotoAndStop( 0 );
				}
			}
		}
		
		/*********************************************************************************
		 * SHIELD UPGRADE
		 */
		
		private function interactionTriggered( tooth:Entity ):void
		{
			tooth.remove( SceneInteraction );
			super.removeEntity( tooth );
			var shield:Entity = super.getEntityById( "shield" );
			
			SceneUtil.lockInput(this, true, false);
			dropShield();
//			SceneUtil.addTimedEvent( this, new TimedEvent( 1, 1, dropShield ));
		}
		
		private function shakeShield( ):void
		{
			var shake:ShakeMotion = super.getEntityById( "shield" ).get( ShakeMotion );
			shake.shakeZone = new RectangleZone( -5, -5, 5, 5 );
		}
		
		private function dropShield( ):void
		{
			var shield:Entity = super.getEntityById( "shield" );
			shield.remove( ShakeMotion );
			
			var spatial:Spatial = shield.get( Spatial );
			var motion:Motion = new Motion();
			motion.acceleration.y = MotionUtils.GRAVITY;
			shield.add( motion );
			
			var threshold:Threshold = new Threshold( "y", ">=" );
			threshold.threshold = 1035;
			threshold.entered.add( getShield );
			
			shield.add( threshold );
		}
		
		private function getShield( ):void
		{
			var shield:Entity = super.getEntityById( "shield" );
			var motion:Motion = shield.get( Motion );
			motion.velocity.y = 0;
			motion.acceleration.y = 0;
			
			Display( shield.get( Display )).alpha = 0;
			_gotShield = true;
			
			SceneUtil.lockInput(this, false, false);
			
			CharUtils.setAnim( super.player, Celebrate );
		}
		
		/*********************************************************************************
		 * BUBBLE PLATFORM PUZZLE SETUP
		 */
		private function bubbleLoader( asset:MovieClip ):void
		{
			var bubble:Entity = _entityPool.request( "bubble" );
			var platform:Entity = _entityPool.request( "platform" );
			var bubbleComp:Bubble;
			var creator:HitCreator;
			var sleep:Sleep;
			
			if( !_total[ "bubble" ]) 
			{ 
				_total[ "bubble" ] = 0; 
			}
			_total[ "bubble" ]++;
			
			if( !_total[ "platform" ]) 
			{ 
				_total[ "platform" ] = 0; 
			}
			_total[ "platform" ]++;
			
			if( bubble != null )
			{
				bubbleComp = bubble.get( Bubble );
				bubbleComp.init = false;
				bubbleComp.recycled = true;
			}
			
			else
			{
				bubbleComp = new Bubble();
				
				sleep = new Sleep();
				sleep.ignoreOffscreenSleep = true;
				
				// create main bubble entityz
				bubble = EntityUtils.createMovingEntity( this, asset, super._hitContainer[ "bubbleContainer" ]);
				bubble.add( bubbleComp ).add( sleep );
				creator = new HitCreator();
				
				// create platform entity to follow the bubble entity
				sleep = new Sleep();
				sleep.ignoreOffscreenSleep = true;
				
				bubbleComp.platform = EntityUtils.createSpatialEntity( this, asset.content.platform, super._hitContainer );
				bubbleComp.platform.add( sleep ).add( new Id( "platform" ));
				creator.makeHit( bubbleComp.platform, HitType.PLATFORM );
			}
			
			SceneUtil.addTimedEvent( this, new TimedEvent( Math.random() + 4, 1, Command.create( super.loadFile, "bubble.swf", bubbleLoader )));
		}
		
		/*********************************************************************************
		 * MUCUS 
		 */
		private function mucusLoader( asset:MovieClip ):void
		{
			var mucus:Entity = _entityPool.request( "mucus" );
			var mucusComp:Mucus;
			var sleep:Sleep;
			
			if( !_total[ "mucus" ]) 
			{ 
				_total[ "mucus" ] = 0; 
			}
			_total[ "mucus" ]++;
			
			if( mucus != null )
			{
				mucusComp = mucus.get( Mucus );
				mucusComp.init = false;
			}
			
			else
			{
				mucusComp = new Mucus();
				sleep = new Sleep();
				sleep.ignoreOffscreenSleep = true;
				mucus = EntityUtils.createMovingEntity( this, asset, super._hitContainer[ "mucusContainer" ]);
				mucus.add( mucusComp ).add( sleep );
			}
			
			SceneUtil.addTimedEvent( this, new TimedEvent( Math.random() * 10, 1, Command.create( super.loadFile, "mucus.swf", mucusLoader )));
		}
		
		/*********************************************************************************
		 * HUD 
		 */
		protected function createCharacterDialogWindow(asset:String = "dialogWindow.swf", groupPrefix:String = "scenes/virusHunter/shared/"):void
		{
			_dialogWindow = new ShipDialogWindow(super.overlayContainer);
			_dialogWindow.config( null, null, false, false, false, false );
			_dialogWindow.configData( groupPrefix, asset );
			_dialogWindow.ready.addOnce(characterDialogWindowReady);
			
			super.addChildGroup(_dialogWindow);
		}
		
		protected function characterDialogWindowReady(charDialog:CharacterDialogWindow):void
		{
			charDialog.screen.x = super.shellApi.viewportWidth/2 - charDialog.screen.width/2;
			// adjust character
			
			charDialog.adjustChar( "player", charDialog.screen.shipText, new Point(20, 45), .5 );
			
			if(super.shellApi.profileManager.active.look)
			{
				SkinUtils.setSkinPart( charDialog.charEntity, SkinUtils.EYES, super.shellApi.profileManager.active.look.eyes );
				SkinUtils.setSkinPart( charDialog.charEntity, SkinUtils.SKIN_COLOR, super.shellApi.profileManager.active.look.skinColor );
				SkinUtils.setSkinPart( charDialog.charEntity, SkinUtils.MOUTH, super.shellApi.profileManager.active.look.mouth );
				SkinUtils.setSkinPart( charDialog.charEntity, SkinUtils.EYE_STATE, super.shellApi.profileManager.active.look.eyeState );
				SkinUtils.setSkinPart( charDialog.charEntity, SkinUtils.MARKS, super.shellApi.profileManager.active.look.marks );
				SkinUtils.setSkinPart( charDialog.charEntity, SkinUtils.FACIAL, super.shellApi.profileManager.active.look.facial );
				SkinUtils.setSkinPart( charDialog.charEntity, SkinUtils.HAIR, super.shellApi.profileManager.active.look.hair );
				SkinUtils.setSkinPart( charDialog.charEntity, SkinUtils.HAIR_COLOR, super.shellApi.profileManager.active.look.hairColor );
			}
			
			charDialog.adjustChar( "drLang", charDialog.screen.shipText, new Point(20, 45), .5 );
			
			// assign textfield
			charDialog.textField = TextUtils.refreshText( charDialog.screen.shipText.text );	
			charDialog.textField.embedFonts = true;
			
			charDialog.textField.defaultTextFormat = new TextFormat( "CreativeBlock BB", 16, 0xffffff );
			MovieClip( charDialog.screen.shipText.bodyMap ).visible = false; //, this );
		}
		
		public function playMessage(id:String, useCharacter:Boolean = true, graphicsFrame:String = null, characterId:String = "drLang"):void
		{
			if( graphicsFrame == null )
			{
				graphicsFrame = id;
			}
			
			_dialogWindow.playShipMessage(id, useCharacter, graphicsFrame, characterId);
		}		
		
		private var _events:VirusHunterEvents;
		private var _entityPool:EntityPool;
		private var _gotShield:Boolean = false;
		private var _total:Dictionary;
		
		protected var _dialogWindow:ShipDialogWindow;
		protected var _bodyMap:Entity;
	}
}