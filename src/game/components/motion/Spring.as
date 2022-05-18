package game.components.motion
{	
	
	import flash.geom.Point;
	
	import ash.core.Component;
	import engine.components.Spatial;
	
	import game.data.motion.spring.SpringData;
	
	import org.osflash.signals.Signal;
	
	public class Spring extends Component
	{
		public function Spring( leader:Spatial = null, spring:Number = .01, damp:Number = .95 )
		{
			this.spring = spring;
			this.damp = damp;
			this.leader = leader;
			
			_velocity = new Point(0, 0);
			
			reachedLeader = new Signal();
		}
		
		public var leader:Spatial;
		public var startPositioned:Boolean 	= true;	// positions to target on first spring update
		public var spring:Number 	= 0;
		public var damp:Number 		= 0;
		public var offsetX:Number 	= 0;
		public var offsetY:Number 	= 0;
		public var offsetXOffset:Number = 0;
		public var offsetYOffset:Number = 0;
		public var rotateRatio:Number = .5;
		
		// reached leader
		public var reachedLeader:Signal;	// dispatchs only if it has listeners
		public var threshold:int = 5;		// threshold that delta distance and velocity must be below to trigger reachedLeader
		
		// used internally
		public var _velocity:Point;
		
		private var _rotateByVelocity:Boolean = false;
		public function get rotateByVelocity():Boolean	{ return _rotateByVelocity; }
		public function set rotateByVelocity( bool:Boolean):void
		{
			_rotateByVelocity = bool;
			if ( _rotateByVelocity )
			{
				_rotateByLeader = false;
			}
		}
		
		private var _rotateByLeader:Boolean = false;
		public function get rotateByLeader():Boolean	{ return _rotateByLeader; }
		public function set rotateByLeader( bool:Boolean):void
		{
			_rotateByLeader = bool;
			if ( _rotateByLeader )
			{
				_rotateByVelocity = false;
			}
		}
		
		/**
		 * Apply SpringData to Spring variables
		 * @param	springData
		 */
		public function applyData( springData:SpringData ):void
		{
			this.rotateByVelocity	= springData.rotateByVelocity;
			this.rotateByLeader		= springData.rotateByLeader;
			this.offsetX 			= springData.offsetX;
			this.offsetY 			= springData.offsetY;
			
			if ( springData.spring > 0 )
			{
				this.spring = springData.spring;
			}
			if ( springData.damp > 0 )
			{
				this.damp = springData.damp;
			}
			if ( springData.rotateRatio > 0 )
			{
				this.rotateRatio = springData.rotateRatio;
			}
		}
	}
}