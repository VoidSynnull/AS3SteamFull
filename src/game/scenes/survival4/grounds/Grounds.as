package game.scenes.survival4.grounds
{
	import com.greensock.easing.Quad;
	import com.greensock.easing.Sine;
	
	import flash.display.DisplayObjectContainer;
	import flash.display.Sprite;
	import flash.geom.Point;
	
	import ash.core.Entity;
	
	import engine.components.Audio;
	import engine.components.AudioRange;
	import engine.components.Display;
	import engine.components.Spatial;
	import engine.creators.CameraLayerCreator;
	import engine.creators.InteractionCreator;
	import engine.data.AudioWrapper;
	import engine.managers.SoundManager;
	import engine.util.Command;
	
	import game.components.entity.Children;
	import game.components.entity.Dialog;
	import game.components.entity.character.CharacterMotionControl;
	import game.components.hit.Platform;
	import game.components.hit.Zone;
	import game.components.render.Light;
	import game.components.scene.SceneInteraction;
	import game.components.timeline.Timeline;
	import game.creators.render.LightCreator;
	import game.creators.ui.ToolTipCreator;
	import game.data.TimedEvent;
	import game.data.animation.entity.character.Drink;
	import game.data.animation.entity.character.Proud;
	import game.data.comm.PopResponse;
	import game.data.scene.characterDialog.DialogData;
	import game.data.sound.SoundModifier;
	import game.data.ui.ToolTipType;
	import game.scene.template.ItemGroup;
	import game.scene.template.PlatformerGameScene;
	import game.scenes.survival4.Survival4Events;
	import game.systems.entity.character.states.CharacterState;
	import game.systems.render.LightSystem;
	import game.ui.elements.DialogPicturePopup;
	import game.ui.popup.IslandEndingPopup;
	import game.util.AudioUtils;
	import game.util.CharUtils;
	import game.util.DisplayUtils;
	import game.util.EntityUtils;
	import game.util.SceneUtil;
	import game.util.SkinUtils;
	import game.util.TimelineUtils;
	import game.util.TweenUtils;
	
	public class Grounds extends PlatformerGameScene
	{
		public function Grounds()
		{
			super();
		}
		
		// pre load setup
		override public function init(container:DisplayObjectContainer = null):void
		{			
			super.groupPrefix = "scenes/survival4/grounds/";
			super.init(container);
			
			var cameraLayerCreator:CameraLayerCreator = new CameraLayerCreator();
			var lightLayerDisplay:Sprite = new Sprite();
			lightLayerDisplay.name = 'lightLayer';
			this.addEntity(cameraLayerCreator.create(lightLayerDisplay, 0, "lightLayer"));
			this.groupContainer.addChild(lightLayerDisplay);
			lightLayerDisplay.mouseChildren = false;
			lightLayerDisplay.mouseEnabled = false;
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
			
			_events = super.events as Survival4Events;
			shellApi.eventTriggered.add(handleEventTrigger);
			
			_gate = EntityUtils.createSpatialEntity(this, _hitContainer["gate"]);
			setupDogZone();			
			
			// Check if goggles are already on before putting the lantern light on
			if(!shellApi.checkHasItem(_events.SURVIVAL_MEDAL))
			{
				addLightOverlay();
				if(SkinUtils.getSkinPart(player, SkinUtils.FACIAL).value == "survival_nightvision")
				{
					switchLights(true);					
				}
				else
				{
					switchLights(false);
					player.get(Dialog).sayById("dark");
				}
			}
			
			DisplayUtils.moveToTop(_hitContainer["frontGate"]);
		}
		
		private function handleEventTrigger(event:String, makeCurrent:Boolean = true, init:Boolean = false, removeEvent:String = null):void
		{
			if(event == _events.NIGHT_VISION_OFF)
			{
				switchLights(false);
				if(shellApi.checkEvent(_events.DOG_ATE_MEAT))
					gateClick(false);
			}
			else if(event == _events.NIGHT_VISION_ON)
			{
				switchLights(true);
				if(shellApi.checkEvent(_events.DOG_ATE_MEAT))
					gateClick();
			}
			else if(event == _events.USE_TAINTED_MEAT)
			{
				var playerSpatial:Spatial = this.player.get(Spatial);					
				if(playerSpatial.x > 1260 && playerSpatial.x < 1550 && playerSpatial.y < 525)
				{
					SceneUtil.lockInput(this, true);						
					CharUtils.moveToTarget(this.player, 1320, 450, true, dropMeat, new Point(20, 100)).validCharStates = new <String>[CharacterState.STAND];
				}
				else
				{
					player.get(Dialog).sayById("no_use");
				}
			}
			else if( event == _events.USE_ARMORY_KEY || event == _events.USE_EMPTY_PITCHER || event == _events.USE_FULL_PITCHER || event == _events.USE_SPEAR || event == _events.USE_TROPHY_ROOM_KEY )
			{
				player.get( Dialog ).sayById( "no_use" );
			}
			else if(event == _events.PLAY_HORN)
			{
				// Play horn sound and show butler playing it
				var butler:Entity = getEntityById("butler");
				CharUtils.setAnim(butler, Drink);
				CharUtils.getTimeline(butler).handleLabel("ending", hornBlown);
			}
		}
		
		private function hornBlown():void
		{
			CharUtils.setDirection(player, false);
			CharUtils.moveToTarget(player, 50, 920, true, showVictoryPopup, new Point(25, 100));
		}
		
		private function dropMeat(entity:Entity):void
		{
			var meat:Entity = EntityUtils.createMovingEntity(this, _hitContainer["meat"]);
			var spatial:Spatial = meat.get(Spatial);
			spatial.x = 1255;
			spatial.y = 455;
			
			SceneUtil.setCameraTarget(this, meat, true);
			TweenUtils.globalTo(this, spatial, 1, {x:1200, y:910, ease:Quad.easeIn, onComplete:Command.create(meatLanded, meat)});
		}
		
		private function meatLanded(meat:Entity):void
		{
			AudioUtils.play(this, SoundManager.EFFECTS_PATH + "flesh_impact_04.mp3");
			var timeline:Timeline = _dog.get(Timeline);
			timeline.gotoAndPlay("eat");
			timeline.handleLabel("chomp", Command.create(AudioUtils.play, this, SoundManager.EFFECTS_PATH + "chomp_01.mp3"));
			timeline.handleLabel("chompEnd", Command.create(SceneUtil.addTimedEvent, this, new TimedEvent(2, 1, makeDogSleep)));
			this.removeEntity(meat);
		}
		
		private function makeDogSleep():void
		{
			var timeline:Timeline = _dog.get(Timeline);
			timeline.gotoAndPlay("sleep");
			timeline.handleLabel("end", dogDoneEating);
		}
		
		private function dogDoneEating():void
		{
			SceneUtil.lockInput(this, false);
			SceneUtil.setCameraTarget(this, player, true);
			shellApi.removeItem(_events.TAINTED_MEAT);
			shellApi.completeEvent(_events.DOG_ATE_MEAT);			
			prepareForEnding();
		}
		
		private function playRandomSnore():void
		{
			var audioWrapper:AudioWrapper = Audio(_dog.get(Audio)).play(SoundManager.EFFECTS_PATH + "large_animal_snore_0" + int(Math.random() * 3 + 1) + ".mp3", false, [SoundModifier.POSITION, SoundModifier.FADE]);
			audioWrapper.complete.addOnce(playRandomSnore);
		}
		
		private function prepareForEnding():void
		{
			_dogZone.get(Zone).entered.removeAll();
			removeEntity(_dogZone, true);
			_dog.add(new Audio());
			_dog.add(new AudioRange(900, 0, 1, Sine.easeIn));
			playRandomSnore();
			
			EntityUtils.turnOffSleep(getEntityById("buren"));
			EntityUtils.turnOffSleep(getEntityById("butler"));
			
			if(!shellApi.checkHasItem(_events.SURVIVAL_MEDAL))
			{
				if(SkinUtils.getSkinPart(player, SkinUtils.FACIAL).value == "survival_nightvision")
				{
					gateClick();
				}
			}
		}
		
		private function showEnding(clicker:Entity, gate:Entity):void
		{
			SceneUtil.lockInput(this, true);
			var dialog:Dialog = player.get(Dialog);
			dialog.sayById("free");
			dialog.complete.addOnce(giveMedal);
		}
		
		private function giveMedal(dialogData:DialogData):void
		{
			var itemGroup:ItemGroup = this.getGroupById( ItemGroup.GROUP_ID ) as ItemGroup;
			itemGroup.showAndGetItem( _events.SURVIVAL_MEDAL, null, beProud);					
			//shellApi.completedIsland();
		}
		
		private function beProud():void
		{
			CharUtils.setAnim(player, Proud);
			CharUtils.getTimeline(player).handleLabel("ending", floodLights);
		}
		
		private function floodLights():void
		{
			// remove overlay and lights
			this.removeSystemByClass(LightSystem);
			player.remove(Light);
			_dog.remove(Light);
			_lantern.remove(Light);
			removeEntity(getEntityById("lightOverlay"));
			
			var lightLayerDisplay:DisplayObjectContainer = this.getEntityById("lightLayer").get(Display).displayObject;
			var lightCreator:LightCreator = new LightCreator();
			lightCreator.setupLight(this, lightLayerDisplay, .4, false, 0xFF0000);
			getEntityById("lightOverlay").get(Display).alpha = 0;
			
			// move van buren and Butler to the player
			var buren:Entity = getEntityById("buren");
			var butler:Entity = getEntityById("butler");
			
			var burenSpatial:Spatial = buren.get(Spatial);
			burenSpatial.x = 2100;
			burenSpatial.y = 870;
			
			var butlerSpatial:Spatial = butler.get(Spatial);
			butlerSpatial.x = 2200;
			butlerSpatial.y = 870;
			
			toRed(getEntityById("lightOverlay").get(Display));
			SceneUtil.setCameraPoint(this, 2270, 280);
			SceneUtil.addTimedEvent(this, new TimedEvent(2, 1, Command.create(moveToBuren, buren, butler)));
		}
		
		private function moveToBuren(buren:Entity, butler:Entity):void
		{
			AudioUtils.play(this, SoundManager.MUSIC_PATH + "caught.mp3");
			SceneUtil.setCameraTarget(this, buren);
			
			var playerSpatial:Spatial = player.get(Spatial);
			playerSpatial.x = 380;
			playerSpatial.y = 870;
			SkinUtils.emptySkinPart(player, SkinUtils.FACIAL);		
			
			var motionControl:CharacterMotionControl = new CharacterMotionControl();
			motionControl.maxVelocityX = 350;
			buren.add(motionControl);
			
			var butlerMotionControl:CharacterMotionControl = new CharacterMotionControl();
			butlerMotionControl.maxVelocityX = 300;
			butler.add(butlerMotionControl);	
			
			CharUtils.moveToTarget(buren, 500, 870, true, burenAtPlayer);	
			CharUtils.moveToTarget(butler, 600, 870, true);		
		}
		
		private function toRed(display:Display):void
		{
			AudioUtils.play(this, SoundManager.EFFECTS_PATH + "alarm_06.mp3", .5);
			TweenUtils.globalTo(this, display, .75, {alpha:1, onComplete:toWhite, onCompleteParams:[display]});
		}
		
		private function toWhite(display:Display):void
		{
			TweenUtils.globalTo(this, display, .75, {alpha:0, onComplete:toRed, onCompleteParams:[display]});
		}
		
		private function burenAtPlayer(buren:Entity):void
		{
			CharUtils.setDirection(player, true);
			buren.get(Dialog).sayById("eager");
		}
		
		private function showVictoryPopup(entity:Entity):void
		{
			shellApi.completedIsland('', onCompletions);
		}

		private function onCompletions(response:PopResponse):void
		{
			SceneUtil.lockInput(this, false);
			this.addChildGroup(new IslandEndingPopup(this.overlayContainer));
			//addChildGroup(new VictoryPopup(this.overlayContainer));			
		}
		
		// Setup the lantern and add the light overlay
		private function addLightOverlay():void
		{
			var lightCreator:LightCreator = new LightCreator();
			var lightLayerDisplay:DisplayObjectContainer = this.getEntityById("lightLayer").get(Display).displayObject;
			lightCreator.setupLight(this, lightLayerDisplay, .97);
			this.groupContainer.setChildIndex(lightLayerDisplay, this.groupContainer.getChildIndex(getEntityById("uiLayer").get(Display).displayObject) - 1);
		}
		
		// Switch between the lights so overlap doesn't cause issues
		private function switchLights(goggles:Boolean):void
		{
			_gogglesOn = goggles;
			if(goggles)
			{
				_lantern.remove(Light);
				_dog.remove(Light);
				_dogLight.remove(Light);
				player.add(new Light(500, .97, .5, true, 0x339933));
				_platforms.add(new Platform());
			}
			else
			{
				_platforms.remove(Platform);
				player.remove(Light);
				_dogLight.add(new Light(200, .97, .1, true, 0xD2F088));
				_lantern.add(new Light(325, .97, .6, true, 0xD2F088));
			}
		}
		
		private function gateClick(add:Boolean = true):void
		{
			if(add)
			{
				InteractionCreator.addToEntity(_gate, [InteractionCreator.CLICK]);
				var sceneInteraction:SceneInteraction = new SceneInteraction();
				sceneInteraction.reached.addOnce(showEnding);
				_gate.add(sceneInteraction);
				ToolTipCreator.addToEntity(_gate, ToolTipType.EXIT_LEFT);				
			}
			else
			{
				if(_gate.has(SceneInteraction))
				{
					_gate.get(SceneInteraction).reached.removeAll();
					 EntityUtils.removeInteraction(_gate);
				}
			}
		}
		
		private function setupDogZone():void
		{
			_lantern = EntityUtils.createSpatialEntity(this, _hitContainer["lanternLight"], _hitContainer);
			_platforms = getEntityById("wood");
			
			_dogLight = EntityUtils.createSpatialEntity(this, _hitContainer["dogLight"], _hitContainer);
			_dogLight.add(new Light(200, .95, .1, true, 0xD2F088));
			
			_dogZone = getEntityById("zoneDog");
			Zone(_dogZone.get(Zone)).entered.addOnce(dogZoneEntered);
			
			this.convertContainer(_hitContainer["dog"]);
			_dog = TimelineUtils.convertAllClips(_hitContainer["dog"], null, this);
			var spatial:Spatial = new Spatial();
			EntityUtils.syncSpatial(spatial, _hitContainer["dog"]);
			_dog.add(spatial);	
			
			if(shellApi.checkEvent(_events.DOG_ATE_MEAT))
			{
				_dog.get(Timeline).gotoAndPlay("sleep");
				prepareForEnding();
			}
			else
			{
				_dog.get(Timeline).gotoAndPlay("idle");
			}
		}
		
		private function dogZoneEntered(zoneId:String, charId:String):void
		{			
			SceneUtil.lockInput(this, true);
			SceneUtil.setCameraTarget(this, _dog);
			var dogChildren:Children = _dog.get(Children);
			var timeline:Timeline = dogChildren.children[0].get(Timeline);
			AudioUtils.play(this, SoundManager.EFFECTS_PATH + "bear_growl_01.mp3"); // dog caught you
			timeline.gotoAndPlay("growl");
			timeline.handleLabel("end", dogAttacked);
		}
		
		private function dogAttacked():void
		{
			AudioUtils.play(this, SoundManager.MUSIC_PATH + "caught.mp3");
			SceneUtil.lockInput(this, false);
			var dogPopup:DialogPicturePopup = new DialogPicturePopup(overlayContainer);
			dogPopup.updateText("The guard dog caught you! You'll need to distract him.", "Try Again");
			dogPopup.configData("dogPopup.swf", "scenes/survival4/shared/dogPopup/");
			dogPopup.popupRemoved.addOnce(dogPopupClosed);
			addChildGroup(dogPopup);
		}
		
		private function dogPopupClosed():void
		{
			shellApi.loadScene(Grounds);
		}
		
		private var _events:Survival4Events;
		private var _gogglesOn:Boolean = false;
		private var _lantern:Entity;
		private var _dog:Entity;
		private var _dogLight:Entity;
		private var _dogZone:Entity;
		private var _platforms:Entity;
		private var _gate:Entity;
	}
}
