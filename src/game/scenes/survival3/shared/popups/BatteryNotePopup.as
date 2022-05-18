package game.scenes.survival3.shared.popups
{
	import flash.display.DisplayObjectContainer;
	import flash.geom.Point;
	
	import game.data.ui.TransitionData;
	import game.ui.popup.Popup;
	
	public class BatteryNotePopup extends Popup
	{
		public function BatteryNotePopup(container:DisplayObjectContainer=null)
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
			this.screenAsset = "batteryNote.swf";
			
			this.load();
		}
		
		override public function loaded():void
		{
			super.loaded();
			
			layout.centerUI(screen["content"]); 
			
			super.loadCloseButton();
		}
	}
}