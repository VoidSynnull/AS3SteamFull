package game.scenes.lands.shared.systems {

	/**
	 * share a single entity and toolTip component for a group of tool tips.
	 */
	
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.display.Sprite;
	
	import ash.core.Engine;
	import ash.core.NodeList;
	import ash.core.System;
	
	import game.scenes.lands.shared.classes.SharedTipTarget;
	import game.scenes.lands.shared.components.SharedToolTip;
	import game.scenes.lands.shared.nodes.SharedToolTipNode;

	public class SharedToolTipSystem extends System {

		/**
		 * the actual tool tip system is on a wait of 10 frames, so this might as well be too.
		 * Our wait is slightly smaller to ensure it runs at least once between every run
		 * of the other system.
		 */
		private var _wait:int = 8;

		private var nodeList:NodeList;

		/**
		 * the tooltip for the entity always needs to have a display object.
		 * when no toolTip is active, it reverts to this empty dummy sprite.
		 */
		private var defaultDisplay:Sprite;

		public function SharedToolTipSystem() {

			super();

			this.defaultDisplay = new Sprite();

		} //

		override public function update( time:Number ):void {

			var targets:Vector.<SharedTipTarget>;
			var target:SharedTipTarget;
			var shared:SharedToolTip;

			/**
			 * only one shared tip at a time. because it's a shared tip...
			 * actually it might make sense to have different sharedTips for different groups.
			 */
			var node:SharedToolTipNode = this.nodeList.head;
			if ( node.entity.sleeping ) {
				return;
			}

			var clip:DisplayObjectContainer;
			
			//for( var node:SharedToolTipNode = this.nodeList.head; node; node = node.next ) {

				// don't check this every frame.
				if ( this._wait-- < 0 ) {

					this._wait = 8;

					// two ways to do this. either set rollOver,rollOut events on all the tipTargets, or just do hitTests vs the cursor.
					targets = node.shared.tipTargets;
					for( var i:int = targets.length-1; i >= 0; i-- ) {
	
						target = targets[i];
						clip = target.clip;
	
						if ( clip.visible && clip.hitTestPoint( clip.stage.mouseX, clip.stage.mouseY ) ) {

							node.toolTip.type = target.tipType;
							node.toolTip.label = target.tipText;
	
							// note that the node must NOT have a spatial, or the clip will move.
							node.display.displayObject = clip;
	
							if ( target.rollOverFrame > 0 ) {
								( clip as MovieClip ).gotoAndStop( target.rollOverFrame );
							}

							node.shared.curTip = target;
	
							return;
	
						} //
	
					} //

				} //

				shared = node.shared;
				if ( shared.curTip != null ) {				// check for hiding current tool tip if non-active.

					clip = shared.curTip.clip;
					if ( !clip.visible || !clip.hitTestPoint( clip.stage.mouseX, clip.stage.mouseY ) ) {
						
						if ( shared.curTip.rollOverFrame > 0 ) {
							( clip as MovieClip ).gotoAndStop( 1 );
						}
						shared.curTip = null;
						
					} else {
						
						// tool tip is still active.
						// no matter how many systems are active, there can only be one tool tip.
						return;
						
					} //
					
				} // ( curTip != null )

				if ( shared.curTip == null ) {

					node.display.displayObject = this.defaultDisplay;
					node.toolTip.showing = false;
					node.toolTip.type = "";

				} //

		} //

		private function onNodeAdded( node:SharedToolTipNode ):void {

			node.display.displayObject = this.defaultDisplay;

		} //

		/*private function onNodeRemoved( node:SharedToolTipNode ):void {
		} //*/

		override public function addToEngine( systemManager:Engine ):void {

			this.nodeList = systemManager.getNodeList( SharedToolTipNode );
			this.nodeList.nodeAdded.add( this.onNodeAdded );
			//this.nodeList.nodeRemoved.add( this.onNodeRemoved );

			for( var n:SharedToolTipNode = this.nodeList.head; n; n = n.next ) {
				this.onNodeAdded( n );
			} //

		} //

		override public function removeFromEngine( systemManager:Engine ):void {

			systemManager.releaseNodeList( SharedToolTipNode );

		} //

	} // End class

} // End package