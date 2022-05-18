package game.scenes.ghd.store.popups
{
	import com.greensock.easing.Bounce;
	import com.greensock.easing.Sine;
	
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.geom.Point;
	
	import game.data.ui.TransitionData;
	import game.ui.popup.Popup;
	
	public class BioPopup extends Popup
	{
		public var frame:*;
		
		public function BioPopup(container:DisplayObjectContainer=null)
		{
			super(container);
			
			this.id 				= "BioPopup";
			this.groupPrefix 		= "scenes/ghd/store/popups/bioPopup/";
			this.screenAsset 		= "bioPopup.swf";
			this.pauseParent 		= true;
			this.darkenBackground 	= true;
		}
		
		override public function init(container:DisplayObjectContainer = null):void
		{
			this.transitionIn 			= new TransitionData();
			this.transitionIn.duration 	= 0.9;
			this.transitionIn.startPos 	= new Point(0, -super.shellApi.viewportHeight);
			this.transitionIn.endPos 	= new Point(0, 0);
			this.transitionIn.ease 		= Bounce.easeOut;
			this.transitionOut 			= transitionIn.duplicateSwitch(Sine.easeIn);
			this.transitionOut.duration = 0.3;
			
			super.init(container);
			
			this.load();
		}
		
		override public function loaded():void
		{
			super.loaded();
			
			this.loadCloseButton();
			
			var content:MovieClip = this.screen.content;
			content.gotoAndStop(frame);
			
			//The extra 100 here is to account for extra width coming from what is probably a mask I just can't find...
			content.x = this.shellApi.viewportWidth / 2 - content.width / 2 + 100;
			content.y = this.shellApi.viewportHeight / 2 - content.height / 2;
		}
	}
}