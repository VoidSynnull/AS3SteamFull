package game.ui.saveGame
{
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.geom.Point;
	
	import ash.core.Entity;
	
	import engine.util.Command;
	
	import game.creators.ui.ButtonCreator;
	import game.data.ui.TransitionData;
	import game.ui.popup.Popup;
	
	public class RealmsRedirectPopup extends Popup
	{
		public var save:Boolean;
		public function RealmsRedirectPopup(container:DisplayObjectContainer=null)
		{
			super(container);
		}
		
		override public function init(container:DisplayObjectContainer=null):void
		{
			super.transitionIn = new TransitionData();
			super.transitionIn.duration = .3;
			super.transitionIn.startPos = new Point(0, -super.shellApi.viewportHeight);
			// this shortcut method flips the start and end position of the transitionIn
			super.transitionOut = super.transitionIn.duplicateSwitch();
			super.darkenBackground = true;
			super.groupPrefix = "ui/saveGame/";
			super.screenAsset = "realmsRedirect.swf";
			super.init(container);
			super.load();
		}
		
		override public function loaded():void
		{
			super.loaded();
			var content:MovieClip = screen.content;
			content.x = shellApi.viewportWidth/2;
			content.y = shellApi.viewportHeight/2;
			ButtonCreator.createButtonEntity(content["btnSave"],this, Command.create(onClose, true));
			ButtonCreator.createButtonEntity(content["btnExit"],this, onClose);
		}
		
		private function onClose(entity:Entity, save:Boolean = false):void
		{
			this.save = save;
			close();
		}
	}
}