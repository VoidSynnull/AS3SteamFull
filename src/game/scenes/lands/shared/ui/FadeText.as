package game.scenes.lands.shared.ui {

	import flash.display.Sprite;
	import flash.events.Event;
	import flash.filters.GlowFilter;
	import flash.text.TextField;
	import flash.text.TextFormat;
	
	import game.scenes.lands.shared.groups.LandUIGroup;

	public class FadeText extends Sprite {

		static private var SharedGlow:Array;

		private var fld:TextField;
		private var uiGroup:LandUIGroup;

		public function FadeText( grp:LandUIGroup, text:String, color:uint=0x1589F0 ) {

			super();

			this.fld = new TextField();
			//this.fld.textColor = this.textColor;
			this.fld.defaultTextFormat = new TextFormat( "CreativeBlock BB", 24, color );
			this.fld.text = text;
			this.addChild( this.fld );

			if ( FadeText.SharedGlow == null ) {
				FadeText.SharedGlow = [ new GlowFilter( 0xFFFFFF, 1, 4, 4, 6 ) ];
			} //
			this.filters = FadeText.SharedGlow;

			this.mouseChildren = this.mouseEnabled = false;
			this.uiGroup = grp;
			grp.inputManager.addEventListener( this, Event.ENTER_FRAME, this.updateFade );

		} //

		public function updateFade( e:Event ):void {

			this.y -= 1.5;
			this.alpha -= 0.001;
			if ( this.alpha <= 0.04 ) {

				// stop the enter frame. remove the object. etc. etc.
				if ( this.parent ) {
					this.parent.removeChild( this );
				}
				this.uiGroup.inputManager.removeListeners( this );

			} //

		} //

		public function getField():TextField {
			return this.fld;
		}

	} // class

} // package