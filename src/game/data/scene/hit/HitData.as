/**
 * Stores data for a hit entity not specific to one of its hit components.
 */

package game.data.scene.hit 
{
	import flash.utils.Dictionary;
	
	import ash.core.Component;

	public class HitData extends Component
	{
		public var id:String;
		public var visible:String;
//		public var visibles:Array;
		public var color:uint;
		public var platform:Boolean;
		public var wrapX:uint;
		public var components:Dictionary;	// Dictionary of HitComponentData, with HitComponentData.type as key
	}
}