package game.data.scene.hit
{
	import game.data.ParamList;

	public class EmitterHitData extends HitDataComponent
	{
		public var impactClass:Class;
		public var stepClass:Class;
		
		public var impactParams:ParamList = null;
		public var stepParams:ParamList = null;
		
		public var action:String;
	}
}