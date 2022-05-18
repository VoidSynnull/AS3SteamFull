package game.scenes.lands.shared.popups.racePopup {

	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.events.MouseEvent;
	import flash.net.URLRequest;
	import flash.net.navigateToURL;
	
	import ash.core.Entity;
	
	import game.data.comm.PopResponse;
	import game.data.ui.ToolTipType;
	import game.scenes.map.map.Map;
	import game.scenes.virusHunter.joesCondo.util.SimpleUtils;
	import game.ui.popup.Popup;

	public class RacePopup extends Popup {

		private var content:MovieClip;
		//private var inputMgr:InputManager;

		private var btnContinue:Entity;
		private var totalSeconds:Number;

		public function RacePopup( tseconds:Number, container:DisplayObjectContainer=null ) {

			super(container);
			totalSeconds = tseconds;
		}

		override public function init( container:DisplayObjectContainer=null ):void {

			darkenBackground = true;
			groupPrefix = "scenes/lands/shared/popups/";
			super.screenAsset = "racePopup.swf";
			super.init( container );
			load();
		}
		
		override public function loaded():void {

			super.preparePopup();
			
			this.content = this.screen.content;
			this.content.seconds.text = String(totalSeconds);
			
			this.btnContinue = SimpleUtils.makeUIBtn( this.content.btnContinue, this.onClickContinue, this );
			
			//loadCloseButton();
			super.groupReady();
		} //

		public function onClickContinue( e:Entity ):void {
			this.close(true);

		} //

		override public function close( removeOnClose:Boolean = true, onClosedHandler:Function = null ):void
		{
			remove();
			super.shellApi.defaultCursor = ToolTipType.NAVIGATION_ARROW;
		}

	} // class

}
