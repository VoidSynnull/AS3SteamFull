package game.scenes.arab3.shared
{
	import com.greensock.easing.Back;
	
	import flash.display.DisplayObjectContainer;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	
	import engine.managers.SoundManager;
	
	import game.data.ui.TransitionData;
	import game.ui.popup.Popup;
	import game.util.AudioUtils;
	
	public class InstructionsPopup extends Popup
	{
		public function InstructionsPopup(container:DisplayObjectContainer=null)
		{
			super(container);
			
			this.id 				= "InstructionsPopup";
			this.groupPrefix 		= "scenes/arab3/shared/";
			this.screenAsset 		= "instructionsPopup.swf";
			this.pauseParent 		= true;
			this.darkenBackground 	= true;
		}
		
		override public function init( container:DisplayObjectContainer = null ):void
		{
			this.transitionIn 			= new TransitionData();
			this.transitionIn.duration 	= 0.9;
			this.transitionIn.startPos 	= new Point(0, this.shellApi.viewportHeight);
			this.transitionIn.endPos 	= new Point(0, 0);
			this.transitionIn.ease 		= Back.easeOut;
			this.transitionOut 			= transitionIn.duplicateSwitch(Back.easeIn);
			this.transitionOut.duration = 0.3;
			
			super.init( container );
			
			this.load();
		}
		
		override public function loaded():void
		{
			super.loaded();
			this.letterbox(this.screen.content, new Rectangle(0, 0, 960, 640), false);
			
			AudioUtils.play( this, SoundManager.EFFECTS_PATH + "paper_flap_02.mp3" );
		}
		
		override public function open( handler:Function = null ):void
		{			
			super.open( super.loadCloseButton );
		}
	}
}