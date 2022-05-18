package game.systems.actionChain.actions
{
	import flash.geom.Rectangle;
	
	import ash.core.Entity;
	
	import engine.components.Spatial;
	import engine.group.Group;
	import engine.group.Scene;
	import engine.systems.CameraSystem;
	import game.systems.actionChain.ActionCommand;
	import game.nodes.specialAbility.SpecialAbilityNode;

	// Pan camera to target
	public class PanAction extends ActionCommand
	{
		private var moveRate:Number;
		private var minDist:Number = 30;

		private var _target:Spatial; // _target's x,y (NOTE: targets moving at high speed might have trouble registering a successful pan since the camera never settles on them)
		private var _camera:CameraSystem;
		private var _cameraBounds:Rectangle;
		private var _saveRate:Number;
		private var _callback:Function;

		/**
		 * Pan camera to target 
		 * @param targetEntity		Entity to pan toward
		 * @param moveRate			Rate of panning
		 * @param minDist			Minimum distance near entity for pan action to complete
		 * 
		 * If the pan _target is about in the middle of the screen, minDist will be the distance to the pan target
		 * But if the pan _target is near a screen edge, this will just be how close the camera is to its final panning position
		 */
		public function PanAction( targetEntity:Entity, moveRate:Number = 0.2, minDist:Number = 30 )
		{
			super.entity = targetEntity;
			this.moveRate = moveRate;
			this.minDist = minDist;
		}

		override public function preExecute( callback:Function, group:Group, node:SpecialAbilityNode = null ):void
		{
			this.update = this.checkPan;

			if( super.entity  )
			{
				this._target = super.entity.get( Spatial );
				if( this._target )
				{
					this._camera = group.getSystem( CameraSystem ) as CameraSystem;
					this._camera.jumpToTarget = false;
					this._cameraBounds = ( group as Scene ).sceneData.cameraLimits;
					
					this._camera.target = this._target;
					
					// temporarily save camera rate.
					this._saveRate = this._camera.rate;
					this._camera.rate = moveRate;
					
					this._callback = callback;
					return
				}
			}
			
			callback();
		}

		/**
		 * checks if the entity is centered in the camera - or as close as it can get.
		 */
		public function checkPan( time:Number ):void
		{
			var halfw:Number = this._camera.viewportWidth*0.5/this._camera.scale;
			var halfh:Number = this._camera.viewportHeight*0.5/this._camera.scale;

			// tx,ty will end up computing the left,top edge of the camera _target. (scaling applies)
			// onscreen the camera is further offset by viewportWidth/2,viewportHeight/2 (unscaled)

			var tx:Number = this._target.x;
			if ( tx < ( this._cameraBounds.left + halfw) ) {
				tx = this._cameraBounds.left + halfw - this._camera.viewportWidth/2;
			} else if ( tx > (_cameraBounds.right - halfw) ) {
				tx = this._cameraBounds.right - halfw - this._camera.viewportWidth/2;
			} else {
				tx -= this._camera.viewportWidth/2;
			}

			tx = (-tx - this._camera.viewport.width*0.5) - this._camera.x;

			var ty:Number = _target.y;
			if ( ty < ( this._cameraBounds.top + halfh ) ) {
				ty = this._cameraBounds.top + halfh - this._camera.viewportHeight/2;
			} else if ( ty > ( this._cameraBounds.bottom - halfh) ) {
				ty = this._cameraBounds.bottom - halfh - this._camera.viewportHeight/2;
			} else {
				ty -= this._camera.viewportHeight/2;
			}

			ty = (-ty - this._camera.viewportHeight*0.5) - this._camera.y;

			if ( (tx*tx + ty*ty) < this.minDist*this.minDist ) {
				this._camera.rate = this._saveRate;
				this._callback();
			}
		}
	}
}