package game.scenes.myth.mountOlympus
{
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.display.Sprite;
	import flash.geom.Matrix;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	
	import ash.core.Entity;
	
	import engine.components.Audio;
	import engine.components.Display;
	import engine.components.Id;
	import engine.components.Interaction;
	import engine.components.Motion;
	import engine.components.Spatial;
	import engine.components.Tween;
	import engine.creators.InteractionCreator;
	import engine.util.Command;
	
	import game.components.entity.Dialog;
	import game.components.entity.character.Character;
	import game.components.entity.character.CharacterMotionControl;
	import game.components.entity.collider.BitmapCollider;
	import game.components.motion.Edge;
	import game.components.motion.Threshold;
	import game.components.scene.SceneInteraction;
	import game.creators.entity.EmitterCreator;
	import game.creators.ui.ToolTipCreator;
	import game.data.animation.entity.character.Angry;
	import game.data.animation.entity.character.Place;
	import game.data.animation.entity.character.Proud;
	import game.data.character.LookAspectData;
	import game.data.character.LookData;
	import game.data.display.BitmapWrapper;
	import game.data.game.GameEvent;
	import game.particles.emitter.specialAbility.FlameBlast;
	import game.scenes.myth.mountOlympus.components.MedusaHairComponent;
	import game.scenes.myth.mountOlympus.systems.MedusaHairSystem;
	import game.scenes.myth.shared.Athena;
	import game.scenes.myth.shared.MythScene;
	import game.systems.SystemPriorities;
	import game.systems.entity.character.states.CharacterState;
	import game.systems.motion.ThresholdSystem;
	import game.ui.showItem.ShowItem;
	import game.util.CharUtils;
	import game.util.EntityUtils;
	import game.util.MotionUtils;
	import game.util.PerformanceUtils;
	import game.util.SceneUtil;
	import game.util.SkinUtils;
	
	import org.flintparticles.common.actions.Age;
	import org.flintparticles.common.actions.Fade;
	import org.flintparticles.common.actions.ScaleImage;
	import org.flintparticles.common.counters.Blast;
	import org.flintparticles.common.counters.Steady;
	import org.flintparticles.common.displayObjects.Blob;
	import org.flintparticles.common.initializers.ColorInit;
	import org.flintparticles.common.initializers.ImageClass;
	import org.flintparticles.common.initializers.Lifetime;
	import org.flintparticles.twoD.actions.Accelerate;
	import org.flintparticles.twoD.actions.Move;
	import org.flintparticles.twoD.actions.RotateToDirection;
	import org.flintparticles.twoD.emitters.Emitter2D;
	import org.flintparticles.twoD.initializers.Position;
	import org.flintparticles.twoD.initializers.Velocity;
	import org.flintparticles.twoD.zones.DiscSectorZone;
	import org.flintparticles.twoD.zones.DiscZone;
	import org.flintparticles.twoD.zones.RectangleZone;
	
	public class MountOlympus extends MythScene
	{
		public function MountOlympus()
		{
			super();
		}
	
		
		// pre load setup
		override public function init(container:DisplayObjectContainer = null):void
		{			
			super.groupPrefix = "scenes/myth/mountOlympus/";
			
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
			super.shellApi.eventTriggered.add(eventTriggers);
			_openAthena = false;
			
			super.addSystem( new ThresholdSystem(), SystemPriorities.update );
		
			var entity:Entity = super.getEntityById( "oliveInteraction" );

			Interaction( entity.get( Interaction )).click.add( athenaPopup );
			entity.remove( SceneInteraction );
			
			setupClouds();
			
			convertContainer( _hitContainer[ "snakeCover" ]);
			convertContainer( _hitContainer[ "statue" ]);
			convertContainer(_hitContainer[ "oliveInteraction" ]);
			
			if( !shellApi.checkEvent( _events.HERCULES_LOST ))
			{
				_hitContainer[ "statue" ].visible = false;
				spotSnake();
			}
			
			else
			{
				_hitContainer[ "snake" ].visible = false;
			}
			CharUtils.setDirection( player, true );
			
			// fix windbag interaction
			var aeolus:Entity = getEntityById("aeolus");
			var sceneinteraction:SceneInteraction = aeolus.get( SceneInteraction );
			sceneinteraction.ignorePlatformTarget = true;
			sceneinteraction.reached.add(lock);
			Dialog(aeolus.get(Dialog)).complete.add(unlock);
		}
		
		private function lock(...p):void
		{
			SceneUtil.lockInput(this,true);
		}
		private function unlock(...p):void
		{
			SceneUtil.lockInput(this,false);
		}
		
		/*************************************
		 * 
		 * 			HERC STATUE
		 * 
		 *************************************/
		override protected function addCharacterDialog( container:Sprite ):void
		{
			setupTalkingHercStatue();
			super.addCharacterDialog( container );
		}
		
		private function setupTalkingHercStatue():void
		{
			// dialog for talking statue
			var entity:Entity = EntityUtils.createSpatialEntity( this, _hitContainer[ "dialog" ]);
			var dialog:Dialog = new Dialog();
			
			dialog.faceSpeaker = true;
			dialog.dialogPositionPercents = new Point( 0, .5 );		
			
			var display:Display = entity.get( Display );
			display.alpha = 0;
			
			entity.add( dialog );
			entity.add( new Id( "statueDialog" ));
			entity.add( new Edge( 50, 50, 50, 80 ));
			entity.add( new Character());				
			InteractionCreator.addToEntity( entity, [ InteractionCreator.CLICK ]);
			var sceneInteraction:SceneInteraction = new SceneInteraction();
			
			ToolTipCreator.addToEntity( entity );
			sceneInteraction.offsetX = 70;
			sceneInteraction.offsetY = 150;
			entity.add( sceneInteraction );			
		}
		
		private function athenaPopup( interactionEntity:Entity ):void
		{
			if( !_openAthena )
			{
				_openAthena = true;
				var popup:Athena = super.addChildGroup( new Athena( super.overlayContainer )) as Athena;
				popup.closeClicked.add( resetPopup );
				popup.id = "athena";
			}
		}
		
		private function resetPopup( ...args ):void
		{
			_openAthena = false;
		}
		
		// process incoming events
		private function eventTriggers(event:String, save:Boolean = true, init:Boolean = false, removeEvent:String = null):void
		{
			var dialog:Dialog;
			
			switch( event )
			{ 
				case _events.BUY_BAG_OF_WIND:
					var aeolus:Entity = getEntityById( "aeolus" );
					dialog = aeolus.get( Dialog );
					dialog.setCurrentById( "get_my_bag" );
					
					var interaction:Interaction = aeolus.get( Interaction );
					interaction.click.dispatch( aeolus ); 
					break;
				
				case GameEvent.GOT_ITEM + _events.BAG_OF_WIND:
					MotionUtils.zeroMotion( player );
					var showItem:ShowItem = super.getGroupById( ShowItem.GROUP_ID ) as ShowItem;
					
					if( !showItem )
					{
						showItem = new ShowItem();
						addChildGroup( showItem );
					}
					
					showItem.transitionComplete.addOnce( handleGotBagOfWind );
					
					break;
				
				case _events.USE_BAG_OF_WIND:
					useBagOfWind();
				 	break;
				
				case "herc_walk_to_snake":
					hercWalkToSnake();
					break;
				
				case "turn_herc_to_stone":
					turnHercToStone();					
					break;
			}
		}
		
		/*************************************
		 *  
		 * 			  BAG OF WIND
		 * 
		 *************************************/
		private function useBagOfWind():void
		{
			SceneUtil.lockInput(this,true);
			
	//		var audioGroup:AudioGroup = super.getGroupById( "audioGroup" ) as AudioGroup;
			
			var charMotionCtrl:CharacterMotionControl = player.get( CharacterMotionControl );			
			var spatial:Spatial = player.get( Spatial );
			
			CharUtils.setState( player, CharacterState.JUMP );
			SkinUtils.setSkinPart( player, SkinUtils.OVERSHIRT, "aeolus" );
			
			charMotionCtrl.gravity = -MotionUtils.GRAVITY;
			charMotionCtrl.airMultiplier = 0;
			
			var motion:Motion = player.get( Motion );
			motion.maxVelocity.y = 300;
			motion.velocity.y = -400;
			motion.acceleration.y = -40;
			
			var threshold:Threshold = new Threshold( "y", "<" );
			threshold.threshold = 1600;
			threshold.entered.addOnce( bagEmpty );
			threshold.entered.addOnce( Command.create(SceneUtil.lockInput,this,false) );
			
			player.add( threshold );
			
			var emitterEntity:Entity = new Entity();
			emitterEntity.add( new Id( "emitterEntity" ));
			
			var emitter:Emitter2D = new Emitter2D();
			emitter.counter = new Steady( 20 );
			
			emitter.addInitializer( new ImageClass( Blob, [ 8 ], true ));
			emitter.addInitializer( new Lifetime( 1.75 ));
			emitter.addInitializer( new ColorInit( 0xFFFFFF, 0xE7FFFF ));
			
			emitter.addInitializer( new Velocity( new RectangleZone( 0, 0, 0, 100 )));
			
			emitter.addAction( new Move());	
			emitter.addAction( new Fade( .45, 0 ));			
			emitter.addAction( new ScaleImage( 1, 2.5 ));	
			emitter.addAction( new Accelerate( 0, 20 ));
			emitter.addAction( new Age());
			super.addEntity( emitterEntity );
			
			var entity:Entity = EmitterCreator.create( this, super._hitContainer[ "smokeEmpty" ], emitter, 0, 0, emitterEntity, "exhaust", spatial );
			_audioGroup.addAudioToEntity( entity );
			
			var audio:Audio = entity.get( Audio );
			audio.playCurrentAction( "random" );
						
			player.remove( BitmapCollider );
		}
		
		private function bagEmpty():void
		{
			var lookData:LookData = new LookData();
			lookData.applyAspect( new LookAspectData( SkinUtils.OVERSHIRT, "aeolus" ));
			
			SkinUtils.removeLook( player, lookData );
			
			var charMotionCtrl:CharacterMotionControl = player.get( CharacterMotionControl );
			charMotionCtrl.gravity = MotionUtils.GRAVITY;
			charMotionCtrl.airMultiplier = 2;
			super.removeEntity( super.getEntityById( "emitterEntity" ));
			player.remove( Tween );
		
			var motion:Motion;
			motion = player.get( Motion );
			motion.maxVelocity.y = 1200;
			
			player.add( new BitmapCollider());
		}
			
		private function handleGotBagOfWind():void
		{
		//	SceneUtil.lockInput( this, false );
			super.shellApi.triggerEvent( _events.USE_BAG_OF_WIND );
		}
		
		/*************************************
		 * 
		 * 				CLOUDS
		 * 
		 *************************************/
		private function setupClouds():void
		{
			var clip:MovieClip;
			
			var points:Vector.<Point> = new Vector.<Point>;
			points.push( new Point( 1880, 5 ), new Point( 1980, 15 ), new Point( 2080, 30 ), new Point( 2180, 15 ), 
				new Point( 2280, 30 ), new Point( 2380, 15 ), new Point( 2480, 5 ),
				new Point( 1791, -42 ), new Point( 1895, -9 ), new Point( 2024, -20 ), new Point( 2133, -10 ),
				new Point( 2265, -18 ), new Point( 2395, -28 ), new Point( 2520, -60 ));
			
			clip = _hitContainer[ "poof" ] as MovieClip;
			var wrapper:BitmapWrapper = this.convertToBitmapSprite( clip[ "content" ] );
			var sprite:Sprite;
			var bitmapData:BitmapData;
			var bitmap:Bitmap;
			var displayObjectBounds:Rectangle = clip.getBounds( clip );
			var offsetMatrix : Matrix = new Matrix( 1, 0, 0, 1, displayObjectBounds.left, displayObjectBounds.top );
			
			var clouds:Number = 14;
			if( PerformanceUtils.qualityLevel < PerformanceUtils.QUALITY_MEDIUM )
			{ 
				clouds = 7;
			}
			for (var i:int = 0; i < clouds; i++) 
			{		
				sprite = new Sprite();
				bitmapData = new BitmapData( clip.width, clip.height, true, 0x000000 );
				bitmapData.draw( wrapper.data, null );
				
				bitmap = new Bitmap( bitmapData, "auto", true );
				bitmap.transform.matrix = offsetMatrix;
				sprite.addChild( bitmap );
				
				var poof:Entity = EntityUtils.createMovingEntity( this, sprite, _hitContainer[ "smokeEmpty" ]);		
				var startX:Number = points[ i ].x - ( .5 * sprite.width );
				var startY:Number = points[ i ].y;
				EntityUtils.position( poof, startX, startY );
				
				var display:Display = poof.get( Display );
				display.alpha = .6;
				
				var motion:Motion = poof.get( Motion );
				motion.rotationFriction = 0;
				motion.rotationVelocity = ( Math.random() * 60 ) - 30;					
			}
			
			wrapper.sprite.visible = false;
			wrapper.bitmap.visible = false;
		}
		
		
		/*************************************
		 * 
		 * 				MEDUSSA
		 * 
		 *************************************/
		
		private function spotSnake():void
		{
			herc = getEntityById( "herc" );
			medusa = getEntityById( "medusa" );				
			
			var display:Display = medusa.get( Display );
			display.visible = false;
			
	//		var audioGroup:AudioGroup = super.getGroupById( "audioGroup" ) as AudioGroup;
			
			medusaSnake = EntityUtils.createSpatialEntity(this,_hitContainer["snake"]);
			medusaSnake.add( new Id( "medusaSnake" ));
			
			_audioGroup.addAudioToEntity( medusa );
			_audioGroup.addAudioToEntity( medusaSnake );
			_audioGroup.addAudioToEntity( herc );
			
			var number:int;
			var spatial:Spatial;
			var point:MovieClip;
			
			var hair:MedusaHairComponent = new MedusaHairComponent();
			hair.radius = Math.random() * 10 + 15;
			
			var speed:Number = Math.random() * .025 + .02;
			var timer:Number = ( Math.random() * 3 );
			hair.timers.push( timer );
			
			hair.snake.push( new Vector.<Spatial>);
			hair.speeds.push( speed );
			var clip:MovieClip = MovieClip( _hitContainer[ "snake" ]);
			
			for( number = 0; number < 5; number ++ )
			{
				point = MovieClip( clip.getChildByName( "p" + number ));
				spatial = new Spatial( point.x, point.y );
				spatial.rotation = point.rotation;
				
				hair.snake[ 0 ].push( spatial );
				if( number == 4 )
				{
					point.visible = false;
				}
			}
			
			hair.state.push( hair.IDLE );
			
			hair.head.push( MovieClip( clip.getChildByName( "head" )));	
			MovieClip( hair.head[ 0 ].getChildByName( "tongue" )).scaleX = 0;
			medusaSnake.add( hair );
			
			
			var audio:Audio = medusaSnake.get( Audio );
			audio.playCurrentAction( "random" );
			
			
			SceneUtil.lockInput( this, true );
			SceneUtil.setCameraTarget( this, medusaSnake );
			SceneUtil.delay(this, 2, camBackToPlayer );
			super.addSystem( new MedusaHairSystem(), SystemPriorities.update );
		}
		
		private function camBackToPlayer():void
		{
			shellApi.triggerEvent( "snake_appear" );
			SceneUtil.setCameraTarget( this, player );
		}
		
		private function hercWalkToSnake():void
		{
			SceneUtil.setCameraTarget( this, herc );
			
			// follow path to snake
			var path:Vector.<Point> = new Vector.<Point>();
			path.push( new Point( 415, 2235 ));
			
			// trigger reached snake
			CharUtils.followPath( herc, path, hercReachedSnake );			
		}
		
		private function hercReachedSnake( entity:Entity ):void
		{
			// do a reach down anim, show medusa at end
			CharUtils.setAnim( herc, Place );
			CharUtils.getTimeline( herc ).handleLabel( "trigger", showMedusa );
			
			var dialog:Dialog = herc.get( Dialog );
			dialog.faceSpeaker = false;
		}
		
		private function showMedusa():void
		{
			var pt:Point = EntityUtils.getPosition(medusa);
			makePoof();
			
			// unsleep medusa
			var display:Display = medusa.get( Display );
			display.visible = true;
			
			// kill snake
			removeEntity( medusaSnake );
			
			var dialog:Dialog = medusa.get( Dialog );
			dialog.sayById( "medusa_appear" );
		}
		
		private function turnHercToStone():void
		{			
			shellApi.completeEvent( _events.HERCULES_LOST );
			CharUtils.setDirection( herc, true );
			CharUtils.setAnim( medusa, Angry );
			CharUtils.getTimeline( medusa ).handleLabel( "stopAnger", toStone );
			
			var audio:Audio = medusa.get( Audio );
			audio.playCurrentAction( "trigger" );
			
			audio = herc.get( Audio );
			audio.playCurrentAction( "trigger" );
		}
		
		private function toStone():void
		{
			CharUtils.setAnim( herc, Proud );
			
			var tween:Tween = new Tween();
			herc.add( tween );
			
			tween.to( herc.get( Display ), 1, { alpha : 0, onComplete : hideMedusa });
			
			_hitContainer[ "statue" ].visible = true;
		}
		
		private function hideMedusa():void
		{			
			makePoof();
			
			removeEntity( medusa );
			removeEntity( herc );
			removeEntity( medusaSnake );
			clearHerc();
		}
		
		
		public function makePoof():void
		{
			var pt:Point = EntityUtils.getPosition( medusa );
			
			var puff:FlameBlast = new FlameBlast();
			puff.counter = new Blast( 20 );
			puff.addInitializer( new Lifetime( 0.2, 0.3 ));
			puff.addInitializer( new Velocity( new DiscSectorZone( new Point( 0, 0 ), 300, 200, -Math.PI, Math.PI )));
			puff.addInitializer( new Position( new DiscZone( new Point( 0, 0 ), 18 )));
			puff.addInitializer( new ImageClass( Blob, [ 6.5, 0xffffff ], true, 6 ));
			puff.addAction( new Age());
			puff.addAction( new Move());
			puff.addAction( new RotateToDirection());
			puff.addAction( new Fade( 0.8, 0.1 ));
			EmitterCreator.create( this, _hitContainer, puff, pt.x, pt.y );
			
			//poof sound
			var audio:Audio = medusa.get( Audio );
			audio.playCurrentAction( "random" );
		}
		
		
		private function clearHerc():void
		{
			SceneUtil.setCameraTarget( this, player );
			removeEntity( herc );			
			SceneUtil.lockInput( this, false );		
		}
				
		
		private var _openAthena:Boolean;
		private var herc:Entity;
		private var medusa:Entity;
		private var medusaSnake:Entity;
	}
}