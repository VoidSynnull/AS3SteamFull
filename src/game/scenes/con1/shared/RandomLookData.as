package game.scenes.con1.shared
{
	import game.data.character.LookData;

	public class RandomLookData
	{
		public function RandomLookData(xml:XML, gender:String = "both", island:String = "default")
		{
			this.gender = gender;
			this.island = island;			
			lookData = new LookData(xml);
		}
		
		public var gender:String;
		public var island:String;
		public var lookData:LookData;
		
		public static var MALE:String = "male";
		public static var FEMALE:String = "female";
		public static var BOTH:String = "both";
	}
}