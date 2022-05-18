package game.scenes.prison.tower.popups
{
	import com.poptropica.AppConfig;
	
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	
	import game.scenes.prison.PrisonEvents;
	import game.ui.popup.Popup;
	import game.util.SkinUtils;
	
	public class HeadshotsPopup extends Popup
	{
		
		private var _events:PrisonEvents;
		public var events:PrisonEvents;
		
		
		public function HeadshotsPopup(container:DisplayObjectContainer = null)
		{
			super(container);
			_events = new PrisonEvents();
			
			this.id 				= "HeadshotsPopup";
			this.groupPrefix 		= "scenes/prison/tower/popups/";
			this.screenAsset 		= "headshotsPopup.swf";
			this.pauseParent 		= true;
			this.darkenAlpha		= 0.8;
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
			
			this.events = this.shellApi.islandEvents as PrisonEvents;
			
			this.setupContent();
			super.loadCloseButton();
		}
		
		private function setupContent():void
		{
			var content:MovieClip = this.screen.content;
			content.x *= this.shellApi.viewportWidth / content.width / 2;
			content.y *= this.shellApi.viewportHeight / content.height / 2;
			
			if(shellApi.profileManager.active.gender){
				if(shellApi.profileManager.active.gender == SkinUtils.GENDER_FEMALE){
					content["male"].visible = false;
				} else {
					content["female"].visible = false;
				}
			}
		}
	}
}