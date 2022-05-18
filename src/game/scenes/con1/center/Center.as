package game.scenes.con1.center
{
	import com.greensock.easing.Sine;
	
	import flash.display.Bitmap;
	import flash.display.DisplayObjectContainer;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	
	import ash.core.Entity;
	
	import engine.components.Audio;
	import engine.components.AudioRange;
	import engine.components.Display;
	import engine.components.Interaction;
	import engine.components.Spatial;
	import engine.group.DisplayGroup;
	import engine.group.Group;
	import engine.managers.SoundManager;
	import engine.util.Command;
	
	import game.components.entity.Dialog;
	import game.components.entity.character.CharacterMotionControl;
	import game.components.scene.SceneInteraction;
	import game.data.animation.Animation;
	import game.data.scene.characterDialog.DialogData;
	import game.data.sound.SoundModifier;
	import game.data.tutorials.ShapeData;
	import game.data.tutorials.StepData;
	import game.data.tutorials.TextData;
	import game.data.ui.ToolTipType;
	import game.scenes.con1.roofRace.RoofRace;
	import game.scenes.con1.shared.Poptropicon1Scene;
	import game.scenes.con1.shared.RandomNPCCreator;
	import game.scenes.con1.shared.RandomNPCGroup;
	import game.scenes.con1.shared.popups.Selfie;
	import game.scenes.custom.AdMiniBillboard;
	import game.ui.costumizer.Costumizer;
	import game.ui.elements.DialogPicturePopup;
	import game.ui.hud.Hud;
	import game.ui.tutorial.TutorialGroup;
	import game.util.AudioUtils;
	import game.util.CharUtils;
	import game.util.DisplayUtils;
	import game.util.EntityUtils;
	import game.util.PlatformUtils;
	import game.util.SceneUtil;
	import game.util.SkinUtils;
	import game.util.TimelineUtils;
	
	public class Center extends Poptropicon1Scene
	{
		public function Center()
		{
			super();
		}
		
		// pre load setup
		override public function init(container:DisplayObjectContainer = null):void
		{			
			super.groupPrefix = "scenes/con1/center/";
			if(!shellApi.checkEvent(_events.SKIP_INTRO))
				SceneUtil.removeIslandParts(this);
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
			
			var minibillboard:AdMiniBillboard = new AdMiniBillboard(this,super.shellApi, new Point(3245, 1215));	

			if(!shellApi.checkEvent(_events.SKIP_INTRO))
			{
				showIntroPopup();	
			}
			else
			{
				addRandomNPCs();
			}			
			
			getEntityById("costumeInteraction").get(SceneInteraction).reached.add(clickedCloset);
			
			
			var wizardSoda:Entity = getEntityById("wizard_soda");
			CharUtils.getRigAnim(wizardSoda).ended.add(wizardAnimation);
			Dialog(getEntityById("fantasy").get(Dialog)).complete.add(fantasyDialogFinished);
			TimelineUtils.convertClip(_hitContainer["reader"], this);
			var bus:Entity = EntityUtils.createSpatialEntity(this, _hitContainer["busAudio"]);
			var busAudio:Audio = new Audio();
			bus.add(busAudio);
			bus.add(new AudioRange(1600, 0, 1, Sine.easeIn));
			busAudio.play(SoundManager.EFFECTS_PATH + "bus_engine_idle_01_loop.mp3", true, [SoundModifier.POSITION, SoundModifier.FADE]);
			
			var noonInteraction:Entity = getEntityById("noonInteraction");
			if(noonInteraction)
			{
				if(shellApi.checkEvent("viking1" + _events.QUEST_ACCEPTED) && !shellApi.checkEvent("viking1" + _events.QUEST_COMPLETE))
					noonInteraction.get(Interaction).click.addOnce(clickedNoonSign);
				else
				{
					EntityUtils.removeInteraction(noonInteraction);
					this.removeEntity(noonInteraction, true);
				}
			}
			
			setupLampPosts();
		}
		
		private function addRandomNPCs():void
		{			
			_hitContainer.setChildIndex(getEntityById("costume").get(Display).displayObject, 0);
			
			var firstGroup:RandomNPCGroup = new RandomNPCGroup("randomNPC1", 1780, 1, 2, 5, 20, 200, 240, 2, 1);
			addChildGroup(firstGroup);
			
			var creator:RandomNPCCreator = new RandomNPCCreator(this, "scenes/con1/shared/randomNPC2.xml");
			firstGroup.setup(hitContainer, this, creator);
			
			if(!PlatformUtils.isMobileOS)
				firstGroup.ready.addOnce(Command.create(addSecondGroup, 1, creator));
		}
		
		private function addSecondGroup(group:Group, index:Number, creator:RandomNPCCreator):void
		{
			var secondGroup:RandomNPCGroup = new RandomNPCGroup("randomNPC2", 1765, 2, 3, 80, 99, 170, 200, 3, index);
			addChildGroup(secondGroup);		
			
			secondGroup.setup(_hitContainer, this, creator);
		}
		
		private function wizardAnimation(animation:Animation):void
		{
			if(animation.data.name == "focus")
				AudioUtils.play(this, SoundManager.EFFECTS_PATH + "machine_impact_01.mp3");
		}
		
		private function fantasyDialogFinished(dialogData:DialogData):void
		{
			if(dialogData.event == "friend_quest_accepted" || dialogData.id == "show_selfie")
			{
				addChildGroup(new Selfie(overlayContainer));
			}
		}
		
		private function setupLampPosts():void
		{
			for(var index:int = 1; index <= 2; ++index)
			{
				var bitmap:Bitmap = this.createBitmap(this._hitContainer["lampPost" + index]);
				bitmap.parent.addChild(bitmap);
			}
		}
		
		override public function handleEventTrigger(event:String, makeCurrent:Boolean = true, init:Boolean = false, removeEvent:String = null):void
		{
			if(event == _events.START_TUTORIAL)
			{
				shellApi.defaultCursor = ToolTipType.NAVIGATION_ARROW;
				var hud:Hud = getGroupById(Hud.GROUP_ID) as Hud;
				
				var stepDatas:Vector.<StepData> = new Vector.<StepData>();
				var shapes:Vector.<ShapeData> = new Vector.<ShapeData>();
				var texts:Vector.<TextData> = new Vector.<TextData>();
				
				var hudButton:Entity = hud.getButtonById(Hud.HUD);
				var hudButtonSpatial:Spatial = hudButton.get(Spatial);
				
				shapes.push(new ShapeData(ShapeData.CIRCLE, new Point(hudButtonSpatial.x, hudButtonSpatial.y), 60, 60, "greenShirt", null, null, hudButton.get(Interaction)));
				texts.push(new TextData("First, click on the menu button to open the costumizer.", "tutorialwhite", new Point(400*shellApi.viewportWidth/960, 100*shellApi.viewportHeight/640)));
				var clickHud:StepData = new StepData("hud", TUTORIAL_ALPHA, 0x000000, 1.5, true, shapes, texts);
				stepDatas.push(clickHud);	
				
				shapes = new Vector.<ShapeData>();
				texts = new Vector.<TextData>();
				shapes.push(new ShapeData(ShapeData.CIRCLE, new Point(shellApi.viewportWidth - 200, 42), 40, 40, "npc", null, costumizerLoaded, null, hud.openingHudElement));
				texts.push(new TextData("Then, click on the green shirt to open the costumizer.", "tutorialwhite", new Point(500*shellApi.viewportWidth/960, 100*shellApi.viewportHeight/640)));
				var clickCostumizer:StepData = new StepData("greenShirt", TUTORIAL_ALPHA, 0x000000, 2, true, shapes, texts);
				stepDatas.push(clickCostumizer);
				
				_tutorialGroup = new TutorialGroup(overlayContainer, stepDatas);
				_tutorialGroup.complete.addOnce(tutorialFinished);
				this.addChildGroup(_tutorialGroup);
				_tutorialGroup.start();
			}
			else if(event == _events.NO_TUTORIAL)
			{
				CharUtils.lockControls(player, false ,false);
				getEntityById("costume").get(Interaction).lock = false;
				shellApi.defaultCursor = ToolTipType.NAVIGATION_ARROW;
				addRandomNPCs();
			}
			else if(event == _events.PLAY_RACE)
			{
				shellApi.loadScene(RoofRace);
			}
			
			super.handleEventTrigger(event, makeCurrent, init, removeEvent);
		}
		
		private function costumizerLoaded():void
		{
			var costumizer:Costumizer = getGroupById(Costumizer.GROUP_ID) as Costumizer;
			var costumeNPC:Entity = getEntityById("costume");
			var costumeUILoc:Point = DisplayUtils.localToLocal(costumeNPC.get(Display).displayObject, overlayContainer);
			costumeUILoc.x -= 52;
			costumeUILoc.y -= 105;
			
			var shapes:Vector.<ShapeData> = new Vector.<ShapeData>();
			var texts:Vector.<TextData> = new Vector.<TextData>();
			shapes.push(new ShapeData(ShapeData.RECTANGLE, costumeUILoc, 115, 155, "hatsOrParts", null, null, null, costumizer.onNPCSelected));
			texts.push(new TextData("Click on me to copy part of my outfit.", "tutorialwhite", new Point(200*shellApi.viewportWidth/960, 420*shellApi.viewportHeight/640)));
			var clickLady:StepData = new StepData("npc", TUTORIAL_ALPHA, 0x000000, 3, true, shapes, texts);
			_tutorialGroup.addStep(clickLady);
			
			costumizer.onNPCSelected.addOnce(Command.create(charSelected, costumizer));
		}
		
		private function charSelected(char:Entity, costumizer:Costumizer):void
		{
			costumizer.allCharsLoaded.addOnce(costumizerReady);
		}
		
		private function costumizerReady(costumizer:Costumizer):void
		{
			var shapes:Vector.<ShapeData> = new Vector.<ShapeData>();
			var texts:Vector.<TextData> = new Vector.<TextData>();
			var char:Entity = costumizer.getEntityById(costumizer.MODEL);
			var scarf:Entity = SkinUtils.getSkinPartEntity(char, SkinUtils.OVERSHIRT);
			var rect:Rectangle = EntityUtils.getDisplayObject(scarf).getBounds(costumizer.screen.content.panel_L);
			shapes.push(new ShapeData(ShapeData.ELLIPSE, rect.topLeft, rect.width, rect.height, "accept", "partTray", null, null, costumizer.onNPCPartSelected));
			shapes.push(new ShapeData(ShapeData.RECTANGLE, new Point(5, shellApi.viewportHeight - 200), 100, 100, "partTray", null, null, costumizer.partsTrayButton.get(Interaction)));
			texts.push(new TextData("Click on my scarf to costumize it...", "tutorialwhite", new Point(160*shellApi.viewportWidth/960, 200*shellApi.viewportHeight/640)));
			texts.push(new TextData("Or click this to see what you can costumize from me.", "tutorialgreen", new Point(150*shellApi.viewportWidth/960, 460*shellApi.viewportHeight/640)));
			var clickHatOrParts:StepData = new StepData("hatsOrParts", TUTORIAL_ALPHA, 0x000000, 2, true, shapes, texts);
			_tutorialGroup.addStep(clickHatOrParts);
			
			shapes = new Vector.<ShapeData>();
			texts = new Vector.<TextData>();
			shapes.push(new ShapeData(ShapeData.RECTANGLE, new Point(shellApi.viewportWidth -733, shellApi.viewportHeight - 90), 100, 90, "accept", null, null, null, costumizer.onPartTraySelected));
			texts.push(new TextData("Here you can select the scarf.", "tutorialwhite", new Point(shellApi.viewportWidth-810, shellApi.viewportHeight - 190)));
			var partsHat:StepData = new StepData("partTray", TUTORIAL_ALPHA, 0x000000, 2, true, shapes, texts);
			_tutorialGroup.addStep(partsHat);
			
			var acceptSpatial:Spatial = costumizer.acceptButton.get(Spatial);
			var cancelSpatial:Spatial = costumizer.cancelButton.get(Spatial);
			shapes = new Vector.<ShapeData>();
			texts = new Vector.<TextData>();
			shapes.push(new ShapeData(ShapeData.CIRCLE, new Point(acceptSpatial.x, acceptSpatial.y), 50, 50, null,  null, null, costumizer.acceptButton.get(Interaction)));
			shapes.push(new ShapeData(ShapeData.CIRCLE, new Point(cancelSpatial.x, cancelSpatial.y), 50, 50, null,  null, null, costumizer.cancelButton.get(Interaction)));
			texts.push(new TextData("Click the checkmark to accept your changes.", "tutorialwhite", new Point(350*shellApi.viewportWidth/960, 150*shellApi.viewportHeight/640)));
			texts.push(new TextData("Click the X to cancel your changes.", "tutorialwhite", new Point(600*shellApi.viewportWidth/960, 250*shellApi.viewportHeight/640)));
			var accept:StepData = new StepData("accept", TUTORIAL_ALPHA, 0x000000, .5, true, shapes, texts);
			_tutorialGroup.addStep(accept);
		}
		
		private function tutorialFinished(group:DisplayGroup):void
		{
			addRandomNPCs();
			CharUtils.lockControls(player, false ,false);
			this.removeGroup(group);
			
			var costume:Entity = getEntityById("costume");
			costume.get(Interaction).lock = false;
			costume.get(Dialog).sayById("tutorial_done");
		}
		
		private function showIntroPopup():void
		{
			var introPopup:DialogPicturePopup = new DialogPicturePopup(overlayContainer);
			introPopup.updateText("Poptropicon is the hottest ticket in town. Find a way inside!", "Start");
			introPopup.configData("introPopup.swf", "scenes/con1/shared/introPopup/");
			introPopup.popupRemoved.addOnce(introClosed);
			addChildGroup(introPopup);
		}
		
		private function introClosed():void
		{
			shellApi.completeEvent(_events.SKIP_INTRO);
			
			var spatial:Spatial = getEntityById("costume").get(Spatial)
			
			SceneUtil.lockInput(this, true, true);
			CharUtils.moveToTarget(player, spatial.x - 100, spatial.y + 25, true, playerAtCostume);
			CharacterMotionControl(player.get(CharacterMotionControl)).jumpVelocity = -5;
		}
		
		private function playerAtCostume(entity:Entity):void
		{
			var costume:Entity = getEntityById("costume");
			costume.get(Interaction).lock = true;
			
			var dialog:Dialog = costume.get(Dialog);
			dialog.sayById("ask_tutorial");
			dialog.complete.addOnce(costumeDoneTalking);
			
			CharUtils.setDirection(player, true);
			CharacterMotionControl(player.get(CharacterMotionControl)).jumpVelocity = -900;
		}
		
		private function costumeDoneTalking(...args):void
		{
			SceneUtil.lockInput(this, false, false);
			CharUtils.lockControls(player);
		}
		
		private function clickedNoonSign(entity:Entity):void
		{
			EntityUtils.removeInteraction(entity);
			this.removeEntity(entity, true);
			player.get(Dialog).sayById("noon");
			shellApi.triggerEvent("viking1" + _events.QUEST_COMPLETE, true);
		}
		
		private function clickedCloset(entity:Entity, clicker:Entity):void
		{
			this.pause(true, true);
			var costumizer:Costumizer = new Costumizer( null, null, false, true );
			addChildGroup( costumizer );
			costumizer.unpause(true, true);
			costumizer.init(this.overlayContainer);
			costumizer.popupRemoved.addOnce(costumizerClosed)
		}
		
		private function costumizerClosed():void
		{
			this.unpause(true, true);
		}
		
		private var _tutorialGroup:TutorialGroup;
		private const TUTORIAL_ALPHA:Number = .85;
	}
}