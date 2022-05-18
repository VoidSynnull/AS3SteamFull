package game.scenes.ghd.neonWiener
{	
	import flash.display.BitmapData;
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.display.Sprite;
	import flash.geom.Point;
	import flash.net.URLRequest;
	import flash.net.navigateToURL;
	
	import ash.core.Entity;
	
	import engine.components.Audio;
	import engine.components.AudioRange;
	import engine.components.Display;
	import engine.components.Id;
	import engine.components.Motion;
	import engine.components.Spatial;
	import engine.components.SpatialAddition;
	import engine.components.Tween;
	import engine.creators.InteractionCreator;
	import engine.managers.SoundManager;
	
	import game.components.Emitter;
	import game.components.entity.Dialog;
	import game.components.entity.Sleep;
	import game.components.entity.character.Character;
	import game.components.entity.character.Npc;
	import game.components.entity.character.animation.AnimationControl;
	import game.components.entity.character.animation.AnimationSequencer;
	import game.components.entity.character.animation.RigAnimation;
	import game.components.entity.character.part.SkinPart;
	import game.components.hit.Door;
	import game.components.motion.Destination;
	import game.components.motion.Edge;
	import game.components.motion.ShakeMotion;
	import game.components.motion.WaveMotion;
	import game.components.scene.SceneInteraction;
	import game.components.timeline.BitmapSequence;
	import game.components.timeline.Timeline;
	import game.creators.entity.AnimationSlotCreator;
	import game.creators.entity.BitmapTimelineCreator;
	import game.creators.entity.EmitterCreator;
	import game.creators.ui.ToolTipCreator;
	import game.data.TimedEvent;
	import game.data.WaveMotionData;
	import game.data.animation.Animation;
	import game.data.animation.AnimationSequence;
	import game.data.animation.FrameEvent;
	import game.data.animation.entity.PartAnimationData;
	import game.data.animation.entity.character.Grief;
	import game.data.animation.entity.character.Overhead;
	import game.data.animation.entity.character.PointItem;
	import game.data.animation.entity.character.Proud;
	import game.data.animation.entity.character.Pull;
	import game.data.animation.entity.character.Push;
	import game.data.animation.entity.character.Sit;
	import game.data.animation.entity.character.Stand;
	import game.data.animation.entity.character.Tremble;
	import game.data.comm.PopResponse;
	import game.data.display.BitmapWrapper;
	import game.data.scene.characterDialog.DialogData;
	import game.particles.FlameCreator;
	import game.scene.SceneSound;
	import game.scene.template.AudioGroup;
	import game.scene.template.CharacterGroup;
	import game.scene.template.ItemGroup;
	import game.scenes.ghd.GalacticHotDogScene;
	import game.scenes.ghd.escape.Escape;
	import game.scenes.ghd.shared.popups.galaxyMap.GalaxyMap;
	import game.scenes.map.map.Map;
	import game.systems.entity.AnimationLoaderSystem;
	import game.systems.motion.ShakeMotionSystem;
	import game.systems.motion.WaveMotionSystem;
	import game.ui.popup.IslandBlockPopup;
	import game.ui.popup.IslandEndingPopup;
	import game.ui.showItem.ShowItem;
	import game.util.AudioUtils;
	import game.util.BitmapUtils;
	import game.util.CharUtils;
	import game.util.DisplayUtils;
	import game.util.EntityUtils;
	import game.util.PerformanceUtils;
	import game.util.SceneUtil;
	import game.util.SkinUtils;
	import game.util.Utils;
	
	import org.flintparticles.common.actions.Age;
	import org.flintparticles.common.actions.Fade;
	import org.flintparticles.common.actions.ScaleImage;
	import org.flintparticles.common.counters.Blast;
	import org.flintparticles.common.counters.Random;
	import org.flintparticles.common.counters.Steady;
	import org.flintparticles.common.displayObjects.Blob;
	import org.flintparticles.common.displayObjects.Line;
	import org.flintparticles.common.displayObjects.Ring;
	import org.flintparticles.common.displayObjects.Star;
	import org.flintparticles.common.initializers.BitmapImage;
	import org.flintparticles.common.initializers.ColorInit;
	import org.flintparticles.common.initializers.ImageClass;
	import org.flintparticles.common.initializers.Lifetime;
	import org.flintparticles.twoD.actions.Accelerate;
	import org.flintparticles.twoD.actions.AccelerateToPoint;
	import org.flintparticles.twoD.actions.DeathZone;
	import org.flintparticles.twoD.actions.Move;
	import org.flintparticles.twoD.actions.MutualGravity;
	import org.flintparticles.twoD.actions.RandomDrift;
	import org.flintparticles.twoD.actions.RotateToDirection;
	import org.flintparticles.twoD.emitters.Emitter2D;
	import org.flintparticles.twoD.initializers.Position;
	import org.flintparticles.twoD.initializers.Velocity;
	import org.flintparticles.twoD.zones.DiscZone;
	import org.flintparticles.twoD.zones.PointZone;
	import org.flintparticles.twoD.zones.RectangleZone;
	
	public class NeonWiener extends GalacticHotDogScene
	{
		private var _animationLoader:AnimationLoaderSystem;
		private var _characterGroup:CharacterGroup;
		private var _flameCreator:FlameCreator;
		private var _audioGroup:AudioGroup;
		
		private var _humphree:Entity;
		private var _cosmoe:Entity;
		private var _dagger:Entity;
		private var _wormHole:Entity;
		private var _helm:Entity;
		private var _fred:Entity;
		private var _chair:Entity;
		private var _ui:Entity;
		private var _sceneSound:Audio;
		
		private var _cameraEntity:Entity;
		private var _humphreeToTheRescue:Boolean 	=	false;
		private var _humphreeFacingLeft:Boolean 	=	false;
		private var _portalOpen:Boolean				= 	false;
		private var _highQuality:Boolean;
		
		private const CLOSE:String					= 	"close";
		private const OPEN:String					=	"open";
		private const TRIGGER:String				=	"trigger";
		private const COSMOE_PLACEMENT:Point		=	new Point( 320, 574 );
		private const COSMOE_HELM:Point				=	new Point( 230, 508 );

		private const NEON_WIENER_TRACK:String		=	"neon_wiener.mp3";
		private const WORM_HOLE_TRACK:String		=	"wormhole.mp3";
		private const MAIN_THEME:String				=	"galactic_hot_dogs_main_theme.mp3";
		private const ENGINES_ON:String				= 	"mid_rumble_01_loop.mp3";
		private const TELEPORT:String				= 	"event_01.mp3";
		private const POWER_DOWN:String				=	"power_down_05.mp3";
		
		public function NeonWiener()
		{
			super();
		}
		
		override public function init( container:DisplayObjectContainer = null ):void
		{			
			super.groupPrefix = "scenes/ghd/neonWiener/";
			
			super.init(container);
		}
		
		override protected function addCharacters():void
		{
			super.addCharacters();
			
			// PRELOAD ANIMATIONS FOR SNEAKING
			_characterGroup = super.getGroupById( CharacterGroup.GROUP_ID ) as CharacterGroup;
			_characterGroup.preloadAnimations( new <Class>[ Push, Pull, Sit ], this );
			
			_animationLoader = super.getSystem( AnimationLoaderSystem ) as AnimationLoaderSystem;
		}
		
		//////////////////////////////// FRED SETUP ////////////////////////////////
		override protected function addCharacterDialog(container:Sprite):void
		{
			setupFred();
			super.addCharacterDialog( container );
		}
		
		private function setupFred():void
		{
			var clip:MovieClip = _hitContainer[ "fred" ];
			var sequence:BitmapSequence = BitmapTimelineCreator.createSequence( clip, true, PerformanceUtils.defaultBitmapQuality );
			
			_fred = EntityUtils.createSpatialEntity( this, clip, _hitContainer );
			BitmapTimelineCreator.convertToBitmapTimeline( _fred, clip, true, sequence, PerformanceUtils.defaultBitmapQuality );
			var timeline:Timeline = _fred.get( Timeline );
			
			_fred.add( new Id( "fred" ));
			
			var waveMotion:WaveMotion = new WaveMotion();
			var waveMotionData:WaveMotionData;
			waveMotionData = new WaveMotionData( "y", 3.4, .04 );
			waveMotion.data.push( waveMotionData );
			
			_fred.add( waveMotion ).add( new SpatialAddition());
			ToolTipCreator.addToEntity( _fred );
			InteractionCreator.addToEntity( _fred, [ InteractionCreator.CLICK ]);
			
			// ADD FRED'S DIALOG
			var dialog:Dialog = new Dialog();
			dialog.faceSpeaker = false;
			dialog.dialogPositionPercents = new Point( -.5, .5 );		
			dialog.balloonPath = "ui/elements/wordBalloonRadio.swf";
			_fred.add( dialog );
			
			// SETUP FRED'S TIMELINE AND INTERACTIONS
			var sceneInteraction:SceneInteraction = new SceneInteraction();
			sceneInteraction.offsetY = 100;
			sceneInteraction.reached.add( talkToFred );
			
			var character:Character = new Character();
			character.costumizable = false;
			
			_fred.add( character ).add( sceneInteraction ).add( new Edge( -50, -50, 100, 100 )).add( new Npc());
		}
		
		
		private function talkToFred( player:Entity, fred:Entity ):void
		{
			var timeline:Timeline = _ui.get( Timeline );
			timeline.play();
			
			if( !shellApi.checkEvent( _events.GOT_ALL_MAP_PIECES ) && ( shellApi.checkEvent( _events.UNFINISHED_CREW ) || shellApi.checkEvent( _events.ASK_FRED )))
			{
				var dialog:Dialog = _fred.get( Dialog );
				dialog.complete.add( launchGalaxyMap );
			}
		}
		
		override protected function addBaseSystems():void
		{
			addSystem( new WaveMotionSystem());
			super.addBaseSystems();
		}
		
		// initiate asset load of scene specific assets.
		override public function load():void
		{
			super.load();
		}
		
		// all assets ready
		override public function loaded():void
		{
			_highQuality = ( PerformanceUtils.qualityLevel < PerformanceUtils.QUALITY_HIGHEST ) ? false : true;
			_audioGroup = this.getGroupById(AudioGroup.GROUP_ID) as AudioGroup;
			
			if( _highQuality )
			{
				addSystem( new ShakeMotionSystem());
			}
			_cameraEntity = getEntityById( "camera" );
			
			initShip();
			
			if( !shellApi.checkEvent( _events.READY_FOR_CONTEST ))
			{
				optimizeAssets();
				removeWormHole();
			}
				
			else
			{
				removeEarlyAssets();
				
				if( !shellApi.checkHasItem( _events.MEDAL_GHD ))
				{
					if( !shellApi.checkEvent( _events.WORM_HOLE_APPEARED ))
					{
						thatWentPoorly();
					}
					else
					{					
						removeWormHole();
						
						if( shellApi.checkHasItem( _events.MAP_O_SPHERE ))
						{
							getOutOfHere();
						}
						
						else if( shellApi.checkEvent( _events.RECOVERED_CREW ))
						{ 
							if( !shellApi.checkEvent( _events.ASK_FRED ))
							{
								findTheMap();
							}
						}
					}
				}
			}
			
			super.loaded();
			_sceneSound = AudioUtils.getAudio( this, SceneSound.SCENE_SOUND );
		}
		
		//////////////////////////////// PILOT ANIMATION /////////////////////////////
		private function initPilotAnimations():void
		{
			var pushAnimation:Push = _animationLoader.animationLibrary.getAnimation( Push ) as Push;
			var pullAnimation:Pull = _animationLoader.animationLibrary.getAnimation( Pull ) as Pull;
			var sitAnimation:Sit = _animationLoader.animationLibrary.getAnimation( Sit ) as Sit;
			
			var frameEvent:FrameEvent;
			var number:int;
			var replacementData:PartAnimationData;
			var parts:Array = [ "foot1", "foot2", "leg1", "leg2" ];
			var part:String;
			
			// MAKE SITTING
			for each( part in parts )
			{
				replacementData = sitAnimation.data.parts[ part ];
				pullAnimation.data.parts[ part ] = replacementData;
				pushAnimation.data.parts[ part ] = replacementData;
			}
			
			// EXTEND ARM
			for( number = 0; number < pullAnimation.data.duration; number ++ )
			{
				pullAnimation.data.parts[ "hand1" ].kframes[ number ].x -= 15;
				pullAnimation.data.parts[ "hand1" ].kframes[ number ].y -= 10;
				
				pushAnimation.data.parts[ "foot2" ].kframes[ number ].x -= 5;
				pushAnimation.data.parts[ "foot2" ].kframes[ number ].y -= 2;
			}
			for( number = 0; number < pushAnimation.data.duration; number ++ )
			{
				pushAnimation.data.parts[ "hand1" ].kframes[ number ].x -= 15;
				pushAnimation.data.parts[ "hand1" ].kframes[ number ].y -= 10;
				
				pushAnimation.data.parts[ "foot2" ].kframes[ number ].x -= 5;
				pushAnimation.data.parts[ "foot2" ].kframes[ number ].y -= 2;
			}
			
			// START AT LOOPING AREA
			
			frameEvent = new FrameEvent( "gotoAndPlay", 12 );
			while( pullAnimation.data.frames[ 0 ].events.length > 0 )
			{
				pullAnimation.data.frames[ 0 ].events.pop();
			}
			pullAnimation.data.frames[ 0 ].events.push( frameEvent );
			while( pushAnimation.data.frames[ 0 ].events.length > 0 )
			{
				pushAnimation.data.frames[ 0 ].events.pop();
			}
			pushAnimation.data.frames[ 0 ].events.push( frameEvent );
		}
		
		//////////////////////////////// ISLAND BLOCK ////////////////////////////////
//		
//		private function setupIslandBlocker():void
//		{
//			if( shellApi.checkEvent( _events.WORM_HOLE_APPEARED ) && IslandBlockPopup.checkIslandBlock( super.shellApi ))// || true )	// TESTING :: Set to true automatically for testing
//			{
//				// get door interaction
//				var shipDoor:Entity = super.getEntityById( "doorShip" );
//				var door:Door = shipDoor.get( Door );
//				door.data.destinationScene = "game.scenes.ghd.spacePort.SpacePort";
//				
//				var sceneInteraction:SceneInteraction = _fred.get( SceneInteraction );
//				sceneInteraction.reached.removeAll();
//				sceneInteraction.reached.add(openIslandBlock);
//			}
//		}
//		
//		private function openIslandBlock( ...args ):void
//		{
//			SceneUtil.lockInput(this, false);
//			var blockPopup:IslandBlockPopup = super.addChildGroup( new IslandBlockPopup( "scenes/ghd/", super.overlayContainer) ) as IslandBlockPopup;	
//		}
//			
		//////////////////////////////// SHIP SETUP ////////////////////////////////
	
		private function initShip():void
		{
			var asset:String;
			var assets:Array;
			var clip:MovieClip;
			var entity:Entity;
			var sceneInteraction:SceneInteraction;
			var sequence:BitmapSequence;
			var spatial:Spatial;
			var timeline:Timeline;
			
			var wrapper:BitmapWrapper;
			
			// CONTROL PANEL ENTITIES THAT SOMETIMES MOVE
			assets = [ "helm", "chair", "redButton" ];
			
			for each( asset in assets )
			{
				clip = _hitContainer[ asset ];
				entity = EntityUtils.createSpatialEntity( this, clip, _hitContainer );
				entity.add( new Id( asset ));
				
				if( asset == "redButton" )
				{
					ToolTipCreator.addToEntity( entity );
					InteractionCreator.addToEntity( entity, [ InteractionCreator.CLICK ]);
					
					sceneInteraction = new SceneInteraction();
					sceneInteraction.reached.add( hitButton );
					entity.add( sceneInteraction );
					_audioGroup.addAudioToEntity( entity );
				}
			}
			
			
			// FRED, ALWAYS MOVING
			assets = [ "ui", "glare", "wormHole" ];

			for each( asset in assets )
			{
				clip = _hitContainer[ asset ];
				sequence = BitmapTimelineCreator.createSequence( clip, true, PerformanceUtils.defaultBitmapQuality );
				
				entity = EntityUtils.createSpatialEntity( this, clip, _hitContainer );
				BitmapTimelineCreator.convertToBitmapTimeline( entity, clip, true, sequence, PerformanceUtils.defaultBitmapQuality );
				timeline = entity.get( Timeline );
				
				entity.add( new Id( asset ));
				if( asset == "ui" )
				{
					entity.add( _fred.get( WaveMotion )).add( _fred.get( SpatialAddition )).add( new Npc());;
				}
				
				if( asset == "wormHole" )
				{
					Display( entity.get( Display )).visible = false;
				}
			}
			initPilotAnimations();
			
			// ASSIGN GLOBAL VARIABLES
			_helm = getEntityById( "helm" );
			_chair = getEntityById( "chair" );
			_ui = getEntityById( "ui" );
			_cosmoe = getEntityById( "cosmoe" );
			_humphree = getEntityById( "humphree" );
			_dagger = getEntityById( "dagger" );
			_wormHole = getEntityById( "wormHole" );
			
			if( !shellApi.checkEvent( _events.WORM_HOLE_APPEARED ) || shellApi.checkEvent( _events.RECOVERED_COSMOE ))
			{
				var goober:Entity = SkinUtils.getSkinPartEntity( _cosmoe, SkinUtils.ITEM );
				var display:Display = goober.get( Display );
				display.moveToFront();
			}
			
			Display( _chair.get( Display )).moveToBack();
			
			_audioGroup.addAudioToEntity( _helm );
			_audioGroup.addAudioToEntity( _wormHole );
			setupShipDoor();
		}
		
		private function setupShipDoor():void
		{
			shellApi.getUserField( _events.PLANET_FIELD, shellApi.island, setExitDoor, true );
		}
		
		private function setExitDoor( currentPlanet:String = "" ):void
		{			
			var doorEntity:Entity = getEntityById( "doorShip" );
			var door:Door = doorEntity.get( Door );
			var sceneInteraction:SceneInteraction = doorEntity.get( SceneInteraction );
			
			switch( currentPlanet )
			{
				case _events.BARREN:
					door.data.destinationScene = "game.scenes.ghd.barren1.Barren1";
					break;
				
				case _events.MUSHROOM:
					door.data.destinationScene = "game.scenes.ghd.mushroom1.Mushroom1";
					break;
				
				case _events.PREHISTORIC:
					door.data.destinationScene = "game.scenes.ghd.prehistoric1.Prehistoric1";
					break;
				
				case _events.SPACE_PORT:
					door.data.destinationScene = "game.scenes.ghd.spacePort.SpacePort";
//					setupIslandBlocker();
					break;
				
				case _events.LOST_TRIANGLE:
					door.data.destinationScene = "game.scenes.ghd.lostTriangle.LostTriangle";
					break;
				
				case _events.OUTER_SPACE:
					if( !IslandBlockPopup.checkIslandBlock( super.shellApi ))
					{
						sceneInteraction.reached.removeAll();
						sceneInteraction.reached.add( notInSpace );
					}
//					else
//					{
//						setupIslandBlocker();					
//					}
					break;
			}
			
			if( shellApi.checkEvent( _events.GOT_ALL_MAP_PIECES ))
			{
				sceneInteraction.reached.removeAll();
				sceneInteraction.reached.add( queenIsAfterUs );
			}
		}
		
		private function notInSpace( player:Entity, door:Entity ):void
		{
			var dialog:Dialog = player.get( Dialog );
			dialog.sayById( "outside_space" );
		}
		
		private function queenIsAfterUs( player:Entity, door:Entity ):void
		{
			var dialog:Dialog = player.get( Dialog );
			dialog.sayById( "queen_is_after_us" );
		}
		
		/** SETUP UTILITIES **/
		private function optimizeAssets():void
		{
			var asset:String;
			var assets:Array = [ "dog", "cookedDog" ];
			var clip:MovieClip;
			var entity:Entity;
			var sequence:BitmapSequence;
			var sleep:Sleep;
			var timeline:Timeline;
			var wrapper:BitmapWrapper;
			
			// BITMAP INTERACTIVE LAYER ASSETS
			for each( asset in assets)
			{
				clip = _hitContainer[ asset ];
				wrapper = DisplayUtils.convertToBitmapSprite( clip );
				
				entity = EntityUtils.createSpatialEntity( this, wrapper.sprite, _hitContainer );
				entity.add( new Id( asset ));
			}
			
			// HIDE COOKED DOG
			Display( entity.get( Display )).alpha = 0;
			entity.add( new Tween());
			
			// COOKING GLOW
			asset = "cookingGlow";
			clip = _hitContainer[ asset ];
			sequence = BitmapTimelineCreator.createSequence( clip, true, PerformanceUtils.defaultBitmapQuality );
			
			entity = EntityUtils.createSpatialEntity( this, clip, _hitContainer );
			BitmapTimelineCreator.convertToBitmapTimeline( entity, clip, true, sequence, PerformanceUtils.defaultBitmapQuality );
			entity.add( new Id( asset )).add( new Sleep( true ));
			
			Display( entity.get( Display )).alpha = 0;
			
			_flameCreator = new FlameCreator();
			_flameCreator.setup( this, super._hitContainer[ "flame" + 1 ], null, onFlameLoaded );
		}
		
		private function removeWormHole():void
		{
			_hitContainer.removeChild( _hitContainer[ "rotator" ]);
			_hitContainer.removeChild( _hitContainer[ "eventHorizon" ]);
			
			removeEntity( getEntityById( "glare" ));
			removeEntity( getEntityById( "wormHole" ));
			
			var dialog:Dialog;
			var display:Display;
			var skinPartEntity:Entity;
			var spatial:Spatial;
			var number:int;
			var crew:Vector.<Entity> = new <Entity>[ _cosmoe, _dagger, _humphree ];
			
			if( shellApi.checkEvent( _events.WORM_HOLE_APPEARED ))
			{
				if( !shellApi.checkEvent( _events.RECOVERED_CREW ))
				{
					if(  shellApi.checkEvent( _events.RECOVERED_HUMPHREE ))
					{
						dialog = _humphree.get( Dialog );
						dialog.setCurrentById( _events.RECOVERED_HUMPHREE );
						dialog.complete.add( faceSpace );
					}
					else
					{
						removeEntity( _humphree );
					}
					
					
					if( shellApi.checkEvent( _events.RECOVERED_COSMOE ))
					{
						spatial = _cosmoe.get( Spatial );
						spatial.x = COSMOE_PLACEMENT.x;
						spatial.y = COSMOE_PLACEMENT.y;
						
						CharUtils.setDirection( _cosmoe, true );
						CharUtils.setAnim( _cosmoe, Stand );
						
						dialog = _cosmoe.get( Dialog );
						dialog.setCurrentById( _events.RECOVERED_COSMOE );
						
						skinPartEntity = SkinUtils.getSkinPartEntity( _cosmoe, "foot1" );
						display = skinPartEntity.get( Display );
						display.alpha = 1;
						
						skinPartEntity = SkinUtils.getSkinPartEntity( _cosmoe, "leg1" );
						display = skinPartEntity.get( Display );
						display.alpha = 1;
					}
					else
					{
						removeEntity( _cosmoe );
					}
					
					if( shellApi.checkEvent( _events.RECOVERED_DAGGER ))
					{
						dialog = _dagger.get( Dialog );
						dialog.setCurrentById( _events.RECOVERED_DAGGER );
					}
					else
					{
						removeEntity( _dagger );
					}
				}
				
				else
				{
					CharUtils.setDirection( _humphree, true );
					
					if( !shellApi.checkEvent( _events.ASK_FRED ))
					{
						dialog = _cosmoe.get( Dialog );
						dialog.faceSpeaker = false;
						dialog.complete.addOnce( turnCosmoeAround );
					}
					
					else
					{
						for( number = 0; number < crew.length; number ++ )
						{
							dialog = crew[ number ].get( Dialog );
							dialog.setCurrentById( _events.ASK_FRED );
						}
					}
					
					spatial = _cosmoe.get( Spatial );
					spatial.x = COSMOE_PLACEMENT.x;
					spatial.y = COSMOE_PLACEMENT.y;
						
					CharUtils.setDirection( _cosmoe, true );
					CharUtils.setAnim( _cosmoe, Stand );
					
					skinPartEntity = SkinUtils.getSkinPartEntity( _cosmoe, "foot1" );
					display = skinPartEntity.get( Display );
					display.alpha = 1;
					
					skinPartEntity = SkinUtils.getSkinPartEntity( _cosmoe, "leg1" );
					display = skinPartEntity.get( Display );
					display.alpha = 1;
				}
			}
		}
		
		private function faceSpace( dialogData:DialogData ):void
		{
			CharUtils.setDirection( _humphree, false );
		}
		
		private function turnCosmoeAround( dialogData:DialogData ):void
		{
			var spatial:Spatial = _cosmoe.get( Spatial );
			spatial.scaleX *= -1;
		}
		
		private function onFlameLoaded():void
		{
			var clip:MovieClip;
			var flameEntity:Entity;
			var spatial:Spatial;
			
			for( var number:uint = 0; number < 12; number ++ )
			{
				clip = super._hitContainer[ "flame" + number ];
				flameEntity = _flameCreator.createFlame( this, clip, true );
				flameEntity.add( new Id( "flame" + number )).add( new Sleep( true, true )).add( new Tween());
			}
		}
		
		private function removeEarlyAssets():void
		{
			var asset:String;
			var assets:Array = [ "dog", "cookedDog", "cookingGlow" ];
			
			for each( asset in assets )
			{
				_hitContainer.removeChild( _hitContainer[ asset ]);
			}
			
			for( var number:uint = 0; number < 12; number ++ )
			{
				_hitContainer.removeChild( _hitContainer[ "flame" + number ]);
			}
		}
		
		/** EVENT LISTENER **/
		override protected function eventTriggers( event:String, save:Boolean = true, init:Boolean = false, removeEvent:String = null ):void
		{
			if( event == _events.GIVE_FUEL_CELL && shellApi.checkHasItem( _events.FUEL_CELL ))
			{
				SceneUtil.lockInput( this );
				var destination:Destination = CharUtils.moveToTarget( player, 1070, 610, true, moveToCosmoe );
				destination.ignorePlatformTarget = true;
			}
			
			if( event == _events.STROKE_OF_LUCK )
			{
				SceneUtil.lockInput( this, false );
				SceneUtil.setCameraTarget( this, player );
				
				var crew:Vector.<Entity> = new <Entity>[ _cosmoe, _dagger, _fred, _humphree ];
				for( var number:int = 0; number < crew.length; number ++ )
				{
					var dialog:Dialog = crew[ number ].get( Dialog );
					dialog.setCurrentById( _events.ASK_FRED );
				}
			}
			
			if( event == _events.TURN_TO_PRINCESS )
			{
				CharUtils.setDirection( player, true );
				CharUtils.setDirection( _cosmoe, true );
			}
			
			if( event == _events.TURN_TO_COSMOE )
			{
				CharUtils.setDirection( player, false );
			}
			
			super.eventTriggers( event, save, init, removeEvent );
		}
		
		/** 
		 * COSMOE COOKING THE GIANT DOG 
		 * **/
		private function moveToCosmoe( player:Entity ):void
		{
			CharUtils.setDirection( player, true );
			var showItem:ShowItem = super.getGroupById( ShowItem.GROUP_ID ) as ShowItem;
			
			if( !showItem )
			{
				showItem = new ShowItem();
				addChildGroup( showItem );
			}

			showItem.takeItem( _events.FUEL_CELL, "ghd", _cosmoe );
			showItem.transitionComplete.addOnce( giveFuelCell );
			
			_characterGroup.addAudio( _cosmoe );
		}
		
		private function giveFuelCell():void
		{
			SceneUtil.setCameraTarget( this, _cosmoe );
			var dialog:Dialog = _cosmoe.get( Dialog );
			shellApi.removeItem( _events.FUEL_CELL );
			
			dialog.sayById( "you_did_it" );
			dialog.complete.addOnce( moveToGrill );		
			CharUtils.setDirection( player, true );
		}
		
		private function moveToGrill( dialogData:DialogData ):void
		{
			CharUtils.moveToTarget( _cosmoe, 1335, 610, true, setSpace );
		}
		
		private function setSpace( cosmoe:Entity ):void
		{
			shellApi.setUserField( _events.PLANET_FIELD, _events.OUTER_SPACE, shellApi.island, true, insertPowerCell );
		}
		
		private function insertPowerCell( ...args ):void
		{
			CharUtils.setAnim( _cosmoe, PointItem );
			
			var timeline:Timeline = _cosmoe.get( Timeline );
			timeline.handleLabel( "pointing", fireUpTheGrill );
		}
		
		private function fireUpTheGrill():void
		{
			var audio:Audio;
			var flameEntity:Entity;
			var sleep:Sleep;
			
			for( var number:uint = 0; number < 12; number ++ )
			{
				flameEntity = getEntityById( "flame" + number );
				sleep = flameEntity.get( Sleep );
				
				sleep.sleeping = false;
				if( number == 0 )
				{
					flameEntity.add( new AudioRange( 600, .02, 2 ));
					_audioGroup.addAudioToEntity( flameEntity );
					
					audio = flameEntity.get( Audio );
					audio.playCurrentAction( TRIGGER );
				}
			}
			
			var glow:Entity = getEntityById( "cookingGlow" );
			display = glow.get( Display );
			display.alpha = 1;
			sleep = glow.get( Sleep );
			sleep.sleeping = false;
			_audioGroup.addAudioToEntity( glow );
			audio = glow.get( Audio );
			audio.playCurrentAction( TRIGGER );
			
			var timeline:Timeline = glow.get( Timeline );
			timeline.play();
			
			var dog:Entity = getEntityById( "cookedDog" );
			var display:Display = dog.get( Display );
			
			var tween:Tween = dog.get( Tween );
			tween.to( display, 3, { alpha : 1, onComplete : nothingCanGoWrong });
		}
		
		private function nothingCanGoWrong():void
		{
			var audio:Audio;
			var dialog:Dialog;
			var display:Display;
			var flameEntity:Entity;
			var glow:Entity;
			var spatial:Spatial;
			var tween:Tween;
			
			dialog = _cosmoe.get( Dialog );
			dialog.sayById( "good_as_ours" );
			dialog.complete.addOnce( leaveWithDog );
			
			for( var number:uint = 0; number < 12; number ++ )
			{
				flameEntity = getEntityById( "flame" + number );
				spatial = flameEntity.get( Spatial );
				
				if( number == 0 )
				{
					audio = flameEntity.get( Audio );
					audio.fadeActionAudio( TRIGGER );
				}
				
				tween = new Tween();
				tween.to( spatial, 1, { scaleX : 0, scaleY : 0 });
				
				flameEntity.add( tween );
			}
			
			glow = getEntityById( "cookingGlow" );
			display = glow.get( Display );
			display.alpha = 0;
			
			audio = glow.get( Audio );
			audio.fadeActionAudio( TRIGGER );
		}
		
		private function leaveWithDog( dialogData:DialogData ):void
		{
			var number:int;
			var spatial:Spatial;
			
			for( number = 0; number < 12; number ++ )
			{
				removeEntity( getEntityById( "flame" + number ));
			}
			
			SkinUtils.setSkinPart( _cosmoe, SkinUtils.ITEM2, "ghd_giant_dog", true, adjustSize );
		}
		
		private function adjustSize( itemPart:SkinPart ):void
		{
			var asset:String;
			var assets:Array = [ "dog", "cookedDog", "glow" ];
			
			for each( asset in assets )
			{
				removeEntity( getEntityById( asset ));					
			}
			
			var dog:Entity = SkinUtils.getSkinPartEntity( _cosmoe, SkinUtils.ITEM2 );
			var cosmoeSpatial:Spatial = _cosmoe.get( Spatial );
			
			var spatial:Spatial = dog.get( Spatial );
			spatial.scale = 1 / cosmoeSpatial.scale;
			
			var rigAnim:RigAnimation = CharUtils.getRigAnim( _cosmoe, 1 );
			if( rigAnim == null )
			{
				var animationSlot:Entity = AnimationSlotCreator.create( _cosmoe );
				rigAnim = animationSlot.get( RigAnimation ) as RigAnimation;
			}
			
			rigAnim.next = Overhead;
			rigAnim.addParts( CharUtils.HAND_FRONT, CharUtils.HAND_BACK );
			
			var door:Entity = getEntityById( "doorShip" );
			spatial = door.get( Spatial );
			CharUtils.moveToTarget( _cosmoe, spatial.x, 610, true,  prepComics );
		}
		
		private function prepComics( cosmoe:Entity ):void
		{
			var display:Display = _cosmoe.get( Display );
			display.visible = false;
			
			shellApi.loadScene( Escape );
		}

		/** 
		 * AFTER THE COOKOFF
		 */
		private function thatWentPoorly():void
		{
			_characterGroup.addAudio( _humphree);

			var dialog:Dialog = _humphree.get( Dialog );
			dialog.faceSpeaker = false;
			dialog.sayById( "that_went_wrong" );
			dialog.complete.addOnce( runFromArmada );
			AudioUtils.play( this, SoundManager.AMBIENT_PATH + ENGINES_ON, 1, true );
			
			var skinPartEntity:Entity = SkinUtils.getSkinPartEntity( _cosmoe, "foot1" );
			var display:Display = skinPartEntity.get( Display );
			display.alpha = 0;
			
			skinPartEntity = SkinUtils.getSkinPartEntity( _cosmoe, "leg1" );
			display = skinPartEntity.get( Display );
			display.alpha = 0;
			
			CharUtils.setAnim( player, Tremble );
			SkinUtils.setEyeStates( player, "open", "front" );
			
			var shake:ShakeMotion = new ShakeMotion( new RectangleZone( -10, -10, 10, 10 ));
			shake.active = false;
			_cameraEntity.add( shake ).add( new SpatialAddition());
			
			SceneUtil.lockInput( this );
			SceneUtil.setCameraTarget( this, _humphree );
			var spatial:Spatial = player.get( Spatial );
			spatial.x -= 40;
			CharUtils.setDirection( player, false );
			
			// ORIENT COSMOE AND HUMPHREE
			var timeline:Timeline = _cosmoe.get( Timeline );
			
			timeline.handleLabel( "push", steerLeft, false );
			timeline.handleLabel( "pull", steerRight, false );
			
			display = _humphree.get( Display );
			display.moveToFront();
			// FRED FREAKING OUT
			timeline = _fred.get( Timeline );
			timeline.gotoAndPlay( "arms_up" );
			
			display = _ui.get( Display );
			display.visible = false;
			
			_humphreeFacingLeft = true;
		}
		
		private function runFromArmada( dialogData:DialogData ):void
		{
			var dialog:Dialog = _cosmoe.get( Dialog );
			dialog.faceSpeaker = false;
			dialog.sayById( "now_we_leave" );
			dialog.complete.addOnce( nowWeLeave );
		}
		
		public function nowWeLeave( dialogData:DialogData ):void
		{
			var dialog:Dialog = _cosmoe.get( Dialog );
			dialog.faceSpeaker = false;
			dialog.sayById( "get_out_of_here" );
			
			dialog = _humphree.get( Dialog );
			dialog.complete.addOnce( humphreeToTheRescue );
			dialog.faceSpeaker = false;
			
			var display:Display = _dagger.get( Display );
			display.visible = true;
		}
		
		private function shakeScene():void
		{
			var shake:ShakeMotion = _cameraEntity.get( ShakeMotion );
			shake.active = true;
			
			var wait:Number = Utils.randInRange( 1, 2 );
			SceneUtil.addTimedEvent( this, new TimedEvent( wait, 1, endShake ));
			
			var audio:Audio = _helm.get( Audio );
			audio.playCurrentAction( TRIGGER );
		}
		
		private function endShake():void
		{
			var shake:ShakeMotion = _cameraEntity.get( ShakeMotion );
			shake.active = false;
			
			var spatialAddition:SpatialAddition = _cameraEntity.get( SpatialAddition );
			spatialAddition.x = 0;
			spatialAddition.y = 0;
			spatialAddition.rotation = 0;
		}
		
		// COSMOE USING THE CONTROLS
		private function steerLeft():void
		{
			evasiveManuevers( new Point( 194, 487 ), -6.4, new Point( 245, 510 ), -6, new Point( 220, 513 ));
		}
		
		private function steerDefault():void
		{
			var timeline:Timeline = _cosmoe.get( Timeline );
			timeline.removeLabelHandler( steerLeft );
			timeline.removeLabelHandler( steerRight );
			
			evasiveManuevers( new Point( 203, 487 ), 0, new Point( 253, 509.5 ), 0, new Point( 230, 508 ), false );
		}
		
		private function steerRight():void
		{
			evasiveManuevers( new Point( 219, 487.5 ), 3, new Point( 259, 511 ), 4.2, new Point( 233, 510 ));
		}
		
		private function evasiveManuevers( helmPosition:Point, helmRotation:Number, chairPosition:Point, chairRotation:Number, cosmoePosition:Point, shakeScreen:Boolean = true ):void
		{
			var spatial:Spatial = _helm.get( Spatial );
			spatial.x = helmPosition.x;
			spatial.y = helmPosition.y;
			spatial.rotation = helmRotation;
			
			spatial = _chair.get( Spatial );
			spatial.x = chairPosition.x;
			spatial.y = chairPosition.y;
			spatial.rotation = chairRotation;
			
			spatial = _cosmoe.get( Spatial );
			spatial.x = cosmoePosition.x;
			spatial.y = cosmoePosition.y;
			
			if( _highQuality && shakeScreen )
			{
				shakeScene();
			}
		}
		
		private function humphreeToTheRescue( dialogData:DialogData ):void
		{
			_humphreeToTheRescue = true;
			CharUtils.stateDrivenOn( _humphree, true );
			CharUtils.setAnim( _humphree, Grief );
			var timeline:Timeline = _humphree.get( Timeline );
			timeline.handleLabel( "trigger", moveToButton );
		}
		
		private function moveToButton():void
		{
			CharUtils.moveToTarget( _humphree, 145, 610, true, hitThrusters );
		}
		
		private function hitThrusters( humphree:Entity ):void
		{
			var timeline:Timeline = _humphree.get( Timeline );
			
			CharUtils.setAnim( _humphree, PointItem );
			timeline.handleLabel( "pointing", somethingWrong );
		}
		
		private function somethingWrong():void
		{
			var timeline:Timeline = _humphree.get( Timeline );
			timeline.handleLabel( "ending", warpDriveFailure );

			var emitter:Emitter;
			var emitter2D:Emitter2D;
			
			var bitmapData:BitmapData = BitmapUtils.createBitmapData( new Star( 12 ));
			
			// DASH LINES PULLING IN	
			emitter2D = new Emitter2D();
			emitter2D.counter = new Blast( 10 );
			emitter2D.addInitializer( new BitmapImage( bitmapData ));
			emitter2D.addInitializer( new ColorInit( 0xFF9900, 0xFFCC66 ));
			emitter2D.addInitializer( new Position( new DiscZone( new Point( 0, 0 ), 10, 1 )));
			emitter2D.addInitializer( new Lifetime( 1.5 ));

			emitter2D.addInitializer( new Velocity( new DiscZone( new Point( 0, 0 ), 40, 20 )));
			
			emitter2D.addAction( new MutualGravity( 1, 10, 1 ));
			emitter2D.addAction( new RandomDrift( 50, 10 ));
			emitter2D.addAction( new Fade( .75, 1 ));			
			emitter2D.addAction( new ScaleImage( 1, .5 ));		
			emitter2D.addAction( new Accelerate( 0, 140 ));
			emitter2D.addAction( new Age());
			emitter2D.addAction( new Move());
			
			var redButton:Entity = getEntityById( "redButton" );
			var display:Display = redButton.get( Display );
			EmitterCreator.create( this, display.displayObject, emitter2D, 0, 0, null, "warpEmitter" );
			
			var audio:Audio = redButton.get( Audio );
			audio.playCurrentAction( CLOSE );
		}
		
		private function warpDriveFailure():void
		{
			var dialog:Dialog = _humphree.get( Dialog );
			dialog.sayById( "warp_drive_busted" );
			dialog.complete.addOnce( whatTheButt );
		}
		
		private function whatTheButt( dialogData:DialogData ):void
		{
			var dialog:Dialog = _cosmoe.get( Dialog );
			
			dialog.sayById( "not_going" );
			dialog.complete.addOnce( openWormhole );
		}
		
		private function openWormhole( dialogData:DialogData ):void
		{
			Display( _wormHole.get( Display )).visible = true;
			SceneUtil.setCameraTarget( this, _wormHole );
			
			var timeline:Timeline = _wormHole.get( Timeline );
			timeline.play();
			timeline.handleLabel( "replay", loopWormhole, false );
			
			var audio:Audio = _wormHole.get( Audio );
			audio.playCurrentAction( OPEN );
			audio.playCurrentAction( TRIGGER );
			
			addWormholeEmitters();
		}
		
		private function addWormholeEmitters():void
		{
			var emitter:Emitter;
			var emitter2D:Emitter2D;
			
			var bitmapData:BitmapData = BitmapUtils.createBitmapData( new Line( 12 ));
			
			// DASH LINES PULLING IN	
			emitter2D = new Emitter2D();
			emitter2D.counter = new Random( 15 * PerformanceUtils.defaultBitmapQuality, 20 * PerformanceUtils.defaultBitmapQuality );
			emitter2D.addInitializer( new BitmapImage( bitmapData, true, 30 * PerformanceUtils.defaultBitmapQuality ));
			emitter2D.addInitializer( new ColorInit( 0x0066FF, 0x6C0069 ));
			emitter2D.addInitializer( new Position( new DiscZone( new Point( 0, 0 ), 160, 50 )));
			emitter2D.addInitializer( new Lifetime( 2.5 ));
			
			emitter2D.addAction( new Fade( .75, 1 ));			
			emitter2D.addAction( new ScaleImage( .4, 1.5 ));						
			emitter2D.addAction( new Age());
			emitter2D.addAction( new RotateToDirection());
			emitter2D.addAction( new AccelerateToPoint( 700 )); 
			emitter2D.addAction( new DeathZone( new DiscZone( new Point( 0, 0 ), 20 )));
			emitter2D.addAction( new Move());
			EmitterCreator.create( this, _hitContainer[ "eventHorizon" ], emitter2D, 0, 0, null, "dashEmitter" );
			
			// WHITE RINGS PULSING IN
			emitter2D = new Emitter2D();
			emitter2D.counter = new Steady( 2 );
			emitter2D.addInitializer( new ImageClass( Ring, [ 135, 130, 0xFFFFFF ], true, 5 ));
			emitter2D.addInitializer( new Position( new PointZone()));
			emitter2D.addInitializer( new Lifetime( 2.4 ));
			
			emitter2D.addAction( new Age());
			emitter2D.addAction( new Fade( .5, .1 ));
			emitter2D.addAction( new ScaleImage( 1, 0 ));
			emitter2D.addAction( new Move());
			EmitterCreator.create( this, _hitContainer[ "eventHorizon" ], emitter2D, 0, 0, null, "rippleEmitter" );
			
			// LIGHT PURPLE CHUNKS ROTATING IN
			var emitterEntity:Entity = EntityUtils.createMovingEntity( this, _hitContainer[ "rotator" ]);
			emitterEntity.add( new Id( "rotator" ));
			var motion:Motion = emitterEntity.get( Motion );
			motion.rotationVelocity = 100;
			var display:Display = emitterEntity.get( Display );
			
			bitmapData = BitmapUtils.createBitmapData( new Blob( 3 ));
			emitter2D = new Emitter2D();
			emitter2D.counter = new Steady( 20 * PerformanceUtils.defaultBitmapQuality );
			
			emitter2D.addInitializer( new BitmapImage( bitmapData, true, 30 * PerformanceUtils.defaultBitmapQuality ));
			emitter2D.addInitializer( new ColorInit( 0xCC1DF8, 0x451043 ));	
			emitter2D.addInitializer( new Position( new DiscZone( new Point( 0, 0 ), 180, 55 )));
			emitter2D.addInitializer( new Lifetime( 2 ));
			
			emitter2D.addAction( new Fade( .75, 1 ));			
			emitter2D.addAction( new ScaleImage( .4, 1.5 ));	
			emitter2D.addAction( new Age());
			emitter2D.addAction( new AccelerateToPoint( 1000 ));
			emitter2D.addAction( new DeathZone( new DiscZone( new Point( 0, 0 ), 20 )));
			emitter2D.addAction( new Move());
			EmitterCreator.create( this, display.displayObject, emitter2D, 0, 0, emitterEntity, "chunkEmitter" );
		}
		
		private function loopWormhole():void
		{
			if( !_portalOpen )
			{
				_portalOpen = true;
				
				CharUtils.setDirection( _humphree, true );
				CharUtils.setAnim( _cosmoe, Push, false, 0, 0, true );
				steerDefault();
				
				var dialog:Dialog = _dagger.get( Dialog );
				dialog.sayById( "worm_hole" );
				dialog.complete.addOnce( stopEscape );
				
				CharUtils.setAnimSequence( _humphree, new <Class>[ Grief ], true );
			}
			
			var timeline:Timeline = _wormHole.get( Timeline );
			timeline.gotoAndPlay( "open" );
		}
		
		private function stopEscape( dialogData:DialogData ):void
		{
			var timeline:Timeline = _cosmoe.get( Timeline );
			timeline.removeLabelHandler( steerLeft );
			timeline.removeLabelHandler( steerRight );
			
			CharUtils.setDirection( _humphree, false );
			snagCharacter( _dagger );
		}
		
		private function snagCharacter( character:Entity ):void
		{
			var id:Id = character.get( Id );
			
			var eventHorizon:Entity = getEntityById( "rotator" );
			var eventHorizonSpatial:Spatial = eventHorizon.get( Spatial );
			
			var spatial:Spatial = character.get( Spatial );
			var tween:Tween = new Tween();
			
			var display:Display = EntityUtils.getDisplay( character );
			display.alpha = 0;
			
			var wrapper:BitmapWrapper =	DisplayUtils.convertToBitmapSprite( display.displayObject, null, PerformanceUtils.defaultBitmapQuality, false, display.container );
			
			wrapper.sprite.x = spatial.x;
			wrapper.sprite.y = spatial.y;
			
			var copy:Entity = EntityUtils.createMovingEntity( this, wrapper.sprite, display.container );
			copy.add( new Id( id.id + "Copy" ));
			spatial = copy.get( Spatial );
			
			var motion:Motion = copy.get( Motion );
			motion.rotationVelocity = 60;
			motion.rotationAcceleration = 350;
			
			tween.to( spatial, 2, { x : eventHorizonSpatial.x, y : eventHorizonSpatial.y, scaleX : .2, scaleY : .2, onComplete : removeCharacter, onCompleteParams : [ character, copy ]});
			copy.add( tween );
		}
		
		private function removeCharacter( character:Entity, copy:Entity ):void
		{
			var id:Id = character.get( Id );
			var glare:Entity = getEntityById( "glare" );
			var display:Display = glare.get( Display );
			display.visible = true;
			
			var timeline:Timeline = glare.get( Timeline );
			timeline.gotoAndPlay( 0 );
			timeline.looped = false;
			
			var tween:Tween = copy.get( Tween );
			display = copy.get( Display );
			tween.to( display, .3, { alpha : 0 });
			
			switch( id.id )
			{
				case "dagger":
					snagCharacter( _humphree );
					break;
				case "humphree":
					snagCharacter( _cosmoe );
					break;
				case "cosmoe":
					killWormhole();
					break;
			}
			
			AudioUtils.play( this, SoundManager.EFFECTS_PATH + TELEPORT );
			removeEntity( character );
		}
		
		private function killWormhole():void
		{
			var character:String;
			var crew:Array = [ "cosmoeCopy", "daggerCopy", "humphreeCopy" ];
			
			for each( character in crew )
			{
				removeEntity( getEntityById( character ));
			}
			
			var timeline:Timeline = _wormHole.get( Timeline );
			timeline.gotoAndPlay( "closing" );
			timeline.handleLabel( "sparkleOut", endEmitters );
			timeline.handleLabel( "ending", finishPortal );
			
			AudioUtils.play( this, SoundManager.EFFECTS_PATH + POWER_DOWN );
		}
		
		private function endEmitters():void
		{
			var emitters:Array = [ "rippleEmitter", "dashEmitter", "chunkEmitter", "warpEmitter" ];
			var emitter:String;
			
			for each( emitter in emitters )
			{
				removeEntity( getEntityById( emitter ));
			}
		}
		
		private function finishPortal():void
		{
			CharUtils.stateDrivenOn( player );
			SceneUtil.setCameraTarget( this, player );
			
			var timeline:Timeline = _wormHole.get( Timeline );
			timeline.removeLabelHandler( endEmitters );
			timeline.removeLabelHandler( finishPortal );
			
			var asset:String;
			var assets:Array = [ "wormHole", "glare" ];
			
			for each( asset in assets )
			{
				removeEntity( getEntityById( asset ), true );
			}
			
			assets = [ "rotator", "eventHorizon" ];
			
			for each( asset in assets )
			{
				_hitContainer.removeChild( _hitContainer[ asset ]);
			}
			
			timeline = _fred.get( Timeline );
			timeline.gotoAndPlay( "idle" );
			
			var display:Display = _ui.get( Display );
			display.visible = true;
			
			shellApi.triggerEvent( _events.WORM_HOLE_APPEARED, true );
			_sceneSound.stop( SoundManager.MUSIC_PATH + WORM_HOLE_TRACK );
			AudioUtils.play( this, SoundManager.MUSIC_PATH + NEON_WIENER_TRACK, 1, true );
			
			var dialog:Dialog = player.get( Dialog );
			dialog.sayById( "worm_hole" );
			
			dialog = _fred.get( Dialog );
			dialog.complete.add( launchGalaxyMap );
//			dialog.complete.addOnce( supFred );
		}
		
//		private function supFred( dialogData:DialogData ):void
//		{
//			var dialog:Dialog = _fred.get( Dialog );
//			if( IslandBlockPopup.checkIslandBlock( super.shellApi ))
//			{
//				dialog.complete.addOnce( openIslandBlock );
//			}
//			
//			else
//			{
//				dialog.complete.addOnce( launchGalaxyMap );
//			}
//		}
		
		private function launchGalaxyMap( dialogData:DialogData ):void
		{
			SceneUtil.lockInput( this, false );
			var popup:GalaxyMap = super.addChildGroup( new GalaxyMap( this.overlayContainer )) as GalaxyMap;
			popup.id = "galaxyMap";
		}
		
		/**
		 * RECOVERED THE WHOLE CREW - GO TO LOST TRIANGLE
		 */
		private function findTheMap():void
		{
			SceneUtil.lockInput( this );
			SceneUtil.setCameraTarget( this, _fred );
			
			var dialog:Dialog = _cosmoe.get( Dialog );
			dialog.sayById( "find_the_map" );
			
			var sceneInteraction:SceneInteraction = getEntityById( "doorShip" ).get( SceneInteraction );
			sceneInteraction.reached.removeAll();
			sceneInteraction.reached.add( figureThisOut );
			shellApi.completeEvent( _events.ASK_FRED );
		}
		
		private function figureThisOut( player:Entity, door:Entity ):void
		{
			var dialog:Dialog = player.get( Dialog );
			dialog.sayById( "figure_this_out" );
		}
		
		// AFTER YOU HAVE ALL 3 PIECES OF THE MAP-o-SPHERE		
		private function getOutOfHere():void
		{
			CharUtils.setDirection( player, false );
			SceneUtil.lockInput( this );
			
			var dialog:Dialog = _cosmoe.get( Dialog );
			dialog.sayById( "you_made_it" );
			
			dialog.complete.addOnce( incomingShips );
		}
		
		private function incomingShips( dialogData:DialogData ):void
		{
			var timeline:Timeline = _fred.get( Timeline );
			timeline.gotoAndPlay( "arms_up" );
			
			var dialog:Dialog = _fred.get( Dialog );
			dialog.sayById( "incoming_ships" );
			dialog.complete.addOnce( moveCosmoeToHelm );
			
			_sceneSound.stop( SoundManager.MUSIC_PATH + NEON_WIENER_TRACK );
			AudioUtils.play( this, SoundManager.MUSIC_PATH + MAIN_THEME, 1, true );
		}
		
		private function moveCosmoeToHelm( dialogData:DialogData ):void
		{
			CharUtils.moveToTarget( _cosmoe, 255, 610, true, cosmoeManTheHelmAgain );
			CharUtils.moveToTarget( _humphree, 340, 610, true, faceLeft );
			
			var dialog:Dialog = _cosmoe.get( Dialog );
			dialog.sayById( "the_queen" );
			
			dialog = _humphree.get( Dialog );
			dialog.faceSpeaker = false;
			dialog.complete.addOnce( facePlayerRight );
			
			dialog = _cosmoe.get( Dialog );
			dialog.faceSpeaker = false;
			
			CharUtils.setDirection( _humphree, false );
		}
		
		private function facePlayerRight( dialogData:DialogData ):void
		{
			CharUtils.setDirection( player, true );
		}
		
		private function faceLeft( entity:Entity ):void
		{
			CharUtils.setDirection( entity, false );
		}
		
		private function cosmoeManTheHelmAgain( cosmoe:Entity ):void
		{
			CharUtils.removeCollisions( _cosmoe );
			
			shellApi.triggerEvent( _events.COSMOE_AT_HELM );
			var sequence:Vector.<Class> = new <Class>[ Push, Pull ];
			CharUtils.setAnimSequence( _cosmoe, sequence, true );
			
			var dialog:Dialog = _dagger.get( Dialog );
			dialog.complete.addOnce( returnControl );
			
			var spatial:Spatial = _cosmoe.get( Spatial );
			spatial.x = COSMOE_HELM.x;
			spatial.y = COSMOE_HELM.y;
			
			AudioUtils.play( this, SoundManager.AMBIENT_PATH + ENGINES_ON, 1, true );
			CharUtils.setAnim( _cosmoe, Push );
			
			var skinPartEntity:Entity = SkinUtils.getSkinPartEntity( _cosmoe, "foot1" );
			var display:Display = skinPartEntity.get( Display );
			display.alpha = 0;
			
			skinPartEntity = SkinUtils.getSkinPartEntity( _cosmoe, "leg1" );
			display = skinPartEntity.get( Display );
			display.alpha = 0;
			

			var shake:ShakeMotion = new ShakeMotion( new RectangleZone( -10, -10, 10, 10 ));
			shake.active = false;
			_cameraEntity.add( shake ).add( new SpatialAddition());
			
			SceneUtil.lockInput( this );
			CharUtils.setDirection( player, false );
			
			// ORIENT COSMOE AND HUMPHREE
			var timeline:Timeline = _cosmoe.get( Timeline );
			
			timeline.handleLabel( "push", steerLeft, false );
			timeline.handleLabel( "pull", steerRight, false );
		}
		
		private function returnControl( dialogData:DialogData ):void
		{
			SceneUtil.lockInput( this, false );
			
			var animationControl:AnimationControl = _cosmoe.get( AnimationControl );
			var animationEntity:Entity = animationControl.getEntityAt( 0 );
			var animationSequencer:AnimationSequencer = animationEntity.get( AnimationSequencer );
			var currentSequence:AnimationSequence = animationSequencer.currentSequence;
			currentSequence.loop = true;
			currentSequence.random = true;
			for( var number:int = 0; number < currentSequence.sequence.length; number ++ )
			{
				currentSequence.sequence[ number ].duration = 15;
			}
			animationSequencer.start = true;
		}
		
		private function hitButton( player:Entity, redButton:Entity ):void
		{
			if( !shellApi.checkItemEvent( _events.MAP_O_SPHERE ) || shellApi.checkItemEvent( _events.MEDAL_GHD ))
			{
				var dialog:Dialog = player.get( Dialog );
				dialog.sayById( "not_now_button" );
			}
			else
			{
				var popup:RedButton = super.addChildGroup( new RedButton( super.overlayContainer )) as RedButton;
				popup.id = "redButton";
				popup.removed.add( readyHotdogsForLaunch );
			}
		}
		
		private function readyHotdogsForLaunch( popup:RedButton ):void
		{			
			SceneUtil.lockInput( this );
			CharUtils.setDirection( player, true );
			var dialog:Dialog = _cosmoe.get( Dialog );
			dialog.sayById( "eat_it" );
			dialog.complete.addOnce( launchHotDogs );
		}
		
		private function launchHotDogs( dialogData:DialogData ):void
		{
			SceneUtil.lockInput( this, false );
			var popup:Comics2 = super.addChildGroup( new Comics2( super.overlayContainer )) as Comics2;
			popup.id = "comics2";
			popup.removed.add( tauntTheQueen );
		}
		
		private function tauntTheQueen( popup:Comics2 ):void
		{
			SceneUtil.lockInput( this );
			CharUtils.setAnim( _cosmoe, Push, false, 0, 0, true );
			steerDefault();
			
			var dialog:Dialog = _dagger.get( Dialog );
			dialog.sayById( "thats_what_it_does" );
			dialog.complete.addOnce( awardMedal );
		}
		
		private function awardMedal( dialogData:DialogData ):void
		{
			super.shellApi.eventTriggered.remove( eventTriggers );
			super.shellApi.getItem( _events.MEDAL_GHD );
			ItemGroup(super.getGroupById( ItemGroup.GROUP_ID )).showItem( _events.MEDAL_GHD, "", null, onMedalReceived );		
			//shellApi.completedIsland();
		}
		
		private function onMedalReceived():void
		{
			CharUtils.setAnim(player, Proud);
			RigAnimation( CharUtils.getRigAnim( player)).ended.add( onCelebrateEnd );
		}
		
		private function onCelebrateEnd( anim:Animation = null ):void
		{		
			RigAnimation( CharUtils.getRigAnim( player)).ended.remove( onCelebrateEnd );
			SceneUtil.lockInput(this, false, false);
		
			var dialog:Dialog = _cosmoe.get( Dialog );
			dialog.sayById( "next_adventure" );
			dialog.complete.addOnce( launchEndingPopup );
		}
		
		private function launchEndingPopup( dialogData:DialogData ):void
		{
			shellApi.completedIsland('', onCompletions);
			SceneUtil.lockInput( this, false );
			this.addChildGroup(new IslandEndingPopup(this.overlayContainer));
		}

		private function onCompletions(response:PopResponse):void
		{
			//SceneUtil.lockInput( this, false );
			//this.addChildGroup(new IslandEndingPopup(this.overlayContainer));
			
			/*var victoryPopup:DualTextDialogPicturePopup = new DualTextDialogPicturePopup( overlayContainer, false, true );
			victoryPopup.updateText( "The adventures of cosmoe, humphree, and princess dagger continue in...", "coming may 5, 2015!", "buy the book", "back to map" );
			victoryPopup.configData( "victoryPopup.swf", "scenes/ghd/neonWiener/" );
			victoryPopup.buttonClicked.add( loadMap );
			addChildGroup( victoryPopup );*/
		} 
		
		private function loadMap( launchStore:Boolean ):void
		{
			if( launchStore )
			{
				var clickURL:String = "https://www.amazon.com/gp/product/1481424947/ref=as_li_qf_sp_asin_il_tl?ie=UTF8&camp=1789&creative=9325&creativeASIN=1481424947&linkCode=as2&tag=poptropica-20&linkId=WSRJ6B2PONL5FQK4";
				navigateToURL(new URLRequest(clickURL), "_blank");
				// TODO: ADD STORE PAGE WINDOW LINK
			}
			shellApi.loadScene( Map );
		}
	}
}