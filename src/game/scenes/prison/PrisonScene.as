package game.scenes.prison
{
	import com.poptropica.AppConfig;
	
	import flash.display.Bitmap;
	import flash.display.MovieClip;
	import flash.geom.Point;
	
	import ash.core.Entity;
	
	import engine.components.Spatial;
	import engine.components.SpatialAddition;
	import engine.group.Scene;
	import engine.managers.SoundManager;
	import engine.util.Command;
	
	import game.components.animation.FSMControl;
	import game.components.entity.Detector;
	import game.components.entity.Dialog;
	import game.components.entity.Hide;
	import game.components.hit.Zone;
	import game.components.motion.WaveMotion;
	import game.data.WaveMotionData;
	import game.data.animation.entity.character.Stand;
	import game.data.animation.entity.character.Tremble;
	import game.scene.template.AudioGroup;
	import game.scene.template.CharacterGroup;
	import game.scene.template.GameScene;
	import game.scene.template.ItemGroup;
	import game.scene.template.PlatformerGameScene;
	import game.scenes.prison.shared.popups.SchedulePopup;
	import game.systems.actionChain.ActionChain;
	import game.systems.actionChain.actions.CallFunctionAction;
	import game.systems.actionChain.actions.RemoveItemAction;
	import game.systems.actionChain.actions.TriggerEventAction;
	import game.systems.actionChain.actions.WaitAction;
	import game.systems.entity.character.states.CharacterState;
	import game.systems.motion.WaveMotionSystem;
	import game.util.AudioUtils;
	import game.util.CharUtils;
	import game.util.DataUtils;
	import game.util.DisplayUtils;
	import game.util.EntityUtils;
	import game.util.MotionUtils;
	import game.util.PerformanceUtils;
	import game.util.SceneUtil;
	import game.util.ScreenEffects;
	import game.util.SkinUtils;
	
	import org.osflash.signals.Signal;
	
	public class PrisonScene extends PlatformerGameScene
	{
		protected var _audioGroup:AudioGroup;
		protected var _characterGroup:CharacterGroup;
		protected var _itemGroup:ItemGroup;
		protected var _events:PrisonEvents;
		private var _loadedGroups:Boolean;
		
		public function PrisonScene()
		{
			super();
		}
		
		override protected function addGroups():void
		{	
			if(!_loadedGroups)
			{
				currentDay = DataUtils.getNumber(shellApi.getUserField(_events.DAYS_IN_PRISON_FIELD, shellApi.island));
				if(isNaN(currentDay)) currentDay = 0;
				
				// checking if parole passed for the prisoners
				switch(currentDay)
				{
					case _events.DAYS_FOR_NOSTRAND - 1:
						shellApi.triggerEvent(_events.PAROLE_NEXT_DAY + "nostrand", true);
						break;
					case _events.DAYS_FOR_NOSTRAND:
						shellApi.triggerEvent(_events.PAROLE_PASSED + "nostrand", true);
						break;
					
					case _events.DAYS_FOR_PATCHES - 1:
						shellApi.triggerEvent(_events.PAROLE_NEXT_DAY + "patches", true);
						break;
					case _events.DAYS_FOR_PATCHES:
						shellApi.triggerEvent(_events.PAROLE_PASSED + "patches", true);
						break;
					
					case _events.DAYS_FOR_MARION - 1:
						shellApi.triggerEvent(_events.PAROLE_NEXT_DAY + "marion", true);
						break;
					case _events.DAYS_FOR_MARION:
						shellApi.triggerEvent(_events.PAROLE_PASSED + "marion", true);
						break;
				}
				
				if(mergeFiles)
				{
					if(!shellApi.profileManager.active.gender && AppConfig.debug)
					{
						shellApi.profileManager.active.gender = SkinUtils.GENDER_MALE;
					}
					super.sceneDataManager.loadSceneConfiguration(GameScene.SCENE_FILE_NAME, super.groupPrefix + shellApi.profileManager.active.gender + "/", loadSpecialMerge);
					return;
				}	
			}
			
			super.addGroups();	
		}
		
		private function loadSpecialMerge(files:Array):void
		{
			_loadedGroups = true;
			sceneDataManager.mergeSceneFiles(files, super.groupPrefix + shellApi.profileManager.active.gender + "/", super.groupPrefix);
			super.addGroups();
		}
		
		override public function loaded():void
		{
			_events 								=	shellApi.islandEvents as PrisonEvents;
			_audioGroup 							=	getGroupById( AudioGroup.GROUP_ID ) as AudioGroup;
			_characterGroup							=	getGroupById( CharacterGroup.GROUP_ID ) as CharacterGroup;
			_itemGroup								=	getGroupById( ItemGroup.GROUP_ID ) as ItemGroup;
			
			// setup our userfields	
			gumCount = DataUtils.getNumber(shellApi.getUserField(_events.GUM_FIELD,shellApi.island));
			if(isNaN(gumCount)) 
			{
				gumCount = 0;
				shellApi.setUserField(_events.GUM_FIELD, gumCount.toString(), shellApi.island);
			}			
			if(!shellApi.getUserField(_events.SUNFLOWER_FIELD, shellApi.island))
			{
				shellApi.setUserField(_events.SUNFLOWER_FIELD, "0,0", shellApi.island);
			}
			
			shellApi.eventTriggered.add( eventTriggered );			
			super.loaded();			
		}
		
		protected function eventTriggered( event:String, makeCurrent:Boolean = true, init:Boolean = false, removeEvent:String = null ):void
		{
			if(event == "use_metal_cup")
			{
				player.get(Dialog).sayById("cant_use_metal_cup");
			}
			else if(event == "use_water_cup")
			{
				player.get(Dialog).sayById("cant_use_water_cup");
			}
			else if(event == "use_plaster_cup")
			{
				player.get(Dialog).sayById("cant_use_plaster_cup");
			}
			else if(event == "use_spoon" || event == "cant_use_spoon")
			{
				player.get(Dialog).sayById("cant_use_spoon");
			}
			else if(event == "use_sunflower_seeds")
			{
				player.get(Dialog).sayById("cant_use_seeds");
			}
			else if(event == "use_sunflower")
			{
				player.get(Dialog).sayById("cant_use_sunflower");
			}
			else if(event == "use_dummy_head")
			{
				player.get(Dialog).sayById("cant_use_dummy_head");
			}
			else if(event == "use_painted_head")
			{
				player.get(Dialog).sayById("cant_use_painted_head");
			}
			else if(event == "use_uncooked_pasta")
			{
				player.get(Dialog).sayById("cant_use_uncooked_pasta")
			}
			else if(event == "use_gum" || event == "use_plaster_cup")
			{
				player.get(Dialog).sayById("cant_use_generic");
			}
			else if(event == "cant_use_painted_pasta")
			{
				player.get(Dialog).sayById("cant_use_painted_pasta");
			}
			else if(event == "cant_use_sharpened_spoon"||event == "use_sharpened_spoon")
			{
				player.get(Dialog).sayById("cant_use_sharpened_spoon");
			}
			else if(event == "use_drill_bit" || event == "cant_use_drill_bit")
			{
				combineDrillMixer(event);
			}			
			else if(event == "use_mixer" || event == "cant_use_mixer")
			{
				player.get(Dialog).sayById("cant_use_mixer");
			}
		}
		
		private function combineDrillMixer(event:String):void
		{
			if(shellApi.checkHasItem(_events.MIXER) && !shellApi.checkEvent(_events.COMBINED_DRILL_BIT))
			{
				var actions:ActionChain = new ActionChain(this);
				actions.lockInput = true;
				
				actions.addAction(new WaitAction(0.8));
				actions.addAction(new RemoveItemAction(_events.DRILL_BIT,"player",true,true));
				actions.addAction(new RemoveItemAction(_events.MIXER,"player",true,false));
				actions.addAction(new WaitAction(0.1));
				actions.addAction(new TriggerEventAction(_events.COMBINED_DRILL_BIT,true));
				actions.addAction(new WaitAction(0.1));
				actions.addAction(new CallFunctionAction(shellApi.showItem, _events.MIXER, shellApi.island));
				
 				actions.execute();
			}
			else
			{
				player.get(Dialog).sayById("cant_use_drill_bit");
			}
		}
		
		protected function openSchedule(currentScene:Scene):void
		{
			var schedule:SchedulePopup = new SchedulePopup(overlayContainer, currentScene);
			addChildGroup(schedule);
		}
		
		protected function givePlayerGum(amount:uint = 1):void
		{
			gumCount += amount;
			shellApi.setUserField(_events.GUM_FIELD, gumCount.toString(), shellApi.island, true);
			
			if(!shellApi.checkHasItem(_events.STICK_OF_GUM))
			{
				shellApi.getItem(_events.STICK_OF_GUM, null, true);
			}
			else
			{
				shellApi.showItem(_events.STICK_OF_GUM, null);
			}			
		}
		
		protected function removePlayerGum(amount:uint = 1, entityId:String = null):void
		{
			if(entityId)
			{
				_itemGroup.takeItem(_events.STICK_OF_GUM, entityId);
			}
			
			gumCount -= amount;
			if(gumCount <= 0)
			{
				gumCount = 0;
				shellApi.removeItem(_events.STICK_OF_GUM);
			}
			
			shellApi.setUserField(_events.GUM_FIELD, gumCount.toString(), shellApi.island, true);
		}
		
		protected function resetGumCount(...p):void
		{
			shellApi.setUserField(_events.GUM_FIELD, "0", shellApi.island, true);
		}
		
		protected function getGumCount(...p):int
		{
			return gumCount;
		}
		
		protected function setupRoofLight(id:String, angRotateTo:Number, width:Number = 5, length:Number = 880, offset:Number = 90):void
		{
			var clip:MovieClip = _hitContainer[id];
			clip.mouseEnabled = false;
			clip.mouseChildren = false;
			var bmp:Bitmap = this.createBitmap(clip, PerformanceUtils.defaultBitmapQuality);
			DisplayUtils.moveToTop(clip);
			
			var light:Entity = EntityUtils.createSpatialEntity(this, bmp);				
			light.add(new SpatialAddition());
			var waveMotion:WaveMotion = new WaveMotion();
			light.add(waveMotion);
			
			var detector:Detector = new Detector(width, length, offset);
			detector.detectorHit.add(roofCaught);
			light.add(detector);
			
			waveMotion.data.push(new WaveMotionData("rotation", angRotateTo, .012, "sin", 0));
		}
		
		protected function setupHideZones(num:int):void
		{
			for(var i:int = 0; i < num; i++)
			{
				var zone:Zone = getEntityById("hideZone" + i).get(Zone);
				zone.entered.add(Command.create(hideZone, true));
				zone.exitted.add(Command.create(hideZone, false));
			}
		}
		
		private function hideZone(zoneId:String, charId:String, hidden:Boolean):void
		{
			if(charId == "player")
			{
				player.get(Hide).hidden = hidden;
			}
		}
		
		protected function roofCaught(...args):void
		{
			if(!_currentlyCaught)
			{
				_currentlyCaught = true;
				removeSystemByClass(WaveMotionSystem);
				AudioUtils.play(this, SoundManager.EFFECTS_PATH + "alarm_06.mp3", 1);
				SceneUtil.lockInput(this, true);			
				MotionUtils.zeroMotion(player);
				
				var fsm:FSMControl = player.get(FSMControl);			
				if(fsm.state.type == CharacterState.STAND)
				{
					finishCaught(CharacterState.STAND);
				}
				else
				{
					fsm.stateChange = new Signal();
					fsm.stateChange.add(finishCaught);
				}
			}
		}
		
		private function finishCaught(type:String, entity:Entity = null):void
		{
			if(type == CharacterState.STAND)
			{
				CharUtils.setAnim(player, Tremble);
				var screenEffects:ScreenEffects = new ScreenEffects(overlayContainer, shellApi.viewportWidth, shellApi.viewportHeight, 1);
				screenEffects.fadeToBlack(2, sendPlayerBack, new Array(screenEffects));
				
				var fsmControl:FSMControl = player.get(FSMControl);
				if(fsmControl.stateChange)
				{
					fsmControl.stateChange.removeAll();
					fsmControl.stateChange = null;
				}
			}
		}
		
		protected function sendPlayerBack(screenEffects:ScreenEffects = null):void
		{			
			var playerSpatial:Spatial = player.get(Spatial);
			playerSpatial.x = roofCheckPoint.x;
			playerSpatial.y = roofCheckPoint.y;			
			
			CharUtils.setAnim(player, Stand);
			CharUtils.setDirection(player, true);
			CharUtils.stateDrivenOn(player);
			CharUtils.setState(player, CharacterState.STAND);
			
			addSystem(new WaveMotionSystem());
			_currentlyCaught = false;
			
			if(screenEffects)
			{
				screenEffects.fadeFromBlack(2, Command.create(SceneUtil.lockInput, this, false));
			}
		}
		
		protected var roofCheckPoint:Point;
		protected var currentDay:Number;
		protected var gumCount:Number;
		protected var mergeFiles:Boolean = false;
		
		private var _currentlyCaught:Boolean = false;
	}
}