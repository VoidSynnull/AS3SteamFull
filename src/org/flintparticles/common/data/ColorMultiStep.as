package org.flintparticles.common.data 
{
	/**
	 * Allows for particles to shift between multiple colors.
	 * Each color is defined by a <code>ColorStep</code> class, which are managed by the ColorMultiStep.
	 * @author ... Bard McKinley
	 */
	public class ColorMultiStep
	{
		private var _steps:Vector.<ColorStep>;

		public function ColorMultiStep() 
		{
			_steps = new Vector.<ColorStep>();
		}
		
		public function addColorStep( colorStep:ColorStep ):void
		{
			if ( _steps.length == 0 )
			{
				_steps.push( colorStep )
			}
			else
			{
				var i:int = 0;
				for ( i; i < _steps.length; i++)
				{
					if ( colorStep.energy > _steps[i].energy  )
					{
						_steps.splice( i, 0, colorStep );
						return;
					}
				}
				_steps.push( colorStep );
			}
		}

		public function getCurrentIndex( energy:Number ):int
		{
			var i:int = 0;
			for ( i; i < _steps.length; i++)
			{
				if ( energy > _steps[i].energy  )
				{
					return i;
				}
			}
			return -1;
		}
		
		public function getStepAt( index:int ):ColorStep 
		{
			if ( index < _steps.length )
			{
				return _steps[index];
			}
			return null;
		}
		
		public function get steps():Vector.<ColorStep> 
		{
			return _steps;
		}
	}
}