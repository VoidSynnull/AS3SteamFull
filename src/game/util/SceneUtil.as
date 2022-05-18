package game.util
{
	import com.poptropica.AppConfig;
	
	import flash.display.MovieClip;
	import flash.geom.Point;
	import flash.ui.Mouse;
	import flash.utils.Dictionary;
	
	import ash.core.Entity;
	
	import engine.ShellApi;
	import engine.components.Audio;
	import engine.components.Display;
	import engine.components.Id;
	import engine.components.Interaction;
	import engine.components.Motion;
	import engine.components.Spatial;
	import engine.components.SpriteSheet;
	import engine.creators.InteractionCreator;
	import engine.group.Group;
	import engine.group.Scene;
	import engine.managers.SoundManager;
	import engine.systems.CameraSystem;
	import engine.systems.MotionSystem;
	import engine.util.Command;
	
	import game.components.Timer;
	import game.components.entity.Sleep;
	import game.components.entity.character.CharacterMotionControl;
	import game.components.entity.character.part.SkinPart;
	import game.components.input.Input;
	import game.components.timeline.Timeline;
	import game.components.ui.Cursor;
	import game.creators.entity.EmitterCreator;
	import game.creators.ui.ToolTipCreator;
	import game.data.TimedEvent;
	import game.data.animation.Animation;
	import game.data.character.LookConverter;
	import game.data.character.LookData;
	import game.data.scene.CameraLayerData;
	import game.data.scene.SceneData;
	import game.managers.ScreenManager;
	import game.particles.emitter.CoinEmitter;
	import game.scene.template.CameraGroup;
	import game.scene.template.GameScene;
	import game.scene.template.SceneUIGroup;
	import game.scene.template.ui.CardGroup;
	import game.systems.SystemPriorities;
	import game.systems.TimerSystem;
	import game.systems.motion.NavigationSystem;
	import game.systems.motion.PositionSmoothingSystem;
	import game.systems.ui.WordBalloonSystem;
	import game.ui.hud.Hud;
	
	import org.osflash.signals.Signal;
	import game.data.island.IslandEvents;
	
	public class SceneUtil
	{				
		/**
		 * TEMP :: retrieves the signal that is dispatched when the current word balloon completes.
		 * @param	group
		 * @return
		 */
		public static function getDialogComplete( group:Group ):Signal
		{
			var wordBalloonSystem:WordBalloonSystem = group.getSystem(WordBalloonSystem) as WordBalloonSystem;
			if ( wordBalloonSystem )
			{
				return wordBalloonSystem.dialogComplete;
			}
			else
			{
				trace( " Error :: SceneUtil :: getDialogComplete :: WordBalloonSystem has not been added to scene " );
				return null;
			}
		}
		
		/**
		 * Removes and replaces island parts designated to be specific to the island in the IslandEvents Class
		 * format: [partId, value, newValue] if no newValue included, it defaults to "empty" or uses default part value in case of rquired parts
		 * @param group
		 * should be called during the load function, loaded will be too late and not effect player look
		 */
		public static function removeIslandParts(group:Group, classString:String = null, save:Boolean = true):void
		{
			var shellApi:ShellApi = group.shellApi;
			var partsToRemove:Vector.<Vector.<String>>;
			var eventClass:Class;
			if (classString != null)
			{
				eventClass = ClassUtils.getClassByName(classString);
				var newClass:IslandEvents = IslandEvents(new eventClass());
				partsToRemove = newClass.removeIslandParts;
				if (partsToRemove == null)
				{
					return;
				}
			}
			else
			{
				partsToRemove = shellApi.islandEvents.removeIslandParts;
			}
			
			if(partsToRemove.length > 0 && shellApi.profileManager.active.look != null)
			{
				var lookConverter:LookConverter = new LookConverter();
				var playerLookData:LookData = lookConverter.lookDataFromPlayerLook(shellApi.profileManager.active.look);
				
				var partType:String;
				var value:String;
				var newValue:String;
				
				for(var i:int = 0; i < partsToRemove.length; i++)
				{
					partType = partsToRemove[i][0];
					value = partsToRemove[i][1];
					
					if (partType == CharUtils.ABILITY)
					{
						// remove ability but don't save because
						shellApi.specialAbilityManager.removeSpecialAbilityFromPlayer(value, save);
					}
					else
					{
						// if value to remove matches current value, determine and assign replacement value
						if( partsToRemove[i][1] == playerLookData.getValue(partType) )
						{
							// if newValue is specified, use this value
							newValue = (partsToRemove[i].length > 2) ? partsToRemove[i][2] : null;
							if(newValue == null)
							{
								newValue = (SkinUtils.PARTS_REQUIRED.indexOf(partType) > -1) ? SkinUtils.getDefaultPart(partType) : SkinPart.EMPTY;
							}
							playerLookData.setValue(partType, newValue);
						}
					}
				}
				shellApi.saveLook(playerLookData);
			}
		}
		
		public static function mergeSharedData(scene:Scene, fileName:String, operationForMatchingAttributes:String = null):XML
		{
			var sourceData:XML = scene.getData(fileName);
			var sharedPaths:Array;
			var sharedData:XML;
			
			if(scene.sceneData.absoluteFilePaths.length > 0)
			{
				sharedPaths = ArrayUtils.getMatchingElements(fileName, scene.sceneData.absoluteFilePaths);
			}
			
			if(sharedPaths != null)
			{
				for (var i:int = 0; i < sharedPaths.length; i++) 
				{
					sharedData = scene.getData(sharedPaths[i], false, true, true);
					if( sharedData == null )
					{
						sharedData = scene.getData(sharedPaths[i], false, true, false);	// TEMP :: had to use full path to get shared dialog
					}
					
					if(sharedData != null)
					{
						if(sourceData == null)
						{
							sourceData = sharedData;
						}
						else
						{
							DataUtils.mergeXML(sourceData, sharedData, operationForMatchingAttributes);
						}
					}
				}
			}
			
			return(sourceData);
		}
		
		public static function mainStreetClass(islandName:String):Class {
			return ClassUtils.getClassByName('game.scenes.' + islandName + '.mainStreet.MainStreet');
		}
		
		public static function isMainStreetClass(scene:*):Boolean {
			var className:String = ClassUtils.getNameByObject(scene);
			return className.indexOf('mainStreet') > -1;
		}
		
		/////////////////////////////////////////////////////////////////////////////////////
		////////////////////////////////////// TIMER ////////////////////////////////////////
		/////////////////////////////////////////////////////////////////////////////////////
		
		/**
		 * Adds a TimeEvent for use in scene.  
		 * TimeEvents must be added, or they will not work.
		 * @param	timed
		 * @param	timerId : specify which Entity you want to use, scene should normally only have one.
		 */
		public static function addTimedEvent( group:Group, timedEvent:TimedEvent, timerId:String = "" ):TimedEvent
		{
			var timer:Timer = SceneUtil.getTimer( group, timerId );
			timer.addTimedEvent( timedEvent );
			return timedEvent;
		}
		
		/**
		 * Abrreviate method for creating a TimeEvent 
		 * @param group
		 * @param delay
		 * @param handler
		 * @return 
		 */
		public static function delay( group:Group, delay:Number, handler:Function ):TimedEvent
		{
			var timer:Timer = SceneUtil.getTimer( group );
			var timedEvent:TimedEvent = new TimedEvent( delay, 1, handler );
			timer.addTimedEvent( timedEvent );
			return timedEvent;
		}
		
		/**
		 * Returns the Timer for the group.
		 * Creates a new timer Entity for the group if one does not already exist.
		 * @param	group
		 * @param	id
		 * @return
		 */
		public static function getTimer( group:Group, id:String = "" ):Timer
		{
			id = ( id == "" ) ? SceneUtil.TIMER_ID : id;
			var entity:Entity = group.getEntityById(id);
			
			if ( entity )
			{
				return entity.get( Timer );
			}
			else
			{
				entity = new Entity();
				
				// add Timer
				var timer:Timer = new Timer();
				entity.add(timer);
				group.addSystem( new TimerSystem(), SystemPriorities.update );
				
				// add Id
				var idComponent:Id = new Id();
				idComponent.id = id;
				entity.add(idComponent);
				
				group.addEntity( entity );
				return timer;
			}
		}
		
		/////////////////////////////////////////////////////////////////////////////////////
		
		/////////////////////////////////////////////////////////////////////////////////////
		////////////////////////////////////// INPUT ////////////////////////////////////////
		/////////////////////////////////////////////////////////////////////////////////////
		
		public static function hideCustomCursor(entity:Entity):void
		{
			entity.remove(SpriteSheet);
			
			var display:Display = entity.get(Display);
			
			if(display)
			{
				if(display.container && display.displayObject)
				{
					display.container.removeChild(display.displayObject);
				}
			}
			
			Mouse.show();	
		}
		
		public static function showCustomCursor(entity:Entity):void
		{
			entity.add(new SpriteSheet());
			
			var cursor:Cursor = entity.get(Cursor);
			
			if(cursor) { cursor._invalidate = true; }
			
			Mouse.hide();	
		}
		
		/**
		 * Get the scene's input component
		 * @param	group
		 * @return
		 */
		public static function getInput( group:Group ):Input
		{
			if ( group.shellApi.inputEntity )
			{
				return group.shellApi.inputEntity.get( Input ) as Input;
			}
			return null;
		}
		
		/**
		 * Lock control for defined time
		 * @param	group
		 * @param	lockInput : blocks clicks
		 * @param   lockPosition : Stop the update of the input position.
		 * @param   lockDelay: how long to lock
		 */
		public static function timedLockInput( group:Group, lockInput:Boolean = true, lockPosition:Boolean = false, lockDelay:Number = 0 ):void
		{
			SceneUtil.lockInput(group,lockInput,lockPosition);
			addTimedEvent(group, new TimedEvent(lockDelay,1,Command.create(SceneUtil.lockInput,group,false,false)));
		}
		/**
		 * Lock control
		 * TODO :: this will probably need to be updated when control is modified.
		 * @param	group
		 * @param	lockInput : blocks clicks
		 * @param   lockPosition : Stop the update of the input position.
		 */
		public static function lockInput( group:Group, lockInput:Boolean = true, lockPosition:Boolean = false ):void
		{
			if (!group.shellApi.inputEntity) return;
			
			var input:Input 		= group.shellApi.inputEntity.get(Input);
			input.lockInput 		= lockInput;
			input.lockPosition 		= lockPosition;
			input.inputActive 		= false;
			input.inputStateDown 	= false;
			
			//Desktop already has a loading icon. Only use the loading wheel if you're mobile.
			if(AppConfig.mobile)
			{
				SceneUtil.createLockIcon(group, lockInput);
			}
		}
		
		public static function createLockIcon(group:Group, lock:Boolean):void
		{
			var lockIcon:Entity = group.getEntityById(LOCK_ICON);
			if(lock)
			{
				if(!lockIcon)
				{
					group.shellApi.loadFile(group.shellApi.assetPrefix + "ui/general/load_wheel.swf", Command.create(lockIconLoaded, group));
				}
			}
			else
			{
				if(lockIcon) group.removeEntity(lockIcon);
			}
		}
		
		private static function lockIconLoaded(clip:MovieClip, group:Group):void
		{
			if(!group.groupManager.hasGroup(group)) return;
			
			/*
			Loading takes time, and in that time, the input could've been unlocked again. If
			it's already unlocked before the loading wheel finishes loading, don't make it.
			*/
			if(!group.shellApi.inputEntity) return;
			if(!group.shellApi.inputEntity.get(Input).lockInput) return;
			if(group.getEntityById(LOCK_ICON)) return;	// NOTE :: Was still getting a crash despite previous checks.  Need to look inot this more.  bard
			
			var entity:Entity = new Entity();
			group.addEntity(entity);
			
			entity.add(new Id(LOCK_ICON));
			entity.add(new Spatial(group.shellApi.viewportWidth - 50, group.shellApi.viewportHeight - 70));
			entity.add(new Display(clip, ScreenManager(group.shellApi.getManager(ScreenManager)).overlayContainer));
			
			var motion:Motion = new Motion();
			motion.rotationVelocity = 350;
			entity.add(motion);
			
			
			if ( !group.getSystem( MotionSystem ) )
			{
				group.addSystem( new MotionSystem(), SystemPriorities.move );
			}
			
			if( !group.getSystem( PositionSmoothingSystem) )
			{
				group.addSystem(new PositionSmoothingSystem(), SystemPriorities.preRender);
			}
		}
		
		public static function createSaveIcon(group:Group):void
		{
			var saveIcon:Entity = group.getEntityById(SAVE_ICON);
			if(saveIcon || group.removalPending) return;
			
			group.shellApi.loadFile(group.shellApi.assetPrefix + "ui/general/saving.swf", Command.create(saveIconLoaded, group));
		}
		
		private static function saveIconLoaded(clip:MovieClip, group:Group):void
		{
			if(!group.groupManager.hasGroup(group) || group.removalPending) return;
			/**
			 * Double checking that another saveIcon Entity wan't loaded and already made before this one.
			 */
			var saveIcon:Entity = group.getEntityById(SAVE_ICON);
			if(saveIcon) return;
			
			var entity:Entity = new Entity(SAVE_ICON);
			group.addEntity(entity);
			var spatial:Spatial = new Spatial(group.shellApi.viewportWidth - 75, group.shellApi.viewportHeight - 25);
			// set clip dimensions immediately in case the renderSystem is not present.
			clip.x = spatial.x;
			clip.y = spatial.y;
			
			entity.add(new Id(SAVE_ICON));
			entity.add(spatial);
			entity.add(new Display(clip, ScreenManager(group.shellApi.getManager(ScreenManager)).overlayContainer));
			entity.add(new Sleep(false, true));
			entity.ignoreGroupPause = true;
			
			TimelineUtils.convertClip(clip, group, entity);
			
			var timeline:Timeline = entity.get(Timeline);
			timeline.handleLabel(Animation.LABEL_ENDING, Command.create(group.removeEntity, entity, true));
		}
		
		/////////////////////////////////////////////////////////////////////////////////////
		
		/////////////////////////////////////////////////////////////////////////////////////
		////////////////////////////////////// CAMERA ///////////////////////////////////////
		/////////////////////////////////////////////////////////////////////////////////////
		
		/**
		 * Set the camera target to an entities spatial.
		 * @param	group
		 * @param	target
		 * @param	jumpToTarget - optional, camera will just to target spatial if true
		 */
		public static function setCameraTarget( group:Scene, target:Entity, jumpToTarget:Boolean = false, rate:Number = .2 ):void
		{
			var targetSpatial:Spatial = target.get( Spatial ) as Spatial;
			if ( targetSpatial )
			{
				var sleep:Sleep = target.get( Sleep );
				if( sleep )
				{
					sleep.sleeping = false;
				}
				var cameraGroup:CameraGroup = group.getGroupById(CameraGroup.GROUP_ID) as CameraGroup;
				if ( cameraGroup )
				{
					cameraGroup.target = targetSpatial;
					cameraGroup.rate = rate;
					CameraSystem( cameraGroup.getSystem( CameraSystem )).jumpToTarget = jumpToTarget;
				}
			}
		}
		
		/**
		 * Set the camera target to an entities spatial.
		 * @param	group
		 * @param	target
		 * @param	jumpToTarget - optional, camera will just to target spatial if true
		 */
		public static function setCameraPoint( group:Scene, xPos:Number, yPos:Number, jumpToTarget:Boolean = false, rate:Number = .2 ):void
		{
			var cameraGroup:CameraGroup = group.getGroupById(CameraGroup.GROUP_ID) as CameraGroup;
			if ( cameraGroup )
			{
				cameraGroup.target = new Spatial( xPos, yPos);
				cameraGroup.rate = rate;
				CameraSystem( cameraGroup.getSystem( CameraSystem )).jumpToTarget = jumpToTarget;
			}
		}
		
		public static function getCameraLayerDataById(data:SceneData, id:String):CameraLayerData
		{
			var layerData:CameraLayerData;
			var allLayerData:Dictionary;
			
			for each(allLayerData in data.layers)
			{
				for each(layerData in allLayerData)
				{
					if(layerData.id == id)
					{
						return(layerData);
					}
				}
			}
			
			return(null);
		}
		
		public static function zeroRotation( character:Entity ):void
		{
			MotionUtils.zeroMotion( character );
			
			var motionControl:CharacterMotionControl = character.get( CharacterMotionControl );
			if( motionControl )
			{
				motionControl.spinning = false;
				motionControl.spinEnd = true;
			}
			
			var motion:Motion = character.get( Motion );
			if( motion )
			{
				motion.rotation = motion.rotationVelocity = motion.rotationAcceleration = 0;
				
			}
		}
		/////////////////////////////////////////////////////////////////////////////////////
		////////////////////////////////////// DEBUG ///////////////////////////////////////
		/////////////////////////////////////////////////////////////////////////////////////
		
		public static function showPath( group:Scene, bool:Boolean = true ):void
		{
			var navSystem:NavigationSystem = group.getSystem( NavigationSystem ) as NavigationSystem;
			if ( navSystem )
			{
				navSystem.debug = bool;
			}
		}
		/////////////////////////////////////////////////////////////////////////////////////
		
		/**
		 * Hide or show standard hud.
		 * Generally the standard Hud is only present in PlatformerScene 
		 * @param group
		 */
		public static function showHud( group:Group, show:Boolean = true ):void
		{
			var uiGroup:SceneUIGroup = group.getGroupById(SceneUIGroup.GROUP_ID) as SceneUIGroup
			
			if(uiGroup != null)
			{
				var hud:Hud = uiGroup.getGroupById(Hud.GROUP_ID) as Hud;
				
				if(hud != null)
				{
					hud.show(show);
				}
			}
		}
		
		public static function getCoins(group:Scene, coins:int, from:Entity = null):void
		{
			if(from == null)
				from = group.shellApi.player;
			
			var origin:Point = DisplayUtils.localToLocal(EntityUtils.getDisplayObject(from), group.overlayContainer);
			var hud:Hud = group.getGroupById(Hud.GROUP_ID) as Hud;
			var hudButton:Entity = hud.getButtonById(Hud.HUD);
			var hudButtonSpatial:Spatial = hudButton.get(Spatial);
			var coinEmitter:CoinEmitter = new CoinEmitter(coins, new Point(hudButtonSpatial.x, hudButtonSpatial.y), origin);
			var entity:Entity = EmitterCreator.create(group, group.overlayContainer, coinEmitter);
			delay(group, 2,Command.create(gaveCoins, group, hud, entity));
			var flips:Number = 3;
			var time:Number = .25/flips;
			SceneUtil.addTimedEvent(group, new TimedEvent(time, flips,Command.create(getCoinAudio, group)));
			SceneUtil.delay(group, 1, Command.create(AudioUtils.play,group, SoundManager.EFFECTS_PATH+"coins_large_rustle_01.mp3"));
		}
		
		private static function getCoinAudio(group:Group):void
		{
			AudioUtils.play(group, SoundManager.EFFECTS_PATH+"coin_toss_0"+Math.ceil(Math.random() * 4)+".mp3");
		}
		
		private static function gaveCoins(group:GameScene, hud:Hud, coins:Entity):void
		{
			group.removeEntity(coins);
			hud.whiten();
		}
		
		public static function CreateSceneItem(group:Group, clip:MovieClip, cardId:String, cardType:String = CardGroup.CUSTOM):Entity
		{
			if (int(cardId) > 3000)
			{
				cardType = CardGroup.STORE;
			}
			if(clip == null || group.shellApi.checkHasItem(cardId, cardType))
			{
				if(clip != null)
					clip.parent.removeChild(clip);
				return null;
			}
			
			var item:Entity = EntityUtils.createSpatialEntity(group, clip);
			ToolTipCreator.addToEntity(item);
			var interaction:Interaction = InteractionCreator.addToEntity(item, [InteractionCreator.CLICK]);
			interaction.click.add(Command.create(clickedItem, cardId, cardType));
			
			return item;
		}
		
		private static function clickedItem(entity:Entity, cardId:String, cardType:String):void
		{
			var group:Group = entity.group;
			group.shellApi.getItem(cardId, cardType,true);
			group.removeEntity(entity);
		}
		
		public static const TIMER_ID:String 	= "timer";
		public static const LOCK_ICON:String 	= "lockIcon";
		public static const SAVE_ICON:String 	= "saveIcon";
		
		public static const FILES_MERGE:String 		= "merge";
		public static const FILES_COMBINE:String 	= "combine";
		public static const FILES_IGNORE:String 	= "ignore";
	}
}