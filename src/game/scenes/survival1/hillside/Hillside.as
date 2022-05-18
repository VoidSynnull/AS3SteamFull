package game.scenes.survival1.hillside
{
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.geom.Point;
	
	import ash.core.Entity;
	
	import engine.components.Display;
	import engine.components.Id;
	import engine.components.Interaction;
	import engine.components.Spatial;
	import engine.components.Tween;
	import engine.creators.InteractionCreator;
	import engine.managers.SoundManager;
	
	import game.components.entity.Children;
	import game.components.entity.Dialog;
	import game.components.entity.Sleep;
	import game.components.entity.character.animation.RigAnimation;
	import game.components.hit.Zone;
	import game.components.motion.Threshold;
	import game.components.scene.SceneInteraction;
	import game.components.specialAbility.SpecialAbilityControl;
	import game.components.timeline.Timeline;
	import game.creators.entity.BitmapTimelineCreator;
	import game.creators.entity.EmitterCreator;
	import game.creators.scene.HitCreator;
	import game.creators.scene.SceneItemCreator;
	import game.creators.ui.ToolTipCreator;
	import game.data.TimedEvent;
	import game.data.animation.entity.character.Proud;
	import game.data.animation.entity.character.Pull;
	import game.data.animation.entity.character.Push;
	import game.data.scene.characterDialog.DialogData;
	import game.data.scene.hit.HitType;
	import game.data.specialAbility.SpecialAbilityData;
	import game.data.specialAbility.islands.survival.SetHandParts;
	import game.scene.template.AudioGroup;
	import game.scene.template.CameraGroup;
	import game.scene.template.ItemGroup;
	import game.scenes.survival1.Survival1Events;
	import game.scenes.survival1.morningAfter.MorningAfter;
	import game.scenes.survival1.shared.EnviornmentInteractions;
	import game.scenes.survival1.shared.SurvivalScene;
	import game.scenes.survival1.shared.components.WindBlock;
	import game.scenes.time.shared.emitters.Fire;
	import game.scenes.time.shared.emitters.FireSmoke;
	import game.systems.SystemPriorities;
	import game.systems.hit.ItemHitSystem;
	import game.systems.motion.ThresholdSystem;
	import game.ui.showItem.ShowItem;
	import game.util.AudioUtils;
	import game.util.CharUtils;
	import game.util.DisplayUtils;
	import game.util.EntityUtils;
	import game.util.PerformanceUtils;
	import game.util.PlatformUtils;
	import game.util.SceneUtil;
	import game.util.SkinUtils;
	import game.util.TimelineUtils;
	
	import org.flintparticles.twoD.zones.LineZone;
	import org.flintparticles.twoD.zones.RectangleZone;
	
	public class Hillside extends SurvivalScene
	{
		private var _events:Survival1Events;
		private var _outside:Boolean = true;
		private var _camTarget:Entity;
		private var _loop:int = 0;
		private const FLINT:String = 		"flint";
		
		private var _defaultCameraZoom:Number;
		
		
		// x, y, rotation and time values for boulder roll
		private var xPos:Array = [ 3892, 3786, 3800, 3100, 2300, 2275, 2475, 2474, 2366, 2072, 2034, 2005 ];
		private var yPos:Array = [ 505, 500, 1000, 1200, 1200, 1200, 1100, 1112, 1128, 1035, 1220, 1211, 1160 ];
		private var tPos:Array = [ 1, 1, .5, 1, 2, 1, .3, .1, .1, 1, 1, .1 ];					
		
		public function Hillside()
		{
			super();
		}
		
		// pre load setup
		override public function init( container:DisplayObjectContainer = null ):void
		{			
			super.groupPrefix = "scenes/survival1/hillside/";
			
			super.init( container );
		}
		
		// all assets ready
		override public function loaded():void
		{
			_events = super.events as Survival1Events;
			
			var itemGroup:ItemGroup = super.getGroupById( ItemGroup.GROUP_ID ) as ItemGroup;

			if(!super.getSystem( ItemHitSystem ))	// items require ItemHitSystem, add system if not yet added
			{
				var itemHitSystem:ItemHitSystem = new ItemHitSystem();
				super.addSystem( itemHitSystem, SystemPriorities.resolveCollisions );
				itemHitSystem.gotItem.add(itemGroup.showAndGetItem  );
			}
			
			var cameraGroup:CameraGroup = super.getGroupById( CameraGroup.GROUP_ID, this ) as CameraGroup;

			// store some defaults for resetting
			_defaultCameraZoom = cameraGroup.zoomTarget;
			
			setUpWindBlockZones();
			
			var boulder1:Entity;
			var boulder2:Entity;
			
			var clip:MovieClip;
			var display:Display;
			var doorEnt:Entity;
			var entity:Entity;
			
			var sceneCreator:SceneItemCreator = new SceneItemCreator();
			var interaction:Interaction;
			var number:int;
			var sceneInteraction:SceneInteraction
			var sleep:Sleep;
			var spatial:Spatial;
			var threshold:Threshold;
			var timeline:Timeline;
			var windBlock:WindBlock;
			var zone:Zone;
			var zoneEnt:Entity;
			
			clip = _hitContainer[ "campFire" ];
			entity = EntityUtils.createSpatialEntity( this, clip );
			entity.add( new Id( "campFire" ));
			display = entity.get( Display );
			
			display.visible = false;

			this.shellApi.eventTriggered.add( this.onEventTriggered );
			createBoulders();
			super.loaded();
			
			threshold = new Threshold( "y", ">" );
			threshold.threshold = 810;
			
			if( PerformanceUtils.qualityLevel > PerformanceUtils.QUALITY_MEDIUM )
			{
				threshold.entered.add( toggleTree );
			}
			else
			{ 
				threshold.entered.add( toggleTreeOff );
			}
			
			player.add( threshold );
			
			DisplayUtils.swap( EntityUtils.getDisplayObject( player ), _hitContainer[ "empty" ]);
			
			clip = _hitContainer[ "caveCover" ];
			entity = EntityUtils.createSpatialEntity( this, clip );
			entity.ignoreGroupPause = true;
			entity.add( new Id( "caveCover" ));
			//TimelineUtils.convertClip( clip, this, entity, null, false );
			BitmapTimelineCreator.convertToBitmapTimeline(entity, clip);
			timeline = entity.get( Timeline );
			
			entity = getEntityById("windBlockZone0");
			windBlock = entity.get(WindBlock);
			windBlock.right = true;
			
			entity = getEntityById("windBlockZone1");
			windBlock = entity.get(WindBlock);
			windBlock.right = true;
			
			entity = getEntityById("windBlockZone4");
			windBlock = entity.get(WindBlock);
			windBlock.left = true;
			
			boulder1 = getEntityById( "boulder1" );
			boulder2 = getEntityById( "boulder2" );
			
			_camTarget = new Entity( "boulderCameraTarget" );
			
			_camTarget.add( new Tween());
			super.addEntity( _camTarget );
			
			if( !shellApi.checkEvent( _events.CAVE_OPEN ))
			{
				doorEnt = getEntityById( "doorCave" );
				
				sleep = doorEnt.get( Sleep );
				sleep.ignoreOffscreenSleep = true;
				doorEnt.ignoreGroupPause = true;
				sleep.sleeping = true;

				clip = _hitContainer[ "flintSparkle" ];
				clip.visible = false;
				clip.stop();
				
				ToolTipCreator.addToEntity( boulder1 ); 
				positionBoulder( 1 );
				
				entity = getEntityById( "windBlockZone0" );
				windBlock = entity.get( WindBlock );
				windBlock.left = true;
				
				_hitContainer[ "upperSnow" ].visible = false;
				spatial = boulder1.get( Spatial );
				_camTarget.add( new Spatial( spatial.x, spatial.y ));
			}
			else
			{
				super.removeEntity( boulder1 );
				entity = getEntityById( "grass0_5leftright" );
				windBlock = entity.get( WindBlock );
				windBlock.left = false;
				
				timeline.gotoAndStop( "caveOpen" );
				timeline = boulder2.get( Timeline );
				sleep = boulder2.get( Sleep );
				sleep.ignoreOffscreenSleep = true;
				entity.ignoreGroupPause = true;
				sleep.sleeping = false;
				
				if( !shellApi.checkHasItem( "flint" ))
				{
					clip = _hitContainer[ "flint" ];
					clip.x += 250;
					clip.y += 25;
					entity = EntityUtils.createSpatialEntity( this, clip );
					entity.add( new Id( "flint" ));
					
					sceneCreator.make( entity, new Point( 25, 100 ));		
					
					clip = _hitContainer["flintSparkle"];
					clip.visible = false;
					
					entity = EntityUtils.createSpatialEntity( this, clip );
					entity.add( new Id( "flintSparkle" ));
					entity.add(new Sleep());
					TimelineUtils.convertClip(clip, this, entity);
				}
					
				else
				{
					clip = _hitContainer[ "flint" ];
					clip.visible = false;
					
					_hitContainer.removeChild(_hitContainer["flintSparkle"]);
				}
			
				if( !shellApi.checkEvent( _events.BOULDER_IN_POSITION ))
				{
					// boulder part2
					InteractionCreator.addToEntity( boulder2, [ InteractionCreator.CLICK ]);
					interaction = boulder2.get( Interaction );
					
					timeline.labelReached.add( boulderHandler );
					
					interaction.click.add( boulderListener );
					ToolTipCreator.addToEntity( boulder2 );
					
					positionBoulder( 2 );
					
					entity = getEntityById("windBlockZone2");
					windBlock = entity.get(WindBlock);
					windBlock.left = true;
					
					entity = getEntityById("windBlockZone3");
					windBlock = entity.get(WindBlock);
					windBlock.right = true;
					
					entity = getEntityById( "grass1_6" );
					windBlock = entity.get( WindBlock );
					windBlock.left = true;
					
					entity = getEntityById("windBlockZone4");
					windBlock = entity.get(WindBlock);
					windBlock.left = true;
					
					spatial = boulder2.get( Spatial );
					_camTarget.add( new Spatial( spatial.x, spatial.y ));
				}
				
				else
				{
					timeline.gotoAndStop( "endBoulder" );
					
					entity = getEntityById( "grass0_0left" );
					windBlock = entity.get( WindBlock );
					windBlock.right = true;
					
					entity = getEntityById( "grass0_2left" );
					windBlock = entity.get( WindBlock );
					windBlock.right = true;
					
					entity = getEntityById("windBlockZone4");
					windBlock = entity.get(WindBlock);
					windBlock.left = true;
					windBlock.right = true;
					
					entity = getEntityById("windBlockZone3");
					windBlock = entity.get(WindBlock);
					windBlock.left = true;
					
					positionBoulder( 3 );
					super.removeEntity( _camTarget );
				}
			}
			
			for( number = 0; number < 3; number ++ )
			{
				clip = _hitContainer[ "crack" + number ];
				entity = EntityUtils.createSpatialEntity( this, clip );
				entity.add( new Id( "crack" + number ));
				TimelineUtils.convertClip( clip, this, entity, null, false );
			}
			
			zoneEnt = getEntityById( "zoneCrack" );
			zone = zoneEnt.get( Zone );
			zone.entered.addOnce( crackIce );
			
			addSystem( new ThresholdSystem(), SystemPriorities.update );
			
			zoneEnt = getEntityById( "windBlockZone4" );
			zone = zoneEnt.get( Zone );
			zone.entered.add( inTheZone );
			zone.exitted.add( outOfZone );
			
			for( number = 0; number < 2; number ++ )
			{
				clip = _hitContainer[ "mouse" + number ];
				TimelineUtils.convertClip( clip, this );
			}
			
			if(this.shellApi.checkItemEvent(_events.SURVIVAL_MEDAL))
			{
				this.setupCampFire();
			}
		}
		
		private function createBoulders():void
		{
			var boulder:MovieClip;
			var boulder1:Entity;
			var boulder2:Entity;
			var clip:MovieClip;
			var interaction:Interaction;
			var sleep:Sleep;
			var timeline:Timeline;
			
			// boulder part1
			clip = _hitContainer[ "boulder1" ];
			if( PerformanceUtils.qualityLevel > PerformanceUtils.QUALITY_MEDIUM && !PlatformUtils.isDesktop )
			{
				boulder = clip["path"]["content"];
				DisplayUtils.convertToBitmapSprite( boulder, null, 2 );
//				DisplayUtils.convertToBitmap( boulder, true, 0, boulder.parent );
			}
			boulder1 = EntityUtils.createSpatialEntity( this, clip );
			boulder1.add( new Id( "boulder1" ));
			InteractionCreator.addToEntity( boulder1, [ InteractionCreator.CLICK ]);
			interaction = boulder1.get( Interaction );
			TimelineUtils.convertClip( clip, this, boulder1, null, false );
			timeline = boulder1.get( Timeline );
			timeline.labelReached.add( boulderHandler );
			
			interaction.click.add( boulderListener );
			sleep = boulder1.get( Sleep );
			sleep.ignoreOffscreenSleep = true;
			boulder1.ignoreGroupPause = true;
			sleep.sleeping = false;
			
			// boulder part2
			clip = _hitContainer[ "boulder2" ];
			if( PerformanceUtils.qualityLevel > PerformanceUtils.QUALITY_MEDIUM && !PlatformUtils.isDesktop )
			{
				boulder = clip["path"]["content"];
				DisplayUtils.convertToBitmapSprite( boulder, null, 2 )
//				DisplayUtils.convertToBitmap( boulder, true, 0, boulder.parent );
			}
			boulder2 = EntityUtils.createSpatialEntity( this, clip );
			boulder2.add( new Id( "boulder2" ));
			TimelineUtils.convertClip( clip, this, boulder2, null, false );
			timeline = boulder2.get( Timeline );
			timeline.labelReached.add( boulderHandler );
			sleep = boulder2.get( Sleep );
			sleep.ignoreOffscreenSleep = true;
			boulder2.ignoreGroupPause = true;
			sleep.sleeping = true;
		}
		
		private function onEventTriggered(event:String, makeCurrent:Boolean = true, init:Boolean = false, removeEvent:String = null):void
		{
			if( event == this._events.FIRE_COMPLETED && !this.shellApi.checkItemEvent(_events.SURVIVAL_MEDAL) )
			{
				if( player.get( Spatial ).x > 1476 )
				{
					CharUtils.setDirection( player, false );
				}
				else
				{
					CharUtils.setDirection( player, true );
				}
				
				SceneUtil.lockInput( this );
				var dialog:Dialog = this.player.get( Dialog );
				dialog.complete.addOnce( celebrate );
				
				this.setupCampFire();
			}
		}
		
		private function setupCampFire():void
		{
			var entity:Entity = getEntityById( "campFire" );
			var display:Display = entity.get( Display );
			display.visible = true;
			
			var fireContainer:DisplayObjectContainer = getEntityById("campFire").get( Display ).displayObject["fire"];
			
			var fire:Fire = new Fire();
			fire.init( 2, new RectangleZone( -13, -4, 13, -4 ));
			
			EmitterCreator.create(this, fireContainer, fire );
			
			var smoke:FireSmoke = new FireSmoke();
			smoke.init( 9, new LineZone( new Point( -2, -20 ), new Point( 2, -40 )), new RectangleZone( -10, -50, 10, -5 ));
			EmitterCreator.create(this, fireContainer, smoke );
		}
		
		/***********************************************
		 * 
		 * 				SCENE INTERACTIONS
		 * 
		 ***********************************************/	
		private function positionBoulder( spot:int ):void
		{
			var audioGroup:AudioGroup = getGroupById( AudioGroup.GROUP_ID ) as AudioGroup;
			var entity:Entity;
			var creator:HitCreator = new HitCreator();
			
			entity = EntityUtils.createSpatialEntity( this, _hitContainer[ "boulderRight" + spot ]);
			entity.add( new Id( "boulderRight" + spot ));
			creator.makeHit( entity, HitType.WALL );
			
			entity = EntityUtils.createSpatialEntity( this, _hitContainer[ "boulderLeft" + spot ]);
			creator.makeHit( entity, HitType.WALL );
			entity.add( new Id( "boulderLeft" + spot ));
			
			entity = EntityUtils.createSpatialEntity( this, _hitContainer[ "boulderTopLeft" + spot ]);
			creator.makeHit( entity, HitType.PLATFORM );
			entity.add( new Id( "boulderTopLeft" + spot ));
			creator.addHitSoundsToEntity( entity, audioGroup.audioData, shellApi );
			
			entity = EntityUtils.createSpatialEntity( this, _hitContainer[ "boulderTopRight" + spot ]);
			creator.makeHit( entity, HitType.PLATFORM );
			entity.add( new Id( "boulderTopRight" + spot ));
			creator.addHitSoundsToEntity( entity, audioGroup.audioData, shellApi );
		}
		
		private function removeBoulder( spot:int ):void 
		{
			removeEntity( getEntityById( "boulderTopLeft" + spot ));
			removeEntity( getEntityById( "boulderTopRight" + spot ));
			removeEntity( getEntityById( "boulderLeft" + spot ));
			removeEntity( getEntityById( "boulderRight" + spot ));
		}
		
		private function crackIce( zoneId:String, playerId:String ):void
		{
			var entity:Entity = getEntityById( "crack0" );
			var timeline:Timeline = entity.get( Timeline );
			timeline.play();
		}
		
		private function inTheZone( zoneId:String, playerId:String ):void
		{
			shellApi.triggerEvent( _events.IN_FIRE_ZONE, true );
		}
		
		private function outOfZone( zoneId:String, playerId:String ):void
		{
			shellApi.removeEvent( _events.IN_FIRE_ZONE );
		}
		
		private function toggleTree():void
		{
			var display:Display = super.getEntityById( "foreground" ).get( Display );
			var threshold:Threshold = player.get( Threshold );
			var spatial:Spatial = player.get( Spatial );
						
			if( _outside )
			{
				if( spatial.x < 1370 ) 
				{
					_outside = false;
					threshold.operator = "<";
					display.alpha = .25;
				}
			}
			
			else
			{
				if( spatial.x > 890 && spatial.x < 1333 )
				{
					_outside = true;
					threshold.operator = ">";
					display.alpha = 1;
				}
			}
		}
		
		private function toggleTreeOff():void
		{
			var display:Display = super.getEntityById( "foreground" ).get( Display );
			var threshold:Threshold = player.get( Threshold );
			var spatial:Spatial = player.get( Spatial );
			
			if( _outside )
			{
				if( spatial.x < 1370 ) 
				{
					_outside = false;
					threshold.operator = "<";
					display.visible = false;
				}
			}
				
			else
			{
				if( spatial.x > 890 && spatial.x < 1333 )
				{
					_outside = true;
					threshold.operator = ">";
					display.visible = true;
				}
			}
		}
		
		/***********************************************
		 * 
		 * 				ROLLING BOULDER
		 * 
		 ***********************************************/
		private function boulderListener( entity:Entity ):void
		{
			var dialog:Dialog = player.get( Dialog );
			var spatial:Spatial = player.get( Spatial );
			
			if( spatial.x < 3820 && !shellApi.checkEvent( _events.CAVE_OPEN ))
			{
				dialog.sayById( "not_from_here" );
			}
			else
			{
				if( shellApi.checkHasItem( _events.AX_HANDLE ))
				{
					SceneUtil.lockInput( this );
					if( shellApi.checkEvent( _events.CAVE_OPEN ))
					{
						positionBoulder( 3 );
						removeBoulder(2);
						CharUtils.moveToTarget( player, 2660, 1120, false, resolvePushInput );
					} 
					else
					{
						positionBoulder( 2 );
						removeBoulder(1);
						CharUtils.moveToTarget( player, 4040, 550, false, resolvePushInput);
					}
				}
				
				else
				{
					CharUtils.moveToTarget( player, 4040, 550, false, cantMove);
				}
			}
		}
		
		private function cantMove( entity:Entity ):void
		{
			SceneUtil.lockInput( this );
			CharUtils.moveToTarget( player, 4040, 550, false, resolveCantMove );
		}
		
		private function resolveCantMove( entity:Entity ):void
		{
			CharUtils.setDirection( player, false );
			CharUtils.setAnim( player, Push );
			
			var timeline:Timeline = player.get( Timeline );
			timeline.handleLabel( "ending", sayCantMove, false );
		}
			
		private function sayCantMove():void
		{
			var timeline:Timeline = player.get( Timeline );
			_loop++;
			if( _loop == 3 )
			{
				_loop = 0;
				
				CharUtils.getRigAnim( player ).manualEnd = true;

				var dialog:Dialog = player.get( Dialog );
				dialog.sayById( "too_heavy" );
					
				timeline.removeLabelHandler( sayCantMove );
				dialog.complete.addOnce( removeLock );
			}
		}
		
		private function boulderHandler( label:String ):void
		{
			var clip:MovieClip;
			var entity:Entity;
			
			var sceneCreator:SceneItemCreator = new SceneItemCreator();
			var interaction:Interaction;
			var environment:EnviornmentInteractions = getGroupById( "environmentalInteractionsGroup" ) as EnviornmentInteractions;
			var number:int;
			var sceneInteraction:SceneInteraction;
			var sleep:Sleep;
			var spatial:Spatial;
			var timeline:Timeline;
			var tween:Tween;
			var windBlock:WindBlock;
			
			switch( label )
			{				
				case "endPath1":
					zoomListener();
					
					entity = getEntityById( "boulder1" );
					timeline = entity.get( Timeline );
					timeline.stop();
					sleep = entity.get( Sleep );
					sleep.sleeping = true;
					
					entity = getEntityById( "boulder2" );
					sleep = entity.get( Sleep );
					sleep.sleeping = false;
					InteractionCreator.addToEntity( entity, [ InteractionCreator.CLICK ]);
					interaction = entity.get( Interaction );
					interaction.click.add( boulderListener );
					
					ToolTipCreator.addToEntity( entity );
					
					_hitContainer[ "upperSnow" ].visible = false;
					break;
				
				case "openCave":
					// add wind motion back to grass by boulder start and if blowing play timeline
					shellApi.completeEvent( _events.CAVE_OPEN );
					entity = getEntityById( "grass0_5leftright" );
					timeline = entity.get( Timeline );
					windBlock = entity.get( WindBlock );
					windBlock.left = false;
					if( environment.isStrongWind() && environment.isBlowingRight() )
					{
						timeline.gotoAndPlay( "startright" );
					}
					
					entity = getEntityById( "caveCover" );
					timeline = entity.get( Timeline );
					timeline.play();
					
					entity = getEntityById( "doorCave" );
					sleep = entity.get( Sleep );
					sleep.ignoreOffscreenSleep = false;
					entity.ignoreGroupPause = false;
					sleep.sleeping = false;
					
					for( number = 1; number < 3; number ++ )
					{
						entity = getEntityById( "crack" + number );
						timeline = entity.get( Timeline );
						timeline.play();
						
						AudioUtils.play( this, SoundManager.EFFECTS_PATH + "icicle_01.mp3" );
					}
					
					entity = getEntityById( "grass0_3" );
					timeline = entity.get( Timeline );
					if( timeline.playing )
					{
						timeline.gotoAndStop( "endright" );
					}
					windBlock = entity.get( WindBlock );
					windBlock.left = true;
										
					entity = getEntityById( "grass1_6" );
					timeline = entity.get( Timeline );
					if( timeline.playing )
					{
						timeline.gotoAndStop( "endright" );
					}
					windBlock = entity.get( WindBlock );
					windBlock.left = true;
					
					entity = getEntityById("windBlockZone0");
					windBlock = entity.get(WindBlock);
					windBlock.left = false;
					
					entity = getEntityById("windBlockZone2");
					windBlock = entity.get(WindBlock);
					windBlock.left = true;
					
					entity = getEntityById("windBlockZone3");
					windBlock = entity.get(WindBlock);
					windBlock.right = true;
					
					clip = _hitContainer[ "flint" ];
					tween = new Tween();
					entity = EntityUtils.createSpatialEntity( this, clip );
					entity.add( new Id( "flint" )).add( tween );
					spatial = entity.get( Spatial );
					tween.to( spatial, 1, { x : spatial.x + 250, y : spatial.y + 25, onComplete:addFlintSparkle });
					
					sceneCreator.make( entity, new Point( 25, 100 ));
					
					AudioUtils.play( this, SoundManager.EFFECTS_PATH + "large_stone_01.mp3" );
					AudioUtils.play( this, SoundManager.EFFECTS_PATH + "ice_large_impact_01.mp3" );
					break;
				
				case "endBoulder":
					
					zoomListener();
					
					shellApi.completeEvent( _events.BOULDER_IN_POSITION );
					entity = getEntityById( "grass0_0left" );
					timeline = entity.get( Timeline );
					if( timeline.playing )
					{
						timeline.gotoAndStop( "endleft" );
					}
					windBlock = entity.get( WindBlock );
					windBlock.right = true;
					
					entity = getEntityById( "grass0_2left" );
					timeline = entity.get( Timeline );
					if( timeline.playing )
					{
						timeline.gotoAndStop( "endleft" );
					}
					windBlock = entity.get( WindBlock );
					windBlock.right = true;
					
					entity = getEntityById( "boulder2" );
					entity.remove( Interaction );
					
					if( entity.get( Children ))
					{
						var toolTip:Entity = entity.get( Children ).children.pop();
						entity.remove( Children );
						removeEntity( toolTip );
					}
					
					entity = getEntityById( "grass0_3" );
					timeline = entity.get( Timeline );
					windBlock = entity.get( WindBlock );
					windBlock.left = false;
					if( environment.isStrongWind() && environment.isBlowingRight() )
					{
						timeline.gotoAndPlay( "startright" );
					}
					
					entity = getEntityById( "grass1_6" );
					timeline = entity.get( Timeline );
					windBlock = entity.get( WindBlock );
					windBlock.left = false;
					if( environment.isStrongWind() && environment.isBlowingRight() )
					{
						timeline.gotoAndPlay( "startright" );
					}
					
					entity = getEntityById("windBlockZone2");
					windBlock = entity.get(WindBlock);
					windBlock.left = false;
					
					entity = getEntityById("windBlockZone3");
					windBlock = entity.get(WindBlock);
					windBlock.left = true;
					windBlock.right = false
					
					entity = getEntityById("windBlockZone4");
					windBlock = entity.get(WindBlock);
					windBlock.right = true;
					break;
			}
		}
		
		private function setUpWindBlockZones():void
		{
			for(var i:int = 0; i < 5; i++)
			{
				var entity:Entity = getEntityById("windBlockZone"+i);
				entity.add(new WindBlock());
				var zone:Zone = entity.get(Zone);
				zone.inside.add(blockWind);
				zone.exitted.add(removeWindBlock);
			}
		}
		
		private function removeWindBlock( zoneId:String, playerId:String ):void
		{
			var playerBlock:WindBlock = player.get(WindBlock);
			playerBlock.left = false;
			playerBlock.right = false;
		}
		
		private function blockWind( zoneId:String, playerId:String ):void
		{
			var block:WindBlock = getEntityById(zoneId).get(WindBlock);
			var playerBlock:WindBlock = player.get(WindBlock);
			playerBlock.left = block.left;
			playerBlock.right = block.right;
		}
		
		public function addFlintSparkle():void
		{
			var clip:MovieClip = this._hitContainer["flintSparkle"];
			
			var entity:Entity = EntityUtils.createSpatialEntity( this, clip );
			entity.add( new Id( "flintSparkle" ));
			entity.add(new Sleep());
			TimelineUtils.convertClip(clip, this, entity);
		}		
		
		private function resolvePushInput( entity:Entity ):void
		{
			CharUtils.setDirection( player, false );
			
			SceneUtil.addTimedEvent( this, new TimedEvent( .5, 1, startPull ));
			SkinUtils.setSkinPart( player, SkinUtils.ITEM, "ax_handle" );
		}
		
		private function removeLock( dialogData:DialogData ):void
		{
			SceneUtil.lockInput( this, false );
		}
		
		private function startPull():void
		{
			CharUtils.setAnim( player, Pull );
			
			var timeline:Timeline = player.get( Timeline );
			timeline.handleLabel( "loop", pullHandler, false );
			
			AudioUtils.play( this, SoundManager.EFFECTS_PATH + "wood_creak_01.mp3" );
		}
		
		private function pullHandler():void
		{
			_loop++;
			
			if( _loop > 2 )
			{
				_loop = 0;
				CharUtils.getRigAnim( player ).manualEnd = true;
				
				startRoll();

				var timeline:Timeline = player.get( Timeline );
				timeline.removeLabelHandler( pullHandler );
				var cameraGroup:CameraGroup = getGroupById( CameraGroup.GROUP_ID ) as CameraGroup;
				if( cameraGroup.zoomTarget != .8 )
				{
					cameraGroup.zoomTarget = .8;
					cameraGroup.target = _camTarget.get( Spatial );
				}
			}
		}
		
		private function zoomListener():void
		{
			var cameraGroup:CameraGroup = super.getGroupById(CameraGroup.GROUP_ID, this) as CameraGroup;
			
			if(cameraGroup.zoomTarget != _defaultCameraZoom)
			{
				cameraGroup.zoomTarget = _defaultCameraZoom;
			}
			
			cameraGroup.target = player.get( Spatial );
			SceneUtil.lockInput( this, false );
		}
		
		private function startRoll():void
		{
			var entity:Entity = getEntityById( "boulder1" );
			var point:int = 0;
			var final:int = 6;
			
			if( shellApi.checkEvent( _events.CAVE_OPEN ))
			{
				entity = getEntityById( "boulder2" );
				point = 7;
				final = 12;
				
				AudioUtils.play( this, SoundManager.EFFECTS_PATH + "snow_large_impact_01.mp3" );
			}
			
			updateCamera( point, final );
			var timeline:Timeline = entity.get( Timeline );
			timeline.play();
			
			AudioUtils.play( this, SoundManager.EFFECTS_PATH + "heavy_gritty_roll_04_loop.mp3" );
		}
		
		private function updateCamera( point:int, final:int ):void
		{
			
			var tween:Tween = _camTarget.get( Tween );
			var spatial:Spatial = _camTarget.get( Spatial );
			var func:Function = updateCamera;
			var params:Array = [ ++point, final ];
			
			if( point < xPos.length )
			{
				if( point == final ) 
				{
					func = null;
					params = null;
					AudioUtils.stop( this, SoundManager.EFFECTS_PATH + "heavy_gritty_roll_04_loop.mp3" );
				}
				
				tween.to( spatial, tPos[ point ], { x : xPos[ point ], y : yPos[ point ], onComplete : func, onCompleteParams : params });
			}
		}
		
		
		private function celebrate( dialogData:DialogData ):void
		{
			CharUtils.setAnim( player, Proud );
			RigAnimation( CharUtils.getRigAnim( player )).ended.add( getMedal );
		}
		
		private function getMedal( ...args ):void
		{
			var specialAbility:SpecialAbilityControl = player.get( SpecialAbilityControl );
			if( specialAbility )
			{
				var specialAbilityData:SpecialAbilityData = specialAbility.getSpecialByClass( SetHandParts );
				if( specialAbilityData )
				{
					super.shellApi.specialAbilityManager.removeSpecialAbility( shellApi.player, specialAbilityData.id );
				}
			}
			
			if( !shellApi.checkHasItem( _events.SURVIVAL_MEDAL ))
			{
				shellApi.getItem( _events.SURVIVAL_MEDAL, null, true );
				
				var showItem:ShowItem = super.getGroupById( ShowItem.GROUP_ID ) as ShowItem;
				if( !showItem )
				{
					showItem = new ShowItem();
					addChildGroup( showItem );
				}
				showItem.transitionComplete.addOnce( loadMorningAfter );
			}
				
			else
			{
				loadMorningAfter();
			}
			
			//shellApi.completedIsland();
		}
		
		private function loadMorningAfter():void
		{
			this.shellApi.loadScene( MorningAfter );
		}
	}
}