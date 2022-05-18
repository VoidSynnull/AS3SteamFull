package game.scenes.prison.metalShop.popups
{
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.geom.Rectangle;
	
	import ash.core.Entity;
	
	import engine.components.Interaction;
	import engine.creators.InteractionCreator;
	
	import game.creators.ui.ButtonCreator;
	import game.creators.ui.ToolTipCreator;
	import game.ui.popup.Popup;
	import game.util.EntityUtils;
	
	public class LicensePlateGuide extends Popup
	{		
		
		public function LicensePlateGuide(container:DisplayObjectContainer=null)
		{
			super(container);
		}
		
		override public function destroy():void
		{
			super.destroy();
		}
		
		// pre load setup
		override public function init(container:DisplayObjectContainer = null):void
		{
			super.darkenBackground = true;
			super.groupPrefix = "scenes/prison/metalShop/popups/";
			super.init(container);
			load();
		}		
		
		// initiate asset load of scene specific assets.
		override public function load():void
		{
			super.shellApi.fileLoadComplete.addOnce(loaded);
			super.loadFiles(["licensePlateGuide.swf"]);
		}
		
		// all assets ready
		override public function loaded():void
		{	
			super.screen = super.getAsset("licensePlateGuide.swf", true) as MovieClip;
			
			MovieClip(super.screen).mouseChildren = true;
			MovieClip(super.screen).mouseEnabled = true;
			
			super.letterbox(super.screen.content, new Rectangle(0,0,960,640));
			
			this.darkenAlpha = 0.90;
			
			loadCloseButton();
			var startbutton:Entity = ButtonCreator.createButtonEntity(this.screen.content["startButton"], this, closeMe, null, null, null, true, true);	
			
			super.loaded();
		}
		
		private function closeMe(...p):void
		{
			this.closeClicked.dispatch(this);
			this.close();
		}		
		
		
	}
}