package game.scenes.con3
{
	import flash.display.DisplayObject;
	import flash.display.MovieClip;
	import flash.display.Sprite;
	import flash.geom.ColorTransform;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.utils.Dictionary;
	
	import ash.core.Entity;
	
	import engine.components.Audio;
	import engine.components.AudioRange;
	import engine.components.Display;
	import engine.components.Id;
	import engine.components.Spatial;
	import engine.components.Tween;
	import engine.creators.InteractionCreator;
	import engine.group.Group;
	import engine.util.Command;
	
	import game.components.entity.Dialog;
	import game.components.entity.Sleep;
	import game.components.entity.character.Npc;
	import game.components.entity.collider.HazardCollider;
	import game.components.hit.EntityIdList;
	import game.components.hit.Hazard;
	import game.components.hit.HitTest;
	import game.components.scene.SceneInteraction;
	import game.components.timeline.BitmapSequence;
	import game.components.timeline.Timeline;
	import game.creators.entity.BitmapTimelineCreator;
	import game.creators.entity.EmitterCreator;
	import game.creators.ui.ToolTipCreator;
	import game.data.TimedEvent;
	import game.data.display.BitmapWrapper;
	import game.data.scene.hit.HitData;
	import game.data.sound.SoundModifier;
	import game.scene.SceneSound;
	import game.scene.template.AudioGroup;
	import game.scene.template.ItemGroup;
	import game.scene.template.PlatformerGameScene;
	import game.scenes.con2.shared.CCGCardManager;
	import game.scenes.con2.shared.cardGame.CardGame;
	import game.scenes.con3.shared.LaserBurn;
	import game.scenes.con3.shared.Ray;
	import game.scenes.con3.shared.WeaponHudGroup;
	import game.scenes.con3.shared.laserPulse.LaserPulse;
	import game.scenes.con3.shared.laserPulse.LaserPulseSystem;
	import game.scenes.con3.shared.rayBlocker.RayBlocker;
	import game.scenes.con3.shared.rayBlocker.RayBlockerSystem;
	import game.scenes.con3.shared.rayCollision.RayCollision;
	import game.scenes.con3.shared.rayCollision.RayCollisionSystem;
	import game.scenes.con3.shared.rayReflect.RayReflectSystem;
	import game.scenes.con3.shared.rayReflect.RayToReflectCollision;
	import game.scenes.con3.shared.rayRender.RayRender;
	import game.scenes.con3.shared.rayRender.RayRenderSystem;
	import game.systems.hit.HazardHitSystem;
	import game.systems.hit.HitTestSystem;
	import game.systems.motion.ThresholdSystem;
	import game.util.AudioUtils;
	import game.util.CharUtils;
	import game.util.DisplayUtils;
	import game.util.EntityUtils;
	import game.util.PerformanceUtils;
	import game.util.PlatformUtils;
	import game.util.SceneUtil;
	
	public class Con3Scene extends PlatformerGameScene
	{
		private var playerHazard:HazardCollider;
		private var _lasersOn:Boolean = false;
		
		private var laserBases:Array = [];
		private var laserSources:Array = [];
		private var _disposables:Array = [];
		
		public function Con3Scene()
		{
			super();
			rewards = new Dictionary();
		}
		
		override public function destroy():void
		{
			if( _laserSourceSequence != null )
			{
				_laserSourceSequence.destroy();
				_laserSourceSequence = null;
			}
			if( _powerSourceSequence != null )
			{
				_powerSourceSequence.destroy();
				_laserSourceSequence = null;
			}
			if( _cageButtonSequence != null )
			{
				_cageButtonSequence.destroy();
				_cageButtonSequence = null;
			}
			if( _cageBeamSequence != null )
			{
				_cageBeamSequence.destroy();
				_cageBeamSequence = null;
			}
			
			super.destroy();
		}
		
		override protected function addBaseSystems():void
		{
			super.addBaseSystems();
			
			this.addSystem(new ThresholdSystem());
			this.addSystem(new HitTestSystem());
			this.addSystem(new HazardHitSystem());
		}
		
		override public function load():void
		{
			cardManager = shellApi.getManager(CCGCardManager) as CCGCardManager;
			if(!cardManager)
				cardManager = shellApi.addManager(new CCGCardManager(), CCGCardManager) as CCGCardManager;
			trace( "con3Scene :: check for card deck item, if has, make sure deck data is available.");
			
			if( shellApi.checkHasItem( _events.CARD_DECK ) )
			{
				trace( "con3Scene :: create deck data.");
				cardManager.createDeckData( super.load, shellApi.island );
			}
			else
			{
				super.load();
			}
		}
		
		override public function loaded():void
		{
			_events = shellApi.islandEvents as Con3Events;
			
			shellApi.eventTriggered.add( eventTriggered );
			_audioGroup = getGroupById( AudioGroup.GROUP_ID ) as AudioGroup;
			
			var handler:Function = this._hitContainer.getChildByName( "cage" ) ? setupCage : setupLasers;
			handler();
		}
		
		private function setupCage():void
		{
			var actor:Entity;
			var number:uint;
			var rescued:Boolean;
			
			switch( shellApi.sceneName )
			{
				case "ThroneRoom":
					actor = getEntityById( "worldGuy" );
					rescued = shellApi.checkEvent( _events.WORLD_GUY_RESCUED );
					break;
				case "Processing":
					actor = getEntityById( "goldFace" );
					rescued = shellApi.checkEvent( _events.GOLD_FACE_RESCUED );
					break;
				case "Menagerie":
					actor = getEntityById( "elf_archer" );
					rescued = shellApi.checkEvent( _events.ELF_ARCHER_RESCUED );
					break;
				default:
					break;
			}
			
			var clip:MovieClip = _hitContainer[ "cageBtn" ];
			_cageButtonSequence = BitmapTimelineCreator.createSequence( clip, true, PerformanceUtils.defaultBitmapQuality + 0.3);
			var cageInteraction:Entity = makeTimeline( clip, true, _cageBeamSequence );
			
			var audio:Audio;
			var bar:Entity;
			
			if( !rescued )
			{
				InteractionCreator.addToEntity( cageInteraction, [ InteractionCreator.CLICK ]);
				ToolTipCreator.addToEntity( cageInteraction );
				
				var sceneInteraction:SceneInteraction = new SceneInteraction();
				sceneInteraction.minTargetDelta = new Point( 25, 60 );
				sceneInteraction.reached.addOnce( openCage );
				cageInteraction.add( sceneInteraction );
				
				clip = _hitContainer[ "cage" ];
				super.convertContainer( clip, PerformanceUtils.defaultBitmapQuality + 0.3);
				DisplayUtils.moveToBack( clip );
				
				for( number = 0; number < 4; number++ )
				{
					clip = _hitContainer[ BAR + number ];
					DisplayUtils.moveToBack( clip );
					if( !_cageBeamSequence )
					{
						_cageBeamSequence = BitmapTimelineCreator.createSequence( clip, true, PerformanceUtils.defaultBitmapQuality + 0.3);						
					}
					bar = makeTimeline( clip, true, _cageBeamSequence );
					bar.add( new Id( BAR + number )).add( new AudioRange( 400 ));
					
					_audioGroup.addAudioToEntity( bar );
					audio = bar.get( Audio );
					audio.playCurrentAction( IDLE );
				}
				
				DisplayUtils.moveToBack( Display( actor.get( Display )).displayObject );
				Npc(actor.get(Npc)).ignoreDepth = true;
				
			}
			else
			{
				for( number = 0; number < 4; number++ )
				{
					this._hitContainer.removeChild( this._hitContainer[ "cageBeam" + number ]);
				}
				Timeline( cageInteraction.get( Timeline )).gotoAndStop( "off" );
				ToolTipCreator.removeFromEntity( cageInteraction );
				this.removeEntity( actor );
			}
			
			setupLasers();
		}
		
		private function openCage( player:Entity, button:Entity ):void
		{
			SceneUtil.lockInput( this );
			var timeline:Timeline = button.get( Timeline );
			timeline.gotoAndPlay( "turnOff" );
			
			var audio:Audio;
			var bar:Entity = getEntityById( BAR + "0" );
			var nextTimeline:Timeline = bar.get( Timeline );
			timeline.handleLabel( "off", Command.create( nextTimeline.gotoAndPlay, "powerdown" ));
			audio = bar.get( Audio );
			audio.playCurrentAction( TRIGGER );
			
			var spatial:Spatial = player.get( Spatial );
			CharUtils.moveToTarget( player, spatial.x + 100, spatial.y, true, faceActor );
			
			for( var number:int = 0; number < 4; number ++ )
			{
				bar = getEntityById( BAR + number );
				timeline = bar.get( Timeline );
				
				bar = getEntityById( BAR + ( number + 1 ));
				
				if( bar )
				{
					nextTimeline = bar.get( Timeline );
					timeline.handleLabel( "off", Command.create( startPowerDown, bar ));
				}
				else
				{
					timeline.handleLabel( "off", freeActor );
				}
			}
			
			SceneInteraction( button.get( SceneInteraction )).reached.removeAll();
			button.remove( SceneInteraction );
			ToolTipCreator.removeFromEntity( button );
			//SOUND
		}
		
		private function startPowerDown( bar:Entity ):void
		{
			var audio:Audio = bar.get( Audio );
			audio.playCurrentAction( TRIGGER );
			
			var timeline:Timeline = bar.get( Timeline );
			timeline.gotoAndPlay( "powerdown" );
		}
		
		private function faceActor( player:Entity ):void
		{
			CharUtils.setDirection( player, false );
		}
		
		private function makeTimeline( clip:MovieClip, play:Boolean = true, seq:BitmapSequence = null ):Entity
		{
			var target:Entity = EntityUtils.createMovingTimelineEntity( this, clip, null, play );
			target = BitmapTimelineCreator.convertToBitmapTimeline( target, clip, true, seq, PerformanceUtils.defaultBitmapQuality + 0.3);
			
			if( play && PerformanceUtils.qualityLevel < PerformanceUtils.QUALITY_HIGH )
			{
				Timeline( target.get( Timeline )).gotoAndStop( 1 );
			}
			return target;
		}
		
		protected function freeActor():void
		{}
		
		private function setupLasers():void
		{
			var checkEvent:Boolean = false;
			var sceneName:String = this.shellApi.sceneName;
			
			trace(sceneName);
			//Don't save events for Omegon boss fight scene.
			if(sceneName == "Menagerie" || sceneName == "ThroneRoom" || sceneName == "Processing")
			{
				checkEvent = true;
			}
			
			var index:int;
			
			for(index = 0; index < this._hitContainer.numChildren; ++index)
			{
				var child:DisplayObject = this._hitContainer.getChildAt(index);
				var name:String = child.name.toLowerCase();
				
				if(name.indexOf("lasersource") > -1 && name.indexOf("ray") == -1)
				{
					this.createLaserSource(child as MovieClip, name, checkEvent);
				}
				else if(name.indexOf("laserhit") > -1)
				{
					this.createLaserHit(child as MovieClip, name, checkEvent);
				}
				else if(name.indexOf("powersource") > -1)
				{
					this.createPowerSource(child as MovieClip, name, checkEvent);
				}
				else if(name.indexOf("powerhit") > -1)
				{
					this.createPowerHit(child as MovieClip, name, checkEvent);
				}
				else if(name.indexOf("blocker") > -1)
				{
					this.createLaserBlocker(child as MovieClip);
				}
			}
			
			for(index = 0; index < this.laserSources.length; ++index)
			{
				var display:DisplayObject;
				var entity:Entity;
				
				entity = this.laserSources[index];
				if(entity)
				{
					display = Display(entity.get(Display)).displayObject;
					display.parent.setChildIndex(display, 0);
				}
				
				entity = this.laserBases[index];
				if(entity)
				{
					display = Display(entity.get(Display)).displayObject;
					display.parent.setChildIndex(display, 1);
				}
			}
			
			while( _disposables.length > 0 )
			{
				child = _disposables.pop();
				_hitContainer.removeChild( child );
			}
			
			setUpScene();
		}
		
		private function createLaserHit(clip:MovieClip, name:String, checkEvent:Boolean):void
		{
			var entity:Entity;
			var eventIndex:int = int(name.split("_")[1]);
			var hazard:Hazard;
			var range:Number;
			
			if( !getEntityById( name )) 
			{
				if(checkEvent && !this.shellApi.checkEvent(Con3Events(events).POWER_BOX_DESTROYED_ + eventIndex))
				{
					entity = EntityUtils.createSpatialEntity(this, clip);
					
					hazard = new Hazard(1500, 500);
					hazard.velocityByHitAngle = false;
					entity.add(hazard);
				}
				else
				{
					_disposables.push( clip );
					//	_hitContainer.removeChild( clip );
				}
			}
			else
			{
				entity = getEntityById( name );
				
				entity.remove( HitData );
				if(checkEvent && !this.shellApi.checkEvent(Con3Events(events).POWER_BOX_DESTROYED_ + eventIndex))
				{
					_audioGroup.addAudioToEntity( entity );
					range = clip.height < clip.width ? 2 * clip.width : 600;
					entity.add( new AudioRange( range ));
					
					Audio( entity.get( Audio )).playCurrentAction( IDLE );
				}
			}
		}
		
		private function createPowerHit(clip:MovieClip, name:String, checkEvent:Boolean):void
		{
			var eventIndex:int = int(name.split("_")[1]);
			
			if(checkEvent && !this.shellApi.checkEvent(Con3Events(events).POWER_BOX_DESTROYED_ + eventIndex))
			{
				var bounds:Rectangle = clip.getBounds(clip);
				
				var entity:Entity = EntityUtils.createSpatialEntity(this, clip);
				entity.add(new Id(clip.name));
				entity.add(new EntityIdList());
				
				var display:Display = entity.get(Display);
				display.visible = false;
				
				var blocker:RayBlocker = new RayBlocker();
				blocker.shape.graphics.beginFill(0, 1);
				blocker.shape.graphics.drawRect(bounds.x, bounds.y, bounds.width, bounds.height);
				blocker.shape.graphics.endFill();
				entity.add(blocker);
				
				EntityUtils.turnOffSleep(entity);
				
				entity.add(new HitTest(onHit, true));
			}
			else
			{
				_disposables.push( clip );
				//	_hitContainer.removeChild( clip  );
			}
		}
		
		public function createPowerSource(clip:MovieClip, name:String, checkEvent:Boolean):void
		{
			var eventIndex:int = int(name.split("_")[1]);
			
			if( !_powerSourceSequence )
			{
				_powerSourceSequence = BitmapTimelineCreator.createSequence( clip, true, PerformanceUtils.defaultBitmapQuality + 0.3);
			}
			
			var entity:Entity = EntityUtils.createSpatialEntity( this, clip );
			BitmapTimelineCreator.convertToBitmapTimeline( entity, clip, true, _powerSourceSequence );
			entity.add( new Id( clip.name ));
			
			var timeline:Timeline = entity.get(Timeline);
			
			if(checkEvent && this.shellApi.checkEvent(Con3Events(events).POWER_BOX_DESTROYED_ + eventIndex))
			{
				timeline.gotoAndStop("off");
			}
			else
			{
				timeline.gotoAndStop("on");
			}
		}
		
		private function onHit(entity:Entity, hitId:String):void
		{
			var group:Group = entity.group;
			var index:int = Id(entity.get(Id)).id.split("_")[1];
			
			var powerSource:Entity = group.getEntityById("powersource_" + index);
			var display:Display = powerSource.get( Display );
			var spatial:Spatial = powerSource.get( Spatial );
			
			// PAN
			SceneUtil.lockInput(this);
			var clip:DisplayObject = container.getChildByName("laserpan_" + index);
			if(clip)
			{
				SceneUtil.setCameraPoint(this, clip.x, clip.y);
			}
			else
			{
				SceneUtil.setCameraPoint(this, spatial.x, spatial.y);
			}
			
			// CREATE THE COPY THAT TWEENS TO WHITE
			var wrapper:BitmapWrapper =	super.convertToBitmapSprite( display.displayObject, null, false );//, null, PerformanceUtils.defaultBitmapQuality, false, display.container );
			wrapper.sprite.x = spatial.x;
			wrapper.sprite.y = spatial.y;
			
			var colorTransform:ColorTransform = new ColorTransform();
			colorTransform.color = 0xFFFFFF;
			wrapper.sprite.transform.colorTransform = colorTransform; 
			
			var copy:Entity = EntityUtils.createMovingEntity( this, wrapper.sprite, display.container );
			copy.add( new Id( "entityCopy" ));
			display = copy.get( Display );
			display.alpha = 0;
			
			var tween:Tween = new Tween();
			tween.to( display, 1.5, { alpha : 1, onComplete : blowPowerSource, onCompleteParams : [ powerSource, copy, index ]});
			copy.add( tween );
		}
		
		private function blowPowerSource( powerSource:Entity, copy:Entity, index:int ):void
		{
			removeEntity( copy );
			Timeline(powerSource.get( Timeline )).play();
			
			var sceneName:String = this.shellApi.sceneName;
			
			//Don't save events for Omegon boss fight scene.
			if(sceneName == "Menagerie" || sceneName == "ThroneRoom" || sceneName == "Processing")
			{
				this.shellApi.triggerEvent( _events.POWER_BOX_DESTROYED_ + index, true );
			}
			
			for(var laserIndex:int = 1; this.getEntityById("lasersource_" + index + "_" + laserIndex); ++laserIndex)
			{
				var laserBase:Entity = this.getEntityById("lasersource_" + index + "_" + laserIndex);
				
				
				var timeline:Timeline = laserBase.get(Timeline);
				timeline.gotoAndPlay("off");
				timeline.handleLabel("offEnd", Command.create(destroyLaser, index, laserIndex));
				laserBase.remove(LaserPulse);
			}
			
			SceneUtil.addTimedEvent( this, new TimedEvent( .65, 1, panBackToPlayer ));
		}
		
		private function destroyLaser(eventIndex:int, laserIndex:int):void
		{
			var laser:Entity = this.getEntityById("lasersource_" + eventIndex + "_" + laserIndex + "Ray");
			
			if(laser)
			{
				this.removeEntity(laser);
			}
			
			var particles:Entity = this.getEntityById("laserburn_" + eventIndex + "_" + laserIndex);
			if(particles)
			{
				this.removeEntity(particles);
			}
		}
		
		protected function panBackToPlayer():void
		{
			SceneUtil.lockInput(this, false);
			SceneUtil.setCameraTarget(this, this.player);
		}
		
		private function createLaserBlocker(clip:MovieClip):void
		{
			var bounds:Rectangle = clip.getBounds(clip);
			
			var entity:Entity = EntityUtils.createSpatialEntity(this, clip);
			entity.add(new Id(clip.name));
			entity.add(new EntityIdList());
			
			var display:Display = entity.get(Display);
			display.visible = false;
			
			var blocker:RayBlocker = new RayBlocker();
			
			if(!PlatformUtils.isMobileOS)// && false)
			{
				blocker.particles = EmitterCreator.create(this, this._hitContainer, new LaserBurn());
			}
			
			blocker.shape.graphics.beginFill(0, 1);
			blocker.shape.graphics.drawRect(bounds.x, bounds.y, bounds.width, bounds.height);
			blocker.shape.graphics.endFill();
			entity.add(blocker);
		}
		
		public function createLaserSource(clip:MovieClip, name:String, checkEvent:Boolean):void
		{
			var laserName:String = name.slice(0, 15);
			var eventIndex:int = int(name.split("_")[1]);
			var laserIndex:int = int(name.split("_")[2]);
			
			if( !_laserSourceSequence )
			{
				_laserSourceSequence = BitmapTimelineCreator.createSequence( clip, true, PerformanceUtils.defaultBitmapQuality + 0.3);
			}
			
			var laserBase:Entity = EntityUtils.createSpatialEntity(this, clip);
			BitmapTimelineCreator.convertToBitmapTimeline( laserBase, clip, true, _laserSourceSequence, PerformanceUtils.defaultBitmapQuality + 0.3);
			laserBase.add(new Id(laserName));
			
			laserBase.sleeping = false;
			
			this.laserBases.push(laserBase);
			
			var timeline:Timeline = laserBase.get(Timeline);
			
			var particleClip:DisplayObject = this._hitContainer.getChildByName("particle_" + eventIndex + "_" + laserIndex);
			if(particleClip)
			{
				_disposables.push( particleClip );
				//		_hitContainer.removeChild( particleClip );
			}
			
			if(checkEvent && this.shellApi.checkEvent(Con3Events(events).POWER_BOX_DESTROYED_ + eventIndex))
			{
				//Don't make anything.
				
				timeline.gotoAndStop("offEnd");
				handleLaserOff(null, eventIndex, laserIndex);
				this.laserSources.push(null);
			}
			else
			{
				_lasersOn = true;
				
				var laserClip:MovieClip = _hitContainer[ laserName + "Ray" ];
				
				var laser:Entity = EntityUtils.createSpatialEntity( this, laserClip.addChildAt(new Sprite(), 0), _hitContainer );
				var spatial:Spatial = laser.get( Spatial );
				spatial.x = laserClip.x;
				spatial.y = laserClip.y;
				spatial.rotation = laserClip.rotation;
				
				laser.add( new Id( clip.name )).add( new AudioRange( 600 ));
				_audioGroup.addAudioToEntity( laser );
				
				var ray:Ray = new Ray();
				
				laser.add(new Id(laserClip.name ));
				laser.add(ray);
				laser.add(new RayRender(1000, 0xFF7DB5, 5));
				
				if(name.indexOf("pulse") > -1)
				{
					laserBase.add(new LaserPulse());
					
					laser.add(new RayCollision());
					laser.add(new RayToReflectCollision());
					laser.add(new EntityIdList());
				}
				else
				{
					var display:DisplayObject = this._hitContainer.getChildByName("laserhit_" + eventIndex + "_" + laserIndex);
					ray.length = Math.max(display.width, display.height);
					
					if(!PlatformUtils.isMobileOS)
					{
						var particles:Entity = EmitterCreator.create(this, this._hitContainer, new LaserBurn(), 0, 0, null, "laserburn_" + eventIndex + "_" + laserIndex);
						var particleSpatial:Spatial = particles.get(Spatial);
						particleSpatial.x = particleClip.x;
						particleSpatial.y = particleClip.y;
					}
				}
				
				timeline.handleLabel("onEnd", Command.create(handleLaserOn, laser, eventIndex, laserIndex), false);
				timeline.handleLabel("offEnd", Command.create(handleLaserOff, laser, eventIndex, laserIndex), false);
				
				timeline.gotoAndStop("onEnd");
				
				this.laserSources.push(laser);
			}
		}
		
		private function handleLaserOn(laser:Entity, eventIndex:int, laserIndex:int):void
		{
			if(laser)
			{
				Ray(laser.get(Ray)).length = 1000;
			}
			
			var laserHit:Entity = this.getEntityById("laserhit_" + eventIndex + "_" + laserIndex);
			if(laserHit)
			{
				Hazard(laserHit.get(Hazard)).active = true;
				Audio( laserHit.get( Audio )).playCurrentAction( IDLE );
			}
		}
		
		private function handleLaserOff(laser:Entity, eventIndex:int, laserIndex:int):void
		{
			if(laser)
			{
				Ray(laser.get(Ray)).length = 0;
			}
			
			var laserHit:Entity = this.getEntityById("laserhit_" + eventIndex + "_" + laserIndex);
			
			if(laserHit)
			{
				Hazard(laserHit.get(Hazard)).active = false;
				if( laserHit.has( Audio ))
				{
					Audio( laserHit.get( Audio )).stopActionAudio( IDLE );
				}
			}
		}
		
		public function setUpScene():void
		{
			if( _lasersOn )
			{
				this.addSystem(new RayRenderSystem());
				this.addSystem(new RayCollisionSystem());
				this.addSystem(new RayReflectSystem());
				this.addSystem(new LaserPulseSystem());
				this.addSystem(new RayBlockerSystem());
			}
			
			var weaponHudGroup:WeaponHudGroup = addChildGroup( new WeaponHudGroup( shellApi )) as WeaponHudGroup;
			weaponHudGroup.ready.addOnce( weaponHudDone );
		}
		
		private function weaponHudDone( weaponHudGroup:WeaponHudGroup ):void
		{
			super.loaded();
		}
		
		protected function eventTriggered(event:String, makeCurrent:Boolean = true, init:Boolean = false, removeEvent:String = null):void
		{			
			if(event == "shield_activated")
			{
				this.playerHazard = this.player.remove(HazardCollider) as HazardCollider;
			}
			else if(event == "shield_deactivated")
			{
				if(this.playerHazard)
				{
					this.player.add(this.playerHazard);
				}
			}
			
			if(event.indexOf(_events.PLAY) == 0)
			{
				openCardGamePopup(event.substring(_events.PLAY.length));
			}
			
			if( event ==_events.USE_SODA )
			{
				if( shellApi.sceneName != "ThroneRoom" )
				{
					var dialog:Dialog = player.get( Dialog );
					dialog.sayById( "cant_use_soda" );
				}
			}
		}
		
		////////////////////////////////////////// CARD GAME //////////////////////////////////////////
		
		private function autoDefeat(npcId:String):void
		{
			cardGameComplete(npcId, rewards[npcId], true);
		}
		
		private function openCardGamePopup(cardPlayer:String):void
		{
			//var audio:Audio = AudioUtils.getAudio(this, SceneSound.SCENE_SOUND);
			//audio.fadeAll(0, NaN, 1, SoundModifier.MUSIC);
			var cardGame:CardGame = new CardGame(overlayContainer, cardPlayer, shellApi.island);
			cardGame.gameComplete.add(cardGameComplete);
			addChildGroup(cardGame);
		}
		
		/**
		 * Method called when card game is closed, determines if a reward is given.
		 * @param opponentId
		 * @param reward
		 * @param won
		 * @param onCardReceived
		 * @param lockInput
		 */
		protected function cardGameComplete(opponentId:String, reward:String, won:Boolean, onCardReceived:Function = null, lockInput:Boolean = false ):void
		{
			//			var audio:Audio = AudioUtils.getAudio(this, SceneSound.SCENE_SOUND);
			//			if(!audio.isPlaying(SoundManager.MUSIC_PATH + MAIN_THEME))
			//			{
			//				audio.play(SoundManager.MUSIC_PATH + MAIN_THEME, true);
			//				audio.fadeAll(1, NaN, 0, SoundModifier.MUSIC);
			//			}
			trace(opponentId + " " + reward + " " + won);
			
			var opponent:Entity = getEntityById(opponentId);
			// prolly have them say a won dialog or loose dialog
			if( won && reward != null)
			{
				if( !shellApi.checkEvent(_events.DEFEATED + opponentId) )
				{
					if( lockInput )	{ SceneUtil.lockInput(this); };
					addCardToDeck( reward, onCardReceived );
					shellApi.triggerEvent( _events.DEFEATED + opponentId, true );
				}
			}
		}
		
		// testing only not used during normal game play
		private function clearDeck():void
		{
			cardManager.updateDeck( "", shellApi.island);
			shellApi.removeEvent(_events.STARTER_DECK);
			shellApi.removeItem(_events.CARD_DECK);
		}
		
		/**
		 * Shows the card game cards and adds them to the deck
		 * @param cardId - the first card to give and show
		 * @param onCompleteHandler - function to call when
		 */		
		protected function addCardToDeck( cardId:String, onCompleteHandler:Function = null ):void
		{
			// if you don't have a deck upon receiving a card, give deck
			if( !shellApi.checkHasItem(_events.CARD_DECK) )
			{
				shellApi.getItem(_events.CARD_DECK);
			}
			
			// add new card(s) to currentDeck & save to userfield
			
			var newCardString:String = ( cardId == _events.CARD_DECK ) ? STARTER_DECK_STRING : cardId;	
			
			cardManager.addCardToDeck(newCardString, shellApi.island);
			// show card
			var itemGroup:ItemGroup = getGroupById(ItemGroup.GROUP_ID) as ItemGroup;
			if(itemGroup == null)
			{
				itemGroup = new ItemGroup();
				itemGroup.setupScene(this);
			}
			itemGroup.showItem(cardId, shellApi.island, null, onCompleteHandler);
		}
		
		/**
		 * Determines if card is within deck.
		 * Checks against userfield.
		 * @param cardId
		 * @return  
		 */
		protected function checkHasCard(cardId:String):Boolean
		{
			return cardManager.hasCard(cardId, shellApi.island);
		}
		
		private var _cageButtonSequence:BitmapSequence;
		private var _cageBeamSequence:BitmapSequence;
		private var _laserSourceSequence:BitmapSequence;
		private var _powerSourceSequence:BitmapSequence;
		
		private const BAR:String 			= "cageBeam";
		private const IDLE:String			= "idle";
		private const TRIGGER:String		= "trigger";
		
		private const STARTER_DECK_STRING:String = "world_guy,mutton_chops,mutton_chops,meow_bot,meow_bot,meow_bot,hench_bot,hench_bot,hench_bot,hench_bot";
		public var cardManager:CCGCardManager;
		
		protected var rewards:Dictionary;
		protected var _audioGroup:AudioGroup;
		protected var _events:Con3Events;
	}
}