package game.scenes.deepDive1.shared
{
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.display.Sprite;
	import flash.geom.Point;
	
	import ash.core.Entity;
	
	import engine.components.Display;
	import engine.components.Spatial;
	import engine.components.Tween;
	
	import game.creators.ui.ButtonCreator;
	import game.data.display.BitmapWrapper;
	import game.data.ui.TransitionData;
	import game.scenes.deepDive1.DeepDive1Events;
	import game.ui.popup.Popup;
	
	public class FishPopup extends Popup
	{
		public function FishPopup(container:DisplayObjectContainer=null)
		{
			super(container);
		}
		
		override public function destroy():void
		{
			// call the super class's 'destroy()' method as well to finish cleanup of this group which removes any entites and systems specific to this group, as well as removing the groupContainer.
			super.destroy();
		}
		
		// pre load setup
		override public function init(container:DisplayObjectContainer = null):void
		{
			
			// setup the transitions 
			super.transitionIn = new TransitionData();
			super.transitionIn.duration = .3;
			super.transitionIn.startPos = new Point(0, -super.shellApi.viewportHeight - 150);
			
			// this shortcut method flips the start and end position of the transitionIn
			super.transitionOut = super.transitionIn.duplicateSwitch();
			
			super.darkenBackground = true;
			super.groupPrefix = "scenes/deepDive1/shared/";
			super.init(container);
			load();
		}
		
		// initiate asset load of scene specific assets.
		override public function load():void
		{
			//super.shellApi.fileLoadComplete.addOnce(loaded);
			super.loadFiles(["ledgerPopup.swf"],false,true,loaded);
		}
		
		override public function loaded():void
		{
			//trace("asset:"+super.getAsset("posterPopup.swf", true));
			super.screen = super.getAsset("ledgerPopup.swf", true) as MovieClip;
			
			//DisplayPositionUtils.centerWithinDimensions(super.screen.content, this.shellApi.viewportWidth, this.shellApi.viewportHeight, 986, 733.45);
			//this.fitToDimensions(this.screen.background, true);
			
			// this loads the standard close button
			super.loadCloseButton();
			
			//super.layout.centerUI(this.screen.content);  // this is returning an error saying that content is not found on __preloader__ ??
			
			//this.centerWithinDimensions(this.screen.content);
			
			super.loaded();

			initEntities();
			initCompletions();
			
			// bitmap pages
			for(var c:int = 1; c <= 5; c++){
				var bmw:BitmapWrapper = this.convertToBitmapSprite(Sprite(super.screen.content["page"+c]["page"]), super.screen.content["page"+c], true);
				bmw.bitmap.smoothing = true;
			}
		}
		
		private function initCompletions():void
		{
			if(!super.shellApi.checkEvent(_events.ANGLER_CAPTURED)){
				super.screen.content.page1.page.photo.visible = false;
				super.screen.content.page1.page.complete.visible = false;
			}
			if(!super.shellApi.checkEvent(_events.BARRELEYE_CAPTURED)){
				super.screen.content.page2.page.photo.visible = false;
				super.screen.content.page2.page.complete.visible = false;
			}
			if(!super.shellApi.checkEvent(_events.CUTTLEFISH_CAPTURED)){
				super.screen.content.page3.page.photo.visible = false;
				super.screen.content.page3.page.complete.visible = false;
			}
			if(!super.shellApi.checkEvent(_events.SEADRAGON_CAPTURED)){
				super.screen.content.page4.page.photo.visible = false;
				super.screen.content.page4.page.complete.visible = false;
			}
			if(!super.shellApi.checkEvent(_events.STONEFISH_CAPTURED)){
				super.screen.content.page5.page.photo.visible = false;
				super.screen.content.page5.page.complete.visible = false;
			}
		}
		
		private function initEntities():void
		{
			for(var c:int = 1; c <= 5; c++){
				
				var pageEntity:Entity = new Entity();
				pageEntity.add(new Display(super.screen.content["page"+c]));
				
				//var pageEntity:Entity = ButtonCreator.createButtonEntity(super.screen.content["page"+c], this, onPage);
				pageEntity.add(new Tween());
				
				ButtonCreator.assignButtonEntity(pageEntity, super.screen.content["page"+c], this, onPage);
				
				_pages.push(pageEntity);
				
				super.addEntity(pageEntity);
			}
		}		
		
		private function onPage($entity):void
		{
			super.screen.content.setChildIndex(Display($entity.get(Display)).displayObject, super.screen.content.numChildren - 1);
			
			// stack down pages on left and right
			
			var selectIndex:int;
			var c:int;
			var d:int;
			
			for(c = 0; c < _pages.length; c++){
				if(_pages[c] == $entity){
					selectIndex = c;
					break;
				}
			}
			
			c = selectIndex;
			d = 2;
			
			// stack pages on left
			while(c > 0){
				c--;
				super.screen.content.setChildIndex(Display(_pages[c].get(Display)).displayObject, super.screen.content.numChildren - d);
				d++;
			}
			
			c = selectIndex;
			
			// stack pages on right
			while(c < 4){
				c++;
				super.screen.content.setChildIndex(Display(_pages[c].get(Display)).displayObject, super.screen.content.numChildren - d);
				d++;
			}
			
			// visual feedback for selecting page
			var tween:Tween = $entity.get(Tween);
			Display($entity.get(Display)).displayObject.scaleX = 1.04;
			Display($entity.get(Display)).displayObject.scaleY = 1.04;
			tween.to(Display($entity.get(Display)).displayObject, 0.3, {scaleX:1, scaleY:1});
		}

		private var _pages:Vector.<Entity> = new Vector.<Entity>;
		private var _events:DeepDive1Events;
		
	}
}