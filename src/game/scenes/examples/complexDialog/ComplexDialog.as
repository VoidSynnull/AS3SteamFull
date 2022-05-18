package game.scenes.examples.complexDialog
{
	import flash.display.DisplayObjectContainer;
	import flash.display.Sprite;
	import flash.geom.Point;
	
	import ash.core.Entity;
	
	import engine.components.Camera;
	import engine.components.Display;
	import engine.components.Id;
	import engine.components.Spatial;
	import engine.creators.InteractionCreator;
	
	import game.components.entity.Dialog;
	import game.components.entity.character.Character;
	import game.components.motion.Edge;
	import game.components.scene.SceneInteraction;
	import game.data.scene.characterDialog.DialogData;
	import game.scene.template.PlatformerGameScene;
	import game.util.CharUtils;
	
	public class ComplexDialog extends PlatformerGameScene
	{
		public function ComplexDialog()
		{
			super();
		}
		
		// pre load setup
		override public function init(container:DisplayObjectContainer = null):void
		{			
			super.groupPrefix = "scenes/examples/complexDialog/";
			
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
			
			super.shellApi.eventTriggered.add(handleEventTriggered);
		}
				
		private function handleEventTriggered(event:String, save:Boolean = true, init:Boolean = false, removeEvent:String = null):void
		{
			if(event == "playerSmall")
			{
				CharUtils.setScale(super.player, .2);
			}
			else if(event == "playerBig")
			{
				CharUtils.setScale(super.player, .8);
			}
			else if(event == "playerNormal")
			{
				CharUtils.setScale(super.player, .4);
			}
		}
		
		private function setupCustomDialog():void
		{
			var entity:Entity = new Entity();
			var dialog:Dialog = new Dialog()
			dialog.faceSpeaker = true;     // the display will turn towards the player if true.
			dialog.dialogPositionPercents = new Point(0, 1);  // set the percent of the bounds that the dialog is offset.  The current arts will cause it to be offset 0% on x axis and 100% on y (66px).
	
			entity.add(dialog);
			entity.add(new Id("customDialog"));
			entity.add(new Spatial());
			entity.add(new Display(_hitContainer["customDialog"]));
			entity.add(new Edge(33, 66, 33, 0));   //set the distance from the characters registration point.
			entity.add(new Character());           //allows this entity to get picked up by the characterInteractionSystem for dialog on click
			
			InteractionCreator.addToEntity(entity, [InteractionCreator.DOWN]);
			var sceneInteraction:SceneInteraction = new SceneInteraction();
			sceneInteraction.offsetX = 120;
			sceneInteraction.offsetY = 0;
			entity.add(sceneInteraction);
			
			super.addEntity(entity);
		}
		
		override protected function addCharacterDialog(container:Sprite):void
		{
			// custom dialog entity MUST be added here so that dialog from the xml gets assigned to it.
			setupCustomDialog();
			super.addCharacterDialog(container);
		}
		
		override protected function allCharactersLoaded():void
		{
			super.allCharactersLoaded();
			
			// get a reference to this entity by its id set in npcs.xml
			var wizard:Entity = super.getEntityById("wizard");
			
			// get a reference to this npc's Dialog component and listen for its 'complete' signal.
			Dialog(wizard.get(Dialog)).complete.add(wizardDialogComplete);
			Dialog(wizard.get(Dialog)).start.add(wizardDialogStart);
		}
		
		private function wizardDialogComplete(dialogData:DialogData):void
		{
			trace("wizard done talking! " + dialogData.id);
		}
		
		private function wizardDialogStart(dialogData:DialogData):void
		{
			trace("wizard started talking!" + dialogData.id);
		}
		
		public function cycleZoom():void
		{
			var cameraEntity:Entity = super.getEntityById("camera");
			var camera:Camera = cameraEntity.get(Camera);
			
			if(camera.scaleTarget == .5)
			{
				camera.scaleTarget = 2;
			}
			else if(camera.scaleTarget == 2)
			{
				camera.scaleTarget = 1;
			}
			else
			{
				camera.scaleTarget = .5;
			}
		}
	}
}