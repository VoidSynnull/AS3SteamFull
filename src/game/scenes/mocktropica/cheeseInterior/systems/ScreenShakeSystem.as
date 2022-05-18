package game.scenes.mocktropica.cheeseInterior.systems {

	import ash.core.Engine;
	import ash.core.Entity;
	
	import engine.components.Spatial;
	
	import game.scenes.mocktropica.cheeseInterior.components.ScreenShake;
	import game.scenes.mocktropica.cheeseInterior.nodes.ScreenShakeNode;
	import game.systems.GameSystem;
	import game.systems.SystemPriorities;
	
	import org.osflash.signals.Signal;

	/**
	 * Altered screen shake system from Poptropolis - no playAudio() signal, a few different parameters.
	 * 
	 * As that system explains, the method used is for the Camera to follow a Shake Spatial which in turn
	 * follows a reference entity: node.entity (usually the player)  This means the camera will stay glued
	 * to the reference entity ( which may be a static point ) while getting the shake spatial offset.
	 * 
	 * Without the reference entity, the camera wouldn't pan with the moving player.
	 * 
	 * The alternative would be to shake the clips at a level higher than the scene container - probably a bad
	 * idea under this system.
	 */
	public class ScreenShakeSystem extends GameSystem {

		/**
		 * Called when a screen-shake completes. Entity that finished shaking ( usually the player )
		 * is the only parameter.
		 * 
		 * onShakeComplete( Entity )
		 */
		public var onShakeComplete:Signal;

		public function ScreenShakeSystem() {

			super( ScreenShakeNode, this.updateNode, this.addNode, this.removeNode );
			super._defaultPriority = SystemPriorities.move;

			this.onShakeComplete = new Signal( Entity );

		} //

		private function updateNode( node:ScreenShakeNode, time:Number):void {

			var shake:ScreenShake = node.shake;

			if ( shake._enabled == false ) {

				if ( shake._switchEnabled ) {
					this.group.shellApi.camera.target = node.spatial;
					shake._switchEnabled = false;
				}

				return;

			} else if ( shake._switchEnabled ) {

				// If shake was disabled/re-enabled the camera target needs to be set back to the shake again.
				this.group.shellApi.camera.target = shake._shakeTarget;
				shake._switchEnabled = false;

			} //

			shake._shakeTarget.x = node.spatial.x;
			shake._shakeTarget.y = node.spatial.y;

			if ( shake.timedShake ) {

				// TIMED SHAKE

				shake._timer -= time;

				shake._shakeTarget.x += ( shake._timer/shake.shakeTime )*Math.cos( shake.frequency*shake._timer ) * shake.maxShakeX;
				shake._shakeTarget.y += ( shake._timer/shake.shakeTime )*Math.sin( shake.frequency*shake._timer ) * shake.maxShakeY;

				if ( shake._timer <= 0 ) {

					// Surely the camera target needs to be put back now..but then you have to set it back again when re-enabled...
					this.group.shellApi.camera.target = node.spatial;

					shake._timer = 0;
					shake._enabled = false;
					this.onShakeComplete.dispatch( node.entity );

				}

			} else {

				// INFINITE/UNTIMED SHAKE
				shake._timer += time;

				shake._shakeTarget.x += Math.sin( shake.frequency*shake._timer ) * shake.maxShakeX - 2 + 4*Math.random();
				shake._shakeTarget.y += Math.sin( shake.frequency*shake._timer ) * shake.maxShakeY;

			} // end-if.

		} //

		/**
		 * Could have a queue for multiple shakes..but who would do such a thing?
		 */
		private function addNode( node:ScreenShakeNode ):void {

			var shake:ScreenShake = node.shake;

			if ( shake._shakeTarget == null ) {
				shake._shakeTarget = new Spatial( node.spatial.x, node.spatial.y );
			} else {
				shake._shakeTarget.x = node.spatial.x;
				shake._shakeTarget.y = node.spatial.y;
			} //

			this.group.shellApi.camera.target = shake._shakeTarget;

			shake._timer = shake.shakeTime;
			//shake._offsetX = shake._offsetY = 0;

		} //

		/**
		 * Question here of whether to destroy node.shake._shakeTarget
		 * If it's going to be reused, might as well keep it. If not,
		 * better to destroy it.
		 */
		private function removeNode( node:ScreenShakeNode ):void {
			
			var sp:Spatial = node.entity.get( Spatial ) as Spatial;
			if ( sp ) {

				this.group.shellApi.camera.target = sp;

			} else if ( this.group.shellApi.player ) {

				sp = this.group.shellApi.player.get( Spatial );
				if ( sp ) {
					this.group.shellApi.camera.target = sp;
				} else {

					// we've run out of spatials to try. better just give up.

				} //

			} //

		} //

		override public function addToEngine( systemManager:Engine ):void {
			
			if ( this.onShakeComplete == null ) {
				this.onShakeComplete = new Signal( Entity );
			}
			
			super.addToEngine( systemManager );
			
		} //
		
		override public function removeFromEngine(systemManager:Engine):void {
			
			this.onShakeComplete.removeAll();
			this.onShakeComplete = null;
			
		} //

	} // class

} // package