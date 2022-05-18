package game.components.entity.character.animation
{
	import ash.core.Component;
	
	import game.data.animation.Animation;
	import game.util.ClassUtils;
	
	import org.osflash.signals.Signal;
	
	public class RigAnimation extends Component
	{
		public function RigAnimation()
		{
			partsApplied = new Vector.<String>();
			queue = new Vector.<Class>();
			ended = new Signal( Animation );
		}

		// Parts 
		public var partsApplied:Vector.<String>;				// array of joint names signifying which joints the animation will be applied to
		
		// Controls
		private var _end:Boolean;								// flag that animation has ended
		public function get end():Boolean	{ return _end; }
		/**
		 * Shoudl only be set by AnimationEndSystem
		 * @param bool
		 */
		public function set end( bool:Boolean):void
		{
			if( _end != bool ){
				_end = bool;
				if ( _end )	{ 
					ended.dispatch( _current ); 
				}
			}
			
			if( _end )
			{
				waitForEnd = false;
			}
		}
		
		public var ended:Signal;
		public var duration:int = 0;							// duration in frames current animation will play for, when reaches 0 end is set to true
		public var nextDuration:int = 0;						// duration that should to be set when next becomes current
		public var loop:Boolean = false;
		public var manualEnd:Boolean;							// manually end an animation, will be processed by AnimationEndSystem, which sets end 
		public var waitForEnd:Boolean = false;					// flag indicating that next should not active until current has reached end
		
		// Animations	
		public var previous:Animation;							// animation that was last active
		
		private var _next:Class;  								// uninstantiated Animation class ( data/animation/entity/character )
		public function get next():Class						{ return _next; }
		public function set next( animClass:Class ):void
		{
			//If the current animation isn't the same as the new one...
			if ( ClassUtils.getClassByObject(_current) != animClass)
			{
				//And the next animation doesn't equal the new one.
				if(_next != animClass)
				{
					_next = animClass;
				}
			}
			//If current animation is the same as the new one, and we have a next animation, set it to null so it doesn't override the current/new animation we want.
			else
			{
				_next = null;
			}
		}
		
		private var _current:Animation;							// animation that is currently active
		public function get current():Animation					{ return _current; }
		public function set current( anim:Animation ):void
		{
			previous = _current;
			_current = anim;
			_next = null;
		}
		
		public var queue:Vector.<Class>;						// queue of aniamtion classes, FIFO, 
		
		/**
		 * Helper function to create a RigAnimation
		 * @param	animClass - Animation Class
		 * @param	...args - name of joints that animation should apply to
		 * @return
		 */
		public static function create( animClass:Class = null, ...args ):RigAnimation
		{
			var rigAnim:RigAnimation = new RigAnimation();
			rigAnim.next = animClass;
			
			for ( var i:int = 0; i < args.length; i++ )
			{
				rigAnim.partsApplied.push( String(args[i]) );	// TODO :: probably want to do some checking here for valid ids
			}
			
			return rigAnim;
		}
		
		/**
		 * Add names of joints that the animation will apply to 
		 * @param	...args - name of joints that animation should apply to
		 * @return
		 */
		public function addParts( ...args ):void
		{
			for ( var i:int = 0; i < args.length; i++ )
			{
				partsApplied.push( String(args[i]) );	// TODO :: probably want to do some checking here for valid ids
			}
		}
		
		/**
		 * Get the index of the specified labels, if not found returns -1
		 */
		public function getLabelIndex( label:String ):int
		{
			return _current.data.getLabelIndex( label );
		}
	}
}
