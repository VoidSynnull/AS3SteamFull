package game.scenes.mocktropica.poptropicaHQ
{
	{
		import com.greensock.easing.Sine;
		
		import flash.display.DisplayObjectContainer;
		import flash.display.MovieClip;
		import flash.events.Event;
		import flash.events.MouseEvent;
		import flash.geom.Point;
		
		import ash.core.Entity;
		
		import engine.components.Display;
		import engine.components.Id;
		import engine.components.Spatial;
		import engine.managers.SoundManager;
		import engine.util.Command;
		
		import game.scenes.mocktropica.MocktropicaEvents;
		import game.systems.dragAndDrop.Drag;
		import game.systems.dragAndDrop.DragDropGroup;
		import game.ui.popup.Popup;
		import game.util.AudioUtils;
		import game.util.EntityUtils;
		import game.util.TweenUtils;
		import game.util.Utils;
		
		public class TrashCanPopup extends Popup
		{
			private var mockEvents:MocktropicaEvents;
			private var content:MovieClip;
			
			public function TrashCanPopup(container:DisplayObjectContainer=null)
			{
				super(container);
			}
			
			override public function init(container:DisplayObjectContainer = null):void
			{
				super.groupPrefix = "scenes/mocktropica/poptropicaHQ/";
				super.screenAsset = "trashCanPopup.swf";
				
				super.darkenBackground = true;
				super.init(container);
				load();
			}
			
			override public function loaded():void
			{
				super.loaded();
				setUp();
				super.loadCloseButton();
			}
			
			private function setUp():void
			{
				var i:int;
				content = screen.content as MovieClip;
				
				var dragGroup:DragDropGroup = addChildGroup(new DragDropGroup(content.items)) as DragDropGroup;
				
				dragGroup.configDragAndDrops("drag","drop");
				dragGroup.dispatchForInvalidDrops = true;
				dragGroup.setUpDragAndDrops(checkIfScript);
				dragGroup.pickedUpEntity.add(pickup);
				
				for each (var entity:Entity in dragGroup.dragList)
				{
					Drag(entity.get(Drag)).origin = null;
				}
			}
			
			private function checkIfScript(entity:Entity, target:Entity, valid:Boolean):void
			{
				if(Id(entity.get(Id)).id.indexOf("script") >=0)
				{
					gameWon(entity);
				}
			}
			// play different sounds when different materials are moved
			private function pickup(entity:Entity):void
			{
				var mc:DisplayObjectContainer = EntityUtils.getDisplayObject(entity);
				var snd:String
				if(mc.name.indexOf("envelope") >= 0)
					snd = "put_misc_item_down_01";
				else if(mc.name.indexOf("metal") >= 0)
					snd = "metal_impact_small_01";
				else if(mc.name.indexOf("plastic") >= 0)
					snd = "hollow_plastic_bottle_01";
				else if(mc.name.indexOf("organic") >= 0)
					snd = "flesh_impact_0" +  game.util.Utils.randInRange(4,6);
				else if(mc.name.indexOf("dossier") >= 0 || mc.name.indexOf("script") >= 0)
					snd = snd = "paper_flap_01";
				else
					snd = "drag_trash_0" + game.util.Utils.randInRange(1,3);
				
				AudioUtils.play(this, SoundManager.EFFECTS_PATH + snd + ".mp3");
			}
			//clicked script win
			private function gameWon(entity:Entity):void 
			{
				var spatial:Spatial = entity.get(Spatial);
				var newScale:Number = spatial.scaleX * 2;
				var newRot:Number = spatial.rotation + 90;
				TweenUtils.entityTo(entity,Spatial,.7,{scaleX:newScale, scaleY:newScale, ease:Sine.easeInOut, rotation:newRot,onComplete:Command.create(scriptScaleAnimComplete,entity)});
				
				AudioUtils.play(this, SoundManager.MUSIC_PATH + "important_item.mp3");
			}
			
			private function scriptScaleAnimComplete(entity:Entity):void 
			{
				var spatial:Spatial = entity.get(Spatial);
				var newScale:Number = spatial.scaleX * .8;
				TweenUtils.entityTo(entity,Spatial,.6,{scaleX:newScale, scaleY:newScale,yoyo:true, repeat:3, ease:Sine.easeInOut, onComplete:winAnimComplete})
			}
			
			private function winAnimComplete (): void 
			{
				shellApi.triggerEvent(mockEvents.SCRIPT, true);
				shellApi.getItem(mockEvents.SCRIPT,null,true );
				super.close();
			}
			
			override public function close( removeOnClose:Boolean = true, onCloseHandler:Function = null ):void
			{
				super.close();
			}
		}
	}
}