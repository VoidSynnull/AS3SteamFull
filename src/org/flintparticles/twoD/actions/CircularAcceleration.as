/*
 * I added this one to the flint library -Jordan Leary, 5/1/13
 */

package org.flintparticles.twoD.actions
{
	import org.flintparticles.common.actions.ActionBase;
	import org.flintparticles.common.emitters.Emitter;
	import org.flintparticles.common.particles.Particle;
	import org.flintparticles.twoD.particles.Particle2D;	

	/**
	 * CircularAcceleration will accelerate particles around in a circle,
	 * simulating particles blowing in the wind in a sort of vortex.
	 */
	public class CircularAcceleration extends ActionBase
	{
		private var _x:Number;
		private var _y:Number;
		private var _magnitude:Number;
		private var _angularSpeed:Number;
		
		/**
		 * The constructor creates an Acceleration action for use by an emitter. 
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
		public function CircularAcceleration(magnitude:Number, angularSpeed:Number )
		{
			_magnitude = magnitude;
			_angularSpeed = angularSpeed;
		}
		
		override public function update( emitter:Emitter, particle:Particle, time:Number ):void
		{			
			var p:Particle2D = Particle2D( particle );
			//Currently using particle's age for time step. This would conflict if also using the Age action, so would be ideal to add special timeStep to particles.
			p.age += _angularSpeed * time;
			_x = _magnitude*Math.cos(p.age);
			_y = _magnitude*Math.sin(p.age);
			p.velX += _x * time;
			p.velY += _y * time;
		}
	}
}
