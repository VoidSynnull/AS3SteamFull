package game.scenes.myth.treeTop
{
	import flash.display.DisplayObject;
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.geom.Point;
	import flash.text.TextFormat;
	
	import ash.core.Entity;
	
	import engine.components.Audio;
	import engine.components.Display;
	import engine.components.Id;
	import engine.components.Interaction;
	import engine.components.Motion;
	import engine.components.Spatial;
	import engine.components.Tween;
	import engine.managers.SoundManager;
	import engine.util.Command;
	
	import game.components.entity.Dialog;
	import game.components.entity.Sleep;
	import game.components.hit.Item;
	import game.components.hit.Platform;
	import game.components.hit.Zone;
	import game.components.motion.Threshold;
	import game.components.scene.SceneInteraction;
	import game.components.timeline.Timeline;
	import game.components.ui.TextDisplay;
	import game.creators.entity.EmitterCreator;
	import game.creators.ui.TextDisplayCreator;
	import game.creators.ui.ToolTipCreator;
	import game.data.TimedEvent;
	import game.data.WaveMotionData;
	import game.data.animation.entity.character.SoarDown;
	import game.data.animation.entity.character.Stomp;
	import game.data.display.BitmapWrapper;
	import game.data.game.GameEvent;
	import game.data.sound.SoundModifier;
	import game.data.text.TextStyleData;
	import game.data.ui.ToolTipType;
	import game.particles.emitter.specialAbility.FlameBlast;
	import game.scenes.myth.shared.MythScene;
	import game.systems.entity.character.states.CharacterState;
	import game.systems.motion.ThresholdSystem;
	import game.util.AudioUtils;
	import game.util.CharUtils;
	import game.util.DisplayUtils;
	import game.util.EntityUtils;
	import game.util.MotionUtils;
	import game.util.PerformanceUtils;
	import game.util.SceneUtil;
	import game.util.TextUtils;
	import game.util.TweenUtils;
	
	import org.flintparticles.common.actions.Age;
	import org.flintparticles.common.actions.Fade;
	import org.flintparticles.common.counters.Blast;
	import org.flintparticles.common.counters.Random;
	import org.flintparticles.common.displayObjects.Blob;
	import org.flintparticles.common.displayObjects.Dot;
	import org.flintparticles.common.initializers.ImageClass;
	import org.flintparticles.common.initializers.Lifetime;
	import org.flintparticles.twoD.actions.Accelerate;
	import org.flintparticles.twoD.actions.DeathZone;
	import org.flintparticles.twoD.actions.Move;
	import org.flintparticles.twoD.actions.RandomDrift;
	import org.flintparticles.twoD.actions.RotateToDirection;
	import org.flintparticles.twoD.emitters.Emitter2D;
	import org.flintparticles.twoD.initializers.Position;
	import org.flintparticles.twoD.initializers.Velocity;
	import org.flintparticles.twoD.zones.DiscSectorZone;
	import org.flintparticles.twoD.zones.DiscZone;
	import org.flintparticles.twoD.zones.RectangleZone;
	
	public class TreeTop extends MythScene
	{
		private const HIDE_SATYR:String 	= "hide_satyr";
		private const SATYR_LEAVES:String 	= "saytr_leaves";
		private const SHOW_PATH:String 		= "show_path";
		private const CHASE_MUSIC:String 	= "myth_honey_chase_countdown_02.mp3";
		private const COLLECTABLES_NEEDED:int = 10;
		private const NUM_POTS:int = 16;
		private const COLLECTION_TIME:int = 100;
		private const APPLE_THRESHOLD:int = 765;
		
		private var _bitmapQuality:Number = 1;
		
		private var _collectedCount:Number = 0;
		private var _countDown:TimedEvent;
		private var _timeLeft:int;
		private var _countText:Entity;
		private var _timerText:Entity;
		private var _tweenText:Entity;
		private var _locked:Boolean = false;
		
		private var sparkles:Emitter2D;
		
		private var _hangingApple:Entity;
		private var _appleItem:Entity;
		private var _scrollItem:Entity;
		private var _zeus:Entity;
		private var _clouds:Entity;
		private var _lightningEnt:Entity;
		private var _hiddenTree:Entity;
				
		public function TreeTop()
		{
			super();
		}
		
		// pre load setup
		override public function init(container:DisplayObjectContainer = null):void
		{			
			super.groupPrefix = "scenes/myth/treeTop/";
			super.init(container);
		}
		
		// initiate asset load of scene specific assets.
		override public function load():void
		{
			super.load();
		}
		override public function destroy():void
		{
			super.destroy();	
		}
		
		// all assets ready
		override public function loaded():void
		{

			super.shellApi.eventTriggered.add(eventTriggers);
			
			_bitmapQuality = ( PerformanceUtils.qualityLevel < PerformanceUtils.QUALITY_LOW ) ? .5 : 1;
		
			setupForeground();			// move light rays behind foreground
			setupCollectionPuzzle();	// setup honeypots
			setupNpcs();
			setupTree();
			setupApple();
			super.loaded();
			setupScroll();
		}
		
		// process incoming events
		private function eventTriggers(event:String, save:Boolean = true, init:Boolean = false, removeEvent:String = null):void
		{
			var clip:MovieClip;
			var entity:Entity;
			var spatial:Spatial;
			
			switch( event )
			{
				case _events.QUEST_STARTED:
					exitZeus();				
					break;
				
				case _events.HONEY_CHASE_STARTED:
					startCollectionChallenge();
					break;
				
				case _events.HONEY_CHASE_FAILED:
					shellApi.removeEvent( _events.HONEY_CHASE_STARTED );
					break;
				
				case _events.HONEY_CHASE_PASSED:
					shellApi.removeEvent( _events.HONEY_CHASE_STARTED );
					break;
					
				case GameEvent.GOT_ITEM + _events.GOLDEN_APPLE:
					entity = getEntityById( "char1" );
					SceneInteraction(entity.get(SceneInteraction)).activated = true;
					Dialog(entity.get(Dialog)).complete.addOnce(hideSatyr);
					break;
				
			 	case SHOW_PATH:
					showHiddenPath();
					break;
				
				case GameEvent.GOT_ITEM + _events.ZEUS_SCROLL:
					if(sparkles != null)
					{
						sparkles.stop();
					}
					break;
			}
		}
		
		private function hideSatyr( ...args ):void
		{
			var entity:Entity = getEntityById( "char1" );
			var spatial:Spatial = entity.get( Spatial );
			
			makePoof( spatial.x, spatial.y );
			removeEntity( entity );
			
			enterZeus();
		}
		
		//////////////////////////////////////////////////////////////////////////
		///////////////////////////// SETUP /////////////////////////////
		//////////////////////////////////////////////////////////////////////////
		
		private function setupForeground():void
		{
			var foregroundDisplay:DisplayObjectContainer = EntityUtils.getDisplayObject( super.getEntityById( "foreground" ));
			var clip:DisplayObject;
			for (var i:int = 1; i < 4; i++) 
			{
				clip = foregroundDisplay.getChildByName( "light" + i );
				if( clip )
				{
					if( PerformanceUtils.qualityLevel > PerformanceUtils.QUALITY_MEDIUM )
					{
						DisplayUtils.moveToBack(clip);
					}
					else
					{
						clip.parent.removeChild( clip );
					}
				}
			}
		}
		
		private function setupCollectionPuzzle():void
		{
			if( !shellApi.checkEvent( _events.HONEY_CHASE_PASSED ))
			{
				// create textual displays
				var format:TextFormat = null;
				var styleData:TextStyleData = shellApi.textManager.getStyleData( TextStyleData.UI, "timer" );	
				var textDisplay:TextDisplay;
				
				_timerText = TextDisplayCreator.create( this, overlayContainer, COLLECTION_TIME.toString(), format, shellApi.viewportWidth / 2, 20 );
				EntityUtils.visible( _timerText, false );
				textDisplay = _timerText.get( TextDisplay );
				TextUtils.applyStyle(styleData, textDisplay.tf );
				Spatial(_timerText.get( Spatial )).x = ( shellApi.viewportWidth / 2 ) - ( textDisplay.tf.width / 2 );
				Sleep(_timerText.get( Sleep )).sleeping = true;
				
				_countText = TextDisplayCreator.create( this, overlayContainer, _collectedCount + "/" + COLLECTABLES_NEEDED, format, 0, 20 );
				EntityUtils.visible( _countText, false );
				textDisplay = _countText.get( TextDisplay );
				TextUtils.applyStyle(styleData, textDisplay.tf );
				var offset:Number = textDisplay.tf.width / 2;
				Sleep(_countText.get( Sleep )).sleeping = true;
				
				_tweenText = TextDisplayCreator.create( this, overlayContainer, "", format, shellApi.viewportWidth / 2, shellApi.viewportHeight / 2 );
				_tweenText.add( new Tween());
				EntityUtils.visible( _tweenText, false );
				textDisplay = _tweenText.get( TextDisplay );
				TextUtils.applyStyle(styleData, textDisplay.tf );
				Spatial(_tweenText.get( Spatial )).x = ( shellApi.viewportWidth / 2 ) - offset;
				Sleep(_tweenText.get( Sleep )).sleeping = true;
				
				// create honey pots
				var clip:MovieClip = _hitContainer[ "honeyPot" ];
				var sourceWrapper:BitmapWrapper = this.convertToBitmapSprite( clip, null, true, _bitmapQuality );
				
				var zoneEntity:Entity;
				var zoneSpatial:Spatial;
				var wrapper:BitmapWrapper;
				var entity:Entity;
				var spatial:Spatial;
				var number:int;
				var sleep:Sleep;
				var display:Display;
				for ( number = 0; number < NUM_POTS; number++ ) 
				{
					zoneEntity = getEntityById( "zone" + number );
					zoneSpatial = zoneEntity.get( Spatial );
					display = zoneEntity.get( Display );
					MovieClip(display.displayObject).mouseEnabled = false;
					MovieClip(display.displayObject).mouseChildren = false;
	
					wrapper = sourceWrapper.duplicate();
					entity = EntityUtils.createSpatialEntity( this, wrapper.sprite, _hitContainer );
					wrapper.sprite.mouseEnabled = false;
					wrapper.sprite.mouseChildren = false;
					spatial = entity.get( Spatial );
					spatial.rotation = zoneSpatial.rotation;
					spatial.x = zoneSpatial.x;
					spatial.y = zoneSpatial.y;
					
					entity.add( new Id( "pot" + number ))
					
					sleep = zoneEntity.get( Sleep );
					sleep.sleeping = true;
					sleep.ignoreOffscreenSleep = true;
					EntityUtils.addParentChild( entity, zoneEntity );
				}	
			}
			else
			{
				clip = _hitContainer[ "honeyPot" ];
				_hitContainer.removeChild( clip );
				
				for( number = 0; number < NUM_POTS; number ++ )
				{
					removeEntity( getEntityById( "zone" + number ));
				}
			}
		}
		
		private function setupNpcs():void
		{
			var cloudClip:MovieClip = _hitContainer["clouds"];
			if( !shellApi.checkEvent( _events.ZEUS_APPEARS_TREE ))
			{
				// setup zeus
				_zeus = getEntityById("char2");
				
				var sleep:Sleep = _zeus.get( Sleep );
				sleep.sleeping = true;
				sleep.ignoreOffscreenSleep = true;
				
				_zeus.remove( SceneInteraction );
				ToolTipCreator.removeFromEntity( _zeus );
				_zeus.remove( Interaction );
				
				//set up clouds
				//var wrapper:BitmapWrapper = super.convertToBitmapSprite( cloudClip );
				//_clouds = EntityUtils.createSpatialEntity( this, wrapper.sprite );
				_clouds = EntityUtils.createSpatialEntity( this, cloudClip );	// NOTE :: Leave as vector, more concerned about memory usage in this scene
				_clouds.get(Display ).alpha = 0;
				
				_clouds.add( new Sleep( true, true ) );
			}
			else
			{	
				// remove zeus & clouds if he has already appeared
				removeEntity( getEntityById( "char2" ));
				_hitContainer.removeChild( cloudClip );
			}
			
			// remove satyr if player has apple 
			if( shellApi.checkItemEvent( _events.GOLDEN_APPLE ))
			{
				removeEntity( getEntityById( "char1" ));
			}
		}
		
		private function setupTree():void
		{
			var clip:MovieClip = _hitContainer["foliage"];
			DisplayUtils.moveToTop( clip );
			var wrapper:BitmapWrapper = super.convertToBitmapSprite( clip, null, true, _bitmapQuality);	// TODO 
			_hiddenTree = EntityUtils.createSpatialEntity( this, wrapper.sprite );	
			
			super.getEntityById("secretPath").remove( Platform );
			
			var appleBranch:Entity = super.getEntityById( "branchInteraction" );
			if( shellApi.checkItemEvent( _events.GOLDEN_APPLE ) )
			{
				super.removeEntity( appleBranch );
			}
			else	// put interaction to sleep until talking to satyr
			{
				var sleep:Sleep = appleBranch.get( Sleep );
				sleep.sleeping = true;
				sleep.ignoreOffscreenSleep = true;
			}
		}
		
		private function setupApple():void
		{
			// hanging dummy
			var clip:MovieClip = _hitContainer["appleHanger"];
			if( !shellApi.checkItemEvent( _events.GOLDEN_APPLE ) )
			{
				var bmp:BitmapWrapper = DisplayUtils.convertToBitmapSprite( clip );
				_hangingApple = EntityUtils.createSpatialEntity( this, bmp.sprite );
			}
			else
			{
				_hitContainer.removeChild( clip );
			}
			
			// actual apple item, put to sleep until dummy apple has dropped
			_appleItem = getEntityById( _events.GOLDEN_APPLE );
			if(_appleItem != null)
			{
				var sleep:Sleep = _appleItem.get( Sleep );
				sleep.sleeping = true;
				sleep.ignoreOffscreenSleep = true;
				
				_appleItem.remove( Item );
				ToolTipCreator.removeFromEntity( _appleItem );
				
				var display:Display = _appleItem.get( Display );
				var displayObject:MovieClip = display.displayObject;
				displayObject.mouseEnabled = false;
				displayObject.mouseChildren = false;
			}
		}
		
		private function setupScroll():void
		{
			// item to drop on branch
			_scrollItem = getEntityById( _events.ZEUS_SCROLL );
			if( _scrollItem != null )
			{
				var sleep:Sleep = _scrollItem.get( Sleep );
				sleep.sleeping = true;
				sleep.ignoreOffscreenSleep = true;	
				
				_scrollItem.remove( Item );
				ToolTipCreator.removeFromEntity( _scrollItem );
				
				var display:Display = _scrollItem.get( Display );
				display.visible = false;
				var displayObject:MovieClip = display.displayObject;
				displayObject.mouseEnabled = false;
				displayObject.mouseChildren = false;
				
				if(shellApi.checkItemEvent( _events.GOLDEN_APPLE ))
				{
					showScroll();
				}
			}
		}
		
		//////////////////////////////////////////////////////////////////////////
		//////////////////////////// HONEY COLLECTION ////////////////////////////
		//////////////////////////////////////////////////////////////////////////
		
		
		
		public function startCollectionChallenge():void
		{
			var display:Display;
			var entity:Entity;
			var number:int;
			var sleep:Sleep;
			var textDisplay:TextDisplay;
			var zone:Zone;
			var zoneEntity:Entity;
					
			Sleep(_timerText.get( Sleep )).sleeping = false;
			EntityUtils.visible( _timerText );
			
			Sleep(_countText.get( Sleep )).sleeping = false;
			EntityUtils.visible( _countText );
			
			Sleep(_tweenText.get( Sleep )).sleeping = false;
			EntityUtils.visible( _tweenText );
			
			for( number = 0; number < NUM_POTS; number++ ) 
			{
				entity = getEntityById( "pot" + number );
				MotionUtils.addWaveMotion( entity, new WaveMotionData( "y", 12, 0.05 ), this );
				
				zoneEntity = getEntityById( "zone" + number );
				sleep = zoneEntity.get( Sleep );
				sleep.sleeping = false;
				sleep.ignoreOffscreenSleep = false;
				
				zone = zoneEntity.get( Zone );
				zone.entered.add( gotHoneyPot );
			}	
			
			//reset values
			_collectedCount = 0;
			_timeLeft = COLLECTION_TIME;
			
			textDisplay = _countText.get( TextDisplay );
			textDisplay.tf.text = _collectedCount + "/" + COLLECTABLES_NEEDED;
			
			textDisplay = _timerText.get( TextDisplay );
			textDisplay.tf.text = _timeLeft.toString();
			
			if( _countDown == null )
			{
				_countDown = new TimedEvent( 1, 0, countDown );
			}
			SceneUtil.addTimedEvent( this, _countDown);
			_countDown.start();
			
			AudioUtils.play( this, SoundManager.MUSIC_PATH + CHASE_MUSIC, 0.8, true, SoundModifier.FADE );
		}
		
		private function countDown():void
		{
			var textDisplay:TextDisplay;
			var spatial:Spatial;
			
			if( !( shellApi.checkEvent( _events.HONEY_CHASE_PASSED ) || shellApi.checkEvent( _events.HONEY_CHASE_FAILED )))
			{
				_timeLeft--;
				if( _timeLeft == 0 )
				{
					collectionFailed();
					_countDown.stop();
				}
				else
				{
					textDisplay = _timerText.get( TextDisplay );
					textDisplay.tf.text = _timeLeft.toString();
					
					spatial = _timerText.get( Spatial );
					spatial.x = ( shellApi.viewportWidth / 2 ) - ( textDisplay.tf.width / 2 );
				}
			}
			else
			{
				_countDown.stop();
			}
		}
		
		private function gotHoneyPot( zoneString:String, playerString:String ):void
		{
			var entity:Entity = getEntityById( "pot" + zoneString.substr( 4 ));
			var spatial:Spatial;
			var textDisplay:TextDisplay = _countText.get( TextDisplay );
			var tween:Tween = _tweenText.get( Tween );
			var zone:Zone;
			
			_collectedCount++;
			
			textDisplay.tf.text = _collectedCount + "/" + COLLECTABLES_NEEDED;
			
			textDisplay = _tweenText.get( TextDisplay );
			textDisplay.tf.text = _collectedCount + "/" + COLLECTABLES_NEEDED;
			textDisplay.tf.x = 0;
			textDisplay.tf.y = 0;
			Spatial(_tweenText.get( Spatial )).x = ( shellApi.viewportWidth / 2 ) - ( textDisplay.tf.width / 2 );
			
			textDisplay.tf.alpha = 1;
			tween.to( textDisplay.tf, .5, { y : textDisplay.tf.y - 50, alpha : 0, onComplete : resetText }, "fadeslide" );
			// play collect sound
		
			shellApi.triggerEvent( "honey_chase_collect_sound" );	
			
			entity = getEntityById( zoneString );
			zone = entity.get( Zone );
			zone.entered.removeAll();
			var sleep:Sleep = entity.get(Sleep);
			sleep.sleeping = true;
			sleep.ignoreOffscreenSleep = true;
			
			if( _collectedCount == COLLECTABLES_NEEDED )
			{
				collectionComplete();
			}
		}
		
		private function resetText():void
		{
			var textDisplay:TextDisplay = _tweenText.get( TextDisplay );
			
			textDisplay.tf.x = shellApi.viewportWidth / 3;
			textDisplay.tf.y = shellApi.viewportHeight / 3;
			textDisplay.tf.alpha = 0;
		}

		public function collectionFailed():void
		{
			shellApi.triggerEvent( _events.HONEY_CHASE_FAILED );
			AudioUtils.stop( this, SoundManager.MUSIC_PATH + CHASE_MUSIC );
			
			// reset honey pots
			var display:Display;
			var entity:Entity;
			var number:int;
			var sleep:Sleep;
			var zone:Zone;
			
			for( number = 0; number < NUM_POTS; number ++ ) 
			{
				entity = getEntityById( "zone" + number );
				sleep = entity.get( Sleep );
				sleep.sleeping  = true;
				sleep.ignoreOffscreenSleep = true;
				
				zone = entity.get( Zone );
				zone.entered.removeAll();
			}
			
			display = _timerText.get( Display );
			display.visible = false;
			sleep = _timerText.get( Sleep );
			sleep.sleeping = true;
			
			display = _countText.get( Display );
			display.visible = false;
			sleep = _countText.get( Sleep );
			sleep.sleeping = true;
			
			display = _tweenText.get( Display );
			display.visible = false;
			sleep = _tweenText.get( Sleep );
			sleep.sleeping = true;
		}
		
		public function collectionComplete():void
		{
			shellApi.triggerEvent( _events.HONEY_CHASE_PASSED, true );
			AudioUtils.stop( this, SoundManager.MUSIC_PATH + CHASE_MUSIC );
			Dialog( super.player.get(Dialog) ).sayById("collectionComplete");
			
			var entity:Entity;
			var number:int;
			var zone:Zone;
			for( number = 0; number < NUM_POTS; number ++ ) 
			{
				entity = getEntityById( "zone" + number );
				Zone(entity.get( Zone )).entered.removeAll();
				super.removeEntity( entity );	// TODO :: does this remove the children as well? - bard
			}
			
			super.removeEntity( _timerText );
			super.removeEntity( _countText );
			super.removeEntity( _tweenText );
			
			_countDown.stop();
			_countDown.signal.removeAll();
			_countDown = null;
		}
		
		////////////////////////////////////////////////////////////////////////
		//////////////////////////// ZEUS SEQUENCE ////////////////////////////
		////////////////////////////////////////////////////////////////////////
		
		private function showHiddenPath():void
		{	
			TweenUtils.entityTo( _hiddenTree, Display, 3, { alpha:0.35, onComplete:showedPath }, "reveal" );
			super.getEntityById("secretPath").add(new Platform());
			SceneUtil.setCameraTarget( this, _hiddenTree);
		}	
		
		private function showedPath():void
		{
			// return cam to player
			SceneUtil.setCameraTarget( this, player);				
			
			// active interaction to trigger apple
			var appleBranch:Entity = getEntityById( "branchInteraction" );
			if( appleBranch )
			{
				var sceneInteraction:SceneInteraction = appleBranch.get( SceneInteraction );
				sceneInteraction.reached.addOnce(stompApple);
				sceneInteraction.minTargetDelta = new Point( 100, 100 );
				sceneInteraction.faceDirection = CharUtils.DIRECTION_RIGHT;
				sceneInteraction.validCharStates = new <String>[ CharacterState.WALK ];
				sceneInteraction.ignorePlatformTarget = false;
				sceneInteraction.offsetY = -210;
				
				var sleep:Sleep = appleBranch.get( Sleep );
				sleep.sleeping = false;
				sleep.ignoreOffscreenSleep = false;
			}
		}
		
		private function stompApple(char:Entity, hit:Entity):void
		{
			CharUtils.setAnim( char, Stomp, false, 100 );
			CharUtils.getTimeline( char ).handleLabel( "end", dropApple );
			CharUtils.getTimeline( char ).handleLabel( "stomp", Command.create( shellApi.triggerEvent, "stomp_sound" ));
			super.removeEntity( super.getEntityById( "branchInteraction" ));
		}
		
		private function dropApple():void
		{
			if( _hangingApple != null )
			{
				removeEntity(_hangingApple);
			}
			
			if( _appleItem != null )
			{
				var display:Display = _appleItem.get( Display );
				display.visible = true;
				
				var sleep:Sleep = _appleItem.get( Sleep );
				sleep.sleeping = false;
				sleep.ignoreOffscreenSleep = true;

				var motion:Motion = new Motion();
				motion.acceleration.y = MotionUtils.GRAVITY;
				
				var threshold:Threshold = new Threshold( "y", ">=" );
				threshold.threshold = APPLE_THRESHOLD;
				
				threshold.entered.add( stopApple );
				_appleItem.add( threshold ).add( motion );
				
				addSystem( new ThresholdSystem() );
			}
		}
		
		private function stopApple( ...args ):void
		{
			Motion(_appleItem.get( Motion )).zeroMotion();
			
			Spatial( _appleItem.get(Spatial) ).y = APPLE_THRESHOLD;
			
			ToolTipCreator.addToEntity( _appleItem, ToolTipType.CLICK, null, new Point( 10, 40 ) );
			_appleItem.add( new Item());
			
			removeSystem( super.getSystem(ThresholdSystem) );
		}
				
		private function enterZeus():void
		{		
			// wake up zeus and clouds
			var sleep:Sleep = _zeus.get( Sleep );
			sleep.sleeping = false;
			sleep.ignoreOffscreenSleep = true;
			
			var display:Display = _zeus.get( Display );
			display.visible = true;
			
			sleep = _clouds.get( Sleep );
			sleep.sleeping = false;
			sleep.ignoreOffscreenSleep = true;
		
			DisplayUtils.moveToTop(EntityUtils.getDisplayObject(_clouds));
			DisplayUtils.moveToTop(EntityUtils.getDisplayObject(_zeus));
			
			// tween to position 					
			TweenUtils.entityTo( _zeus, Spatial, 3, { y : 660 });	

			//set animation
			CharUtils.setAnim(_zeus,SoarDown);			
			var timeline:Timeline = _zeus.get( Timeline );
			timeline.gotoAndStop( 9 );
			
			// set camera target to pre-defined point in scene
			SceneUtil.setCameraTarget(this, EntityUtils.createSpatialEntity(this, _hitContainer["cameraDummy"]));
			super.createLightningCover();
			shellApi.triggerEvent("bigThunder_sound");
			
			var tween:Tween = new Tween();
			_clouds.add( tween );
			tween.to( _clouds.get(Spatial), 3, {y:360});		
			tween.to( _clouds.get(Display), 4, {alpha:1, onComplete:speakZeus });
		}	
		
		private function speakZeus():void
		{
			CharUtils.faceTargetEntity(player,_zeus);
			MotionUtils.addWaveMotion(_zeus,new WaveMotionData( "y", 8, 0.05 ),this);
			shellApi.triggerEvent( _events.ZEUS_APPEARS_TREE, true);
		}
		
		private function exitZeus():void
		{					
			var tween:Tween = _zeus.get(Tween);
			tween.to(_zeus.get(Spatial), 3, {y:100, onComplete:zeusGone});	
			tween.to(_clouds.get(Display), 2, {alpha:0});	
		}	

		private function zeusGone():void
		{
			// zeus seqeuence complete, unlock controls
			SceneUtil.lockInput(this,false,false);
			
			removeEntity( _zeus, true );
			removeEntity( _clouds, true );
			SceneUtil.setCameraTarget(this, player);
			
			_flashing = false;
			showScroll();
		}
		
		// wake the scroll, add sparkles and floating
		private function showScroll():void
		{
			var sleep:Sleep = _scrollItem.get( Sleep );
			sleep.sleeping = false;
			sleep.ignoreOffscreenSleep = true;
			_scrollItem.ignoreGroupPause = false;	
			
			var display:Display = _scrollItem.get( Display );
			display.visible = true;
			
			_scrollItem.add( new Item());
			ToolTipCreator.addToEntity( _scrollItem );
			
			MotionUtils.addWaveMotion( _scrollItem, new WaveMotionData( "y", 8, 0.04 ), this );
			var pt:Point = EntityUtils.getPosition( _scrollItem );
	
			if( PerformanceUtils.qualityLevel > PerformanceUtils.QUALITY_MEDIUM )
			{	
				makePoof( pt.x, pt.y );
				makeSparkles( pt.x, pt.y );
			}
		}
		
		/////////////////////////////////////////////////////////////////////
		////////////////////////////// EFFECTS ////////////////////////////// 
		/////////////////////////////////////////////////////////////////////
		
		private function makeSparkles(x:Number, y:Number):void
		{
			sparkles= new Emitter2D();
			var box:RectangleZone = new RectangleZone(x-40,y-10,x+40,y+100);
			sparkles.counter = new Random( 20, 40 );
			sparkles.addInitializer(new ImageClass(Dot, [1.5, 0xE7B13F], true));
			sparkles.addInitializer(new Position(new RectangleZone(box.right,box.top,box.left,box.bottom-90)));
			sparkles.addInitializer(new Lifetime(3));			
			sparkles.addAction(new Move());
			sparkles.addAction(new Accelerate(0, 50));
			sparkles.addAction(new RandomDrift(0, 50));
			sparkles.addAction(new DeathZone(box, true));
			sparkles.addAction(new Fade(1,0));
			sparkles.addAction(new Age());			
			EmitterCreator.create(this,_hitContainer,sparkles,0,0);
			
			//sparkle_sound
			var scroll:Entity = getEntityById( "zeusScroll" );
			_audioGroup.addAudioToEntity(scroll);			
			var audio:Audio =  scroll.get( Audio );
			audio.playCurrentAction( "go" );
		}
		
		private function makePoof( x:Number, y:Number ):void
		{
			var puff:FlameBlast = new FlameBlast();
			puff.counter = new Blast( 20);
			puff.addInitializer(new Lifetime(0.2, 0.3));
			puff.addInitializer(new Velocity(new DiscSectorZone(new Point(0,0), 300, 200, -Math.PI, Math.PI )));
			puff.addInitializer(new Position(new DiscZone(new Point(0,0), 18)));
			puff.addInitializer(new ImageClass(Blob, [6.5,0xffffff], true, 6));
			puff.addAction(new Age());
			puff.addAction(new Move());
			puff.addAction(new RotateToDirection());
			puff.addAction(new Fade(0.8,0.1));
			EmitterCreator.create(this,_hitContainer,puff,x,y);		
			//poof sound
			shellApi.triggerEvent("poof_sound");
		}
	}
}