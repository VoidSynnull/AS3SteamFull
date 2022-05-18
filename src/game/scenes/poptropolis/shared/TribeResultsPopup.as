package game.scenes.poptropolis.shared {

	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.geom.Point;
	import flash.text.TextFormat;
	
	import ash.core.Entity;
	
	import game.creators.ui.ButtonCreator;
	import game.data.ui.TransitionData;
	import game.scenes.poptropolis.shared.data.Competitor;
	import game.scenes.poptropolis.shared.data.MatchType;
	import game.ui.popup.Popup;
	import game.util.DisplayPositions;
	import game.util.TextUtils;

	public class TribeResultsPopup extends Popup {

		/**
		 * Height of rows between each tribe score field.
		 */
		private const ROW_HEIGHT:Number = 42.5;

		private var popupFileName:String;
		private var useCloseButton:Boolean = false;

		private var btnNext:Entity;

		private var poptropolis:Poptropolis;

		public function TribeResultsPopup( popInfo:Poptropolis, fileName:String, container:DisplayObjectContainer=null ) {

			super( container );
			this.screenAsset = fileName;
			this.poptropolis = popInfo;

		} //

		// pre load setup
		override public function init( container:DisplayObjectContainer=null ):void {

			// setup the transitions 
			super.transitionIn = new TransitionData();
			super.transitionIn.startPos = new Point( 0, -super.shellApi.viewportHeight );
			super.transitionIn.endPos = new Point( 0, 0 );
			super.transitionIn.duration = .5;
			super.transitionOut = super.transitionIn.duplicateSwitch();
			super.transitionOut.duration = .5;
			super.darkenBackground = true;
			
			super.init( container );
			super.load();

		} //

		// all assets ready
		override public function loaded():void {

			super.loaded();
			
			this.centerWithinDimensions(this.screen.content);
			
			this.initScreen();

			if ( this.useCloseButton ) {
				super.closeButton = ButtonCreator.loadCloseButton( this, super.container, super.handleCloseClicked, DisplayPositions.TOP_RIGHT);
			}

			this.seedFields();

		} //

		private function initScreen():void {

			TextUtils.refreshText( super.screen.content.place_tf, "ExpletiveDeleted" );
			TextUtils.refreshText( super.screen.content.tribe_name_tf, "ExpletiveDeleted" );
			TextUtils.refreshText( super.screen.content.score_tf, "ExpletiveDeleted" );

			var btnClip:MovieClip = this.screen.content["btnNext"] as MovieClip;
			ButtonCreator.createButtonEntity( btnClip, this, onNext ); 
			TextUtils.refreshText( MovieClip(btnClip.tf_clip).tf, "Diogenes" );
			btnClip.mouseChildren = false;

		} //

		private function onNext( btnEntity:Entity = null):void {

			super.handleCloseClicked();

		} //

		/**
		 * fldRanks is static - not even labelled now.
		 * fldTribes - the tribe names in order of rank in the event. (lowest first)
		 * fldScores - the scores (with unit type) for the tribes.
		 */
		private function seedFields():void {

			var ranks:Vector.<Competitor> = this.poptropolis.getRankings();

			var match:MatchType = this.poptropolis.getCurMatch();
			var precision:int = match.precision;

			var tribeStr:String = "";
			var scoreStr:String = "";

			var len:int = ranks.length;

			trace( "LEN: " + len );
			if ( isNaN(len ) ) {
				trace( "NONANANA" );
				return;
			}

			var competitor:Competitor;
			for( var i:int = 0; i < len; i++ ) {

				competitor = ranks[i];

				// if player, set hilite
				if  ( competitor.isNpc() == false ) {
					this.screen.content.hilite.y = this.screen.content.tribes_tf.y + (this.ROW_HEIGHT)*i - 5;		// -5 is stupid offset.
				}

				tribeStr += competitor.tribe.name + "\n";
				scoreStr += competitor.tempScore.toFixed( precision ) + " " + match.unitType + "\n";

			} //

			TextUtils.convertText( this.screen.content.tribes_tf, new TextFormat( "ExpletiveDeleted" ), tribeStr );
			TextUtils.convertText( this.screen.content.scores_tf, new TextFormat( "ExpletiveDeleted" ), scoreStr );

			this.screen.content.matchClip.gotoAndStop( match.eventName );

		} //

	} // class

} //