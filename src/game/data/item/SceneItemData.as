package game.data.item 
{
	import game.data.scene.labels.LabelData;

	public class SceneItemData 
	{
		public var id:String;     // unique string to identify this
		public var x:Number;
		public var y:Number;
		public var rotation:Number;
		public var asset:String;
		public var label:LabelData;
		public var event:String;
		public var collection:String;
		public var triggeredByEvent:String;
	}
}