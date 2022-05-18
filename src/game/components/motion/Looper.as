package game.components.motion
{
	import flash.geom.Point;
	
	import ash.core.Component;
	import ash.core.Entity;
	
	import engine.components.Motion;
	
	import game.components.Emitter;
	import game.nodes.hit.LooperHitNode;
	
	public class Looper extends Component
	{
		public function Looper( visualWidth:Number = NaN, visualWidth:Number = NaN, isSegment:Boolean = false, alwaysOn:Boolean = false, type:String = null )
		{
			this.visualWidth = visualWidth;
			this.visualHeight = visualHeight;
			
			this.isSegment = isSegment;
			this.alwaysOn = alwaysOn;
			this.type = type;
		}
		
		public function startMotion( motion:Motion ):void
		{
			motion.velocity = this.velocity;
			motion.minVelocity = this.minVelocity;
			motion.maxVelocity = this.maxVelocity;
			motion.acceleration = this.acceleration;
		}
		
		public function toggleEvent( event:String ):void
		{
			if( this.event == event )
			{
				this.inactive = false;
			}
			else
			{
				this.inactive = true;
			}
		}
		
		public function stopMotion( node:LooperHitNode ):void
		{
			var motion:Motion = node.motion;
			
			motion.maxVelocity = new Point( 0, 0 );
			motion.acceleration = new Point( 0, 0 );
		}
		
		
		/**
		 * <code>String</code> optional event name for when to activate looper object.
		 * 
		 * @default null
		 */
		private var _event:String;
		
		public function get event():String  { return _event; }
		public function set event( event:String ):void 
		{
			if( event )
			{
				_event = event;
				inactive = true;
			}
		}
		
		/**
		 * <code>Boolean</code> flag for syncing the tiles and entities
		 */
		public var linkedToTiles:Boolean = true;
		
		public var firstLinkCheck:Boolean = true;
		/**
		 * <code>Entity</code> of the following visual.
		 */
		public var visualEntity:Entity;
		
		/**
		 * <code>Boolean</code> flag for looper object turning off.
		 * 
		 * @default false
		 */
		public var inactive:Boolean = false;
		
		
		/**
		 *  <code>Boolean</code> for first object, put any other loopers to sleep.
		 * 
		 *  @default false
		 */
		public var isFirst:Boolean = false;
		
		/**
		 *  <code>Boolean</code> for last object
		 * 
		 *  @default false
		 */
		public var isLast:Boolean = false;
		/**
		 *  <code>Boolean</code> flag set true when collision is detected, is set back to false on next update.
		 * 
		 *  @default false
		 */
//		public var collided:Boolean = false;
		
		/**
		 *  Optional <code>Number</code> to reposition the hit correctly if the visual is wider.
		 * 
		 *  @default NaN
		 */
		
		public var colliders:Vector.<Entity> = new Vector.<Entity>;
		
		public var visualWidth:Number = NaN;
		
		/**
		 *  Optional <code>Number</code> to reposition the hit correctly if the visual is taller.
		 * 
		 *  @default NaN
		 */
		public var visualHeight:Number = NaN;
		
		/**
		 * Velocity <code>Point</code> for starting velocity of the object.  Utilizes MOTION SYSTEM.
		 * 
		 * @default Point( 0, 0 )
		 */
		public var velocity:Point = new Point( 0, 0 );
		
		/**
		 * Minimum Velocity <code>Point</code> for minimum velocity of the object.  Utilizes MOTION SYSTEM.
		 * 
		 * @default Point( 0, 0 )
		 */
		public var minVelocity:Point = new Point( 0, 0 );
		
		/**
		 * Maximum Velocity <code>Point</code> for maximum 'normal' velocity of the object.  Utilizes MOTION SYSTEM.
		 * 
		 * @default Point( 0, 0 ) - overwrites in scene creation, ideally to prevent objects flying away forever fast. 
		 */
		public var maxVelocity:Point = new Point( 0, 0 );
		
		/**
		 * Normal Acceleration <code>Point</code> to be applied to the object.  Utilizes MOTION SYSTEM.
		 * 
		 * @default Point( 0, 0 )
		 */
		public var acceleration:Point = new Point( 0, 0 );
		
		/**
		 *               !!!!!!!!    EXPASION SECTION    !!!!!!!!
		 * For new looping hits
		 * I was thinking it would be easy to write a "ramp", "booster", "pit".  We can then have the system fire their ID and the 
		 * fsm will handle what happens in that exact instance.
		 */
		/**
		 * Boost Acceleration <code>Point</code> to be applied to the object on imagined "boost" hit.  Utilizes MOTION SYSTEM.
		 * 
		 * @default Point( 0, 0 )
		 */
		public var boostAcceleration:Point = new Point( 0, 0 );
		
		/**
		 * Maximum Boost Velocity <code>Point</code> to be applied to the object on imagined "boost" hit.  Utilizes MOTION SYSTEM.
		 * 
		 * @default Point( 0, 0 )
		 */
		public var boostMaxVelocity:Point = new Point( 0, 0 );
		
		
		// HOPEFULLY CAN TAKE THE PLACE OF EMITTER 1 & 2 and GET RID OF THAT ID STRING PARSING
		
		public var emitters:Vector.<Emitter>;
		public var type:String;
		
		// EXPANSION FOR SEGMENTS
		public var isSegment:Boolean = false;
		public var startX:Number;
		public var startY:Number;
		public var alwaysOn:Boolean = false;
	}
}