package game.scenes.lands.shared.systems {

	/**
	 * this tracks separate lightning targets which can be hit by lightning.
	 * the cost of some of these functions may become prohibitive with
	 * a large number of targets -- in which case the system should change.
	 */

	import flash.display.DisplayObjectContainer;
	import flash.events.MouseEvent;
	import flash.utils.Dictionary;
	
	import ash.core.Engine;
	import ash.core.Entity;
	import ash.core.NodeList;
	import ash.core.System;
	
	import game.scenes.lands.shared.components.InputManager;
	import game.scenes.lands.shared.components.LightningStrike;
	import game.scenes.lands.shared.components.LightningTarget;
	import game.scenes.lands.shared.nodes.LightningStrikeNode;
	import game.scenes.lands.shared.nodes.LightningTargetNode;

	public class LightningTargetSystem extends System {

		private var lightningNodes:NodeList;
		private var targetNodes:NodeList;

		private var curTargetDisplay:DisplayObjectContainer;
		private var curTarget:LightningTarget;
		//private var curTargetEntity:Entity;

		/**
		 * countdown to triggering a lightning strike.
		 */
		//private var strikeTimer:Number;

		/**
		 * maps display objects to lightning target entities.
		 */
		private var targetEntities:Dictionary;

		/**
		 * true when mouse is held down.
		 */
		private var striking:Boolean;

		private var inputMgr:InputManager;

		/**
		 * starts paused, unpauses in mining mode.
		 */
		private var paused:Boolean = true;

		public function LightningTargetSystem( input:InputManager ) {

			super();

			this.targetEntities = new Dictionary( true );
			this.inputMgr = input;

		} //

		public function pauseSystem():void {

			this.paused = true;

			for( var node:LightningTargetNode = this.targetNodes.head; node; node = node.next ) {
				this.disableTarget( node.target );
			} //

			var lightningNode:LightningStrikeNode = this.lightningNodes.head;
			lightningNode.audio.stopActionAudio( "strike" );

			if ( this.striking ) {
				this.striking = false;
				
				this.curTarget = null;
				this.curTargetDisplay = null;

				lightningNode.lightning.stop();				
			}

		} //

		public function unpauseSystem():void {

			for( var node:LightningTargetNode = this.targetNodes.head; node; node = node.next ) {
				this.enableTarget( node.target );
			} //

			this.paused = false;

		} //

		override public function update( time:Number ):void {

			if ( this.striking == false || this.paused ) {
				return;
			}

			var lightningNode:LightningStrikeNode = this.lightningNodes.head;
			if ( lightningNode.entity.sleeping ) {
				return;
			}

			var lightning:LightningStrike = lightningNode.lightning;
			lightning.setTarget( lightning.effectParent.mouseX, lightning.effectParent.mouseY );

			if ( this.curTarget && this.curTarget.enabled ) {

				this.curTarget._timer += time;
				if ( this.curTarget._timer > this.curTarget.strikeTime ) {

					this.curTarget._timer = 0;
					if ( this.curTarget.strikeFunc ) {
						this.curTarget.strikeFunc( this.targetEntities[ this.curTargetDisplay ], lightning );
					}

				} //

			} // curTarget.enabled

		} // update()

		private function setActiveTarget( entity:Entity, target:LightningTarget ):void {

			//this.curTargetEntity = entity;
			this.curTarget = target;

		} //

		/**
		 * mouse down on a lightning target.
		 */
		private function targetMouseDown( e:MouseEvent ):void {

			var display:DisplayObjectContainer = e.currentTarget as DisplayObjectContainer;

			this.curTarget = null;
			this.curTargetDisplay = null;

			var entity:Entity = this.targetEntities[ display ];
			if ( entity == null ) {
				//trace( "NO ENTITY FOR TARGET" );
				return;
			}
			var target:LightningTarget = entity.get( LightningTarget ) as LightningTarget;
			if ( !target ) {
			//trace( "NO TARGET FOR THINGY" );
			} else if ( !target.enabled  ) {
				//trace( "TARGET NOT ENABLED" );
				return;
			}

			target._timer = 0;

			this.curTarget = target;
			this.curTargetDisplay = display;
			//this.curTargetEntity = entity;

			this.striking = true;

			var lightningNode:LightningStrikeNode = this.lightningNodes.head;
			lightningNode.lightning.start();
			lightningNode.audio.playCurrentAction( "strike" );

		} //

		/**
		 * this should fire for ANY mouse up ( in the display hierarchy where the lightning is active )
		 */
		private function onMouseRelease( e:MouseEvent ):void {

			//trace( "MOUSE UP ");

			if ( !this.striking ) {
				return;
			}

			// if there's a mouse up, then all striking should stop.
			this.striking = false;

			this.curTarget = null;
			this.curTargetDisplay = null;

			var lightningNode:LightningStrikeNode = this.lightningNodes.head;
			lightningNode.lightning.stop();

			//trace( "MOUSE UP STOP AUDIO" );
			lightningNode.audio.stopActionAudio( "strike" );

		} //

		/**
		 * roll over a lightning target.
		 */
		private function targetRollOver( e:MouseEvent ):void {

			if ( !this.striking ) {
				return;
			}

			var display:DisplayObjectContainer = e.target as DisplayObjectContainer;

			var entity:Entity = this.targetEntities[ display ];
			if ( entity == null ) {
				//trace( "NO ENTITY FOR DISPLAY " );
				return;
			}
			var target:LightningTarget = entity.get( LightningTarget ) as LightningTarget;
			if ( !target ) {
			//	trace( "NO TARGET FOR ROLL OVER" );
			} else if ( target.enabled ) {
				this.curTargetDisplay = display;
				target._timer = 0;
				this.curTarget = target;
			} /*else {
				trace( "NO TARGET CHANGE." );
				trace( "lightning target: " + this.curTarget );
			}*/

		} //

		/**
		 * roll out of a lightning target.
		 */
		private function targetRollOut( e:MouseEvent ):void {

			if ( !this.striking ) {
				return;
			}

			//trace( "ROLL OUT: " + e.target.name );

			var display:DisplayObjectContainer = e.target as DisplayObjectContainer;
			if ( display == this.curTargetDisplay ) {

			//	trace( "LEAVING ACTIVE - clearing current" );
				this.curTargetDisplay = null;
				this.curTarget = null;

			} //

		} //

		/**
		 * disable a lightning target and all its events.
		 */
		private function disableTarget( target:LightningTarget ):void {

			var display:DisplayObjectContainer = target.targetClip;

			this.inputMgr.removeEventListener( display, MouseEvent.ROLL_OUT, this.targetRollOut );
			this.inputMgr.removeEventListener( display, MouseEvent.ROLL_OVER, this.targetRollOver );
			this.inputMgr.removeEventListener( display, MouseEvent.MOUSE_DOWN, this.targetMouseDown );
			this.inputMgr.removeEventListener( display, MouseEvent.MOUSE_UP, this.onMouseRelease );
			this.inputMgr.removeEventListener( display, MouseEvent.RELEASE_OUTSIDE, this.onMouseRelease );

		} //

		/**
		 * enable a lightning target and its events.
		 */
		private function enableTarget( target:LightningTarget ):void {

			var display:DisplayObjectContainer = target.targetClip;

			this.inputMgr.addEventListener( display, MouseEvent.ROLL_OUT, this.targetRollOut );
			this.inputMgr.addEventListener( display, MouseEvent.ROLL_OVER, this.targetRollOver );
			this.inputMgr.addEventListener( display, MouseEvent.MOUSE_DOWN, this.targetMouseDown );
			this.inputMgr.addEventListener( display, MouseEvent.MOUSE_UP, this.onMouseRelease );
			this.inputMgr.addEventListener( display, MouseEvent.RELEASE_OUTSIDE, this.onMouseRelease );

		} //

		private function targetNodeAdded( node:LightningTargetNode ):void {

			var display:DisplayObjectContainer = node.target.targetClip;
			display.mouseEnabled = true;

			this.targetEntities[ display ] = node.entity;

			if ( !this.paused ) {
				this.enableTarget( node.target );
			}

		} //

		private function targetNodeRemoved( node:LightningTargetNode ):void {

			var display:DisplayObjectContainer = node.target.targetClip;
			delete this.targetEntities[ display ];

			if ( !this.paused ) {
				this.disableTarget( node.target );
			}

		} //

		/**
		 * find the lightning target which matches the display object.
		 * this can be slow with many targets and could be replaced by
		 * a dictionary lookup.
		 */
		/*private function findMatchingTarget( display:DisplayObject ):LightningTarget {

			for( var node:LightningTargetNode = this.targetNodes.head; node; node = node.next ) {

				if ( node.target.targetClip == display ) {
					return node.target;
				}

			} //

			return null;

		} //*/

		override public function addToEngine( systemManager:Engine ):void {

			this.lightningNodes = systemManager.getNodeList( LightningStrikeNode );
			this.targetNodes = systemManager.getNodeList( LightningTargetNode );

			var display:DisplayObjectContainer = this.group.shellApi.backgroundContainer;//( this.group as LandGroup ).mainScene.hitContainer.parent;
			this.inputMgr.addEventListener( display, MouseEvent.MOUSE_UP, this.onMouseRelease );

			for( var node:LightningTargetNode = this.targetNodes.head; node; node = node.next ) {

				this.targetNodeAdded( node );

			} //
			this.targetNodes.nodeAdded.add( this.targetNodeAdded );
			this.targetNodes.nodeRemoved.add( this.targetNodeRemoved );

		} //

		override public function removeFromEngine( systemManager:Engine ):void {

			var lightningNode:LightningStrikeNode = this.lightningNodes.head;
			if ( lightningNode && lightningNode.audio ) {
				lightningNode.audio.stopActionAudio( "strike" );
			}

			var display:DisplayObjectContainer = this.group.shellApi.backgroundContainer;//( this.group as LandGroup ).mainScene.hitContainer.parent;
			this.inputMgr.removeEventListener( display, MouseEvent.MOUSE_UP, this.onMouseRelease );

			this.targetNodes.nodeAdded.remove( this.targetNodeAdded );
			this.targetNodes.nodeRemoved.remove( this.targetNodeRemoved );

			this.targetNodes = this.lightningNodes = null;
			//systemManager.releaseNodeList( LightningTargetNode );

		} //

	} // class

} // package