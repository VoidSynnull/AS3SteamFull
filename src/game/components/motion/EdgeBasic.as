package game.components.motion {

	import ash.core.Component;

	// Mimics basic edge data without extraneous dictionary, EdgeData objects.
	public class EdgeBasic extends Component {

		public var top:Number;
		public var left:Number;
		public var right:Number;
		public var bottom:Number;

		public function EdgeBasic( left:Number=0, top:Number=0, right:Number=0, bottom:Number=0 ) 
		{
			this.left = left;
			this.top = top;
			this.right = right;
			this.bottom = bottom;
		}
	}
}