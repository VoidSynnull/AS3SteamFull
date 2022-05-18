package game.scenes.survival3.shared.popups
{
	import flash.display.DisplayObjectContainer;
	import flash.geom.Point;
	
	import ash.core.Entity;
	
	import game.creators.ui.ButtonCreator;
	import game.data.ui.ToolTipType;
	import game.data.ui.TransitionData;
	import game.ui.popup.Popup;
	
	public class IntroPopup extends Popup
	{
		public function IntroPopup(container:DisplayObjectContainer=null)
		{
			super(container);
		}
		
		override public function init(container:DisplayObjectContainer=null):void
		{
			super.init(container);
			
			this.transitionIn = new TransitionData();
			this.transitionIn.duration = 0.3;
			this.transitionIn.startPos = new Point(0, -super.shellApi.viewportHeight);
			this.transitionOut = this.transitionIn.duplicateSwitch();
			
			this.pauseParent 		= true;
			this.darkenBackground 	= true;
			this.autoOpen 			= true;
			this.groupPrefix = "scenes/survival3/shared/popups/";
			this.screenAsset = "survival3_intro_popup.swf";
			
			this.load();
		}
		
		override public function loaded():void
		{
			super.loaded();
			
			var display:DisplayObjectContainer = this.screen.content;
			
			layout.centerUI(display);
			
			ButtonCreator.createButtonEntity(this.screen.content.start, this, onConfirmClicked, null, null, null, true, true); 
		}
		
		private function onConfirmClicked(entity:Entity):void
		{
			super.shellApi.defaultCursor = ToolTipType.NAVIGATION_ARROW;
			this.close();
		}
	}
}