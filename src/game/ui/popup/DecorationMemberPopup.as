package game.ui.popup
{
	import flash.display.DisplayObjectContainer;
	import flash.net.URLRequest;
	import flash.net.URLRequestMethod;
	import flash.net.URLVariables;
	import flash.net.navigateToURL;
	
	import ash.core.Entity;
	
	import game.creators.ui.ButtonCreator;
	import game.data.ui.ToolTipType;
	import game.ui.hud.HudPopBrowser;
	import game.util.DisplayPositions;
	
	/**
	 * DecorationMemberPopup is membership popup for clubhouse
	 */
	public class DecorationMemberPopup extends Popup
	{
		public function DecorationMemberPopup(container:DisplayObjectContainer=null)
		{
			super(container);
		}
		
		public override function init(container:DisplayObjectContainer=null):void 
		{
			this.groupPrefix 		= "ui/clubhouse/";
			this.screenAsset 		= "membership.swf";
			this.id = GROUP_ID;
			
			darkenBackground = true;
			
			super.init(container);
			super.load();
		}
		
		// all assets ready
		override public function loaded():void
		{
			super.loaded();
			
			// position close button at top right
			this.loadCloseButton(DisplayPositions.TOP_RIGHT, 0, 0, false, this.screen);

			// center screen
			this.screen.x = this.shellApi.viewportWidth * 0.5 - this.screen.width * 0.5;
			this.screen.y = this.shellApi.viewportHeight * 0.5 - this.screen.height * 0.5;
			
			ButtonCreator.createButtonEntity( this.screen.memberButton, this, buyMembership, null, null, ToolTipType.CLICK);
		}
		
		// buy membership
		private function buyMembership(btn:Entity):void
		{
			super.close();
			
			HudPopBrowser.buyMembership(shellApi);
		}
		
		public static const GROUP_ID:String = "decoration_membership";
	}
}