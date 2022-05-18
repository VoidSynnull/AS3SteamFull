/*
 * FLINT PARTICLE SYSTEM
 * .....................
 * 
 * Author: Richard Lord
 * Copyright (c) Richard Lord 2008-2011
 * http://flintparticles.org
 * 
 * 
 * Licence Agreement
 * 
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 * 
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 * 
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 */

package org.flintparticles.common.actions 
{
	import org.flintparticles.common.data.ColorMultiStep;
	import org.flintparticles.common.data.ColorStep;
	import org.flintparticles.common.emitters.Emitter;
	import org.flintparticles.common.particles.Particle;
	import org.flintparticles.common.utils.interpolateColors;	

	/**
	 * The ColorMultiChange action alters the color of the particle as it ages.
	 * It uses the particle's energy level to decide what colour to display.
	 * Unlike ColorChange ColorMultiChange is able to alter between multiple colors.
	 * 
	 * <p>Usually a particle's energy changes from 1 to 0 over its lifetime, but
	 * this can be altered via the easing function set within the age action.</p>
	 * 
	 * <p>This action should be used in conjunction with the Age action.</p>
	 * 
	 * @see org.flintparticles.common.actions.Action
	 * @see org.flintparticles.common.actions.Age
	 */

	public class ColorMultiChange extends ActionBase
	{
		private var _colorSteps:ColorMultiStep;
		private var _startStep:ColorStep;
		private var _endStep:ColorStep;
		
		/**
		 * The constructor creates a ColorChange action for use by an emitter. 
		 * To add a ColorChange to all particles created by an emitter, use the
		 * emitter's addAction method.
		 * @param	colorStep1 - need at least 2 ColorSteps, this is the 1st
		 * @param	colorStep2 - need at least 2 ColorSteps, this is the 2nd
		 * @param	...args - other args need to be ColorStep as well.
		 */
		
		public function ColorMultiChange( colorStep1:ColorStep, colorStep2:ColorStep, ...args  )
		{
			_colorSteps = new ColorMultiStep();
			
			args.unshift( colorStep1, colorStep2 );
			
			var i:int = args.length - 1;
			for ( i; i > -1; i-- )
			{
				_colorSteps.addColorStep( ColorStep( args[i] ) );
			}	
		}
		
		public function addColorStep( color:Number, range:Number ):void
		{
			_colorSteps.addColorStep( new ColorStep( color, range ) );
		}
		
		/**
		 * Sets the color of the particle based on the color steps and the particle's 
		 * energy level.
		 * 
		 * <p>This method is called by the emitter and need not be called by the 
		 * user</p>
		 * 
		 * @param	emitter
		 * @param	particle
		 * @param	time
		 */
		override public function update( emitter:Emitter, particle:Particle, time:Number ):void
		{
			var index:int = _colorSteps.getCurrentIndex( particle.energy );
			
			if ( index > 0 )
			{
				_startStep = _colorSteps.steps[index-1];
				_endStep = _colorSteps.steps[index]; 
				// get percent of previous by dividing energy difference of current and next step by energy difference of start and end steps.
				particle.color = interpolateColors( _startStep.color, _endStep.color, (particle.energy - _endStep.energy) / (_startStep.energy - _endStep.energy) );
			}
			else if( index == 0 )
			{
				particle.color = _colorSteps.steps[0].color;
			}
			else
			{
				particle.color = _colorSteps.steps[_colorSteps.steps.length-1].color;
			}
		}
	}
}
