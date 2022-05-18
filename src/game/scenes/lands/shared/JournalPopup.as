package game.scenes.lands.shared {

	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	
	import ash.core.Entity;
	
	import engine.components.Display;
	
	import game.data.ui.ToolTipType;
	import game.scenes.virusHunter.joesCondo.util.SimpleUtils;
	import game.ui.popup.Popup;

	public class JournalPopup extends Popup {

		private var content:MovieClip;
		//private var inputMgr:InputManager;

		private var btnLeft:Entity;
		private var btnRight:Entity;

		public function JournalPopup( container:DisplayObjectContainer=null ) {

			super(container);
		}

		override public function init( container:DisplayObjectContainer=null ):void {

			darkenBackground = true;
			groupPrefix = "scenes/lands/shared/";
			super.screenAsset = "journalPopup.swf";
			super.init( container );
			load();
		}
		
		override public function loaded():void {

			super.preparePopup();
			
			this.content = this.screen.content;
			this.content.gotoAndStop( 1 );

			var btn:MovieClip = this.content.btnLeft;
			this.btnLeft = SimpleUtils.makeUIBtn( btn, this.onClickLeft, this );
			( this.btnLeft.get( Display ) as Display ).alpha = 0;

			this.btnRight = SimpleUtils.makeUIBtn( this.content.btnRight, this.onClickRight, this );
			( this.btnRight.get( Display ) as Display ).alpha = 0;

			loadCloseButton();
			super.groupReady();

		} //

		public function onClickLeft( e:Entity ):void {

			if ( this.content.currentFrame == 1 ) {
				return;
			} else {
				this.content.prevFrame();
			}

		} //

		public function onClickRight( e:Entity ):void {

			if ( this.content.currentFrame == this.content.totalFrames ) {
				return;
			} else {
				this.content.nextFrame();
			}

		} //
		
		override public function close( removeOnClose:Boolean = true, onClosedHandler:Function = null ):void
		{
			remove();
			super.shellApi.defaultCursor = ToolTipType.NAVIGATION_ARROW;
		}

	} // class

}