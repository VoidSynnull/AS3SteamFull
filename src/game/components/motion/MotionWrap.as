package game.components.motion
{
	import flash.display.DisplayObject;
	import flash.geom.Point;
	
	import ash.core.Component;
	
	import engine.components.Motion;
	import engine.components.Spatial;
	
	import game.nodes.motion.MotionWrapNode;

	public class MotionWrap extends Component
	{
		/**
		 * <code>MotionWrap</code> component provides a means for wrapping moving layers.
	 	 * The size of the tiles need not be equal or more than the viewport dimensions.
		 * @param	align <code>Boolean</code> for if the tile should be flush with it's neighbor or not.
		 * @param 	subGroup <code>String</code> name of the tile's sub-group used to find the next tile.
		 */
		public function MotionWrap( displayObject:DisplayObject, align:Boolean, subGroup:String, motionRate:Number = 1, autoStart:Boolean = false )
		{
			this.x = displayObject.x;
			this.y = displayObject.y;
			
			this.align = align;
			this.subGroup = subGroup;
			this.motionRate = motionRate;
			this.autoStart = autoStart;
		}
		
		public function createMotion( node:MotionWrapNode ):void
		{
			var motion:Motion = node.motion;
			var motionWrap:MotionWrap = node.motionWrap;
			if( !motionWrap.autoStart )
			{
				motion.pause = true;
			}
			
			motion.velocity = motionWrap.velocity;
			motion.minVelocity = motionWrap.minVelocity;
			motion.maxVelocity = motionWrap.maxVelocity;
			motion.acceleration = motionWrap.acceleration;
			
			if( motion.velocity.x != 0 )
			{
				this.axis = X_AXIS;
			}
			else
			{
				this.axis = Y_AXIS;
			}
		}
		
		public function startMotion( node:MotionWrapNode ):void
		{
			var motion:Motion = node.motion;
			motion.pause = false;
			var motionWrap:MotionWrap = node.motionWrap;
			
			motion.velocity = motionWrap.velocity;
			motion.minVelocity = motionWrap.minVelocity;
			motion.maxVelocity = motionWrap.maxVelocity;
			motion.acceleration = motionWrap.acceleration;
		}
		
		public function stopMotion( node:MotionWrapNode ):void
		{
			var motion:Motion = node.motion;
//			motion.pause = true;
			motion.velocity = new Point( 0, 0);
			motion.minVelocity = new Point( 0, 0 );
			motion.maxVelocity = new Point( 0, 0 );
			motion.acceleration = new Point( 0, 0 );
		}
		
		public var x:Number = 0;
		public var y:Number = 0;
		
		/**
		 * 	<code>Boolean</code> active when on screen.
		 * 
		 * 	@default false
		 */
		public var autoStart:Boolean = false;
		
		/**
		 * <code>Number</code> modifier for this layer follows the player's motionMaster values.
		 * 
		 * @default null
		 */
		public var motionRate:Number = 1;
		
		/**
		 * <code>String</code> name for tile's subgroup.
		 * 
		 * @default null
		 */
		public var subGroup:String = null;

		/**
		 * 	<code>Boolean</code> active when on screen.
		 * 
		 * 	@default false
		 */
		public var active:Boolean = false;
		
		/**
		 * 	<code>Boolean</code> is the left/top most active tile in this sub-group.
		 * 	Used to determine when to wake a new sub-group tile
		 * 
		 * 	@default false
		 */
		public var isFirst:Boolean = false;
		
		/**
		 * 	<code>Boolean</code> is the right/bottom most active tile in this sub-group.
		 * 	Used to determine when to wake a new sub-group tile
		 * 
		 * 	@default false
		 */
		public var isLast:Boolean = false;
		
		/**
		 * 	<code>Boolean</code> is flush with previous tile in sub-group.
		 * 
		 * 	@default true
		 */
		public var align:Boolean = true;
		
		/**
		 * 	<code>Boolean</code> flag for layers that are aligned.  When the layer wakes up it misses a motion cycle and needs to catch up to the previous tile to maintain flush alignment.  
		 * 	Resets to false after first <code>MotionWrapSystem</code> cycle awake.
		 * 
		 * 	@default false
		 */
		public var reposition:Boolean = false;
		
		// PREVIOUS ASSUMES THE LEFT/TOP
		
		/**
		 * <code>Number</code> for the x-axis camera offset.
		 * 
		 * @default 0
		 */
		public var previousLayerOffsetX:Number = 0;
		
		/**
		 * <code>Number</code> for the y-axis camera offset.
		 * 
		 * @default 0
		 */
		public var previousLayerOffsetY:Number = 0;
		
		/**
		 * <code>Motion</code> of the last active tile in this sub-group, used for repositioning in flush-aligned tiles.
		 * 
		 * @default null
		 */
		public var previousMotion:Motion;
		
		/**
		 * <code>Spatial</code> of the last active tile in this sub-group, used for reposition in flush-aligned tiles.
		 * 
		 * @default null
		 */
		public var previousSpatial:Spatial;
		
		// NEXT ASSUMES THE BOTTOM/RIGHT
		public var nextLayerOffsetX:Number = 0;
		public var nextLayerOffsetY:Number = 0;
		public var nextMotion:Motion;
		public var nextSpatial:Spatial;
		
		// USED TO SET THE MOTION ON A TRIGGER
		public var velocity:Point = new Point( 0, 0 );
		public var minVelocity:Point = new Point( 0, 0 );
		public var maxVelocity:Point = new Point( Infinity, Infinity );
		public var acceleration:Point = new Point( 0, 0 );
		
		public var axis:String;
		public const X_AXIS:String 			= 		"x";
		public const Y_AXIS:String			=		"y";
	}
}