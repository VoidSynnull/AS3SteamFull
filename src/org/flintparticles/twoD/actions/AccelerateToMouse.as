/*
 * I added this one to the flint library -Jordan Leary, 10/14/14
 */

package org.flintparticles.twoD.actions 
{
	import flash.display.DisplayObject;
	
	import org.flintparticles.common.actions.ActionBase;
	import org.flintparticles.common.emitters.Emitter;
	import org.flintparticles.common.particles.Particle;
	import org.flintparticles.twoD.particles.Particle2D;

	/**
	 * The AccelerateToPoint Action adjusts the velocity of each particle by a 
	 * constant acceleration towards a specified point. Set axis to "x" or "y"
	 * for movement in only one axis. Set to "both" for both.
	 */
	public class AccelerateToMouse extends ActionBase
	{
		private var _power:Number;
		private var _axis:String;
		private var _renderer:DisplayObject;
		
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
		public function AccelerateToMouse( power:Number = 100, renderer:DisplayObject = null, axis:String = "both" )
		{
			_power = power;
			_axis = axis;
			_renderer = renderer;
		}
		
		override public function update( emitter:Emitter, particle:Particle, time:Number ):void
		{			
			var p:Particle2D = Particle2D( particle );
			
			if (_axis == "x" || _axis == "both") {
				var accelX:Number = (_renderer.mouseX - p.x)*_power/1000;
				p.velX += accelX * time;
			}
			if (_axis == "y" || _axis == "both") {
				var accelY:Number = (_renderer.mouseY - p.y)*_power/1000;
				p.velY += accelY * time;
			}
		}
	}
}
