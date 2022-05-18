package game.scenes.lands.shared.components {

	/**
	 * By default, Poptropica toolTips can only be created for entities, and they do this by creating a new toolTip entity
	 * that springs to the parent entity. creating land tool tips for all the buttons and interactions made too many entities
	 * and was far too slow.
	 * 
	 * this component collects toolTips for display objects and shares a single tool tip entity that will display
	 * when the mouse rolls over any one of the clips. The individual display objects can define their toolTip type,
	 * their toolTip text, and their rollOver frames ( if they are movieClips )
	 */
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.utils.Dictionary;
	
	import ash.core.Component;
	
	import game.data.ui.ToolTipType;
	import game.scenes.lands.shared.classes.SharedTipTarget;

	public class SharedToolTip extends Component {

		/**
		 * All the targets that this sharedToolTip object uses for its toolTips.
		 * when one of these targets is rolled over, a toolTip will activate.
		 */
		public var tipTargets:Vector.<SharedTipTarget>;

		/**
		 * maps clip -> SharedTipTarget
		 * used to deactive and reactivate tips without losing the tool tip information.
		 * this is basically a list of 'paused' tooltips - they won't trigger onRollOver, but can be
		 * quickly reactivated.
		 */
		public var inactive:Dictionary;

		/**
		 * tip that should display currently. ( its displayobject is being targeted by mouse )
		 */
		public var curTip:SharedTipTarget;

		public function SharedToolTip() {

			this.tipTargets = new Vector.<SharedTipTarget>();
			this.inactive = new Dictionary( true );

		} //

		private function clearCurTip():void {

			if ( this.curTip.rollOverFrame > 0 ) {
				( this.curTip.clip as MovieClip ).gotoAndStop( 1 );
			}

			this.curTip = null;

		} //

		/**
		 * remove the tool tip associated with the given displayObjectContainer
		 */
		public function removeToolTip( clip:DisplayObjectContainer ):void {

			if ( this.curTip && this.curTip.clip == clip ) {
				this.clearCurTip();
			} //

			if ( this.inactive[ clip ] ) {
				delete this.inactive[ clip ];
			} else {

				var target:SharedTipTarget;
				for( var i:int = this.tipTargets.length-1; i >= 0; i-- ) {
					
					if ( tipTargets[i].clip == clip ) {
						
						if ( i < tipTargets.length-1 ) {
							tipTargets[i] = tipTargets.pop();
						} else {
							tipTargets.pop();
						} //
	
						break;
	
					} //
					
				} // for-loop.

			} // end-else

		} //

		public function addToolTip( target:SharedTipTarget, active:Boolean=true ):void {

			if ( active ) {
				this.tipTargets.push( target );
			} else {
				this.inactive[target.clip] = target;
			}

		} //

		public function deactivate( clip:DisplayObjectContainer ):void {

			if ( this.curTip && this.curTip.clip == clip ) {
				this.clearCurTip();
				// also need to reset the ToolTip.type somehow...
			} //

			// find the TipTarget info for the clip and move it to the inactive dictionary.
			var target:SharedTipTarget;
			for( var i:int = this.tipTargets.length-1; i >= 0; i-- ) {

				if ( this.tipTargets[i].clip == clip ) {

					this.inactive[clip] = this.tipTargets[i];

					if ( i < this.tipTargets.length-1 ) {
						this.tipTargets[i] = this.tipTargets.pop();
					} else {
						this.tipTargets.pop();
					} //

					return;

				} //

			} // for-loop.

		} //

		/**
		 * reactivate a rollOver toolTip that was made inactive.
		 */
		public function reactivate( clip:DisplayObjectContainer ):void {

			var target:SharedTipTarget = this.inactive[ clip ];
			if ( target ) {

				delete this.inactive[clip];
				this.tipTargets.push( target );

			} //

		} //

		/**
		 * Adds a rollOver toolTip to the given displayObjectContainer.
		 * - tipType is a standard poptropica toolTipType (usually ToolTipType.CLICK)
		 * - rollOverText currently is not functional but will eventually be the text that shows up when you rollOver.
		 * - if active=false, the toolTip rollOver will start disabled and will not activate until sharedToolTip.reactivate() is called.
		 */
		public function addClipTip( clip:DisplayObjectContainer, tipType:String=ToolTipType.CLICK,
									rollOverText:String=null, active:Boolean=true ):SharedTipTarget {

			var target:SharedTipTarget =  new SharedTipTarget( clip, tipType, rollOverText );

			if ( active ) {
				this.tipTargets.push( target );
			} else {
				this.inactive[clip] = target;
			}

			return target;

		} //

		override public function destroy():void {

			super.destroy();

			this.tipTargets.length = 0;
			this.curTip = null;

		} //

	} // class
	
} // package