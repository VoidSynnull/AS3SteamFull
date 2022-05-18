/*
 * I added this one to the flint library -Jordan Leary, 2/13/14
 */

package org.flintparticles.twoD.actions 
{
	import org.flintparticles.common.actions.ActionBase;
	import org.flintparticles.common.emitters.Emitter;
	import org.flintparticles.common.particles.Particle;
	import org.flintparticles.twoD.particles.Particle2D;	

	/**
	 * The AccelerateToPoint Action adjusts the velocity of each particle by a 
	 * constant acceleration towards a specified point. Set axis to "x" or "y"
	 * for movement in only one axis. Set to "both" for both.
	 */
	public class AccelerateToPoint extends ActionBase
	{
		private var _targetX:Number;
		private var _targetY:Number;
		private var _power:Number;
		private var _axis:String;
		
		/**
		 * The constructor creates an AccelerationToPoint action for use by an emitter. 
		 * To add an Accelerator to all particles created by an emitter, use the
		 * emitter's addAction method.
		 * 
		 * @see org.flintparticles.common.emitters.Emitter#addAction()
		 * 
		 * @param accelerationX The x coordinate of the acceleration to apply, in
		 * pixels per second per second.
		 * @param accelerationY The y coordinate of the acceleration to apply, in 
		 * pixels per second per second.
		 */
		public function AccelerateToPoint( power:Number = 100, targetX:Number = 0, targetY:Number = 0, axis:String = "both" )
		{
			_targetX = targetX;
			_targetY = targetY;
			_power = power;
			_axis = axis;
		}
		
		override public function update( emitter:Emitter, particle:Particle, time:Number ):void
		{			
			var p:Particle2D = Particle2D( particle );
			
			if (_axis == "x" || _axis == "both") {
				var accelX:Number = (_targetX - p.x)*_power/1000;
				p.velX += accelX * time;
			}
			if (_axis == "y" || _axis == "both") {
				var accelY:Number = (_targetY - p.y)*_power/1000;
				p.velY += accelY * time;
			}
		}
	}
}
