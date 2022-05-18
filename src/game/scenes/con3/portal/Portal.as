package game.scenes.con3.portal
{
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.filters.GlowFilter;
	import flash.geom.ColorTransform;
	import flash.geom.Point;
	
	import ash.core.Entity;
	
	import engine.components.Display;
	import engine.components.Id;
	import engine.components.Motion;
	import engine.components.Spatial;
	import engine.components.Tween;
	import engine.managers.SoundManager;
	import engine.util.Command;
	
	import game.components.entity.character.ColorSet;
	import game.components.entity.character.part.eye.Eyes;
	import game.components.timeline.Timeline;
	import game.creators.entity.EmitterCreator;
	import game.data.TimedEvent;
	import game.data.animation.entity.character.Hurt;
	import game.data.animation.entity.character.Swim;
	import game.data.animation.entity.character.SwimTread;
	import game.data.character.part.eye.EyeBallData;
	import game.data.display.BitmapWrapper;
	import game.scene.template.CharacterGroup;
	import game.scene.template.CutScene;
	import game.scene.template.CutSubScene;
	import game.scenes.con3.omegon.Omegon;
	import game.scenes.con3.portal.subscenes.PowerUpSubScene;
	import game.scenes.con3.throneRoom.components.InwardSpiralComponent;
	import game.scenes.con3.throneRoom.systems.InwardSpiralSystem;
	import game.systems.entity.EyeSystem;
	import game.util.AudioUtils;
	import game.util.CharUtils;
	import game.util.DisplayUtils;
	import game.util.EntityUtils;
	import game.util.PerformanceUtils;
	import game.util.PlatformUtils;
	import game.util.SceneUtil;
	import game.util.SkinUtils;
	
	import org.flintparticles.common.actions.Age;
	import org.flintparticles.common.actions.Fade;
	import org.flintparticles.common.actions.ScaleImage;
	import org.flintparticles.common.counters.Steady;
	import org.flintparticles.common.initializers.BitmapImage;
	import org.flintparticles.common.initializers.ColorInit;
	import org.flintparticles.common.initializers.Lifetime;
	import org.flintparticles.twoD.actions.Move;
	import org.flintparticles.twoD.emitters.Emitter2D;
	import org.flintparticles.twoD.initializers.Position;
	import org.flintparticles.twoD.initializers.Velocity;
	import org.flintparticles.twoD.zones.PointZone;
	
	public class Portal extends CutScene
	{
		private var _subSceneIndex:int = 0;
		
		private var _originalScale:Number;
		private var _characterCopy:Entity;
		private var _sceneNumber:Number = -1;
		private var _scenes:Vector.<MovieClip>;
		private var _sceneEntities:Vector.<Entity>;
		
		private var _scene01:CutSubScene;
		private var _scene02:CutSubScene;
		private var _sceneGoldFace:CutSubScene;
		private var _sceneWorldGuy:CutSubScene;
		private var _sceneElfArcher:CutSubScene;
		private var _scenePowerUp:PowerUpSubScene;
		
		private var _scenePowerUpGloves:CutSubScene;
		private var _sceneEyeSpy:CutSubScene;
		private var _sceneOmegon:CutSubScene;
		
		private const GOLDFACE_FRONT:String	= "poptropicon_goldface_front";
		private const GOLDFACE_BACK:String	= "poptropicon_goldface_back";
		private const WORLDGUY:String		= "poptropicon_worldguy";
		private const ELF_ARCHER:String		= "bow";
		
		private const TELEPORT:String	= 	"transition_05.mp3";
		private const GLEAM:String		=	"event_01.mp3";
		private const CHARGE:String		= 	"charge";
		private const PHASE:String		= 	"phase";
		
		private const FADER:String		=	"fader";
		private const SECTION:String 	= 	"section";
		
		public function Portal()
		{
			super();
			super.configData( "scenes/con3/portal/" );
		}
		
		override public function init( container:DisplayObjectContainer = null ):void
		{
			super.init( container );
		}
		
		override protected function convertScreen():Entity
		{
			var bitmapQuality:Number = PerformanceUtils.defaultBitmapQuality;
			
			//setup subscenes
			_sceneOmegon = this.addChildGroup(new CutSubScene()) as CutSubScene; 
			_sceneOmegon.setup( _screen["scene_Omegon"] as MovieClip, null, playNext, false, false );	// NOTE :: Don't destroy last subscene, causes destroy issues
			bitmapSideScenes( _sceneOmegon, bitmapQuality ); 
			
			_sceneEyeSpy = this.addChildGroup(new CutSubScene()) as CutSubScene;
			_sceneEyeSpy.setup(_screen["scene_EyeSpy"] as MovieClip, _sceneOmegon, playNext, true, false );
			
			_scenePowerUp = this.addChildGroup(new PowerUpSubScene()) as PowerUpSubScene;
			_scenePowerUp.setup(_screen["scene_PowerUp"] as MovieClip, null, playNext, false, false );
			
			_sceneElfArcher = this.addChildGroup(new CutSubScene()) as CutSubScene;
			_sceneElfArcher.setup(_screen["scene_ElfArcher"] as MovieClip, _scenePowerUp, playNext, true, false);
			bitmapSideScenes( _sceneElfArcher, bitmapQuality ); 
			
			_sceneWorldGuy = this.addChildGroup(new CutSubScene()) as CutSubScene;	
			_sceneWorldGuy.setup(_screen["scene_WorldGuy"] as MovieClip, _scenePowerUp, playNext, true, false);
			bitmapSideScenes( _sceneWorldGuy, bitmapQuality ); 
			
			_sceneGoldFace = this.addChildGroup(new CutSubScene()) as CutSubScene;
			_sceneGoldFace.setup(_screen["scene_GoldFace"] as MovieClip, _scenePowerUp, playNext, true, false);
			bitmapSideScenes( _sceneGoldFace, bitmapQuality ); 
			
			_scene02 = this.addChildGroup(new CutSubScene()) as CutSubScene;
			_scene02.setup(_screen["scene_02"] as MovieClip, _sceneGoldFace, playNext, true, false);
			_scene02.createBitmapSprite( _scene02.sceneClip["bg"], bitmapQuality);
			
			_scene01 = this.addChildGroup(new CutSubScene()) as CutSubScene;
			_scene01.setup( _screen["scene_01"] as MovieClip, _scene02, playNext, true, false);
			
			return null;	// all a default 'screen' entity to be created
		}
		
		private function bitmapSideScenes( subScene:CutSubScene, bitmapQuality ):void
		{
			// NOTE :: for some reason we don;t want to swap the sprites. -bard
			subScene.createBitmapSprite(subScene.sceneClip["glow"] as MovieClip, bitmapQuality, null, true, 0, null, false);
			subScene.createBitmapSprite( subScene.sceneClip["panel_front"] as MovieClip, bitmapQuality, null, true, 0, null, false);
			subScene.createBitmapSprite(subScene.sceneClip["bg"] as MovieClip, bitmapQuality, null, true, 0, null, false);
			
			if( subScene.sceneClip[ "space" ])
			{
				subScene.createBitmapSprite( subScene.sceneClip[ "space" ] as MovieClip, bitmapQuality, null, true, 0, null, true );
			}
		}
		
		override public function start(...args):void
		{
			SkinUtils.setSkinPart(player,SkinUtils.ITEM,"empty");
			SkinUtils.setSkinPart(player,SkinUtils.ITEM2,"empty");
			
			EntityUtils.position(super.player, 0, 0 );
			( super.getGroupById( CharacterGroup.GROUP_ID ) as CharacterGroup).removeFSM( super.player );
			
			var clip:MovieClip;
			var wrapper:BitmapWrapper;
			var display:Display;
			var ringEntity:Entity;
			var spatial:Spatial;
			var tween:Tween;
			
			clip = _scene01.sceneClip[ "portal_circle" ];
			wrapper = DisplayUtils.convertToBitmapSprite( clip, null, PerformanceUtils.defaultBitmapQuality, false, _scene01.sceneClip );  //createBitmapSprite( clip, PerformanceUtils.defaultBitmapQuality, null, true );
			// 1', 2', 3', 4' oclock ...
			var pointZones:Vector.<Point> = new <Point>[ new Point( -270, -360 ), new Point( -180, -360 )
				, new Point( 0, -360 ), new Point( 90, -270 )
				, new Point( 180, -180 ), new Point( 180, 0 )
				, new Point( 90, 180 ) , new Point( -90, 180 ) 
				, new Point( -270, 180 ), new Point( -360, 90 )
				, new Point( -360, -180 ), new Point( -360, -270 )];
			
			var emitter2D:Emitter2D;
			var color:uint;
			
			for( var number:int = 0; number < pointZones.length; number ++ )
			{
				if( number % 2 )
				{
					color = 0xC47C06;
				}
				else
				{
					color = 0xF3DA01;
				}
				
				emitter2D = new Emitter2D();
				
				emitter2D.counter = new Steady( 3 );
				emitter2D.addInitializer( new BitmapImage( wrapper.data, true, 10 ));
				emitter2D.addInitializer( new ColorInit( color, color ));
				emitter2D.addInitializer( new Position( new PointZone( new Point( 0, 0 ))));
				emitter2D.addInitializer( new Lifetime( 2 )); 
				emitter2D.addInitializer( new Velocity( new PointZone( pointZones[ number ])));
				
				emitter2D.addAction( new Fade( .25, 1 ));
				emitter2D.addAction( new ScaleImage( .2, 2 ));	
				emitter2D.addAction( new Age());
				emitter2D.addAction( new Move());
				
				EmitterCreator.create( this, _scene01.sceneClip[ "emitterContainer" ], emitter2D, 0, 0, null, "pulse" );
			}
			
			_scene01.setupCharacter( super.player, _scene01.sceneClip[ "playerContainer" ]);
			
			spatial = player.get( Spatial );
			spatial.x = shellApi.viewportWidth / 2;
			spatial.y = shellApi.viewportHeight + 300;
			
			CharUtils.setAnim( player, Hurt );
			SceneUtil.addTimedEvent( this, new TimedEvent( 1, 1, copyPlayer ));
			
			_subSceneIndex = 1;
			_scene01.start();
			super.groupReady();
			
			
			addSystem( new InwardSpiralSystem());
			
			_scene01.sceneClip.removeChild( clip );
			_scene01.sceneClip.removeChild( wrapper.sprite );
		}
		
		private function copyPlayer():void
		{
			// SETUP COPY OF PLAYER 
			var display:Display = EntityUtils.getDisplay( player );
			var spatial:Spatial = player.get( Spatial );
			display.alpha = 0;
			
			var wrapper:BitmapWrapper =	DisplayUtils.convertToBitmapSprite( display.displayObject, null, PerformanceUtils.defaultBitmapQuality, false, display.container );
			
			wrapper.sprite.x = spatial.x;
			wrapper.sprite.y = spatial.y;
			
			var copy:Entity = EntityUtils.createMovingEntity( this, wrapper.sprite, display.container );
			copy.add( new Id( "playerCopy" ));
			spatial = copy.get( Spatial );
			
			var tween:Tween = new Tween();
			tween.to( copy.get( Display ), 10, { alpha : 0 }, "alpha" );
			tween.to( copy.get( Spatial ), 10, { scaleX : spatial.scaleX / 2, scaleY : spatial.scaleY / 2 }, "scale" );
			copy.add( tween );
			
			var inwardSpiral:InwardSpiralComponent = new InwardSpiralComponent( new Point( shellApi.viewportWidth / 2, shellApi.viewportHeight / 2 ), resetPlayer );
			//	inwardSpiral.angleStep *= 2; 
			inwardSpiral.radiusStep *= 2;
			copy.add( inwardSpiral );
		}
		
		private function resetPlayer( copy:Entity ):void
		{ 
			copy.remove( InwardSpiralComponent );
			
			Spatial( player.get( Spatial )).x = 0;
			Spatial( player.get( Spatial )).y = 0;
			_scene01.subSceneEntity.get( Timeline ).gotoAndPlay( "flare" );
		}
		
		public function playNext( current:CutSubScene = null, next:CutSubScene = null ):void
		{
			_subSceneIndex++;
			var colorSet:ColorSet;
			var timeline:Timeline;
			
			switch(_subSceneIndex)
			{
				case 2:	
				{
					player.remove( Tween );
					Display( player.get( Display )).alpha = 1;;
					SkinUtils.setEyeStates( player, EyeSystem.OPEN );
					CharUtils.setDirection( player, false );
					
					var motion:Motion = new Motion();
					motion.rotationVelocity = 100;
					player.add( motion );
					_scene02.setupCharacter( super.player, _scene02.sceneClip["playerContainer"] );
					_scene02.start();
					break;
				}
					
				case 3:	
				{
					_sceneGoldFace.setupCharacter( super.player, _sceneGoldFace.sceneClip["playerContainer"] );
					
					timeline = _sceneGoldFace.subSceneEntity.get( Timeline );
					timeline.handleLabel( PHASE, Command.create( AudioUtils.play, this, SoundManager.EFFECTS_PATH + TELEPORT ));
					_sceneGoldFace.start();
					break;
				}
					
				case 4:
				{
					_scenePowerUp.start( _scenePowerUp.GLOVES );
					SkinUtils.setSkinPart( player, SkinUtils.ITEM, GOLDFACE_FRONT );
					SkinUtils.setSkinPart( player, SkinUtils.ITEM2, GOLDFACE_BACK );
				
					var eyeballDatum:EyeBallData;
					var eyeEntity:Entity = SkinUtils.getSkinPartEntity( player, SkinUtils.EYES );
					var eyeballData:Vector.<EyeBallData> = new <EyeBallData>[ eyeEntity.get( Eyes ).eye1, eyeEntity.get( Eyes ).eye2 ];
					
					for each( eyeballDatum in eyeballData )
					{
						eyeballDatum.pupil.transform.colorTransform = new ColorTransform( 1, 1, 1, 1,  0, 92, 204 );
					}
					
					timeline = _scenePowerUp.getEntityById( _scenePowerUp.GLOVES ).get( Timeline );
					timeline.handleLabel( CHARGE, Command.create( AudioUtils.play, this, SoundManager.EFFECTS_PATH + GLEAM ));
					timeline.handleLabel( "linger", Command.create( lingerOnItem, timeline ));
					break;
				}
					
				case 5:	
				{
					_sceneWorldGuy.setupCharacter( super.player, _sceneWorldGuy.sceneClip["playerContainer"] );
					
					timeline = _sceneWorldGuy.subSceneEntity.get( Timeline );
					timeline.handleLabel( PHASE, Command.create( AudioUtils.play, this, SoundManager.EFFECTS_PATH + TELEPORT ));
					_sceneWorldGuy.start();
					break;
				}
					
				case 6:
				{
					_scenePowerUp.start( _scenePowerUp.SHIELD );
					SkinUtils.setSkinPart( player, SkinUtils.ITEM, WORLDGUY );
					SkinUtils.emptySkinPart( player, SkinUtils.ITEM2 );
					
					var hairEntity:Entity = SkinUtils.getSkinPartEntity( player, SkinUtils.HAIR_COLOR );
					colorSet = hairEntity.get( ColorSet );
					colorSet.setColorAspect( 11657972, SkinUtils.HAIR_COLOR );
					
					timeline = _scenePowerUp.getEntityById( _scenePowerUp.SHIELD ).get( Timeline );
					timeline.handleLabel( CHARGE, Command.create( AudioUtils.play, this, SoundManager.EFFECTS_PATH + GLEAM ));
					timeline.handleLabel( "linger", Command.create( lingerOnItem, timeline ));
					break;
				}
					
				case 7:
				{
					_sceneElfArcher.setupCharacter( super.player, _sceneElfArcher.sceneClip["playerContainer"] );
					
					timeline = _sceneElfArcher.subSceneEntity.get( Timeline );
					timeline.handleLabel( PHASE, Command.create( AudioUtils.play, this, SoundManager.EFFECTS_PATH + TELEPORT ));
					_sceneElfArcher.start();
					break;
				}
					
				case 8:
				{
					_scenePowerUp.destroyOnComplete = true;
					_scenePowerUp.start( _scenePowerUp.BOW );
					SkinUtils.setSkinPart( player, SkinUtils.ITEM, ELF_ARCHER );
					
					var skinEntity:Entity = SkinUtils.getSkinPartEntity( player, SkinUtils.SKIN_COLOR );
					colorSet = skinEntity.get( ColorSet );
					colorSet.setColorAspect( 8177389, SkinUtils.SKIN_COLOR );
					
					if(!PlatformUtils.isMobileOS)
					{
						var display:Display = player.get( Display );
						var whiteOutline:GlowFilter = new GlowFilter( 0xFFFFFF, 1, 8, 8, 2, 1, true );
						var colorGlow:GlowFilter = new GlowFilter( 0xFFFFFF, 1, 20, 20, 1, 1 );
						
						var filters:Array = new Array( colorGlow, whiteOutline );
						display.displayObject.filters = filters;
					}
					
					timeline = _scenePowerUp.getEntityById( _scenePowerUp.BOW ).get( Timeline );
					timeline.handleLabel( CHARGE, Command.create( AudioUtils.play, this, SoundManager.EFFECTS_PATH + GLEAM ));
					timeline.handleLabel( "linger", Command.create( lingerOnItem, timeline ));
					break;
				}
					
				case 9:	
				{
					CharUtils.setAnim( player, SwimTread );
					SkinUtils.setSkinPart( player, SkinUtils.MOUTH, "cry" );
					
					player.remove( Motion );
					var spatial:Spatial = player.get( Spatial );
					spatial.rotation = 0;
					spatial.scaleX *= -1;
					
					_sceneEyeSpy.setupCharacter( super.player, _sceneEyeSpy.sceneClip["playerContainer"] );
					_sceneEyeSpy.start();
					break;
				}
					
				case 10:
				{
					CharUtils.setAnim( player, Swim );
					SkinUtils.setSkinPart( player, SkinUtils.MOUTH, "cry" );
					
					_sceneOmegon.setupCharacter( super.player, _sceneOmegon.sceneClip["playerContainer"] );
					_sceneOmegon.start();
					
					timeline = _sceneOmegon.subSceneEntity.get( Timeline );
					timeline.handleLabel( PHASE, Command.create( AudioUtils.play, this, SoundManager.EFFECTS_PATH + TELEPORT ));
					break;
				}
					
				case 11:
				{
					shellApi.loadScene( Omegon );
					break;
				}
					
				default:
				{
					next.start();
					break;
				}
			}
		}
		
		private function lingerOnItem( timeline:Timeline ):void
		{
			SceneUtil.addTimedEvent( this, new TimedEvent( .5, 1, timeline.play ));
		}
	}
}

