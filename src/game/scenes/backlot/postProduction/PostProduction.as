package game.scenes.backlot.postProduction
{
	import flash.display.DisplayObjectContainer;
	import flash.geom.Point;
	
	import ash.core.Entity;
	
	import engine.components.Display;
	import engine.components.Id;
	import engine.components.Interaction;
	import engine.creators.InteractionCreator;
	
	import game.components.animation.FSMControl;
	import game.components.entity.Dialog;
	import game.components.entity.character.CharacterMotionControl;
	import game.components.scene.SceneInteraction;
	import game.creators.ui.ToolTipCreator;
	import game.data.game.GameEvent;
	import game.scenes.backlot.BacklotEvents;
	import game.data.ui.ToolTipType;
	import game.scene.template.PlatformerGameScene;
	import game.scenes.backlot.shared.popups.FilmEditorPopup;
	import game.scenes.backlot.shared.popups.FoleyGamePopup;
	import game.util.CharUtils;
	import game.util.EntityUtils;
	import game.util.SceneUtil;
	
	public class PostProduction extends PlatformerGameScene
	{
		public function PostProduction()
		{
			super();
		}
		
		// pre load setup
		override public function init(container:DisplayObjectContainer = null):void
		{			
			super.groupPrefix = "scenes/backlot/postProduction/";
			
			super.init(container);
		}
		
		// initiate asset load of scene specific assets.
		override public function load():void
		{
			super.load();
		}
		private var backlot:BacklotEvents;
		private var carson:Entity;
		private var filmEditor:FilmEditorPopup;
		private var foleyEditor:FoleyGamePopup;
		
		// all assets ready
		override public function loaded():void
		{
			super.loaded();
			
			backlot = events as BacklotEvents;
			shellApi.eventTriggered.add(onEventTrigger);
			
			setUpNPCs();
			
			setUpEditingBay();
			setUpFoleyZone();
		}
		
		private function onEventTrigger(event:String, makeCurrent:Boolean = true, init:Boolean = false, removeEvent:String = null):void
		{
			if(event == backlot.MOVE_TO_EDITING || event == backlot.MOVE_TO_FOLEY)
			{
				moveToStation(event);
			}
			if(event == backlot.FINISHED_TALKING)
			{
				SceneUtil.lockInput(this, false);
			}
			
			if(event == GameEvent.GOT_ITEM + backlot.REELS)
			{
				SceneUtil.lockInput(this, false);
				SceneInteraction(carson.get(SceneInteraction)).reached.removeAll();
			}
			
			if(event == backlot.COMPLETE_EDITING)
			{
				removeEntityInteraction(getEntityById("editingBay"));
				setUpNPCs();
			}
			
			if(event == backlot.COMPLETE_FOLEY)
			{
				removeEntityInteraction(getEntityById("folleyClick"));
				setUpNPCs();
			}
		}
		
		private function removeEntityInteraction(entity:Entity):void
		{
			entity.remove(SceneInteraction);
			entity.remove(Interaction);
			ToolTipCreator.addToEntity(entity, ToolTipType.NAVIGATION_ARROW);
		}
		
		private function moveToStation(stationEvent:String):void
		{
			SceneUtil.lockInput(this, false);
			var destination:Point = new Point();
			
			switch(stationEvent)
			{
				case backlot.MOVE_TO_EDITING:
				{
					Dialog(carson.get(Dialog)).setCurrentById("excise errors");
					destination = new Point(150, 475);
					break;
				}
				case backlot.MOVE_TO_FOLEY:
				{
					Dialog(carson.get(Dialog)).setCurrentById("add sound");
					destination = new Point(1800, 475);
					break;
				}
			}
			
			CharUtils.moveToTarget(carson, destination.x, destination.y);
			FSMControl(carson.get(FSMControl)).active = true;
			CharacterMotionControl(carson.get(CharacterMotionControl)).maxVelocityX = 200;
		}
		
		private function setUpNPCs():void
		{
			carson = getEntityById("char1");
			var sceneInteraction:SceneInteraction = carson.get(SceneInteraction);
			if(!shellApi.checkHasItem(backlot.REELS))
			{
				sceneInteraction.reached.remove(stopAndListen);
				sceneInteraction.reached.add(stopAndListen);
			}
			if(!shellApi.checkEvent(backlot.COMPLETE_EDITING))
			{
				if(!shellApi.checkEvent(backlot.COMPLETE_FOLEY))
					Dialog(carson.get(Dialog)).setCurrentById("filming");
				else
					Dialog(carson.get(Dialog)).setCurrentById("excise");
			}
			else
			{
				if(!shellApi.checkEvent(backlot.COMPLETE_MOVIE_EDITING))
					Dialog(carson.get(Dialog)).setCurrentById("sound");
				//else
					//Dialog(carson.get(Dialog)).setCurrentById("film_and_sound_done");
			}
		}
		
		private function stopAndListen(player:Entity, entity:Entity):void
		{
			SceneUtil.lockInput(this);
		}
		
		private function setUpEditingBay():void
		{
			if(shellApi.checkEvent(backlot.COMPLETE_EDITING))
				return;
			
			var editingBay:Entity = EntityUtils.createSpatialEntity(this, _hitContainer["editingBay"], _hitContainer);
			editingBay.add(new Id("editingBay"));
			Display(editingBay.get(Display)).moveToBack();
			editingBay.add(new SceneInteraction());
			InteractionCreator.addToEntity(editingBay,[InteractionCreator.CLICK],_hitContainer["editingBay"]);
			var interaction:SceneInteraction = editingBay.get(SceneInteraction);
			interaction.reached.add(startEditing);
			ToolTipCreator.addToEntity(editingBay)
		}
		
		private function startEditing(player:Entity, entity:Entity):void
		{
			//trace("bring up editing popup");
			filmEditor = super.addChildGroup( new FilmEditorPopup( super.overlayContainer )) as FilmEditorPopup;
		}
		
		private function setUpFoleyZone():void
		{
			if(shellApi.checkEvent(backlot.COMPLETE_FOLEY))
				return;
			
			var foleyClickZone:Entity = EntityUtils.createSpatialEntity(this, _hitContainer["foleyClickZone"], _hitContainer);
			foleyClickZone.add(new Id("folleyClick"));
			foleyClickZone.add(new SceneInteraction());
			InteractionCreator.addToEntity(foleyClickZone,[InteractionCreator.CLICK],_hitContainer["foleyClickZone"]);
			var interaction:SceneInteraction = foleyClickZone.get(SceneInteraction);
			interaction.reached.add(startFoley);
			ToolTipCreator.addToEntity(foleyClickZone)
		}		
		
		private function startFoley(player:Entity, entity:Entity):void
		{
			//trace("bring up foley popup");
			foleyEditor = super.addChildGroup( new FoleyGamePopup( super.overlayContainer )) as FoleyGamePopup;
		}
	}
}