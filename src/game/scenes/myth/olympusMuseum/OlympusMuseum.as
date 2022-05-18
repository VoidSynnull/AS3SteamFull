package game.scenes.myth.olympusMuseum{
	import flash.display.DisplayObjectContainer;
	import flash.display.Sprite;
	import flash.geom.Point;
	
	import ash.core.Entity;
	
	import engine.components.Display;
	import engine.components.Id;
	import engine.components.Spatial;
	import engine.creators.InteractionCreator;
	import engine.util.Command;
	
	import game.components.entity.Dialog;
	import game.components.entity.character.Character;
	import game.components.hit.Zone;
	import game.components.motion.Edge;
	import game.components.scene.SceneInteraction;
	import game.data.scene.characterDialog.DialogData;
	import game.scene.template.AudioGroup;
	import game.scenes.myth.shared.MythScene;
	import game.util.SceneUtil;
	
	public class OlympusMuseum extends MythScene
	{
		public function OlympusMuseum()
		{
			super();
		}
		
		// pre load setup
		override public function init(container:DisplayObjectContainer = null):void
		{			
			super.groupPrefix = "scenes/myth/olympusMuseum/";
			super.init(container);
			cameraTargets = new Vector.<Entity>();
			dialogEnts = new Vector.<Entity>();
		}
		
		// initiate asset load of scene specific assets.
		override public function load():void
		{
			super.load();
		}
		
		// all assets ready
		override public function loaded():void
		{
			//camMoved = new Signal0();
			super.loaded();
			super.shellApi.eventTriggered.add(eventTriggers);
			setupInfoPlaques();
			setupTourPanning();
			setUpTourButton();
			setupTourStartZone();
		}
		
		
		override protected function addGroups():void
		{
			// This group holds a reference to the parsed sound.xml data and can be used to setup an entity with its sound assets if they are defined for it in the xml.
			var audioGroup:AudioGroup = addAudio();
			
			super.addCamera();
			super.addCollisions(audioGroup);
			super.addCharacters();
			addCharacterDialog(this.uiLayer);
			addUI(this.uiLayer);
			super.addDoors(audioGroup);
			super.addItems();
			super.addPhotos();
			addBaseSystems();
		}
		
		override protected function addCharacterDialog(container:Sprite):void
		{
			setupTourDialog();
			super.addCharacterDialog(container);
		}
		
		// process incoming events
		private function eventTriggers(event:String, save:Boolean = true, init:Boolean = false, removeEvent:String = null):void
		{
			
		}
		
		private function setupInfoPlaques():void
		{
			var plaqueCount:int = 14;
			for (var i:int = 1; i <= plaqueCount; i++) 
			{
				var infoId:String =  "infoInteraction"+i;							
				SceneInteraction(super.getEntityById(infoId).get(SceneInteraction)).reached.add(Command.create(playInfo, infoId));
			}	
		}
		
		private function playInfo( character:Entity, interactionEntity:Entity, infoId:String):void
		{
			var dialog:Dialog = player.get(Dialog);
			dialog.sayById(infoId);
		}
		
		private function setupTourDialog():void
		{
			// dialog for museum tour sequence
			for (var i:int = 1; i <= 8; i++) 
			{
				var entity:Entity = new Entity();
				var dialog:Dialog = new Dialog()
				dialog.faceSpeaker = true;
				dialog.dialogPositionPercents = new Point(0, 1);
				
				entity.add(dialog);
				entity.add(new Id("customDialog"+i));
				entity.add(new Spatial());
				entity.add(new Display(_hitContainer["customDialog"+i]));
				entity.add(new Edge(30, 30, 30, 30));
				entity.add(new Character());
				
				InteractionCreator.addToEntity(entity, [InteractionCreator.CLICK]);
				var sceneInteraction:SceneInteraction = new SceneInteraction();
				sceneInteraction.offsetX = 120;
				sceneInteraction.offsetY = 0;
				entity.add(sceneInteraction);
				super.addEntity(entity);
				dialogEnts.push(entity);				
			}
		}
		
		private function setUpTourButton():void
		{
			var infoId:String =  "interactionStart";				
			var infoEnt:Entity = getEntityById(infoId);				
			SceneInteraction(super.getEntityById(infoId).get(SceneInteraction)).reached.add(runMuseumTour);
		}
		
		private function setupTourPanning():void
		{
			// 0 index is player
			cameraTargets.push(player);			
			// camera waypoints for museum tour sequence
			for (var i:int = 1; i <= 8; i++) 
			{
				var entity:Entity = new Entity();

				entity.add(new Id("pan"+i));
				entity.add(new Spatial());
				entity.add(new Display(_hitContainer["pan"+i]));
				
				super.addEntity(entity);
				cameraTargets.push(entity);
			}
		}
		
		// start sequence
		private function runMuseumTour(character:Entity = null, interactionEntity:Entity = null):void
		{
			SceneUtil.lockInput(this,true);
			advanceMuseumTour();
			// add complete triggers to advance the plot
			for (var i:int = 0; i < dialogEnts.length; i++) 
			{
				Dialog(dialogEnts[i].get(Dialog)).complete.addOnce(advanceMuseumTour);
			}
			Dialog(dialogEnts[0].get(Dialog)).sayById("talk1");	
		}
		private function triggerMuseumTour( zoneId:String ="", characterId:String =""):void
		{
			if(!shellApi.checkEvent("museum_toured")){
				runMuseumTour();
			}
		}
		
		// next camera loc
		private function advanceMuseumTour(dialogData:DialogData=null):void
		{
			if(tourIndex < cameraTargets.length -1){
				tourIndex++;	
				SceneUtil.setCameraTarget( this, cameraTargets[tourIndex]);			
			}
			else
			{
				endMuseumTour();
			}
		}
		
		// return control to player
		private function endMuseumTour():void
		{
			tourIndex = 0;
			SceneUtil.setCameraTarget( this, cameraTargets[tourIndex]);
			SceneUtil.lockInput(this,false);
			shellApi.completeEvent("museum_toured");
		}
		
		private function setupTourStartZone():void
		{
			if(!shellApi.checkEvent("museum_toured")){
				var hit:Entity = super.getEntityById("zone1");
				var zone:Zone = hit.get(Zone);
				zone.pointHit = true;
				zone.entered.addOnce( triggerMuseumTour);
			}
		}
		
		private var tourIndex:Number = 0;
		private var cameraTargets:Vector.<Entity>;
		private var dialogEnts:Vector.<Entity>;
	}
}