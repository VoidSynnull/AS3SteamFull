package game.data.character
{
import game.util.DataUtils;
import game.util.Utils;

	/**
	 * Basic class used to send and receive look data for player from server
	 */
	public class PlayerLook
	{

		public static function instanceFromJSON(json:String):PlayerLook
		{
			// sample JSON: {"eyes":"eyes","overpants":null,"overshirt":null,"eyeState":"open","skinColor":9321734,"hairColor":16763955,"pack":null,"item":null,"mouth":"15","facial":"empty","marks":"empty","hair":"1","item2":null,"pants":"2","gender":0,"shirt":"2"}
			var instance:PlayerLook = new PlayerLook();
			Utils.overlayObjectProperties(JSON.parse(json), instance);
			return instance;
		}

		public function PlayerLook()
		{
		}
		
		public var gender:int;
		public var skinColor:Number;
		public var hairColor:Number;
		public var eyeState:String;
		public var marks:String;
		public var mouth:String;
		public var facial:String;
		public var hair:String;
		public var pants:String;
		public var shirt:String;
		public var overpants:String;
		public var overshirt:String;
		public var item:String;
		public var item2:String;
		public var pack:String;
		public var eyes:String;

		public function toString():String
		{
			return "[PlayerLook: " +
				"gender=" + gender + ", " +
				"skinColor=" + skinColor + ", " +
				"hairColor=" + hairColor + ", " +
				"eyeState=" + eyeState + ", " +
				"marks=" + marks + ", " +
				"mouth=" + mouth + ", " +
				"facial=" + facial + ", " +
				"hair=" + hair + ", " +
				"pants=" + pants + ", " +
				"shirt=" + shirt + ", " +
				"overpants=" + overpants + ", " +
				"overshirt=" + overshirt + ", " +
				"item=" + item + ", " +
				"item2=" + item2 + ", " +
				"pack=" + pack + ", " +
				"eyes=" + eyes + "]";
		}

		public function toJSONString():String {
			return DataUtils.toPrunedJSONString(this);
		}

	}
}