package game.scenes.virusHunter.heart.components {
	
	import flash.display.DisplayObjectContainer;
	
	import ash.core.Entity;
	
	import ash.core.Component;
	import engine.components.Display;
	import engine.components.Id;
	import engine.components.Spatial;


	public class ArmSegment extends Component {

		static public const DEG_PER_RAD:Number = 180 / Math.PI;
		static public const RAD_PER_DEG:Number = Math.PI / 180;

		public var x:Number;
		public var y:Number;

		public var clip:DisplayObjectContainer;

		/**
		 * Point where the next segment connects. Got rid of arbitrary dx,dy offsets.
		 */
		public var radius:Number;

		/**
		 * Rotation of segment relative to the axis of the previous segment.
		 */
		public var theta:Number;

		/**
		 * Max relative theta between this segment and the previous segment.
		 */
		public var maxTheta:Number = Math.PI/6;

		/**
		 * yeah....
		 */
		public var omega:Number = 0;

		/**
		 * Angle the arm segment reverts to for certain behaviors.
		 */
		public var baseTheta:Number;

		/**
		 * Storing the absolute theta during the rigid arm forward computation
		 * avoids the necessity of recomputing this value for display.
		 * 
		 * It might be useful as general information as well.
		 */
		public var absTheta:Number;

		public var entity:Entity;
		public var spatial:Spatial;

		public function ArmSegment( mc:DisplayObjectContainer ) {

			this.clip = mc;
			this.x = mc.x;
			this.y = mc.y;

			this.spatial = new Spatial( this.x, this.y );
			entity = new Entity()
				.add( this.spatial, Spatial )
				.add( new Id( mc.name ), Id )
				.add( this, ArmSegment )
				.add( new Display( mc ), Display );

			this.absTheta = mc.rotation*RAD_PER_DEG;

		} //

	} // End ArmSegment

} // End package