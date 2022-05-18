package game.scenes.shrink.bedroomShrunk01.Popups
{
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	
	import ash.core.Entity;
	
	import engine.components.Display;
	
	import game.scenes.shrink.ShrinkEvents;
	import game.ui.popup.Popup;
	import game.util.EntityUtils;
	import game.util.SceneUtil;
	import game.util.TweenUtils;
	
	public class BlankPaperPopup extends Popup
	{
		public function BlankPaperPopup(container:DisplayObjectContainer=null)
		{
			super(container);
		}
		
		override public function init(container:DisplayObjectContainer = null):void
		{
			super.groupPrefix = "scenes/shrink/bedroomShrunk01/";
			super.screenAsset = "blank_paper.swf";
			
			super.darkenBackground = true;
			super.init(container);
			load();
		}
		
		private var content:MovieClip;
		
		private var shrink:ShrinkEvents;
		
		public const LOOK_AWAY_FROM_PAPER:String = "look_away_from_paper";
		
		override public function loaded():void
		{
			super.loaded();
			
			content = screen.content as MovieClip;
			
			layout.centerUI(content);
			
			super.loadCloseButton();
			
			setUp();
		}
		
		private function setUp():void
		{
			if(shellApi.checkEvent(shrink.CJ_AT_SCHOOL))
				return;
			
			if(!shellApi.checkEvent(shrink.PAPER_MESSAGE_VISIBLE))
			{
				content.secretMessage.visible = false;
				return;
			}
			
			var message:Entity = EntityUtils.createSpatialEntity(this,content.secretMessage,content);
			Display(message.get(Display)).alpha = 0;
			SceneUtil.lockInput(this);
			TweenUtils.entityTo(message,Display,3,{alpha:1,onComplete:messageVisible});
		}
		
		private function messageVisible():void
		{
			SceneUtil.lockInput(this, false);
			shellApi.completeEvent(shrink.CJ_AT_SCHOOL);
		}
		
		override public function close( removeOnClose:Boolean = true, onCloseHandler:Function = null ):void
		{
			shellApi.triggerEvent(LOOK_AWAY_FROM_PAPER);
			super.close();
		}
	}
}