package game.data.scene.hit
{
	import ash.core.Component;
	
	public class HitDataComponent extends Component
	{
		public var type:String;
		public var visible:String;
		public var visibles:Array;	// incase we need multiple visible assets to follow a hit.
		public var xml:XML;  // the original, unparsed xml.  This can be used for custom hits.
		public var followProperties:Array;
	}
}