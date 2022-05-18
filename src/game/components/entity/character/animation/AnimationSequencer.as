package game.components.entity.character.animation
{
	import ash.core.Component;
	
	import game.data.animation.AnimationSequence;

	/**
	 * Current animation info for Rig based Entity
	 */
	public class AnimationSequencer extends Component
	{
		//public var current:RigAnimation;			// current RigAnimation 
		public var index:int;						// index of current RigAnimation within currentSequence
		public var start:Boolean = false;			// flag to begin animation sequence

		// current AnimationSequence data
		private var _currentSequence:AnimationSequence;		
		public function get currentSequence():AnimationSequence	{ return _currentSequence; }
		public function set currentSequence( value:AnimationSequence ):void
		{
			_currentSequence = value;
			determineActive();
		}
		
		// default AnimationSequence data ( current reverts to default when current == null )
		private var _defaultSequence:AnimationSequence;		
		public function get defaultSequence():AnimationSequence	{ return _defaultSequence; }
		public function set defaultSequence( value:AnimationSequence ):void
		{
			_defaultSequence = value;
			determineActive();
		}
		
		private function determineActive():void
		{
			this.active = ( _defaultSequence != null || _currentSequence != null );
		}

		public var active:Boolean = false;				// set to active it contains currentSequence or defaultSequence
		public var interrupt:Boolean = false;			// flag used to interrupt a sequence, interrupt will be set back to false once it detects an animation end.
		
		/**
		 * Sets a sequence with null as the only animation, when null is found by AnimationSequenceSystem it defaults to stateDriven.
		 * Used when sequence needs to be interrupted temporarily, e.g. talking 
		 */
		public function interruptSequence():void
		{
			this.currentSequence = _emptySequence;
		}
		private var _emptySequence:AnimationSequence = AnimationSequence.create( null );	
		
		/**
		 * Resets sequence to default.
		 */
		public function reset():void
		{
			this.currentSequence = _defaultSequence;
		}
	}
}
