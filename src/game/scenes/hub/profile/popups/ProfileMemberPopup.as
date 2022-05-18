package game.scenes.hub.profile.popups
{
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.geom.Point;
	
	import game.data.ui.TransitionData;
	import game.ui.popup.Popup;
	
	public class ProfileMemberPopup extends Popup
	{		
		private var content:MovieClip;
		private var showMessage2:Boolean = false;
		
		public function ProfileMemberPopup(container:DisplayObjectContainer=null,showmessage2:Boolean=false)
		{
			showMessage2 = showmessage2;
			super(container);
		}
		
		override public function destroy():void
		{
			super.destroy();
		}
		
		// pre load setup
		override public function init(container:DisplayObjectContainer = null):void
		{
			// setup the transitions 
			super.transitionIn = new TransitionData();
			super.transitionIn.duration = .3;
			super.transitionIn.startPos = new Point(0, -super.shellApi.viewportHeight);
			// this shortcut method flips the start and end position of the transitionIn
			super.transitionOut = super.transitionIn.duplicateSwitch();
			super.darkenBackground = true;
			super.groupPrefix = "scenes/hub/profile/popups/";
			super.init(container);
			load();
		}		
		
		// initiate asset load of scene specific assets.
		override public function load():void
		{
			super.shellApi.fileLoadComplete.addOnce(loaded);
			super.loadFiles(["profileMemberPopup.swf"]);
		}
		
		// all assets ready
		override public function loaded():void
		{		
			super.screen = super.getAsset("profileMemberPopup.swf", true) as MovieClip;
			content = screen.content;
			content.mouseChildren = true;
			content.mouseEnabled = false;
			
			if(showMessage2){
				content["message"].visible = false;
				content["message2"].visible = true;
			} else {
				content["message"].visible = true;
				content["message2"].visible = false;
			}
			
			// this loads the standard close button
			super.loadCloseButton();
			super.loaded();
		}
	};
};