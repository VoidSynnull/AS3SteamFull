package game.particles.emitter.specialAbility 
{
	import org.flintparticles.common.actions.ActionBase;
	import org.flintparticles.common.emitters.Emitter;
	import org.flintparticles.common.particles.Particle;
	import org.flintparticles.twoD.particles.Particle2D;
	
	/**
	 * This adds a sine vibration to an existing x velocity
	 * 
	 * <p>This action has a priority of -10, so that it executes after other actions.</p>
	 */
	public class SineVibrate extends ActionBase
	{
		private var _spikeRad:Number;
		private var _spikeInc:Number;
		private var _time:Number = 0;
		
		/**
		 * The constructor creates a SineVibrate action for use by an emitter. 
		 * To add a SineVibrate to all particles created by an emitter, use the
		 * emitter's addAction method.
		 */
		public function SineVibrate(spikeRad:Number, spikeInc:Number)
		{
			priority = -10;
			_spikeRad = spikeRad;
			_spikeInc = spikeInc;
		}
		
		/**
		 * Updates the particle's position based on its velocity and the period of 
		 * time indicated.
		 * 
		 * <p>This method is called by the emitter and need not be called by the 
		 * user.</p>
		 * 
		 * @param emitter The Emitter that created the particle.
		 * @param particle The particle to be updated.
		 * @param time The duration of the frame - used for time based updates.
		 */
		override public function update( emitter:Emitter, particle:Particle, time:Number ):void
		{
			var p:Particle2D = Particle2D( particle );
			// if no offset for radians, then add it now
			if (p.dictionary["offset"] == null)
				p.dictionary["offset"] = Math.random() * 2 * Math.PI;
			// increment time
			_time += time;
			// apply sine offset to x direction
			p.x += (Math.sin( p.dictionary["offset"] + _spikeInc * _time) * _spikeRad);
		}
	}
}

