package game.data.animation 
{
	import game.data.animation.AnimationData;
	/**
	 * ...
	 * @author Bard
	 */
	public class AnimationSequence
	{
		public var random:Boolean = false;
		public var loop:Boolean = true;
		//public var end:Boolean = false;
		
		private var _sequence:Vector.<AnimationData>;
		public function get sequence():Vector.<AnimationData>	{ return _sequence; }
		
		/**
		 * Can pass Aniamtion Classes directly into constructor to instatiate sequence.
		 */
		public function AnimationSequence( ...rest )
		{
			_sequence = new Vector.<AnimationData>();
			
			if( rest.length > 0 ) 
			{
				for ( var i:int = 0; i < rest.length; i++ )
				{
					this.add( new AnimationData( rest[i] ) );
				}
			}
		}
		
		public static function create( ...rest ):AnimationSequence
		{
			var animSequence:AnimationSequence = new AnimationSequence();
			for ( var i:int = 0; i < rest.length; i++ )
			{
				animSequence.add( new AnimationData( rest[i] ) );
			}
			return animSequence;
		}
		
		public function add( animData:AnimationData ):void
		{
			_sequence.push( animData );
		}
		
		/**
		 * 
		 * @param	...rest : AnimationDatas 
		 */
		public function replace( ...rest ):void
		{
			_sequence.length = 0;
			for ( var i:int = 0; i < rest.length; i++ )
			{
				add( rest[i] );
			}
		}
		
		public function duplicate():AnimationSequence
		{
			var animSequence:AnimationSequence = new AnimationSequence();
			animSequence.random 				= this.random;
			animSequence.loop 					= this.loop;
			
			for ( var i:int = 0; i < _sequence.length; i++ )
			{
				animSequence.add( _sequence[i].duplicate() );
			}
			return animSequence;
		}
		
		public function getAnimDataAt( index:int ):AnimationData
		{
			if ( _sequence.length > 0 )
			{
				if ( index > -1 && index < _sequence.length )
				{
					return _sequence[index];
				}
			}
			return null;
		}
	}

}