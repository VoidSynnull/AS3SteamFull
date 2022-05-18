package game.scenes.poptropolis.shared {

	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.geom.Point;
	import flash.text.TextField;
	import flash.text.TextFormat;
	
	import game.creators.ui.ButtonCreator;
	import game.data.ui.TransitionData;
	import game.scenes.poptropolis.shared.data.Competitor;
	import game.ui.popup.Popup;
	import game.util.DisplayPositions;
	import game.util.TextUtils;

	public class TribeRanksPopup extends Popup {
		/**
		 * Symbol to use when match has not yet been played.
		 */
		private const UNDEFINED_SYMBOL:String = "-";

		private const HILITE_MIN_Y:int = 166;			// starting value for hilite clip-y.

		private var _useCloseButton:Boolean = true;

		private var _poptropolis:Poptropolis;

		public function TribeRanksPopup( popInfo:Poptropolis, fileName:String, container:DisplayObjectContainer=null ) {
			super( container );
			super.screenAsset = fileName;
			this._poptropolis = popInfo;
		}

		// pre load setup
		override public function init( container:DisplayObjectContainer=null ):void {

			// setup the transitions 
			/*
			super.transitionIn = new TransitionData();
			super.transitionIn.startPos = new Point( 0, -super.shellApi.viewportHeight );
			super.transitionIn.endPos = new Point( 0, 0 );
			super.transitionIn.duration = .3;
			super.transitionOut = super.transitionIn.duplicateSwitch();
			super.transitionOut.duration = .3;
			*/
			super.darkenBackground = true;
			super.darkenAlpha = .6;
			
			super.init( container );
			this.load();
		}

		// all assets ready
		override public function loaded():void {

			super.loaded();
			
			this.fillDimensions(this.screen.background);
			this.centerWithinDimensions(this.screen.content);

			if ( this._useCloseButton ) {
				super.closeButton = ButtonCreator.loadCloseButton( this, super.container, super.handleCloseClicked, DisplayPositions.TOP_RIGHT);
			}
			
			// refesh static text
			TextUtils.refreshText( TextField(this.screen.content["tribes_tf"]), "ExpletiveDeleted" );
			TextUtils.refreshText( TextField(this.screen.content["overall_tf"]), "ExpletiveDeleted" );
			TextUtils.refreshText( TextField(this.screen.content["rank_tf"]), "ExpletiveDeleted" );;
			
			// define tribe & rank text
			seedFields();
		}

		/**
		 * fldRanks is static - not even labelled now.
		 * fldTribes - the tribe names in order of rank in the event. (lowest first)
		 * fldScores - the scores (with unit type) for the tribes.
		 */
		private function seedFields():void {

			var leaders:Vector.<Competitor> = this._poptropolis.getLeaders();
			var competitor:Competitor;

			var ranks:Vector.<int>;
			var matchRank:int;

			var rowClip:MovieClip;
			var rankString:String;

			var len:int = leaders.length;

			this.shellApi.logWWW( "LEADER COUNT: " + len );

			for( var i:int = leaders.length-1; i >= 0; i-- ) {

				competitor = leaders[ i ];
				ranks = competitor.getRanks();
				rowClip = super.screen.content[ "row" + i ];

				this.shellApi.logWWW( "RANKS" + i + ": " + ranks );

				// display hilite and arrow for player's row
				if ( competitor.isNpc() == false ) {
					rowClip.hilite.visible = true;
					super.screen.content[ "playerArrow" ].y = rowClip.y + rowClip.height/2; 
				} else {
					rowClip.hilite.visible = false;
				}
				
				// set tribe text
				TextUtils.convertText( rowClip.tribe_tf, new TextFormat("ExpletiveDeleted"), competitor.tribe.name );

				// set rank text
				for( var j:int = ranks.length-1; j >= 0; j-- ) {
					matchRank = ranks[ j ];
					rankString = ( matchRank == Rankings.NO_RANK ) ? UNDEFINED_SYMBOL : ( matchRank + 1 ).toString();
					TextUtils.convertText( rowClip[ "rank_tf_" + j ], new TextFormat("ExpletiveDeleted", 18 ), rankString );
				} // end for-loop.

			} // end for-loop.

		} //

	} // class

} // package