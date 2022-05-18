package game.scenes.arab3.vizierRoom.popups
{
	import com.greensock.easing.Bounce;
	import com.greensock.easing.Sine;
	
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.geom.Point;
	
	import ash.core.Entity;
	
	import engine.components.Display;
	import engine.components.Interaction;
	import engine.components.Spatial;
	
	import game.components.timeline.Timeline;
	import game.components.ui.Button;
	import game.components.ui.ToolTip;
	import game.components.ui.ToolTipActive;
	import game.creators.entity.BitmapTimelineCreator;
	import game.creators.ui.ButtonCreator;
	import game.data.ui.TransitionData;
	import game.scenes.arab3.Arab3Events;
	import game.ui.popup.Popup;
	import game.util.EntityUtils;
	
	public class MagicBookPopup extends Popup
	{
		
		private var _events:Arab3Events;
		public var events:Arab3Events;
		private var book:Entity;
		private var currPage:int = 1;
		private var bookClip:MovieClip;
		private var btnLeft:Entity;
		private var btnRight:Entity;
		private var rToolTipActive:ToolTipActive;
		private var lToolTipActive:ToolTipActive;
		
		
		public function MagicBookPopup(container:DisplayObjectContainer = null)
		{
			super(container);
			_events = new Arab3Events();
			
			this.id 				= "MagicBookPopup";
			this.groupPrefix 		= "scenes/arab3/vizierRoom/popups/";
			this.screenAsset 		= "magicBookPopup.swf";
			this.pauseParent 		= true;
			this.darkenBackground 	= true;
		}
		
		override public function destroy():void
		{			
			super.destroy();
		}
		
		override public function init(container:DisplayObjectContainer = null):void
		{
			//this.transitionIn 			= new TransitionData();
			//this.transitionIn.duration 	= 0.3;
			//this.transitionIn.startPos 	= new Point(0, -super.shellApi.viewportHeight);
			//this.transitionIn.endPos 		= new Point(0, 0);
			//this.transitionIn.ease 		= Bounce.easeIn;
			//this.transitionOut 			= transitionIn.duplicateSwitch(Sine.easeIn);
			//this.transitionOut.duration = 0.3;
			
			super.init(container);
			
			this.load();
		}
		
		override public function loaded():void
		{	
			super.loaded();
			
			this.events = this.shellApi.islandEvents as Arab3Events;
			
			this.setupContent();
			this.setupBook();
			super.loadCloseButton();
		}
		
		private function setupBook():void
		{
			var content:MovieClip = this.screen.content;
			content.x = (shellApi.viewportWidth / 2) - (content.width / 2);
			content.y = (shellApi.viewportHeight / 2) - (content.height / 2);
			book = EntityUtils.createSpatialEntity(this, content["book"], content);
			bookClip = book.get(Display).displayObject;
			bookClip.gotoAndStop(1);
			
			btnLeft = ButtonCreator.createButtonEntity(this.screen.content.btnLeft, this, onLeftClick, null, null, null, true, true);	
			btnRight = ButtonCreator.createButtonEntity(this.screen.content.btnRight, this, onRightClick, null, null, null, true, true);
			lToolTipActive = btnLeft.get(ToolTipActive);
			rToolTipActive = btnRight.get(ToolTipActive);
			
			removeButtonFunctionality(btnLeft);
		}
		
		private function onLeftClick(entity:Entity):void
		{
			if(currPage == 5){
				addButtonFunctionality(btnRight);
			}
			if(currPage > 1){
				currPage--;
				bookClip.gotoAndStop(currPage);
			}
			if(currPage == 1){
				removeButtonFunctionality(btnLeft);
			}
		}
		
		private function onRightClick(entity:Entity):void
		{
			if(currPage == 1){
				addButtonFunctionality(btnLeft);
			}
			if(currPage < 5){
				currPage++;
				bookClip.gotoAndStop(currPage);
			}
			if(currPage == 5){
				removeButtonFunctionality(btnRight);
			}
		}
		
		private function removeButtonFunctionality(btn:Entity):void {
			btn.remove(ToolTipActive);
			btn.get(Interaction).lock = true;
		}
		
		private function addButtonFunctionality(btn:Entity):void {
			if(btn == btnLeft){
				btn.add(lToolTipActive);
			} else {
				btn.add(rToolTipActive);
			}
			
			btn.get(Interaction).lock = false;
		}
		
		private function setupContent():void
		{
			var content:MovieClip = this.screen.content;
			content.x *= this.shellApi.viewportWidth / content.width / 2;
			content.y *= this.shellApi.viewportHeight / content.height / 2;
		}
	}
}