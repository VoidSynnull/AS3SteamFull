package game.data.scene
{
	import flash.utils.Dictionary;

	import game.data.scene.labels.LabelData;

	public class DoorData
	{
		public var destinationScene:String;
		public var destinationSceneX:Number;
		public var destinationSceneY:Number;
		public var destinationSceneDirection:String;
		public var label:LabelData;
		public var sound_doorOpened:String;
		public var type:String;
		public var id:String;
		public var openOnHit:Boolean;
		public var connectingSceneDoors:Dictionary;
		public var event:String;
		public var triggeredByEvent:String;
		public var destinationSceneOld:String;
		//public var destinationSceneXOld:Number;
		//public var destinationSceneYOld:Number;
		//public var destinationSceneDirectionOld:String;
		public var minDistanceX:Number;
		public var minDistanceY:Number;
		public var adDoor:Boolean;
		public var skipAdType:String;
		public var campaignName:String;
		public var multiplayer:Boolean = false;

		public function DoorData() {}

		// TODO: get a better distinction for common room doors
		public function get doorLeadsToCommonRoom():Boolean
		{
			// TODO :: Fix this, shouldn't rely on label to determine common room.  Just add an attribute. - bard
			if(!label)
				return false;

			return -1 < label.text.toUpperCase().indexOf('COMMON ROOM');
		}

		public function toString():String {
			return '[DoorData type:' + type + ' id:' + id + ' label:' + label + ']';
		}
	}
}
